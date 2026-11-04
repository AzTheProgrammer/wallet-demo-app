import 'package:flutter/material.dart';
import 'package:wallet_app/core/domain/money.dart';
import 'package:wallet_app/core/theme/tokens.dart';

class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney({required this.amount, this.style, super.key});

  final Money amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.slow;
    return Semantics(
      label: amount.format(),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: amount.cents.toDouble()),
        duration: duration,
        curve: AppMotion.curve,
        builder: (context, value, _) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(Money(value.round()).format(), style: style),
        ),
      ),
    );
  }
}
