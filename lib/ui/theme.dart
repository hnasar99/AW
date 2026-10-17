import 'package:flutter/material.dart';

/// Fluuix brand color palette for Material 3 theming.
abstract final class FluuixColors {
  /// Primary navy blue - main brand color
  static const navy = Color(0xFF1C477C);

  /// Accent gold - secondary brand color
  static const gold = Color(0xFFF2C86E);

  /// Bright gold variant for emphasis
  static const goldBright = Color(0xFFF6D478);

  /// Light blue for interactive elements
  static const lightBlue = Color(0xFF5AA9FF);

  /// Dark background for scaffolds
  static const backgroundDark = Color(0xFF0A0D14);

  /// Surface color for cards
  static const surface = Color(0xFF141820);

  /// Elevated surface for dialogs and sheets
  static const surfaceElevated = Color(0xFF1A1F2A);

  /// Subtle border color
  static const border = Color(0xFF2A3142);

  /// Success green
  static const success = Color(0xFF4CAF50);

  /// Warning amber
  static const warning = Color(0xFFFFB300);

  /// Error red
  static const error = Color(0xFFEF5350);

  /// Muted text
  static const textMuted = Color(0xFF9CA3AF);

  /// TESTNET badge background
  static const testnetBadge = Color(0xFF7C3AED);
}

/// Creates the Fluuix Material 3 dark theme.
ThemeData fluuixTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: FluuixColors.navy,
    brightness: Brightness.dark,
    primary: FluuixColors.navy,
    onPrimary: Colors.white,
    secondary: FluuixColors.gold,
    onSecondary: FluuixColors.backgroundDark,
    tertiary: FluuixColors.lightBlue,
    onTertiary: Colors.white,
    surface: FluuixColors.surface,
    onSurface: Colors.white,
    error: FluuixColors.error,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: FluuixColors.backgroundDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: FluuixColors.backgroundDark,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: FluuixColors.navy,
    ),
    cardTheme: CardThemeData(
      color: FluuixColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FluuixColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FluuixColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FluuixColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FluuixColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: FluuixColors.lightBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: FluuixColors.textMuted),
      hintStyle: const TextStyle(color: FluuixColors.textMuted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FluuixColors.navy,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FluuixColors.lightBlue,
        side: const BorderSide(color: FluuixColors.lightBlue),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FluuixColors.lightBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: FluuixColors.surfaceElevated,
      labelStyle: const TextStyle(color: Colors.white),
      side: const BorderSide(color: FluuixColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: FluuixColors.surface,
      indicatorColor: FluuixColors.navy.withValues(alpha: 0.3),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: FluuixColors.lightBlue,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }
        return const TextStyle(color: FluuixColors.textMuted, fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: FluuixColors.lightBlue);
        }
        return const IconThemeData(color: FluuixColors.textMuted);
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: FluuixColors.border,
      thickness: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: FluuixColors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: FluuixColors.surfaceElevated,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: FluuixColors.lightBlue,
      linearTrackColor: FluuixColors.border,
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: FluuixColors.textMuted,
      collapsedIconColor: FluuixColors.textMuted,
      textColor: Colors.white,
      collapsedTextColor: Colors.white,
    ),
  );
}

/// Extension providing semantic color access for Fluuix components.
extension FluuixThemeExtension on ThemeData {
  Color get cardBackground => FluuixColors.surface;
  Color get cardBorder => FluuixColors.border;
  Color get accentGold => FluuixColors.gold;
  Color get accentGoldBright => FluuixColors.goldBright;
  Color get accentBlue => FluuixColors.lightBlue;
  Color get textMuted => FluuixColors.textMuted;
  Color get success => FluuixColors.success;
  Color get warning => FluuixColors.warning;
  Color get testnetBadge => FluuixColors.testnetBadge;
}
