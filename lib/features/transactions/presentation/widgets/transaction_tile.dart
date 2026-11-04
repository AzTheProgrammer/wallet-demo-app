import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/router/app_routes.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/utils/formatters.dart';
import 'package:wallet_app/core/widgets/icon_tile.dart';
import 'package:wallet_app/features/transactions/domain/entities/transaction.dart';
import 'package:wallet_app/features/transactions/presentation/widgets/transaction_visuals.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    required this.transaction,
    required this.heroScope,
    super.key,
  });

  final Transaction transaction;
  final String heroScope;

  @override
  Widget build(BuildContext context) {
    final amount = transaction.isIncoming
        ? '+${transaction.amount.format()}'
        : transaction.amount.format();
    return Semantics(
      button: true,
      label:
          '${transaction.title}, $amount, ${formatDay(transaction.occurredAt)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadii.card,
        onTap: () => context.push(
          AppRoutes.transactionDetail(transaction.id, heroScope),
          extra: transaction,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Hero(
                tag: '$heroScope-${transaction.id}',
                child: IconTile(icon: transactionIcon(transaction.type)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      formatDay(transaction.occurredAt),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                amount,
                style: context.text.titleSmall?.copyWith(
                  color: transaction.isIncoming
                      ? context.colors.positive
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
