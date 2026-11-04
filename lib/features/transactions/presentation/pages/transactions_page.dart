import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/widgets/app_text_field.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/core/widgets/state_views.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transaction_filters.dart';
import 'package:wallet_app/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:wallet_app/features/transactions/presentation/widgets/filter_sheet.dart';
import 'package:wallet_app/features/transactions/presentation/widgets/transaction_tile.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  Future<void> _openFilters(BuildContext context) async {
    final bloc = context.read<TransactionsBloc>();
    final filters = await showModalBottomSheet<TransactionFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FilterSheet(initial: bloc.state.filters),
    );
    if (filters != null) bloc.add(TransactionsEvent.filtersChanged(filters));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TransactionsBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          BlocSelector<TransactionsBloc, TransactionsState, int>(
            selector: (state) => state.filters.activeCount,
            builder: (context, count) => IconButton(
              tooltip: 'Filter activity',
              onPressed: () => _openFilters(context),
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.tune_rounded),
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: AppTextField(
                label: 'Search activity',
                prefixIcon: Icons.search_rounded,
                textInputAction: TextInputAction.search,
                onChanged: (value) =>
                    bloc.add(TransactionsEvent.searchChanged(value)),
              ),
            ),
            const Expanded(child: _TransactionsBody()),
          ],
        ),
      ),
    );
  }
}

class _TransactionsBody extends StatelessWidget {
  const _TransactionsBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        final bloc = context.read<TransactionsBloc>();
        return switch (state.status) {
          ViewStatus.failure => FailureView(
            failure: state.failure!,
            onRetry: () => bloc.add(const TransactionsEvent.started()),
          ),
          ViewStatus.success when state.items.isEmpty => EmptyView(
            icon: Icons.search_off_rounded,
            title: state.isFiltered ? 'No matches' : 'No activity yet',
            message: state.isFiltered
                ? 'Try a different search or clear your filters.'
                : 'Your payments and top-ups will show up here.',
          ),
          ViewStatus.success => _TransactionList(state: state),
          _ => const SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SkeletonList(count: 8),
          ),
        };
      },
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.state});

  final TransactionsState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TransactionsBloc>();
    return RefreshIndicator(
      onRefresh: () async => bloc.add(const TransactionsEvent.refreshed()),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - 240) {
            bloc.add(const TransactionsEvent.nextPageRequested());
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: state.items.length + 1,
          itemBuilder: (context, index) {
            if (index < state.items.length) {
              return TransactionTile(
                key: ValueKey(state.items[index].id),
                transaction: state.items[index],
                heroScope: 'activity',
              );
            }
            return _ListFooter(state: state);
          },
        ),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state});

  final TransactionsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) return const SkeletonList(count: 2);
    final failure = state.nextPageFailure;
    if (failure != null) {
      return TextButton(
        onPressed: () => context.read<TransactionsBloc>().add(
          const TransactionsEvent.nextPageRequested(),
        ),
        child: const Text('Load more failed. Try again'),
      );
    }
    return const SizedBox(height: AppSpacing.lg);
  }
}
