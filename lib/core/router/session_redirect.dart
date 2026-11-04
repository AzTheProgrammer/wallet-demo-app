import 'package:wallet_app/core/router/app_routes.dart';
import 'package:wallet_app/features/auth/presentation/session/session_cubit.dart';

String? sessionRedirect(SessionStatus status, String location) =>
    switch (status) {
      SessionStatus.unknown =>
        location == AppRoutes.splash ? null : AppRoutes.splash,
      SessionStatus.onboarding =>
        location == AppRoutes.onboarding || location == AppRoutes.pinSetup
            ? null
            : AppRoutes.onboarding,
      SessionStatus.locked =>
        location == AppRoutes.login ? null : AppRoutes.login,
      SessionStatus.authenticated =>
        AppRoutes.publicOnly.contains(location) ? AppRoutes.home : null,
    };
