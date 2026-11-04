import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/animated_money.dart';
import 'package:wallet_app/features/dashboard/domain/entities/account.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({required this.account, super.key});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final isMain = account.kind == AccountKind.main;
    final label = context.text.labelMedium?.copyWith(
      color: AppPalette.paper.withValues(alpha: 0.82),
    );
    return Container(
      padding: EdgeInsets.all(isMain ? AppSpacing.lg : AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadii.hero,
        boxShadow: isMain ? AppElevation.hero : null,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMain
              ? context.colors.heroGradient
              : context.colors.savingsGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(account.name, style: label)),
              Text(account.maskedNumber, style: label),
            ],
          ),
          SizedBox(height: isMain ? AppSpacing.lg : AppSpacing.xs),
          AnimatedMoney(
            amount: account.balance,
            style:
                (isMain ? context.text.displayMedium : context.text.titleLarge)
                    ?.copyWith(color: AppPalette.paper),
          ),
          if (isMain) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text('Available balance', style: label),
          ],
        ],
      ),
    );
  }
}
