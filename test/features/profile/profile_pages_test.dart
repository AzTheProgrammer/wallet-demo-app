import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet_app/core/config/data_source_mode.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/features/auth/domain/entities/biometric_status.dart';
import 'package:wallet_app/features/profile/domain/entities/theme_preference.dart';
import 'package:wallet_app/features/profile/presentation/cubit/developer_cubit.dart';
import 'package:wallet_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wallet_app/features/profile/presentation/cubit/settings_cubit.dart';
import 'package:wallet_app/features/profile/presentation/pages/design_system_page.dart';
import 'package:wallet_app/features/profile/presentation/pages/developer_page.dart';
import 'package:wallet_app/features/profile/presentation/pages/personal_details_page.dart';
import 'package:wallet_app/features/profile/presentation/pages/profile_page.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUpAll(() => registerFallbackValue(ThemePreference.system));

  group('ProfilePage', () {
    late MockProfileCubit profile;
    late MockSettingsCubit settings;

    final loaded = ProfileState(status: ViewStatus.success, profile: thandi);

    setUp(() {
      profile = MockProfileCubit();
      settings = MockSettingsCubit();
      when(() => settings.state).thenReturn(const SettingsState());
    });

    Future<void> pump(WidgetTester tester, {VoidCallback? onLock}) =>
        tester.pumpRouted(
          MultiBlocProvider(
            providers: [
              BlocProvider<ProfileCubit>.value(value: profile),
              BlocProvider<SettingsCubit>.value(value: settings),
            ],
            child: ProfilePage(onLock: onLock ?? () {}),
          ),
        );

    testWidgets('shows a skeleton while loading', (tester) async {
      when(
        () => profile.state,
      ).thenReturn(const ProfileState(status: ViewStatus.loading));
      await pump(tester);
      expect(find.byType(Skeleton), findsOneWidget);
    });

    testWidgets('retries a failure', (tester) async {
      when(() => profile.state).thenReturn(
        const ProfileState(
          status: ViewStatus.failure,
          failure: OfflineFailure(),
        ),
      );
      when(() => profile.load()).thenAnswer((_) async {});
      await pump(tester);
      await tester.tap(find.text('Try again'));
      verify(() => profile.load()).called(1);
    });

    testWidgets('shows the person and opens details', (tester) async {
      when(() => profile.state).thenReturn(loaded);
      await pump(tester);
      expect(find.text('Thandi Mokoena'), findsOneWidget);
      await tester.tap(find.text('Thandi Mokoena'));
      await tester.pumpAndSettle();
      expect(find.text('route:/profile/details'), findsOneWidget);
    });

    testWidgets('opens change PIN', (tester) async {
      when(() => profile.state).thenReturn(loaded);
      await pump(tester);
      await tester.tap(find.text('Change PIN'));
      await tester.pumpAndSettle();
      expect(find.text('route:/profile/change-pin'), findsOneWidget);
    });

    testWidgets('biometrics are off when unavailable', (tester) async {
      when(() => profile.state).thenReturn(loaded);
      await pump(tester);
      expect(find.text('Not available on this device'), findsOneWidget);
      await tester.tap(find.text('Biometric unlock'));
      verifyNever(
        () => settings.setBiometrics(enabled: any(named: 'enabled')),
      );
    });

    testWidgets('toggles biometrics when available', (tester) async {
      when(() => profile.state).thenReturn(loaded);
      when(() => settings.state).thenReturn(
        const SettingsState(
          biometrics: BiometricStatus(available: true, enabled: false),
        ),
      );
      when(
        () => settings.setBiometrics(enabled: true),
      ).thenAnswer((_) async {});
      await pump(tester);
      await tester.tap(find.text('Biometric unlock'));
      verify(() => settings.setBiometrics(enabled: true)).called(1);
    });

    testWidgets('shows setting errors', (tester) async {
      when(() => profile.state).thenReturn(loaded);
      whenListen(
        settings,
        Stream.value(const SettingsState(error: 'Nope')),
        initialState: const SettingsState(),
      );
      await pump(tester);
      await tester.pump();
      expect(find.text('Nope'), findsOneWidget);
    });

    testWidgets('changes the theme', (tester) async {
      when(() => profile.state).thenReturn(loaded);
      when(() => settings.setTheme(any())).thenAnswer((_) async {});
      await pump(tester);
      await tester.tap(find.text('Dark'));
      verify(() => settings.setTheme(ThemePreference.dark)).called(1);
    });

    testWidgets('locks the wallet', (tester) async {
      var locked = false;
      when(() => profile.state).thenReturn(loaded);
      await pump(tester, onLock: () => locked = true);
      await tester.tap(find.text('Lock wallet'));
      expect(locked, isTrue);
    });

    testWidgets('seven taps on the version open the developer menu', (
      tester,
    ) async {
      when(() => profile.state).thenReturn(loaded);
      await pump(tester);
      final version = find.text('Wallet demo 1.0.0');
      await tester.ensureVisible(version);
      for (var i = 0; i < 6; i++) {
        await tester.tap(version);
      }
      await tester.pump();
      expect(find.text('route:/developer'), findsNothing);
      await tester.tap(version);
      await tester.pumpAndSettle();
      expect(find.text('route:/developer'), findsOneWidget);
    });
  });

  group('PersonalDetailsPage', () {
    late MockProfileCubit cubit;

    final loaded = ProfileState(status: ViewStatus.success, profile: thandi);

    setUp(() {
      cubit = MockProfileCubit();
      when(() => cubit.state).thenReturn(loaded);
      when(
        () => cubit.save(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async {});
    });

    Future<void> pump(WidgetTester tester) => tester.pumpApp(
      BlocProvider<ProfileCubit>.value(
        value: cubit,
        child: const PersonalDetailsPage(),
      ),
    );

    testWidgets('prefills and shows the join date', (tester) async {
      await pump(tester);
      expect(find.text('Thandi Mokoena'), findsOneWidget);
      expect(find.text('Member since March 2023'), findsOneWidget);
    });

    testWidgets('validates before saving', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField).at(1), 'nope');
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      verifyNever(
        () => cubit.save(
          fullName: any(named: 'fullName'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
        ),
      );
    });

    testWidgets('saves valid details', (tester) async {
      await pump(tester);
      await tester.enterText(find.byType(TextFormField).at(0), ' Lerato K ');
      await tester.tap(find.text('Save changes'));
      verify(
        () => cubit.save(
          fullName: 'Lerato K',
          email: thandi.email,
          phone: thandi.phone,
        ),
      ).called(1);
    });

    testWidgets('confirms a save', (tester) async {
      whenListen(
        cubit,
        Stream.value(loaded.copyWith(saved: true)),
        initialState: loaded.copyWith(isSaving: true),
      );
      await pump(tester);
      await tester.pump();
      expect(find.text('Details saved'), findsOneWidget);
    });

    testWidgets('reports a failed save', (tester) async {
      whenListen(
        cubit,
        Stream.value(loaded.copyWith(saveFailure: const ServerFailure())),
        initialState: loaded.copyWith(isSaving: true),
      );
      await pump(tester);
      await tester.pump();
      expect(find.text(const ServerFailure().message), findsOneWidget);
    });
  });

  group('DeveloperPage', () {
    late MockDeveloperCubit cubit;

    setUp(() {
      cubit = MockDeveloperCubit();
      when(() => cubit.state).thenReturn(
        const DeveloperState(
          mode: DataSourceMode.mock,
          failureRate: 0.2,
          offline: false,
        ),
      );
    });

    Future<void> pump(WidgetTester tester) => tester.pumpRouted(
      BlocProvider<DeveloperCubit>.value(
        value: cubit,
        child: const DeveloperPage(),
      ),
    );

    testWidgets('shows the data source and failure rate', (tester) async {
      await pump(tester);
      expect(find.text('Mock'), findsOneWidget);
      expect(find.text('API (Phase 2)'), findsOneWidget);
      expect(find.text('Failure rate: 20%'), findsOneWidget);
    });

    testWidgets('toggles offline and the failure rate', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Simulate offline'));
      verify(() => cubit.setOffline(offline: true)).called(1);
      await tester.tap(find.byType(Slider));
      verify(() => cubit.setFailureRate(any())).called(1);
    });

    testWidgets('opens the design system', (tester) async {
      await pump(tester);
      await tester.tap(find.text('Open design system'));
      await tester.pumpAndSettle();
      expect(
        find.text('route:/developer/design-system'),
        findsOneWidget,
      );
    });
  });

  testWidgets('DesignSystemPage renders the components', (tester) async {
    await tester.pumpApp(const DesignSystemPage());
    expect(find.text('Design system'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
    await tester.tap(find.text('Primary'));
    await tester.tap(find.text('Secondary'));
    await tester.tap(find.text('Quiet'));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -800),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
