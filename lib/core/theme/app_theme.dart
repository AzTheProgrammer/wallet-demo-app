import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/app_typography.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(
    scheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.brand,
      onPrimary: AppPalette.paper,
      primaryContainer: AppPalette.brandTint,
      onPrimaryContainer: AppPalette.brandInk,
      secondary: AppPalette.inkSoft,
      onSecondary: AppPalette.paper,
      error: AppPalette.negative,
      onError: AppPalette.paper,
      surface: AppPalette.paper,
      onSurface: AppPalette.ink,
      surfaceContainerHighest: AppPalette.mist,
      onSurfaceVariant: AppPalette.inkSoft,
      outline: AppPalette.line,
    ),
    canvas: AppPalette.canvas,
    colors: WalletColors.light,
    text: AppTypography.textTheme(AppPalette.ink, AppPalette.inkSoft),
  );

  static final ThemeData dark = _build(
    scheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppPalette.brandBright,
      onPrimary: AppPalette.brandInk,
      primaryContainer: Color(0xFF16295A),
      onPrimaryContainer: AppPalette.moon,
      secondary: AppPalette.moonSoft,
      onSecondary: AppPalette.night,
      error: AppPalette.negativeDark,
      onError: AppPalette.night,
      surface: AppPalette.nightRaised,
      onSurface: AppPalette.moon,
      surfaceContainerHighest: AppPalette.nightHigh,
      onSurfaceVariant: AppPalette.moonSoft,
      outline: AppPalette.nightLine,
    ),
    canvas: AppPalette.night,
    colors: WalletColors.dark,
    text: AppTypography.textTheme(AppPalette.moon, AppPalette.moonSoft),
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required Color canvas,
    required WalletColors colors,
    required TextTheme text,
  }) => ThemeData(
    colorScheme: scheme,
    fontFamily: AppTypography.family,
    scaffoldBackgroundColor: canvas,
    textTheme: text,
    extensions: [colors],
    dividerTheme: DividerThemeData(color: colors.line, space: 1, thickness: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    navigationBarTheme: _navigationBar(scheme, colors, text),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: colors.muted),
      selectedLabelTextStyle: text.labelMedium?.copyWith(
        color: scheme.onSurface,
      ),
      unselectedLabelTextStyle: text.labelMedium,
    ),
    inputDecorationTheme: _input(scheme, colors, text),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: colors.line,
      constraints: const BoxConstraints(maxWidth: AppLayout.contentMaxWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadii.lg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.control),
      backgroundColor: scheme.onSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: scheme.surface),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide(color: colors.line),
      shape: const StadiumBorder(),
      backgroundColor: scheme.surface,
      selectedColor: scheme.primaryContainer,
      labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        side: BorderSide(color: colors.line),
        textStyle: text.labelMedium,
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );

  static NavigationBarThemeData _navigationBar(
    ColorScheme scheme,
    WalletColors colors,
    TextTheme text,
  ) => NavigationBarThemeData(
    backgroundColor: scheme.surface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: scheme.primaryContainer,
    elevation: 0,
    height: 68,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? scheme.primary
            : colors.muted,
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => text.labelSmall?.copyWith(
        color: states.contains(WidgetState.selected)
            ? scheme.onSurface
            : colors.muted,
      ),
    ),
  );

  static InputDecorationTheme _input(
    ColorScheme scheme,
    WalletColors colors,
    TextTheme text,
  ) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadii.control,
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      labelStyle: text.bodyMedium?.copyWith(color: colors.muted),
      hintStyle: text.bodyMedium?.copyWith(color: colors.faint),
      border: border(colors.line),
      enabledBorder: border(colors.line),
      focusedBorder: border(scheme.primary, 1.5),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 1.5),
    );
  }
}
