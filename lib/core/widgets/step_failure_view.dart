import 'package:flutter/material.dart';
import 'package:wallet_app/core/error/failures.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/state_views.dart';

class StepFailureView extends StatelessWidget {
  const StepFailureView({
    required this.failure,
    required this.onRetry,
    required this.onCancel,
    super.key,
  });

  final Failure failure;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Expanded(child: FailureView(failure: failure)),
          AppButton(label: 'Try again', onPressed: onRetry),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Cancel',
            variant: AppButtonVariant.quiet,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
