import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const brand = Color(0xFF1D4FD1);
  static const brandBright = Color(0xFF6EA8FF);
  static const brandDeep = Color(0xFF143A9E);
  static const brandInk = Color(0xFF0A1F4D);
  static const brandTint = Color(0xFFE3ECFC);

  static const ink = Color(0xFF121A2B);
  static const inkSoft = Color(0xFF4E5970);
  static const inkFaint = Color(0xFF66718A);
  static const line = Color(0xFFE0E5EE);
  static const canvas = Color(0xFFF5F7FB);
  static const paper = Color(0xFFFFFFFF);
  static const mist = Color(0xFFECF0F7);

  static const night = Color(0xFF0B1120);
  static const nightRaised = Color(0xFF141B2D);
  static const nightHigh = Color(0xFF1E2639);
  static const nightLine = Color(0xFF2B3449);
  static const moon = Color(0xFFECF0F8);
  static const moonSoft = Color(0xFFA8B2C7);
  static const moonFaint = Color(0xFF8A94AA);

  static const positive = Color(0xFF0B7A5E);
  static const positiveDark = Color(0xFF4FD8AE);
  static const negative = Color(0xFFC03A2B);
  static const negativeDark = Color(0xFFFF8A7A);
  static const warning = Color(0xFF9A6200);
  static const warningDark = Color(0xFFF2B65A);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadii {
  static const sm = Radius.circular(10);
  static const md = Radius.circular(16);
  static const lg = Radius.circular(24);
  static const card = BorderRadius.all(md);
  static const hero = BorderRadius.all(lg);
  static const control = BorderRadius.all(Radius.circular(14));
}

abstract final class AppElevation {
  static const raised = [
    BoxShadow(color: Color(0x14081530), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const hero = [
    BoxShadow(color: Color(0x330A2A73), blurRadius: 32, offset: Offset(0, 16)),
  ];
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 700);
  static const Cubic curve = Curves.easeOutCubic;
}

abstract final class AppLayout {
  static const contentMaxWidth = 560.0;
  static const railBreakpoint = 840.0;
}
