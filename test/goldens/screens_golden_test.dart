import 'package:alchemist/alchemist.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/theme/app_theme.dart';
import 'package:wallet_app/features/auth/presentation/pages/login_page.dart';
import 'package:wallet_app/features/auth/presentation/pin_entry/pin_entry_cubit.dart';
import 'package:wallet_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:wallet_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:wallet_app/features/rewards/presentation/cubit/rewards_cubit.dart';
import 'package:wallet_app/features/rewards/presentation/pages/rewards_page.dart';
import 'package:wallet_app/features/send_money/presentation/bloc/send_money_bloc.dart';
import 'package:wallet_app/features/send_money/presentation/pages/send_money_page.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:wallet_app/features/transactions/presentation/pages/transactions_page.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

const _phone = BoxConstraints.tightFor(width: 390, height: 844);

Widget _routed(Widget child) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => child)],
  );
  return Router.withConfig(config: router);
}

Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

GoldenTestGroup _themes(Widget Function() screen) => GoldenTestGroup(
  columns: 2,
  children: [
    for (final (name, theme) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ])
      GoldenTestScenario(
        name: name,
        constraints: _phone,
        child: Theme(data: theme, child: _still(_routed(screen()))),
      ),
  ],
);

void main() {
  goldenTest(
    'login',
    fileName: 'login',
    builder: () => _themes(() {
      final cubit = MockPinEntryCubit();
      whenListen(
        cubit,
        const Stream<PinEntryState>.empty(),
        initialState: const PinEntryState(entered: '12'),
      );
      return BlocProvider<PinEntryCubit>.value(
        value: cubit,
        child: LoginPage(onAuthenticated: () {}),
      );
    }),
  );

  goldenTest(
    'dashboard',
    fileName: 'dashboard',
    builder: () => _themes(() {
      final cubit = MockDashboardCubit();
      whenListen(
        cubit,
        const Stream<DashboardState>.empty(),
        initialState: DashboardState(
          status: ViewStatus.success,
          accounts: const [mainAccount, savingsAccount],
          recent: [payment, salary, electricity],
          firstName: 'Thandi',
        ),
      );
      return BlocProvider<DashboardCubit>.value(
        value: cubit,
        child: const DashboardPage(),
      );
    }),
  );

  goldenTest(
    'activity',
    fileName: 'activity',
    builder: () => _themes(() {
      final bloc = MockTransactionsBloc();
      whenListen(
        bloc,
        const Stream<TransactionsState>.empty(),
        initialState: TransactionsState(
          status: ViewStatus.success,
          items: [payment, salary, electricity],
        ),
      );
      return BlocProvider<TransactionsBloc>.value(
        value: bloc,
        child: const TransactionsPage(),
      );
    }),
  );

  goldenTest(
    'send money review',
    fileName: 'send_review',
    builder: () => _themes(() {
      final bloc = MockSendMoneyBloc();
      whenListen(
        bloc,
        const Stream<SendMoneyState>.empty(),
        initialState: const SendMoneyState(
          step: SendMoneyStep.review,
          loadStatus: ViewStatus.success,
          beneficiary: sipho,
          account: mainAccount,
          amountText: '150',
          reference: 'Lunch',
        ),
      );
      return BlocProvider<SendMoneyBloc>.value(
        value: bloc,
        child: const SendMoneyPage(),
      );
    }),
  );

  goldenTest(
    'rewards',
    fileName: 'rewards',
    builder: () => _themes(() {
      final cubit = MockRewardsCubit();
      whenListen(
        cubit,
        const Stream<RewardsState>.empty(),
        initialState: const RewardsState(
          status: ViewStatus.success,
          summary: rewardsSummary,
          offers: [airtimeOffer, fuelOffer],
        ),
      );
      return BlocProvider<RewardsCubit>.value(
        value: cubit,
        child: const RewardsPage(),
      );
    }),
  );
}
