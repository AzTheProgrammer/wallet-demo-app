import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/pin_dots.dart';
import 'package:wallet_app/core/widgets/pin_pad.dart';

class PinScreenBody extends StatelessWidget {
  const PinScreenBody({
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onDigit,
    required this.onBackspace,
    this.error,
    this.onBiometric,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final int filled;
  final String? error;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final message = error;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - AppSpacing.xl - AppSpacing.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    title,
                    style: context.text.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              PinDots(
                filled: filled,
                hasError: message != null,
              ),
              SizedBox(
                height: AppSpacing.xxl,
                child: message == null
                    ? null
                    : Center(
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            message,
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.negative,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              ),
              PinPad(
                onDigit: onDigit,
                onBackspace: onBackspace,
                onBiometric: onBiometric,
                enabled: enabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
