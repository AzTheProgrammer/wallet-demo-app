import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/auth/domain/entities/biometric_status.dart';
import 'package:wallet_app/features/auth/domain/usecases/auth_usecases.dart';
import 'package:wallet_app/features/auth/presentation/change_pin/change_pin_cubit.dart';
import 'package:wallet_app/features/auth/presentation/pin_entry/pin_entry_cubit.dart';
import 'package:wallet_app/features/auth/presentation/pin_setup/pin_setup_cubit.dart';
import 'package:wallet_app/features/auth/presentation/session/session_cubit.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

const usable = BiometricStatus(available: true, enabled: true);

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const ChangePinParams(current: '', next: ''));
  });

  group('SessionCubit', () {
    late MockCheckPinExists check;
    late MockClock clock;

    setUp(() {
      check = MockCheckPinExists();
      clock = MockClock();
      when(() => clock.now()).thenReturn(fixedNow);
    });

    blocTest<SessionCubit, SessionStatus>(
      'goes to onboarding without a PIN',
      setUp: () =>
          when(() => check(any())).thenAnswer((_) async => right(false)),
      build: () => SessionCubit(check, clock),
      act: (cubit) => cubit.bootstrap(),
      expect: () => [SessionStatus.onboarding],
    );

    blocTest<SessionCubit, SessionStatus>(
      'locks when a PIN exists',
      setUp: () =>
          when(() => check(any())).thenAnswer((_) async => right(true)),
      build: () => SessionCubit(check, clock),
      act: (cubit) => cubit.bootstrap(),
      expect: () => [SessionStatus.locked],
    );

    blocTest<SessionCubit, SessionStatus>(
      'fails safe to locked when storage breaks',
      setUp: () => when(
        () => check(any()),
      ).thenAnswer((_) async => left(const StorageFailure())),
      build: () => SessionCubit(check, clock),
      act: (cubit) => cubit.bootstrap(),
      expect: () => [SessionStatus.locked],
    );

    blocTest<SessionCubit, SessionStatus>(
      'authenticates and locks on request',
      build: () => SessionCubit(check, clock),
      act: (cubit) => cubit
        ..authenticated()
        ..lock(),
      expect: () => [SessionStatus.authenticated, SessionStatus.locked],
    );

    blocTest<SessionCubit, SessionStatus>(
      'stays open after a short trip to the background',
      build: () => SessionCubit(check, clock),
      seed: () => SessionStatus.authenticated,
      act: (cubit) => cubit
        ..backgrounded()
        ..resumed(),
      expect: () => <SessionStatus>[],
    );

    blocTest<SessionCubit, SessionStatus>(
      'locks after a long trip to the background',
      build: () => SessionCubit(check, clock),
      seed: () => SessionStatus.authenticated,
      act: (cubit) {
        cubit.backgrounded();
        when(
          () => clock.now(),
        ).thenReturn(fixedNow.add(SessionCubit.backgroundGrace));
        cubit.resumed();
      },
      expect: () => [SessionStatus.locked],
    );
  });

  group('PinEntryCubit', () {
    late MockVerifyPin verify;
    late MockGetLockout lockout;
    late MockGetBiometricStatus status;
    late MockAuthenticate authenticate;
    late MockClock clock;

    PinEntryCubit build() =>
        PinEntryCubit(verify, lockout, status, authenticate, clock);

    setUp(() {
      verify = MockVerifyPin();
      lockout = MockGetLockout();
      status = MockGetBiometricStatus();
      authenticate = MockAuthenticate();
      clock = MockClock();
      when(() => clock.now()).thenReturn(fixedNow);
      when(() => lockout(any())).thenAnswer((_) async => right(null));
      when(
        () => status(any()),
      ).thenAnswer((_) async => right(BiometricStatus.off));
    });

    blocTest<PinEntryCubit, PinEntryState>(
      'start without biometrics only reports readiness',
      build: build,
      act: (cubit) => cubit.start(biometricReason: 'why'),
      expect: () => [const PinEntryState()],
    );

    blocTest<PinEntryCubit, PinEntryState>(
      'start prompts for biometrics when enabled',
      setUp: () {
        when(() => status(any())).thenAnswer((_) async => right(usable));
        when(() => authenticate('why')).thenAnswer((_) async => right(unit));
      },
      build: build,
      act: (cubit) => cubit.start(biometricReason: 'why'),
      expect: () => [
        const PinEntryState(biometricsReady: true),
        const PinEntryState(
          biometricsReady: true,
          status: PinEntryStatus.success,
        ),
      ],
    );

    blocTest<PinEntryCubit, PinEntryState>(
      'biometric failure leaves the PIN pad usable',
      setUp: () {
        when(
          () => authenticate('why'),
        ).thenAnswer((_) async => left(const BiometricFailure()));
      },
      build: build,
      seed: () => const PinEntryState(biometricsReady: true),
      act: (cubit) => cubit.useBiometrics('why'),
      expect: () => [
        PinEntryState(
          biometricsReady: true,
          error: const BiometricFailure().message,
        ),
      ],
    );

    blocTest<PinEntryCubit, PinEntryState>(
      'biometrics do nothing when not ready',
      build: build,
      act: (cubit) => cubit.useBiometrics('why'),
      expect: () => <PinEntryState>[],
    );

    blocTest<PinEntryCubit, PinEntryState>(
      'collects digits and handles backspace',
      build: build,
      act: (cubit) async {
        await cubit.digitEntered('1');
        await cubit.digitEntered('2');
        cubit.backspace();
      },
      expect: () => [
        const PinEntryState(entered: '1'),
        const PinEntryState(entered: '12'),
        const PinEntryState(entered: '1'),
      ],
    );

    blocTest<PinEntryCubit, PinEntryState>(
      'backspace on an empty PIN does nothing',
      build: build,
      act: (cubit) => cubit.backspace(),
      expect: () => <PinEntryState>[],
    );

    blocTest<PinEntryCubit, PinEntryState>(
      'submits the fifth digit and succeeds',
      setUp: () =>
          when(() => verify('25804')).thenAnswer((_) async => right(unit)),
      build: build,
      seed: () => const PinEntryState(entered: '2580'),
      act: (cubit) => cubit.digitEntered('4'),
      expect: () => [
        const PinEntryState(entered: '25804'),
        const PinEntryState(
          entered: '25804',
          status: PinEntryStatus.verifying,
        ),
        const PinEntryState(entered: '25804', status: PinEntryStatus.success),
      ],
    );

    blocTest<PinEntryCubit, PinEntryState>(
      'clears the PIN and shows the error when wrong',
      setUp: () => when(
        () => verify('25804'),
      ).thenAnswer((_) async => left(const InvalidPinFailure(2))),
      build: build,
      seed: () => const PinEntryState(entered: '2580'),
      act: (cubit) => cubit.digitEntered('4'),
      skip: 2,
      expect: () => [PinEntryState(error: const InvalidPinFailure(2).message)],
    );

    blocTest<PinEntryCubit, PinEntryState>(
      'counts down during a lockout and blocks input',
      setUp: () => when(() => verify('25804')).thenAnswer(
        (_) async => left(
          LockedOutFailure(fixedNow.add(const Duration(seconds: 30))),
        ),
      ),
      build: build,
      seed: () => const PinEntryState(entered: '2580'),
      act: (cubit) async {
        await cubit.digitEntered('4');
        await cubit.digitEntered('1');
      },
      verify: (cubit) {
        expect(cubit.state.isLocked, isTrue);
        expect(cubit.state.lockoutSeconds, 31);
        expect(cubit.state.entered, isEmpty);
      },
    );

    blocTest<PinEntryCubit, PinEntryState>(
      'resumes a saved lockout on start',
      setUp: () => when(() => lockout(any())).thenAnswer(
        (_) async => right(fixedNow.add(const Duration(seconds: 5))),
      ),
      build: build,
      act: (cubit) => cubit.start(biometricReason: 'why'),
      verify: (cubit) => expect(cubit.state.lockoutSeconds, 6),
    );

    blocTest<PinEntryCubit, PinEntryState>(
      'unlocks when the lockout timer runs out',
      setUp: () => when(() => lockout(any())).thenAnswer(
        (_) async => right(fixedNow.add(const Duration(milliseconds: 500))),
      ),
      build: build,
      act: (cubit) async {
        await cubit.start(biometricReason: 'why');
        when(
          () => clock.now(),
        ).thenReturn(fixedNow.add(const Duration(hours: 1)));
      },
      wait: const Duration(milliseconds: 1100),
      verify: (cubit) => expect(cubit.state.isLocked, isFalse),
    );
  });

  group('PinSetupCubit', () {
    late MockCreatePin create;
    late MockGetBiometricStatus status;
    late MockSetBiometricsEnabled setEnabled;

    PinSetupCubit build() => PinSetupCubit(create, status, setEnabled);

    setUp(() {
      create = MockCreatePin();
      status = MockGetBiometricStatus();
      setEnabled = MockSetBiometricsEnabled();
      when(
        () => status(any()),
      ).thenAnswer((_) async => right(BiometricStatus.off));
    });

    blocTest<PinSetupCubit, PinSetupState>(
      'moves to confirm after a strong PIN',
      build: build,
      seed: () => const PinSetupState(entered: '2580'),
      act: (cubit) => cubit.digitEntered('4'),
      skip: 1,
      expect: () => [
        const PinSetupState(step: PinSetupStep.confirm, firstPin: '25804'),
      ],
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'rejects a weak PIN',
      build: build,
      seed: () => const PinSetupState(entered: '1111'),
      act: (cubit) => cubit.digitEntered('1'),
      verify: (cubit) {
        expect(cubit.state.step, PinSetupStep.create);
        expect(cubit.state.error, isNotNull);
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'restarts when the confirmation differs',
      build: build,
      seed: () => const PinSetupState(
        step: PinSetupStep.confirm,
        firstPin: '25804',
        entered: '2580',
      ),
      act: (cubit) => cubit.digitEntered('9'),
      verify: (cubit) {
        expect(cubit.state.step, PinSetupStep.create);
        expect(cubit.state.firstPin, isEmpty);
        expect(cubit.state.error, isNotNull);
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'finishes when biometrics are unavailable',
      setUp: () =>
          when(() => create('25804')).thenAnswer((_) async => right(unit)),
      build: build,
      seed: () => const PinSetupState(
        step: PinSetupStep.confirm,
        firstPin: '25804',
        entered: '2580',
      ),
      act: (cubit) => cubit.digitEntered('4'),
      verify: (cubit) => expect(cubit.state.step, PinSetupStep.done),
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'offers biometrics when available',
      setUp: () {
        when(() => create('25804')).thenAnswer((_) async => right(unit));
        when(() => status(any())).thenAnswer(
          (_) async =>
              right(const BiometricStatus(available: true, enabled: false)),
        );
      },
      build: build,
      seed: () => const PinSetupState(
        step: PinSetupStep.confirm,
        firstPin: '25804',
        entered: '2580',
      ),
      act: (cubit) => cubit.digitEntered('4'),
      verify: (cubit) => expect(cubit.state.step, PinSetupStep.biometrics),
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'shows an error when saving fails',
      setUp: () => when(
        () => create('25804'),
      ).thenAnswer((_) async => left(const StorageFailure())),
      build: build,
      seed: () => const PinSetupState(
        step: PinSetupStep.confirm,
        firstPin: '25804',
        entered: '2580',
      ),
      act: (cubit) => cubit.digitEntered('4'),
      verify: (cubit) {
        expect(cubit.state.isSaving, isFalse);
        expect(cubit.state.error, const StorageFailure().message);
      },
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'saves the biometric choice',
      setUp: () =>
          when(() => setEnabled(true)).thenAnswer((_) async => right(unit)),
      build: build,
      act: (cubit) => cubit.chooseBiometrics(enable: true),
      expect: () => [const PinSetupState(step: PinSetupStep.done)],
      verify: (_) => verify(() => setEnabled(true)).called(1),
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'skips biometrics when declined',
      build: build,
      act: (cubit) => cubit.chooseBiometrics(enable: false),
      expect: () => [const PinSetupState(step: PinSetupStep.done)],
      verify: (_) => verifyNever(() => setEnabled(any())),
    );

    blocTest<PinSetupCubit, PinSetupState>(
      'backspace removes a digit and ignores an empty entry',
      build: build,
      seed: () => const PinSetupState(entered: '2'),
      act: (cubit) => cubit
        ..backspace()
        ..backspace(),
      expect: () => [const PinSetupState()],
    );
  });

  group('ChangePinCubit', () {
    late MockChangePin change;

    setUp(() => change = MockChangePin());

    blocTest<ChangePinCubit, ChangePinState>(
      'moves from current to next',
      build: () => ChangePinCubit(change),
      seed: () => const ChangePinState(entered: '2580'),
      act: (cubit) => cubit.digitEntered('4'),
      skip: 1,
      expect: () => [
        const ChangePinState(step: ChangePinStep.next, currentPin: '25804'),
      ],
    );

    blocTest<ChangePinCubit, ChangePinState>(
      'rejects a weak new PIN',
      build: () => ChangePinCubit(change),
      seed: () =>
          const ChangePinState(step: ChangePinStep.next, entered: '1234'),
      act: (cubit) => cubit.digitEntered('5'),
      verify: (cubit) {
        expect(cubit.state.step, ChangePinStep.next);
        expect(cubit.state.error, isNotNull);
      },
    );

    blocTest<ChangePinCubit, ChangePinState>(
      'moves from next to confirm',
      build: () => ChangePinCubit(change),
      seed: () =>
          const ChangePinState(step: ChangePinStep.next, entered: '3691'),
      act: (cubit) => cubit.digitEntered('5'),
      verify: (cubit) {
        expect(cubit.state.step, ChangePinStep.confirm);
        expect(cubit.state.nextPin, '36915');
      },
    );

    blocTest<ChangePinCubit, ChangePinState>(
      'goes back when the confirmation differs',
      build: () => ChangePinCubit(change),
      seed: () => const ChangePinState(
        step: ChangePinStep.confirm,
        nextPin: '36915',
        entered: '3691',
      ),
      act: (cubit) => cubit.digitEntered('0'),
      verify: (cubit) {
        expect(cubit.state.step, ChangePinStep.next);
        expect(cubit.state.error, isNotNull);
      },
    );

    blocTest<ChangePinCubit, ChangePinState>(
      'saves and finishes',
      setUp: () =>
          when(() => change(any())).thenAnswer((_) async => right(unit)),
      build: () => ChangePinCubit(change),
      seed: () => const ChangePinState(
        step: ChangePinStep.confirm,
        currentPin: '25804',
        nextPin: '36915',
        entered: '3691',
      ),
      act: (cubit) => cubit.digitEntered('5'),
      verify: (cubit) => expect(cubit.state.step, ChangePinStep.done),
    );

    blocTest<ChangePinCubit, ChangePinState>(
      'restarts when the current PIN was wrong',
      setUp: () => when(
        () => change(any()),
      ).thenAnswer((_) async => left(const InvalidPinFailure(2))),
      build: () => ChangePinCubit(change),
      seed: () => const ChangePinState(
        step: ChangePinStep.confirm,
        currentPin: '00000',
        nextPin: '36915',
        entered: '3691',
      ),
      act: (cubit) => cubit.digitEntered('5'),
      verify: (cubit) {
        expect(cubit.state.step, ChangePinStep.current);
        expect(cubit.state.error, const InvalidPinFailure(2).message);
      },
    );

    blocTest<ChangePinCubit, ChangePinState>(
      'backspace removes a digit',
      build: () => ChangePinCubit(change),
      seed: () => const ChangePinState(entered: '25'),
      act: (cubit) => cubit.backspace(),
      expect: () => [const ChangePinState(entered: '2')],
    );
  });
}
