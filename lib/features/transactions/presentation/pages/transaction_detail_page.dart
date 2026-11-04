import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/utils/formatters.dart';
import 'package:wallet_app/core/widgets/app_card.dart';
import 'package:wallet_app/core/widgets/detail_row.dart';
import 'package:wallet_app/core/widgets/icon_tile.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/core/widgets/state_views.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import 'package:wallet_app/features/transactions/presentation/widgets/transaction_visuals.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({
    required this.transactionId,
    required this.heroTag,
    super.key,
  });

  final String transactionId;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: BlocBuilder<TransactionDetailCubit, TransactionDetailState>(
        builder: (context, state) => switch (state.status) {
          ViewStatus.failure => FailureView(
            failure: state.failure!,
            onRetry: () =>
                context.read<TransactionDetailCubit>().load(transactionId),
          ),
          ViewStatus.success => _DetailContent(
            transaction: state.transaction!,
            heroTag: heroTag,
          ),
          _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: SkeletonList(count: 4),
          ),
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.transaction, required this.heroTag});

  final Transaction transaction;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final token = transaction.token;
    final account = transaction.accountName;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Hero(
                tag: heroTag,
                child: IconTile(
                  icon: transactionIcon(transaction.type),
                  size: 72,
                  color: context.scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              transaction.title,
              style: context.text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              transaction.amount.format(),
              style: context.text.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (token != null) ...[
              TokenCard(token: token),
              const SizedBox(height: AppSpacing.md),
            ],
            AppCard(
              child: Column(
                children: [
                  DetailRow(label: 'Status', value: _statusLabel(transaction)),
                  DetailRow(label: 'Type', value: transaction.type.label),
                  DetailRow(
                    label: 'Date',
                    value: formatDayTime(transaction.occurredAt),
                  ),
                  if (account != null)
                    DetailRow(label: 'Account', value: account),
                  DetailRow(label: 'Reference', value: transaction.reference),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(Transaction transaction) => switch (transaction.status) {
    TransactionStatus.completed => 'Completed',
    TransactionStatus.pending => 'Pending',
    TransactionStatus.failed => 'Failed',
  };
}

class TokenCard extends StatelessWidget {
  const TokenCard({required this.token, super.key});

  final String token;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Electricity token', style: context.text.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  groupToken(token),
                  style: context.text.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Copy token',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: token));
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Token copied')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
