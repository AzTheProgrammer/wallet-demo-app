import 'package:fpdart/fpdart.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/auth/domain/entities/biometric_status.dart';

abstract class AuthRepository {
  Future<Either<Failure, bool>> hasPin();

  Future<Either<Failure, Unit>> createPin(String pin);

  Future<Either<Failure, Unit>> verifyPin(String pin);

  Future<Either<Failure, Unit>> changePin({
    required String current,
    required String next,
  });

  Future<Either<Failure, DateTime?>> lockedUntil();

  Future<Either<Failure, BiometricStatus>> biometricStatus();

  Future<Either<Failure, Unit>> setBiometricsEnabled({required bool enabled});

  Future<Either<Failure, Unit>> authenticateWithBiometrics(String reason);
}
