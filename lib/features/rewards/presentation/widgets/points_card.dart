import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/utils/formatters.dart';
import 'package:wallet_app/features/rewards/domain/entities/rewards.dart';

class PointsCard extends StatelessWidget {
  const PointsCard({required this.summary, super.key});

  final RewardsSummary summary;

  @override
  Widget build(BuildContext context) {
    final next = summary.nextTier;
    final label = context.text.labelMedium?.copyWith(
      color: AppPalette.paper.withValues(alpha: 0.85),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadii.hero,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.colors.heroGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${summary.currentTier.name} member', style: label),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${formatPoints(summary.points)} pts',
            style: context.text.displayMedium?.copyWith(
              color: AppPalette.paper,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: const BorderRadius.all(AppRadii.sm),
            child: LinearProgressIndicator(
              value: summary.progress,
              minHeight: 8,
              color: AppPalette.brandBright,
              backgroundColor: AppPalette.paper.withValues(alpha: 0.2),
              semanticsLabel: 'Progress to next tier',
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            next == null
                ? 'You have reached the top tier'
                : '${formatPoints(next.minPoints - summary.points)} pts to ${next.name}',
            style: label,
          ),
        ],
      ),
    );
  }
}
