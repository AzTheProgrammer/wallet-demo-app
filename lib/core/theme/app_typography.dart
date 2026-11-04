import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const family = 'WorkSans';
  static const _tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color ink, Color soft) => TextTheme(
    displayLarge: _style(44, FontWeight.w600, 1.1, ink, -1.2, tabular: true),
    displayMedium: _style(34, FontWeight.w600, 1.15, ink, -0.8, tabular: true),
    headlineLarge: _style(28, FontWeight.w600, 1.2, ink, -0.5),
    headlineMedium: _style(24, FontWeight.w600, 1.25, ink, -0.3),
    titleLarge: _style(20, FontWeight.w600, 1.3, ink, -0.2),
    titleMedium: _style(16, FontWeight.w600, 1.35, ink, 0),
    titleSmall: _style(14, FontWeight.w600, 1.35, ink, 0),
    bodyLarge: _style(16, FontWeight.w400, 1.5, ink, 0),
    bodyMedium: _style(14, FontWeight.w400, 1.45, ink, 0),
    bodySmall: _style(13, FontWeight.w400, 1.4, soft, 0),
    labelLarge: _style(15, FontWeight.w600, 1.2, ink, 0.1),
    labelMedium: _style(13, FontWeight.w500, 1.3, soft, 0.1),
    labelSmall: _style(12, FontWeight.w500, 1.3, soft, 0.2),
  );

  static TextStyle _style(
    double size,
    FontWeight weight,
    double height,
    Color color,
    double tracking, {
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
    letterSpacing: tracking,
    fontFeatures: tabular ? _tabular : null,
  );
}
