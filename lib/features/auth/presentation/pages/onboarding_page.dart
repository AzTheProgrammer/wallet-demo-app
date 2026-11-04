import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/brand_mark.dart';
import 'package:wallet_app/core/widgets/icon_tile.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({required this.onGetStarted, super.key});

  final VoidCallback onGetStarted;

  static const List<(IconData, String, String)> _points = [
    (
      Icons.send_rounded,
      'Pay anyone',
      'Send money to any South African bank account in a few taps.',
    ),
    (
      Icons.bolt_rounded,
      'Top up in seconds',
      'Buy airtime, data and prepaid electricity, with your token on screen.',
    ),
    (
      Icons.workspace_premium_rounded,
      'Earn as you go',
      'Collect points and swap them for airtime, data or vouchers.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BrandMark(size: 56),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Your money, in one calm place.',
                  style: context.text.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This is a demo wallet with sample data. No real money moves.',
                  style: context.text.bodyLarge?.copyWith(
                    color: context.colors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final (icon, title, body) in _points)
                  _Point(icon: icon, title: title, body: body),
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: 'Set up my PIN', onPressed: onGetStarted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, color: context.scheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(body, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
