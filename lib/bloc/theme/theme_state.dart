import 'package:flutter/material.dart';

abstract class ThemeState {
  ThemeData get themeData;
  ThemeMode get themeMode;
}

class ThemeInitial extends ThemeState {
  @override
  ThemeData get themeData => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        scaffoldBackgroundColor: const Color(0xFFF2F5F3),
      );

  @override
  ThemeMode get themeMode => ThemeMode.light;
}

const ColorScheme _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF0F7253),
  onPrimary: Colors.white,
  secondary: Color(0xFF0F7253),
  onSecondary: Colors.white,
  error: Color(0xFFBA1A1A),
  onError: Colors.white,
  surface: Colors.white,
  onSurface: Color(0xFF191C1B),
  onSurfaceVariant: Color(0xFF6E7A75),
  outline: Color(0xFFE2E8E5),
  outlineVariant: Color(0xFFE2E8E5),
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFF7F9F8),
  surfaceContainer: Color(0xFFF2F5F3),
  surfaceContainerHigh: Color(0xFFE7EBE9),
  surfaceContainerHighest: Color(0xFFDCE1DE),
);

const ColorScheme _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF0F7253),
  onPrimary: Colors.white,
  secondary: Color(0xFF0F7253),
  onSecondary: Colors.white,
  error: Color(0xFFBA1A1A),
  onError: Colors.white,
  surface: Color(0xFF151E1A),
  onSurface: Color(0xFFD1DDD7),
  onSurfaceVariant: Color(0xFF8B9B94),
  outline: Color(0xFF1D322A),
  outlineVariant: Color(0xFF1D322A),
  surfaceContainerLowest: Color(0xFF0C1310),
  surfaceContainerLow: Color(0xFF1A2520),
  surfaceContainer: Color(0xFF1D322A),
  surfaceContainerHigh: Color(0xFF263D33),
  surfaceContainerHighest: Color(0xFF324A3E),
);

class ThemeLight extends ThemeState {
  @override
  ThemeData get themeData => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        scaffoldBackgroundColor: const Color(0xFFF2F5F3),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      );

  @override
  ThemeMode get themeMode => ThemeMode.light;
}

class ThemeDark extends ThemeState {
  @override
  ThemeData get themeData => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        scaffoldBackgroundColor: const Color(0xFF0C1310),
        cardTheme: const CardThemeData(
          color: Color(0xFF1D322A),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      );

  @override
  ThemeMode get themeMode => ThemeMode.dark;
}
