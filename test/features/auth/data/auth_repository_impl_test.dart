import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:wallet_app/features/auth/data/datasources/biometric_data_source.dart';
import 'package:wallet_app/features/auth/data/pin_hasher.dart';
import 'package:wallet_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:wallet_app/features/auth/domain/entities/biometric_status.dart';
import 'package:wallet_app/features/auth/domain/pin_policy.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

class FakeLocal implements AuthLocalDataSource {
  final values = <String, String>{};
  bool broken = false;

  void _check() {
    if (broken) throw const StorageException();
  }

  @override
  Future<String?> read(String key) async {
    _check();
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _check();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _check();
    values.remove(key);
  }
}

class MockBiometrics extends Mock implements BiometricDataSource {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLocalAuth extends Mock implements LocalAuthentication {}

void main() {
  late FakeLocal local;
  late MockBiometrics biometrics;
  late MockClock clock;
  late AuthRepositoryImpl repository;

  setUp(() {
    local = FakeLocal();
    biometrics = MockBiometrics();
    clock = MockClock();
    when(() => clock.now()).thenReturn(fixedNow);
    repository = AuthRepositoryImpl(local, biometrics, PinHasher(), clock);
  });

  group('PIN storage', () {
    test('hasPin is false until a PIN is created', () async {
      expect(await repository.hasPin(), right<Failure, bool>(false));
      await repository.createPin('25804');
      expect(await repository.hasPin(), right<Failure, bool>(true));
    });

    test('never stores the raw PIN', () async {
      await repository.createPin('25804');
      expect(local.values.values, isNot(contains('25804')));
    });

    test('surfaces storage failures', () async {
      local.broken = true;
      expect(
        await repository.hasPin(),
        left<Failure, bool>(const StorageFailure()),
      );
    });
  });

  group('verifyPin', () {
    setUp(() => repository.createPin('25804'));

    test('accepts the right PIN and clears attempts', () async {
      await repository.verifyPin('00000');
      expect(await repository.verifyPin('25804'), right<Failure, Unit>(unit));
      expect(local.values[AuthKeys.failedAttempts], isNull);
    });

    test('counts down remaining attempts', () async {
      expect(
        await repository.verifyPin('00000'),
        left<Failure, Unit>(
          const InvalidPinFailure(PinPolicy.maxAttempts - 1),
        ),
      );
    });

    test('locks out after too many attempts', () async {
      for (var i = 0; i < PinPolicy.maxAttempts - 1; i++) {
        await repository.verifyPin('00000');
      }
      final until = fixedNow.add(PinPolicy.lockout);
      expect(
        await repository.verifyPin('00000'),
        left<Failure, Unit>(LockedOutFailure(until)),
      );
      expect(
        await repository.verifyPin('25804'),
        left<Failure, Unit>(LockedOutFailure(until)),
      );
      expect(await repository.lockedUntil(), right<Failure, DateTime?>(until));
    });

    test('allows attempts again after the lockout passes', () async {
      for (var i = 0; i < PinPolicy.maxAttempts; i++) {
        await repository.verifyPin('00000');
      }
      when(
        () => clock.now(),
      ).thenReturn(fixedNow.add(PinPolicy.lockout * 2));
      expect(await repository.lockedUntil(), right<Failure, DateTime?>(null));
      expect(await repository.verifyPin('25804'), right<Failure, Unit>(unit));
    });

    test('fails when no PIN is stored', () async {
      local.values.clear();
      expect((await repository.verifyPin('25804')).isLeft(), isTrue);
    });

    test('surfaces storage failures', () async {
      local.broken = true;
      expect(
        await repository.verifyPin('25804'),
        left<Failure, Unit>(const StorageFailure()),
      );
    });
  });

  group('changePin', () {
    setUp(() => repository.createPin('25804'));

    test('replaces the PIN after verifying the old one', () async {
      expect(
        await repository.changePin(current: '25804', next: '36915'),
        right<Failure, Unit>(unit),
      );
      expect(await repository.verifyPin('36915'), right<Failure, Unit>(unit));
    });

    test('keeps the PIN when the old one is wrong', () async {
      final result = await repository.changePin(
        current: '00000',
        next: '36915',
      );
      expect(result.isLeft(), isTrue);
      expect(await repository.verifyPin('25804'), right<Failure, Unit>(unit));
    });
  });

  group('biometrics', () {
    test('reports availability and the saved preference', () async {
      when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
      await repository.setBiometricsEnabled(enabled: true);
      expect(
        await repository.biometricStatus(),
        right<Failure, BiometricStatus>(
          const BiometricStatus(available: true, enabled: true),
        ),
      );
    });

    test('authenticate succeeds when the device confirms', () async {
      when(() => biometrics.authenticate('why')).thenAnswer((_) async => true);
      expect(
        await repository.authenticateWithBiometrics('why'),
        right<Failure, Unit>(unit),
      );
    });

    test('authenticate fails when the device declines', () async {
      when(() => biometrics.authenticate('why')).thenAnswer((_) async => false);
      expect(
        await repository.authenticateWithBiometrics('why'),
        left<Failure, Unit>(const BiometricFailure()),
      );
    });
  });

  group('SecureAuthLocalDataSource', () {
    late MockSecureStorage storage;
    late SecureAuthLocalDataSource source;

    setUp(() {
      storage = MockSecureStorage();
      source = SecureAuthLocalDataSource(storage);
    });

    test('reads, writes and deletes', () async {
      when(() => storage.read(key: 'k')).thenAnswer((_) async => 'v');
      when(
        () => storage.write(key: 'k', value: 'v'),
      ).thenAnswer((_) async {});
      when(() => storage.delete(key: 'k')).thenAnswer((_) async {});
      expect(await source.read('k'), 'v');
      await source.write('k', 'v');
      await source.delete('k');
      verify(() => storage.delete(key: 'k')).called(1);
    });

    test('wraps platform errors', () {
      when(() => storage.read(key: 'k')).thenThrow(Exception('locked'));
      expect(() => source.read('k'), throwsA(isA<StorageException>()));
    });
  });

  group('LocalBiometricDataSource', () {
    late MockLocalAuth auth;
    late LocalBiometricDataSource source;

    setUp(() {
      auth = MockLocalAuth();
      source = LocalBiometricDataSource(auth);
    });

    test('is available only with enrolled biometrics', () async {
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);
      when(
        () => auth.getAvailableBiometrics(),
      ).thenAnswer((_) async => [BiometricType.fingerprint]);
      expect(await source.isAvailable(), isTrue);
      when(() => auth.getAvailableBiometrics()).thenAnswer((_) async => []);
      expect(await source.isAvailable(), isFalse);
    });

    test('is unavailable on unsupported devices', () async {
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => false);
      expect(await source.isAvailable(), isFalse);
    });

    test('treats missing plugins and platform errors as unavailable', () async {
      when(() => auth.isDeviceSupported()).thenThrow(MissingPluginException());
      expect(await source.isAvailable(), isFalse);
      when(
        () => auth.isDeviceSupported(),
      ).thenThrow(PlatformException(code: 'x'));
      expect(await source.isAvailable(), isFalse);
    });

    test('authenticate returns the device answer', () async {
      when(
        () => auth.authenticate(
          localizedReason: 'why',
          biometricOnly: true,
        ),
      ).thenAnswer((_) async => true);
      expect(await source.authenticate('why'), isTrue);
    });

    test('authenticate treats errors as a decline', () async {
      when(
        () => auth.authenticate(
          localizedReason: 'why',
          biometricOnly: true,
        ),
      ).thenThrow(PlatformException(code: 'x'));
      expect(await source.authenticate('why'), isFalse);
    });
  });

  test('PinHasher is salted and repeatable', () {
    final hasher = PinHasher();
    expect(hasher.hash('25804', 'a'), hasher.hash('25804', 'a'));
    expect(hasher.hash('25804', 'a'), isNot(hasher.hash('25804', 'b')));
    expect(hasher.newSalt(), isNot(hasher.newSalt()));
  });
}
