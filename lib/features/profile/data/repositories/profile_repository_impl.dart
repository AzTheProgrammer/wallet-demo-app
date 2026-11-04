import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:wallet_app/core/data/guard.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/features/profile/data/datasources/profile_data_sources.dart';
import 'package:wallet_app/features/profile/data/models/profile_model.dart';
import 'package:wallet_app/features/profile/domain/entities/profile.dart';
import 'package:wallet_app/features/profile/domain/entities/theme_preference.dart';
import 'package:wallet_app/features/profile/domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, Profile>> getProfile() =>
      guard(() async => (await _remote.getProfile()).toEntity());

  @override
  Future<Either<Failure, Profile>> updateProfile(Profile profile) =>
      guard(() async {
        final saved = await _remote.updateProfile(
          ProfileModel.fromEntity(profile),
        );
        return saved.toEntity();
      });
}

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  @override
  Future<Either<Failure, ThemePreference>> getThemePreference() =>
      guard(() async => _local.readTheme());

  @override
  Future<Either<Failure, Unit>> saveThemePreference(
    ThemePreference preference,
  ) => guard(() async {
    await _local.writeTheme(preference);
    return unit;
  });
}
