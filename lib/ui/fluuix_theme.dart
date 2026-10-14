import 'package:flutter/material.dart';

const fluuixBackground = Color(0xff07080c);
const fluuixSurface = Color(0xff14161e);
const fluuixAccent = Color(0xff3dffE8);
const fluuixInk = Color(0xff04120f);

ThemeData fluuixTheme() {
  const scheme = ColorScheme.dark(
    primary: fluuixAccent,
    onPrimary: fluuixInk,
    surface: fluuixSurface,
    onSurface: Colors.white,
    secondary: fluuixAccent,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: fluuixBackground,
    canvasColor: fluuixBackground,
    dividerColor: const Color(0xff2a2e3a),
    appBarTheme: const AppBarTheme(
      backgroundColor: fluuixBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
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
        backgroundColor: fluuixAccent,
        foregroundColor: fluuixInk,
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 48),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: fluuixAccent,
      textColor: Colors.white,
    ),
  );
}
