import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/router/app_routes.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/icon_tile.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Action(
          icon: Icons.send_rounded,
          label: 'Send',
          onTap: () => context.push(AppRoutes.send),
        ),
        _Action(
          icon: Icons.phone_android_rounded,
          label: 'Airtime',
          onTap: () => context.push(AppRoutes.vas('airtime')),
        ),
        _Action(
          icon: Icons.wifi_rounded,
          label: 'Data',
          onTap: () => context.push(AppRoutes.vas('data')),
        ),
        _Action(
          icon: Icons.bolt_rounded,
          label: 'Electricity',
          onTap: () => context.push(AppRoutes.vas('electricity')),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: AppRadii.card,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              children: [
                IconTile(icon: icon, size: 52, color: context.scheme.primary),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: context.text.labelMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
