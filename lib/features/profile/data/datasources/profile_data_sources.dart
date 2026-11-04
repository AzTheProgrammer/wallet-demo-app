import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/features/profile/data/models/profile_model.dart';
import 'package:wallet_app/features/profile/domain/entities/theme_preference.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();

  Future<ProfileModel> updateProfile(ProfileModel profile);
}

@mockSource
@LazySingleton(as: ProfileRemoteDataSource)
class MockProfileDataSource implements ProfileRemoteDataSource {
  const MockProfileDataSource(this._server);

  final MockServer _server;

  @override
  Future<ProfileModel> getProfile() => _server.respond(() async {
    return ProfileModel.fromJson(await _server.document('profile'));
  });

  @override
  Future<ProfileModel> updateProfile(ProfileModel profile) =>
      _server.respond(() async {
        final row = await _server.document('profile');
        row.addAll(profile.toJson());
        return profile;
      });
}

abstract class SettingsLocalDataSource {
  ThemePreference readTheme();

  Future<void> writeTheme(ThemePreference preference);
}

@LazySingleton(as: SettingsLocalDataSource)
class PrefsSettingsDataSource implements SettingsLocalDataSource {
  const PrefsSettingsDataSource(this._preferences);

  static const _themeKey = 'theme_preference';

  final SharedPreferences _preferences;

  @override
  ThemePreference readTheme() {
    final stored = _preferences.getString(_themeKey);
    return ThemePreference.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => ThemePreference.system,
    );
  }

  @override
  Future<void> writeTheme(ThemePreference preference) =>
      _preferences.setString(_themeKey, preference.name);
}
