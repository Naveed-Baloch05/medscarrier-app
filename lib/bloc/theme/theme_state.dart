import 'package:flutter/material.dart';

abstract class ThemeState {
  ThemeData get themeData;
  ThemeMode get themeMode;
}

class ThemeInitial extends ThemeState {
  @override
  ThemeData get themeData => ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      );

  @override
  ThemeMode get themeMode => ThemeMode.light;
}

class ThemeLight extends ThemeState {
  @override
  ThemeData get themeData => ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      );

  @override
  ThemeMode get themeMode => ThemeMode.light;
}

class ThemeDark extends ThemeState {
  @override
  ThemeData get themeData => ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      );

  @override
  ThemeMode get themeMode => ThemeMode.dark;
}
