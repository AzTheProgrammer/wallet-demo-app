import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/router/app_router.dart';
import 'package:wallet_app/core/theme/app_theme.dart';
import 'package:wallet_app/features/auth/presentation/session/session_cubit.dart';
import 'package:wallet_app/features/profile/domain/entities/theme_preference.dart';
import 'package:wallet_app/features/profile/presentation/cubit/settings_cubit.dart';

class WalletApp extends StatefulWidget {
  const WalletApp({super.key});

  @override
  State<WalletApp> createState() => _WalletAppState();
}

class _WalletAppState extends State<WalletApp> {
  final SessionCubit _session = getIt<SessionCubit>();
  final SettingsCubit _settings = getIt<SettingsCubit>();
  late final GoRouter _router = createRouter(_session);
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _session.bootstrap();
    _settings.load();
    _lifecycle = AppLifecycleListener(
      onPause: _session.backgrounded,
      onResume: _session.resumed,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  ThemeMode _modeFor(ThemePreference preference) => switch (preference) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _settings,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (previous, current) => previous.theme != current.theme,
        builder: (context, state) => MaterialApp.router(
          title: 'Wallet',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _modeFor(state.theme),
          routerConfig: _router,
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.5,
            child: child!,
          ),
        ),
      ),
    );
  }
}
