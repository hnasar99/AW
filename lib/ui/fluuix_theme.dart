import 'package:flutter/material.dart';

const fluuixBackground = Color(0xff07080c);
const fluuixSurface = Color(0xff14161e);
const fluuixBlue = Color(0xff2f6bff);
const fluuixGold = Color(0xffe4b23a);
const fluuixAccent = fluuixBlue;
const fluuixInk = Color(0xff141006);

ThemeData fluuixTheme() {
  const scheme = ColorScheme.dark(
    primary: fluuixGold,
    onPrimary: fluuixInk,
    surface: fluuixSurface,
    onSurface: Colors.white,
    secondary: fluuixBlue,
    onSecondary: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: fluuixBackground,
    canvasColor: fluuixBackground,
    dividerColor: const Color(0xff2a2e3a),
    textTheme: const TextTheme(
      titleMedium: TextStyle(
        fontSize: 13,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w600,
        color: fluuixGold,
      ),
      bodyLarge: TextStyle(color: Colors.white, height: 1.45),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      },
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: Color(0xff0c0e14)),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: fluuixBackground,
      indicatorColor: fluuixAccent.withValues(alpha: 0.16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fluuixSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: fluuixGold,
        foregroundColor: fluuixInk,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: fluuixGold,
        side: BorderSide(color: fluuixGold.withValues(alpha: 0.7)),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 48),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xff12141c),
      selectedColor: fluuixGold.withValues(alpha: 0.18),
      side: BorderSide(color: fluuixGold.withValues(alpha: 0.35)),
      labelStyle: const TextStyle(color: Colors.white),
      secondaryLabelStyle: const TextStyle(color: fluuixGold),
      showCheckmark: false,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: fluuixGold,
      textColor: Colors.white,
    ),
  );
}
