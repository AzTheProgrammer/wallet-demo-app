import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/data/guard.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/utils/app_clock.dart';
import 'package:wallet_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:wallet_app/features/auth/data/datasources/biometric_data_source.dart';
import 'package:wallet_app/features/auth/data/pin_hasher.dart';
import 'package:wallet_app/features/auth/domain/entities/biometric_status.dart';
import 'package:wallet_app/features/auth/domain/pin_policy.dart';
import 'package:wallet_app/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this._local,
    this._biometrics,
    this._hasher,
    this._clock,
  );

  final AuthLocalDataSource _local;
  final BiometricDataSource _biometrics;
  final PinHasher _hasher;
  final AppClock _clock;

  @override
  Future<Either<Failure, bool>> hasPin() =>
      guard(() async => await _local.read(AuthKeys.pinHash) != null);

  @override
  Future<Either<Failure, Unit>> createPin(String pin) => guard(() async {
    await _storePin(pin);
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> verifyPin(String pin) async {
    final locked = await lockedUntil();
    final until = locked.getOrElse((_) => null);
    if (until != null) return left(LockedOutFailure(until));
    final matched = await guard(() => _matches(pin));
    return matched.fold(left, (isMatch) => _recordAttempt(isMatch: isMatch));
  }

  @override
  Future<Either<Failure, Unit>> changePin({
    required String current,
    required String next,
  }) async {
    final verified = await verifyPin(current);
    return verified.fold(left, (_) => createPin(next));
  }

  @override
  Future<Either<Failure, DateTime?>> lockedUntil() => guard(() async {
    final raw = await _local.read(AuthKeys.lockedUntil);
    final until = raw == null ? null : DateTime.tryParse(raw);
    if (until == null || !until.isAfter(_clock.now())) return null;
    return until;
  });

  @override
  Future<Either<Failure, BiometricStatus>> biometricStatus() => guard(() async {
    final available = await _biometrics.isAvailable();
    final enabled = await _local.read(AuthKeys.biometricsEnabled) == 'true';
    return BiometricStatus(available: available, enabled: enabled);
  });

  @override
  Future<Either<Failure, Unit>> setBiometricsEnabled({
    required bool enabled,
  }) => guard(() async {
    await _local.write(AuthKeys.biometricsEnabled, enabled.toString());
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> authenticateWithBiometrics(
    String reason,
  ) async {
    final result = await guard(() => _biometrics.authenticate(reason));
    return result.fold(
      left,
      (passed) => passed ? right(unit) : left(const BiometricFailure()),
    );
  }

  Future<void> _storePin(String pin) async {
    final salt = _hasher.newSalt();
    await _local.write(AuthKeys.pinSalt, salt);
    await _local.write(AuthKeys.pinHash, _hasher.hash(pin, salt));
    await _clearAttempts();
  }

  Future<bool> _matches(String pin) async {
    final stored = await _local.read(AuthKeys.pinHash);
    final salt = await _local.read(AuthKeys.pinSalt);
    if (stored == null || salt == null) return false;
    return _hasher.hash(pin, salt) == stored;
  }

  Future<Either<Failure, Unit>> _recordAttempt({required bool isMatch}) async {
    final recorded = await guard<Failure?>(() async {
      if (isMatch) {
        await _clearAttempts();
        return null;
      }
      return _registerFailure();
    });
    return recorded.fold(
      left,
      (failure) => failure == null ? right(unit) : left(failure),
    );
  }

  Future<Failure> _registerFailure() async {
    final raw = await _local.read(AuthKeys.failedAttempts);
    final attempts = (int.tryParse(raw ?? '') ?? 0) + 1;
    if (attempts >= PinPolicy.maxAttempts) {
      final until = _clock.now().add(PinPolicy.lockout);
      await _local.write(AuthKeys.lockedUntil, until.toIso8601String());
      await _local.delete(AuthKeys.failedAttempts);
      return LockedOutFailure(until);
    }
    await _local.write(AuthKeys.failedAttempts, attempts.toString());
    return InvalidPinFailure(PinPolicy.maxAttempts - attempts);
  }

  Future<void> _clearAttempts() async {
    await _local.delete(AuthKeys.failedAttempts);
    await _local.delete(AuthKeys.lockedUntil);
  }
}
