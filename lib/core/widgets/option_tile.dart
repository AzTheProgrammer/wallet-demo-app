import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_card.dart';

class OptionTile extends StatelessWidget {
  const OptionTile({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = subtitle;
    return Semantics(
      selected: selected,
      button: true,
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  if (detail != null)
                    Text(detail, style: context.text.bodySmall),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (selected)
              Icon(Icons.check_circle_rounded, color: context.scheme.primary),
          ],
        ),
      ),
    );
  }
}
