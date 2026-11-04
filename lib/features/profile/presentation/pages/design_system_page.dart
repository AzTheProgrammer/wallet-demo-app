import 'package:flutter/material.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/animated_money.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/app_card.dart';
import 'package:wallet_app/core/widgets/app_text_field.dart';
import 'package:wallet_app/core/widgets/detail_row.dart';
import 'package:wallet_app/core/widgets/icon_tile.dart';
import 'package:wallet_app/core/widgets/pin_dots.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/section_header.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/core/widgets/state_views.dart';
import 'package:wallet_app/core/widgets/success_mark.dart';

class DesignSystemPage extends StatelessWidget {
  const DesignSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design system')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              const SectionHeader(title: 'Colour'),
              _Swatches(),
              const SectionHeader(title: 'Type'),
              Text('Display', style: context.text.displayMedium),
              Text('Headline', style: context.text.headlineMedium),
              Text('Title', style: context.text.titleMedium),
              Text('Body copy for longer text', style: context.text.bodyMedium),
              const SectionHeader(title: 'Controls'),
              AppButton(label: 'Primary', onPressed: () {}),
              AppButton(
                label: 'Secondary',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
              AppButton(
                label: 'Quiet',
                variant: AppButtonVariant.quiet,
                onPressed: () {},
              ),
              const AppTextField(label: 'Text field', hint: 'Hint'),
              const SectionHeader(title: 'Components'),
              const AppCard(
                child: DetailRow(label: 'Reference', value: 'Rent'),
              ),
              const Row(
                children: [
                  IconTile(icon: Icons.bolt_rounded),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: PinDots(filled: 3)),
                ],
              ),
              AnimatedMoney(
                amount: const Money(1245050),
                style: context.text.displayMedium,
              ),
              const Center(child: SuccessMark(size: 72)),
              const SkeletonList(count: 2),
              const SizedBox(
                height: 240,
                child: FailureView(failure: OfflineFailure()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatches extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = [
      context.scheme.primary,
      context.scheme.primaryContainer,
      context.colors.positive,
      context.colors.negative,
      context.colors.warning,
      context.colors.muted,
      context.colors.tile,
      context.colors.line,
    ];
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final color in colors)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.all(AppRadii.sm),
            ),
          ),
      ],
    );
  }
}
