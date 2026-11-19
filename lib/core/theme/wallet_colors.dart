import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';

@immutable
class WalletColors extends ThemeExtension<WalletColors> {
  const WalletColors({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.muted,
    required this.faint,
    required this.line,
    required this.tile,
    required this.skeleton,
    required this.skeletonHighlight,
    required this.heroGradient,
    required this.savingsGradient,
  });

  static const light = WalletColors(
    positive: AppPalette.positive,
    negative: AppPalette.negative,
    warning: AppPalette.warning,
    muted: AppPalette.inkSoft,
    faint: AppPalette.inkFaint,
    line: AppPalette.line,
    tile: AppPalette.mist,
    skeleton: Color(0xFFE5E9F1),
    skeletonHighlight: Color(0xFFF3F5FA),
    heroGradient: [AppPalette.brand, AppPalette.brandDeep],
    savingsGradient: [Color(0xFF222C42), AppPalette.brandInk],
  );

  static const dark = WalletColors(
    positive: AppPalette.positiveDark,
    negative: AppPalette.negativeDark,
    warning: AppPalette.warningDark,
    muted: AppPalette.moonSoft,
    faint: AppPalette.moonFaint,
    line: AppPalette.nightLine,
    tile: AppPalette.nightHigh,
    skeleton: Color(0xFF1B2335),
    skeletonHighlight: Color(0xFF283147),
    heroGradient: [Color(0xFF2160E0), AppPalette.brandInk],
    savingsGradient: [Color(0xFF283249), Color(0xFF121A2B)],
  );

  final Color positive;
  final Color negative;
  final Color warning;
  final Color muted;
  final Color faint;
  final Color line;
  final Color tile;
  final Color skeleton;
  final Color skeletonHighlight;
  final List<Color> heroGradient;
  final List<Color> savingsGradient;

  @override
  WalletColors copyWith({Color? positive, Color? negative}) => WalletColors(
    positive: positive ?? this.positive,
    negative: negative ?? this.negative,
    warning: warning,
    muted: muted,
    faint: faint,
    line: line,
    tile: tile,
    skeleton: skeleton,
    skeletonHighlight: skeletonHighlight,
    heroGradient: heroGradient,
    savingsGradient: savingsGradient,
  );

  @override
  WalletColors lerp(ThemeExtension<WalletColors>? other, double t) =>
      t < 0.5 || other is! WalletColors ? this : other;
}

extension WalletTheme on BuildContext {
  WalletColors get colors => Theme.of(this).extension<WalletColors>()!;

  TextTheme get text => Theme.of(this).textTheme;

  ColorScheme get scheme => Theme.of(this).colorScheme;
}
