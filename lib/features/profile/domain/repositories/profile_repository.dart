import 'package:fpdart/fpdart.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/profile/domain/entities/profile.dart';
import 'package:wallet_app/features/profile/domain/entities/theme_preference.dart';

abstract class ProfileRepository {
  Future<Either<Failure, Profile>> getProfile();

  Future<Either<Failure, Profile>> updateProfile(Profile profile);
}

abstract class SettingsRepository {
  Future<Either<Failure, ThemePreference>> getThemePreference();

  Future<Either<Failure, Unit>> saveThemePreference(ThemePreference preference);
}
