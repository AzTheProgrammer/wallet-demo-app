import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/router/app_routes.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/section_header.dart';
import 'package:wallet_app/core/widgets/state_views.dart';
import 'package:wallet_app/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:wallet_app/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:wallet_app/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:wallet_app/features/dashboard/presentation/widgets/quick_actions.dart';
import 'package:wallet_app/features/transactions/presentation/widgets/transaction_tile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<DashboardCubit, DashboardState>(
          listenWhen: (previous, current) =>
              current.refreshFailure != null &&
              previous.refreshFailure != current.refreshFailure,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.refreshFailure!.message)),
            );
          },
          builder: (context, state) => switch (state.status) {
            ViewStatus.failure => FailureView(
              failure: state.failure!,
              onRetry: context.read<DashboardCubit>().load,
            ),
            ViewStatus.success => _DashboardContent(state: state),
            _ => const SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ResponsiveCenter(child: DashboardSkeleton()),
            ),
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final name = state.firstName;
    return RefreshIndicator(
      onRefresh: context.read<DashboardCubit>().refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                name.isEmpty ? 'Welcome' : 'Hi $name',
                style: context.text.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final account in state.accounts) ...[
                BalanceCard(account: account),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.xs),
              const QuickActions(),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(
                title: 'Recent activity',
                actionLabel: 'See all',
                onAction: () => context.go(AppRoutes.transactions),
              ),
              if (state.recent.isEmpty)
                const EmptyView(
                  title: 'No activity yet',
                  message: 'Your payments and top-ups will show up here.',
                )
              else
                for (final transaction in state.recent)
                  TransactionTile(transaction: transaction, heroScope: 'home'),
            ],
          ),
        ),
      ),
    );
  }
}
