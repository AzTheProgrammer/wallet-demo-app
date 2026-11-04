import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/auth/domain/entities/biometric_status.dart';
import 'package:wallet_app/features/auth/domain/pin_policy.dart';
import 'package:wallet_app/features/auth/domain/repositories/auth_repository.dart';

@injectable
class CheckPinExists implements UseCase<bool, NoParams> {
  const CheckPinExists(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) => _repository.hasPin();
}

@injectable
class CreatePin implements UseCase<Unit, String> {
  const CreatePin(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String pin) async {
    final problem = PinPolicy.validate(pin);
    if (problem != null) return left(ValidationFailure(problem));
    return _repository.createPin(pin);
  }
}

@injectable
class VerifyPin implements UseCase<Unit, String> {
  const VerifyPin(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String pin) => _repository.verifyPin(pin);
}

class ChangePinParams {
  const ChangePinParams({required this.current, required this.next});

  final String current;
  final String next;
}

@injectable
class ChangePin implements UseCase<Unit, ChangePinParams> {
  const ChangePin(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ChangePinParams params) async {
    final problem = PinPolicy.validate(params.next);
    if (problem != null) return left(ValidationFailure(problem));
    if (params.current == params.next) {
      return left(
        const ValidationFailure('Your new PIN must be different.'),
      );
    }
    return _repository.changePin(current: params.current, next: params.next);
  }
}

@injectable
class GetLockout implements UseCase<DateTime?, NoParams> {
  const GetLockout(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, DateTime?>> call(NoParams params) =>
      _repository.lockedUntil();
}

@injectable
class GetBiometricStatus implements UseCase<BiometricStatus, NoParams> {
  const GetBiometricStatus(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, BiometricStatus>> call(NoParams params) =>
      _repository.biometricStatus();
}

@injectable
class SetBiometricsEnabled implements UseCase<Unit, bool> {
  const SetBiometricsEnabled(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(bool enabled) =>
      _repository.setBiometricsEnabled(enabled: enabled);
}

@injectable
class AuthenticateWithBiometrics implements UseCase<Unit, String> {
  const AuthenticateWithBiometrics(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String reason) =>
      _repository.authenticateWithBiometrics(reason);
}
