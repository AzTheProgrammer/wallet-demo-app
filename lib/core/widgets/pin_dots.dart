import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';

class PinDots extends StatelessWidget {
  const PinDots({
    required this.filled,
    this.length = 5,
    this.hasError = false,
    super.key,
  });

  final int filled;
  final int length;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final active = hasError ? context.colors.negative : context.scheme.primary;
    return Semantics(
      label: 'PIN entry, $filled of $length digits entered',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < length; i++)
            AnimatedContainer(
              duration: AppMotion.fast,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? active : Colors.transparent,
                border: Border.all(
                  color: i < filled ? active : context.colors.faint,
                  width: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
