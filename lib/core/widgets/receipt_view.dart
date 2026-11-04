import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/app_card.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/success_mark.dart';

class ReceiptView extends StatelessWidget {
  const ReceiptView({
    required this.title,
    required this.amount,
    required this.rows,
    required this.onDone,
    this.highlight,
    super.key,
  });

  final String title;
  final String amount;
  final List<Widget> rows;
  final VoidCallback onDone;
  final Widget? highlight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SuccessMark()),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: context.text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              amount,
              style: context.text.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (highlight != null) ...[
              highlight!,
              const SizedBox(height: AppSpacing.md),
            ],
            AppCard(child: Column(children: rows)),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Done', onPressed: onDone),
          ],
        ),
      ),
    );
  }
}
