import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/auth/domain/entities/biometric_status.dart';
import 'package:wallet_app/features/auth/domain/pin_policy.dart';
import 'package:wallet_app/features/auth/domain/usecases/auth_usecases.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  group('PinPolicy', () {
    test(
      'accepts a good PIN',
      () => expect(PinPolicy.validate('25804'), isNull),
    );

    for (final pin in ['123', 'abcde', '11111', '12345', '54321']) {
      test('rejects $pin', () => expect(PinPolicy.validate(pin), isNotNull));
    }
  });

  group('BiometricStatus', () {
    test('canUse needs both flags', () {
      expect(
        const BiometricStatus(available: true, enabled: true).canUse,
        isTrue,
      );
      expect(
        const BiometricStatus(available: true, enabled: false).canUse,
        isFalse,
      );
      expect(BiometricStatus.off.canUse, isFalse);
    });
  });

  test('CheckPinExists passes through', () async {
    when(() => repository.hasPin()).thenAnswer((_) async => right(true));
    expect(
      await CheckPinExists(repository)(const NoParams()),
      right<Failure, bool>(true),
    );
  });

  group('CreatePin', () {
    test('stores a valid PIN', () async {
      when(
        () => repository.createPin('25804'),
      ).thenAnswer((_) async => right(unit));
      expect(
        await CreatePin(repository)('25804'),
        right<Failure, Unit>(unit),
      );
    });

    test('rejects a weak PIN without touching the repository', () async {
      final result = await CreatePin(repository)('11111');
      expect(result.isLeft(), isTrue);
      verifyNever(() => repository.createPin(any()));
    });
  });

  test('VerifyPin passes failures through', () async {
    when(
      () => repository.verifyPin('25804'),
    ).thenAnswer((_) async => left(const InvalidPinFailure(3)));
    expect(
      await VerifyPin(repository)('25804'),
      left<Failure, Unit>(const InvalidPinFailure(3)),
    );
  });

  group('ChangePin', () {
    test('changes to a valid new PIN', () async {
      when(
        () => repository.changePin(current: '25804', next: '36915'),
      ).thenAnswer((_) async => right(unit));
      final result = await ChangePin(repository)(
        const ChangePinParams(current: '25804', next: '36915'),
      );
      expect(result, right<Failure, Unit>(unit));
    });

    test('rejects a weak new PIN', () async {
      final result = await ChangePin(repository)(
        const ChangePinParams(current: '25804', next: '12345'),
      );
      expect(result.isLeft(), isTrue);
    });

    test('rejects reusing the same PIN', () async {
      final result = await ChangePin(repository)(
        const ChangePinParams(current: '25804', next: '25804'),
      );
      expect(result.isLeft(), isTrue);
    });
  });

  test('GetLockout passes through', () async {
    when(() => repository.lockedUntil()).thenAnswer((_) async => right(null));
    expect(
      await GetLockout(repository)(const NoParams()),
      right<Failure, DateTime?>(null),
    );
  });

  test('GetBiometricStatus passes through', () async {
    when(
      () => repository.biometricStatus(),
    ).thenAnswer((_) async => right(BiometricStatus.off));
    expect(
      await GetBiometricStatus(repository)(const NoParams()),
      right<Failure, BiometricStatus>(BiometricStatus.off),
    );
  });

  test('SetBiometricsEnabled passes the flag', () async {
    when(
      () => repository.setBiometricsEnabled(enabled: true),
    ).thenAnswer((_) async => right(unit));
    expect(
      await SetBiometricsEnabled(repository)(true),
      right<Failure, Unit>(unit),
    );
  });

  test('AuthenticateWithBiometrics passes the reason', () async {
    when(
      () => repository.authenticateWithBiometrics('why'),
    ).thenAnswer((_) async => left(const BiometricFailure()));
    expect(
      await AuthenticateWithBiometrics(repository)('why'),
      left<Failure, Unit>(const BiometricFailure()),
    );
  });
}
