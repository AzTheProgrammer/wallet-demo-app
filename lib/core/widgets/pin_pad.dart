import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';

class PinPad extends StatelessWidget {
  const PinPad({
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;
  final bool enabled;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in _rows)
            Row(children: [for (final digit in row) _digit(digit)]),
          Row(
            children: [
              _PadKey(
                semanticLabel: 'Use biometrics',
                onTap: enabled ? onBiometric : null,
                child: onBiometric == null
                    ? const SizedBox.shrink()
                    : const Icon(Icons.fingerprint_rounded, size: 30),
              ),
              _digit('0'),
              _PadKey(
                semanticLabel: 'Delete digit',
                onTap: enabled ? onBackspace : null,
                child: const Icon(Icons.backspace_outlined, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _digit(String digit) => _PadKey(
    semanticLabel: digit,
    onTap: enabled ? () => onDigit(digit) : null,
    child: Builder(
      builder: (context) => Text(digit, style: context.text.headlineMedium),
    ),
  );
}

class _PadKey extends StatelessWidget {
  const _PadKey({
    required this.semanticLabel,
    required this.child,
    required this.onTap,
  });

  final String semanticLabel;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tap = onTap;
    return Expanded(
      child: Semantics(
        button: true,
        enabled: tap != null,
        label: semanticLabel,
        excludeSemantics: true,
        child: InkResponse(
          onTap: tap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  tap();
                },
          radius: 36,
          child: SizedBox(height: 68, child: Center(child: child)),
        ),
      ),
    );
  }
}
