import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_app/core/config/data_source_mode.dart';
import 'package:wallet_app/core/config/demo_config.dart';
import 'package:wallet_app/core/domain/usecase.dart';
import 'package:wallet_app/core/error/exceptions.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/mock/mock_server.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/features/auth/domain/entities/biometric_status.dart';
import 'package:wallet_app/features/profile/data/datasources/profile_data_sources.dart';
import 'package:wallet_app/features/profile/data/models/profile_model.dart';
import 'package:wallet_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:wallet_app/features/profile/domain/entities/profile.dart';
import 'package:wallet_app/features/profile/domain/entities/theme_preference.dart';
import 'package:wallet_app/features/profile/domain/usecases/profile_usecases.dart';
import 'package:wallet_app/features/profile/presentation/cubit/developer_cubit.dart';
import 'package:wallet_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wallet_app/features/profile/presentation/cubit/settings_cubit.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';

class MockRemote extends Mock implements ProfileRemoteDataSource {}

class MockLocal extends Mock implements SettingsLocalDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(thandi);
    registerFallbackValue(ThemePreference.system);
    registerFallbackValue(ProfileModel.fromEntity(thandi));
  });

  test('Profile derives a first name and copies', () {
    expect(thandi.firstName, 'Thandi');
    expect(thandi.copyWith(fullName: 'Lerato K').firstName, 'Lerato');
    expect(thandi.copyWith(), thandi);
  });

  group('use cases', () {
    late MockProfileRepository profiles;
    late MockSettingsRepository settings;

    setUp(() {
      profiles = MockProfileRepository();
      settings = MockSettingsRepository();
    });

    test('GetProfile', () async {
      when(() => profiles.getProfile()).thenAnswer((_) async => right(thandi));
      expect(
        await GetProfile(profiles)(const NoParams()),
        right<Failure, Profile>(thandi),
      );
    });

    test('UpdateProfile saves valid details', () async {
      when(
        () => profiles.updateProfile(thandi),
      ).thenAnswer((_) async => right(thandi));
      expect(
        await UpdateProfile(profiles)(thandi),
        right<Failure, Profile>(thandi),
      );
    });

    test('UpdateProfile rejects invalid details', () async {
      final result = await UpdateProfile(profiles)(
        thandi.copyWith(email: 'nope'),
      );
      expect(result.isLeft(), isTrue);
      verifyNever(() => profiles.updateProfile(any()));
    });

    test('theme preference round trip', () async {
      when(
        () => settings.getThemePreference(),
      ).thenAnswer((_) async => right(ThemePreference.dark));
      when(
        () => settings.saveThemePreference(ThemePreference.dark),
      ).thenAnswer((_) async => right(unit));
      expect(
        await GetThemePreference(settings)(const NoParams()),
        right<Failure, ThemePreference>(ThemePreference.dark),
      );
      expect(
        await SaveThemePreference(settings)(ThemePreference.dark),
        right<Failure, Unit>(unit),
      );
    });
  });

  group('repositories', () {
    test('ProfileRepositoryImpl maps models and failures', () async {
      final remote = MockRemote();
      final repository = ProfileRepositoryImpl(remote);
      final model = ProfileModel.fromEntity(thandi);
      when(remote.getProfile).thenAnswer((_) async => model);
      when(() => remote.updateProfile(any())).thenAnswer((_) async => model);
      expect(await repository.getProfile(), right<Failure, Profile>(thandi));
      expect(
        await repository.updateProfile(thandi),
        right<Failure, Profile>(thandi),
      );
      when(remote.getProfile).thenThrow(const OfflineException());
      expect(
        await repository.getProfile(),
        left<Failure, Profile>(const OfflineFailure()),
      );
    });

    test('SettingsRepositoryImpl reads and writes', () async {
      final local = MockLocal();
      final repository = SettingsRepositoryImpl(local);
      when(local.readTheme).thenReturn(ThemePreference.light);
      when(() => local.writeTheme(any())).thenAnswer((_) async {});
      expect(
        await repository.getThemePreference(),
        right<Failure, ThemePreference>(ThemePreference.light),
      );
      expect(
        await repository.saveThemePreference(ThemePreference.dark),
        right<Failure, Unit>(unit),
      );
    });
  });

  group('data sources', () {
    test('MockProfileDataSource reads and updates', () async {
      final fixtures = MockFixtureLoader();
      when(() => fixtures.load('profile')).thenAnswer(
        (_) async => <String, dynamic>{
          'full_name': 'Thandi Mokoena',
          'email': 'a@b.co',
          'phone': '0825550142',
          'member_since': '2023-03-14T00:00:00.000',
        },
      );
      final config = DemoConfig()
        ..failureRate = 0
        ..minLatency = Duration.zero
        ..maxLatency = Duration.zero;
      final clock = MockClock();
      when(clock.now).thenReturn(fixedNow);
      final source = MockProfileDataSource(MockServer(config, fixtures, clock));
      final profile = await source.getProfile();
      await source.updateProfile(profile.copyWith(fullName: 'Lerato'));
      expect((await source.getProfile()).fullName, 'Lerato');
    });

    test('PrefsSettingsDataSource persists the theme', () async {
      SharedPreferences.setMockInitialValues({});
      final source = PrefsSettingsDataSource(
        await SharedPreferences.getInstance(),
      );
      expect(source.readTheme(), ThemePreference.system);
      await source.writeTheme(ThemePreference.dark);
      expect(source.readTheme(), ThemePreference.dark);
    });
  });

  group('ProfileCubit', () {
    late MockGetProfile getProfile;
    late MockUpdateProfile update;

    setUp(() {
      getProfile = MockGetProfile();
      update = MockUpdateProfile();
    });

    final loaded = ProfileState(status: ViewStatus.success, profile: thandi);

    blocTest<ProfileCubit, ProfileState>(
      'loads',
      setUp: () =>
          when(() => getProfile(any())).thenAnswer((_) async => right(thandi)),
      build: () => ProfileCubit(getProfile, update),
      act: (cubit) => cubit.load(),
      expect: () => [const ProfileState(status: ViewStatus.loading), loaded],
    );

    blocTest<ProfileCubit, ProfileState>(
      'reports load failures',
      setUp: () => when(
        () => getProfile(any()),
      ).thenAnswer((_) async => left(const OfflineFailure())),
      build: () => ProfileCubit(getProfile, update),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.status, ViewStatus.failure),
    );

    blocTest<ProfileCubit, ProfileState>(
      'saves',
      setUp: () =>
          when(() => update(any())).thenAnswer((_) async => right(thandi)),
      build: () => ProfileCubit(getProfile, update),
      seed: () => loaded,
      act: (cubit) => cubit.save(
        fullName: thandi.fullName,
        email: thandi.email,
        phone: thandi.phone,
      ),
      expect: () => [
        loaded.copyWith(isSaving: true),
        loaded.copyWith(saved: true),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'reports save failures',
      setUp: () => when(
        () => update(any()),
      ).thenAnswer((_) async => left(const ServerFailure())),
      build: () => ProfileCubit(getProfile, update),
      seed: () => loaded,
      act: (cubit) => cubit.save(fullName: 'a', email: 'b', phone: 'c'),
      expect: () => [
        loaded.copyWith(isSaving: true),
        loaded.copyWith(saveFailure: const ServerFailure()),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'does nothing before a profile has loaded',
      build: () => ProfileCubit(getProfile, update),
      act: (cubit) => cubit.save(fullName: 'a', email: 'b', phone: 'c'),
      expect: () => <ProfileState>[],
    );
  });

  group('SettingsCubit', () {
    late MockGetTheme getTheme;
    late MockSaveTheme saveTheme;
    late MockGetBiometricStatus getBiometrics;
    late MockSetBiometricsEnabled setBiometrics;
    late MockAuthenticate authenticate;

    const available = BiometricStatus(available: true, enabled: false);

    setUp(() {
      getTheme = MockGetTheme();
      saveTheme = MockSaveTheme();
      getBiometrics = MockGetBiometricStatus();
      setBiometrics = MockSetBiometricsEnabled();
      authenticate = MockAuthenticate();
    });

    SettingsCubit build() => SettingsCubit(
      getTheme,
      saveTheme,
      getBiometrics,
      setBiometrics,
      authenticate,
    );

    blocTest<SettingsCubit, SettingsState>(
      'loads saved settings',
      setUp: () {
        when(
          () => getTheme(any()),
        ).thenAnswer((_) async => right(ThemePreference.dark));
        when(
          () => getBiometrics(any()),
        ).thenAnswer((_) async => right(available));
      },
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const SettingsState(theme: ThemePreference.dark, biometrics: available),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'falls back to defaults when loading fails',
      setUp: () {
        when(
          () => getTheme(any()),
        ).thenAnswer((_) async => left(const StorageFailure()));
        when(
          () => getBiometrics(any()),
        ).thenAnswer((_) async => left(const StorageFailure()));
      },
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [const SettingsState()],
    );

    blocTest<SettingsCubit, SettingsState>(
      'saves the theme',
      setUp: () =>
          when(() => saveTheme(any())).thenAnswer((_) async => right(unit)),
      build: build,
      act: (cubit) => cubit.setTheme(ThemePreference.light),
      expect: () => [const SettingsState(theme: ThemePreference.light)],
    );

    blocTest<SettingsCubit, SettingsState>(
      'reports a theme save failure',
      setUp: () => when(
        () => saveTheme(any()),
      ).thenAnswer((_) async => left(const UnknownFailure())),
      build: build,
      act: (cubit) => cubit.setTheme(ThemePreference.light),
      verify: (cubit) => expect(cubit.state.error, isNotNull),
    );

    blocTest<SettingsCubit, SettingsState>(
      'turning biometrics on needs a successful check',
      setUp: () {
        when(() => authenticate(any())).thenAnswer((_) async => right(unit));
        when(() => setBiometrics(true)).thenAnswer((_) async => right(unit));
      },
      build: build,
      seed: () => const SettingsState(biometrics: available),
      act: (cubit) => cubit.setBiometrics(enabled: true),
      verify: (cubit) => expect(cubit.state.biometrics.canUse, isTrue),
    );

    blocTest<SettingsCubit, SettingsState>(
      'stays off when the check fails',
      setUp: () => when(
        () => authenticate(any()),
      ).thenAnswer((_) async => left(const BiometricFailure())),
      build: build,
      seed: () => const SettingsState(biometrics: available),
      act: (cubit) => cubit.setBiometrics(enabled: true),
      verify: (cubit) {
        expect(cubit.state.biometrics.canUse, isFalse);
        expect(cubit.state.error, isNotNull);
        verifyNever(() => setBiometrics(any()));
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'turning off skips the check and reports save failures',
      setUp: () => when(
        () => setBiometrics(false),
      ).thenAnswer((_) async => left(const StorageFailure())),
      build: build,
      act: (cubit) => cubit.setBiometrics(enabled: false),
      verify: (cubit) {
        expect(cubit.state.error, isNotNull);
        verifyNever(() => authenticate(any()));
      },
    );
  });

  group('DeveloperCubit', () {
    late DemoConfig config;

    setUp(() => config = DemoConfig());

    blocTest<DeveloperCubit, DeveloperState>(
      'updates the demo config',
      build: () => DeveloperCubit(config, DataSourceMode.mock),
      act: (cubit) => cubit
        ..setFailureRate(0.5)
        ..setOffline(offline: true),
      verify: (cubit) {
        expect(config.failureRate, 0.5);
        expect(config.offline, isTrue);
        expect(cubit.state.mode, DataSourceMode.mock);
      },
    );
  });
}
