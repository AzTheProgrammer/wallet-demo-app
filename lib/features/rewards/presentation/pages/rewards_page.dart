import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/utils/formatters.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/icon_tile.dart';
import 'package:wallet_app/core/widgets/option_tile.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/section_header.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/core/widgets/state_views.dart';
import 'package:wallet_app/features/rewards/domain/entities/rewards.dart';
import 'package:wallet_app/features/rewards/presentation/cubit/rewards_cubit.dart';
import 'package:wallet_app/features/rewards/presentation/widgets/points_card.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  void _showResult(BuildContext context, RewardsState state) {
    final failure = state.redeemFailure;
    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    final redemption = state.redemption;
    if (redemption == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _RedemptionSheet(redemption: redemption),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: BlocConsumer<RewardsCubit, RewardsState>(
        listenWhen: (previous, current) =>
            previous.redeemingId != null && current.redeemingId == null,
        listener: _showResult,
        builder: (context, state) => switch (state.status) {
          ViewStatus.failure => FailureView(
            failure: state.failure!,
            onRetry: context.read<RewardsCubit>().load,
          ),
          ViewStatus.success => _RewardsContent(state: state),
          _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Skeleton(
              child: Column(
                children: [
                  SkeletonBox(height: 180, radius: AppRadii.lg),
                  SizedBox(height: AppSpacing.lg),
                  SkeletonListTile(),
                  SkeletonListTile(),
                  SkeletonListTile(),
                ],
              ),
            ),
          ),
        },
      ),
    );
  }
}

class _RewardsContent extends StatelessWidget {
  const _RewardsContent({required this.state});

  final RewardsState state;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary!;
    return RefreshIndicator(
      onRefresh: context.read<RewardsCubit>().load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PointsCard(summary: summary),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Redeem your points'),
              if (state.offers.isEmpty)
                const EmptyView(
                  icon: Icons.card_giftcard_rounded,
                  title: 'No rewards right now',
                  message: 'Check back soon for new offers.',
                ),
              for (final offer in state.offers)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _OfferTile(
                    offer: offer,
                    affordable: offer.cost <= summary.points,
                    isBusy: state.redeemingId != null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.affordable,
    required this.isBusy,
  });

  final RewardOffer offer;
  final bool affordable;
  final bool isBusy;

  IconData get _icon => switch (offer.kind) {
    RewardKind.airtime => Icons.phone_android_rounded,
    RewardKind.data => Icons.wifi_rounded,
    RewardKind.voucher => Icons.card_giftcard_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return OptionTile(
      title: offer.title,
      subtitle: '${offer.description} · ${formatPoints(offer.cost)} pts',
      leading: IconTile(icon: _icon, color: context.scheme.primary),
      trailing: Text(
        affordable ? 'Redeem' : 'Not enough',
        style: context.text.labelMedium?.copyWith(
          color: affordable ? context.scheme.primary : context.colors.muted,
        ),
      ),
      onTap: () {
        if (!affordable || isBusy) return;
        context.read<RewardsCubit>().redeem(offer);
      },
    );
  }
}

class _RedemptionSheet extends StatelessWidget {
  const _RedemptionSheet({required this.redemption});

  final Redemption redemption;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(redemption.offerTitle, style: context.text.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Your code', style: context.text.labelMedium),
          SelectableText(redemption.code, style: context.text.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${formatPoints(redemption.pointsRemaining)} pts left',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
