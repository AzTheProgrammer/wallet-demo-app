import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/widgets/pin_dots.dart';
import 'package:wallet_app/features/auth/presentation/change_pin/change_pin_cubit.dart';
import 'package:wallet_app/features/auth/presentation/pages/change_pin_page.dart';
import 'package:wallet_app/features/auth/presentation/pages/login_page.dart';
import 'package:wallet_app/features/auth/presentation/pages/onboarding_page.dart';
import 'package:wallet_app/features/auth/presentation/pages/pin_setup_page.dart';
import 'package:wallet_app/features/auth/presentation/pages/splash_page.dart';
import 'package:wallet_app/features/auth/presentation/pin_entry/pin_entry_cubit.dart';
import 'package:wallet_app/features/auth/presentation/pin_setup/pin_setup_cubit.dart';
import 'package:wallet_app/features/auth/presentation/widgets/pin_confirm_sheet.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('SplashPage shows the brand', (tester) async {
    await tester.pumpApp(const SplashPage());
    expect(find.bySemanticsLabel('Wallet'), findsOneWidget);
  });

  group('OnboardingPage', () {
    testWidgets('explains the demo and starts setup', (tester) async {
      var started = false;
      await tester.pumpApp(OnboardingPage(onGetStarted: () => started = true));
      expect(find.textContaining('No real money moves'), findsOneWidget);
      await tester.tap(find.text('Set up my PIN'));
      expect(started, isTrue);
    });

    testWidgets('fits at 1.5x text', (tester) async {
      await tester.pumpApp(OnboardingPage(onGetStarted: () {}), textScale: 1.5);
      expect(tester.takeException(), isNull);
    });
  });

  group('PinSetupPage', () {
    late MockPinSetupCubit cubit;

    setUp(() => cubit = MockPinSetupCubit());

    Future<void> pump(WidgetTester tester, {VoidCallback? onComplete}) =>
        tester.pumpApp(
          BlocProvider<PinSetupCubit>.value(
            value: cubit,
            child: PinSetupPage(onComplete: onComplete ?? () {}),
          ),
        );

    testWidgets('create step passes digits to the cubit', (tester) async {
      when(() => cubit.state).thenReturn(const PinSetupState());
      when(() => cubit.digitEntered('1')).thenAnswer((_) async {});
      await pump(tester);
      expect(find.text('Create a PIN'), findsOneWidget);
      await tester.tap(find.text('1'));
      verify(() => cubit.digitEntered('1')).called(1);
    });

    testWidgets('confirm step shows errors and progress', (tester) async {
      when(() => cubit.state).thenReturn(
        const PinSetupState(
          step: PinSetupStep.confirm,
          entered: '12',
          error: 'Nope',
        ),
      );
      await pump(tester);
      expect(find.text('Confirm your PIN'), findsOneWidget);
      expect(find.text('Nope'), findsOneWidget);
      expect(tester.widget<PinDots>(find.byType(PinDots)).filled, 2);
    });

    testWidgets('biometric offer records the choice', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const PinSetupState(step: PinSetupStep.biometrics));
      when(
        () => cubit.chooseBiometrics(enable: any(named: 'enable')),
      ).thenAnswer((_) async {});
      await pump(tester);
      await tester.tap(find.text('Turn on biometrics'));
      verify(() => cubit.chooseBiometrics(enable: true)).called(1);
      await tester.tap(find.text('Not now'));
      verify(() => cubit.chooseBiometrics(enable: false)).called(1);
    });

    testWidgets('finishes when done', (tester) async {
      var completed = false;
      whenListen(
        cubit,
        Stream.value(const PinSetupState(step: PinSetupStep.done)),
        initialState: const PinSetupState(),
      );
      await pump(tester, onComplete: () => completed = true);
      await tester.pump();
      expect(completed, isTrue);
    });
  });

  group('LoginPage', () {
    late MockPinEntryCubit cubit;

    setUp(() => cubit = MockPinEntryCubit());

    Future<void> pump(WidgetTester tester, {VoidCallback? onAuthenticated}) =>
        tester.pumpApp(
          BlocProvider<PinEntryCubit>.value(
            value: cubit,
            child: LoginPage(onAuthenticated: onAuthenticated ?? () {}),
          ),
        );

    testWidgets('sends digits and backspace', (tester) async {
      when(() => cubit.state).thenReturn(const PinEntryState());
      when(() => cubit.digitEntered('4')).thenAnswer((_) async {});
      await pump(tester);
      expect(find.text('Welcome back'), findsOneWidget);
      await tester.tap(find.text('4'));
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      verify(() => cubit.digitEntered('4')).called(1);
      verify(() => cubit.backspace()).called(1);
    });

    testWidgets('shows the wrong PIN message', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const PinEntryState(error: 'Incorrect PIN'));
      await pump(tester);
      expect(find.text('Incorrect PIN'), findsOneWidget);
    });

    testWidgets('shows the lockout countdown and blocks input', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const PinEntryState(lockoutSeconds: 12));
      await pump(tester);
      expect(find.text('Locked. Try again in 12s.'), findsOneWidget);
      await tester.tap(find.text('4'));
      verifyNever(() => cubit.digitEntered(any()));
    });

    testWidgets('offers biometrics when ready', (tester) async {
      when(
        () => cubit.state,
      ).thenReturn(const PinEntryState(biometricsReady: true));
      when(() => cubit.useBiometrics(any())).thenAnswer((_) async {});
      await pump(tester);
      await tester.tap(find.byIcon(Icons.fingerprint_rounded));
      verify(
        () => cubit.useBiometrics(LoginPage.biometricReason),
      ).called(1);
    });

    testWidgets('reports success', (tester) async {
      var authenticated = false;
      whenListen(
        cubit,
        Stream.value(const PinEntryState(status: PinEntryStatus.success)),
        initialState: const PinEntryState(),
      );
      await pump(tester, onAuthenticated: () => authenticated = true);
      await tester.pump();
      expect(authenticated, isTrue);
    });
  });

  group('ChangePinPage', () {
    late MockChangePinCubit cubit;

    setUp(() => cubit = MockChangePinCubit());

    Future<void> pump(WidgetTester tester, {VoidCallback? onDone}) =>
        tester.pumpApp(
          BlocProvider<ChangePinCubit>.value(
            value: cubit,
            child: ChangePinPage(onDone: onDone ?? () {}),
          ),
        );

    for (final (step, title) in [
      (ChangePinStep.current, 'Current PIN'),
      (ChangePinStep.next, 'New PIN'),
      (ChangePinStep.confirm, 'Confirm new PIN'),
    ]) {
      testWidgets('shows the $step step', (tester) async {
        when(() => cubit.state).thenReturn(ChangePinState(step: step));
        await pump(tester);
        expect(find.text(title), findsOneWidget);
      });
    }

    testWidgets('sends digits', (tester) async {
      when(() => cubit.state).thenReturn(const ChangePinState());
      when(() => cubit.digitEntered('9')).thenAnswer((_) async {});
      await pump(tester);
      await tester.tap(find.text('9'));
      verify(() => cubit.digitEntered('9')).called(1);
    });

    testWidgets('confirms and leaves when done', (tester) async {
      var done = false;
      whenListen(
        cubit,
        Stream.value(const ChangePinState(step: ChangePinStep.done)),
        initialState: const ChangePinState(),
      );
      await pump(tester, onDone: () => done = true);
      await tester.pump();
      expect(done, isTrue);
      expect(find.text('Your PIN has changed'), findsOneWidget);
    });
  });

  group('confirmWithPin', () {
    late MockPinEntryCubit cubit;

    setUp(() {
      cubit = MockPinEntryCubit();
      when(
        () => cubit.start(biometricReason: any(named: 'biometricReason')),
      ).thenAnswer((_) async {});
    });

    Future<bool?> open(WidgetTester tester) async {
      bool? result;
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await confirmWithPin(
                context,
                reason: 'Approve R10',
                createCubit: () => cubit,
              );
            },
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('returns true after a correct PIN', (tester) async {
      whenListen(
        cubit,
        Stream.fromFuture(
          Future.delayed(
            const Duration(milliseconds: 10),
            () => const PinEntryState(status: PinEntryStatus.success),
          ),
        ),
        initialState: const PinEntryState(),
      );
      await open(tester);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();
      expect(find.text('Enter your PIN'), findsNothing);
    });

    testWidgets('shows the reason, errors and biometrics', (tester) async {
      when(() => cubit.state).thenReturn(
        const PinEntryState(error: 'Incorrect PIN', biometricsReady: true),
      );
      when(() => cubit.useBiometrics(any())).thenAnswer((_) async {});
      when(() => cubit.digitEntered('3')).thenAnswer((_) async {});
      await open(tester);
      expect(find.text('Approve R10'), findsOneWidget);
      expect(find.text('Incorrect PIN'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.fingerprint_rounded));
      await tester.tap(find.text('3'));
      verify(() => cubit.useBiometrics('Approve R10')).called(1);
      verify(() => cubit.digitEntered('3')).called(1);
    });
  });
}
