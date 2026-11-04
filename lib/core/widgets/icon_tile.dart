import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';

class IconTile extends StatelessWidget {
  const IconTile({required this.icon, this.color, this.size = 44, super.key});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.tile,
        borderRadius: const BorderRadius.all(AppRadii.md),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: color ?? context.scheme.onSurface,
      ),
    );
  }
}
