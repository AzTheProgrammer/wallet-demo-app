import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/router/app_routes.dart';
import 'package:wallet_app/core/router/home_shell.dart';
import 'package:wallet_app/core/router/session_redirect.dart';
import 'package:wallet_app/features/auth/presentation/change_pin/change_pin_cubit.dart';
import 'package:wallet_app/features/auth/presentation/pages/change_pin_page.dart';
import 'package:wallet_app/features/auth/presentation/pages/login_page.dart';
import 'package:wallet_app/features/auth/presentation/pages/onboarding_page.dart';
import 'package:wallet_app/features/auth/presentation/pages/pin_setup_page.dart';
import 'package:wallet_app/features/auth/presentation/pages/splash_page.dart';
import 'package:wallet_app/features/auth/presentation/pin_entry/pin_entry_cubit.dart';
import 'package:wallet_app/features/auth/presentation/pin_setup/pin_setup_cubit.dart';
import 'package:wallet_app/features/auth/presentation/session/session_cubit.dart';
import 'package:wallet_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:wallet_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:wallet_app/features/profile/presentation/cubit/developer_cubit.dart';
import 'package:wallet_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wallet_app/features/profile/presentation/pages/design_system_page.dart';
import 'package:wallet_app/features/profile/presentation/pages/developer_page.dart';
import 'package:wallet_app/features/profile/presentation/pages/personal_details_page.dart';
import 'package:wallet_app/features/profile/presentation/pages/profile_page.dart';
import 'package:wallet_app/features/rewards/presentation/cubit/rewards_cubit.dart';
import 'package:wallet_app/features/rewards/presentation/pages/rewards_page.dart';
import 'package:wallet_app/features/send_money/presentation/bloc/send_money_bloc.dart';
import 'package:wallet_app/features/send_money/presentation/pages/send_money_page.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:wallet_app/features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import 'package:wallet_app/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:wallet_app/features/transactions/presentation/pages/transactions_page.dart';
import 'package:wallet_app/features/vas/domain/entities/vas.dart';
import 'package:wallet_app/features/vas/presentation/bloc/vas_bloc.dart';
import 'package:wallet_app/features/vas/presentation/pages/vas_page.dart';

class SessionRefresh extends ChangeNotifier {
  SessionRefresh(Stream<SessionStatus> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<SessionStatus> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

GoRouter createRouter(SessionCubit session) => GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: SessionRefresh(session.stream),
  redirect: (context, state) =>
      sessionRedirect(session.state, state.matchedLocation),
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => OnboardingPage(
        onGetStarted: () => context.push(AppRoutes.pinSetup),
      ),
      routes: [
        GoRoute(
          path: 'pin',
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<PinSetupCubit>(),
            child: PinSetupPage(onComplete: session.authenticated),
          ),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => BlocProvider(
        create: (_) =>
            getIt<PinEntryCubit>()
              ..start(biometricReason: LoginPage.biometricReason),
        child: LoginPage(onAuthenticated: session.authenticated),
      ),
    ),
    _shell(),
    GoRoute(
      path: '${AppRoutes.transactions}/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final scope = state.uri.queryParameters['from'] ?? 'link';
        return BlocProvider(
          create: (_) =>
              getIt<TransactionDetailCubit>()
                ..load(id, initial: state.extra as Transaction?),
          child: TransactionDetailPage(
            transactionId: id,
            heroTag: '$scope-$id',
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.send,
      builder: (context, state) => BlocProvider(
        create: (_) =>
            getIt<SendMoneyBloc>()..add(const SendMoneyEvent.started()),
        child: const SendMoneyPage(),
      ),
    ),
    GoRoute(
      path: '/vas/:kind',
      builder: (context, state) {
        final kind = VasKind.values.firstWhere(
          (value) => value.name == state.pathParameters['kind'],
          orElse: () => VasKind.airtime,
        );
        return BlocProvider(
          create: (_) => getIt<VasBloc>()..add(VasEvent.started(kind)),
          child: const VasPage(),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.personalDetails,
      builder: (context, state) => BlocProvider.value(
        value: state.extra! as ProfileCubit,
        child: const PersonalDetailsPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.changePin,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<ChangePinCubit>(),
        child: ChangePinPage(onDone: () => context.pop()),
      ),
    ),
    GoRoute(
      path: AppRoutes.developer,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<DeveloperCubit>(),
        child: const DeveloperPage(),
      ),
      routes: [
        GoRoute(
          path: 'design-system',
          builder: (context, state) => const DesignSystemPage(),
        ),
      ],
    ),
  ],
);

StatefulShellRoute _shell() => StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => HomeShell(shell: shell),
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<DashboardCubit>()..load(),
            child: const DashboardPage(),
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.transactions,
          builder: (context, state) => BlocProvider(
            create: (_) =>
                getIt<TransactionsBloc>()
                  ..add(const TransactionsEvent.started()),
            child: const TransactionsPage(),
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.rewards,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<RewardsCubit>()..load(),
            child: const RewardsPage(),
          ),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<ProfileCubit>()..load(),
            child: const ProfilePage(),
          ),
        ),
      ],
    ),
  ],
);
