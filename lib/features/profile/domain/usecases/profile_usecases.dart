import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/utils/validators.dart';
import 'package:wallet_app/features/profile/domain/entities/profile.dart';
import 'package:wallet_app/features/profile/domain/entities/theme_preference.dart';
import 'package:wallet_app/features/profile/domain/repositories/profile_repository.dart';

@injectable
class GetProfile implements UseCase<Profile, NoParams> {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Profile>> call(NoParams params) =>
      _repository.getProfile();
}

@injectable
class UpdateProfile implements UseCase<Profile, Profile> {
  const UpdateProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, Profile>> call(Profile profile) async {
    final problem =
        Validators.required(profile.fullName, 'your name') ??
        Validators.email(profile.email) ??
        Validators.mobileNumber(profile.phone);
    if (problem != null) return left(ValidationFailure(problem));
    return _repository.updateProfile(profile);
  }
}

@injectable
class GetThemePreference implements UseCase<ThemePreference, NoParams> {
  const GetThemePreference(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, ThemePreference>> call(NoParams params) =>
      _repository.getThemePreference();
}

@injectable
class SaveThemePreference implements UseCase<Unit, ThemePreference> {
  const SaveThemePreference(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ThemePreference preference) =>
      _repository.saveThemePreference(preference);
}
