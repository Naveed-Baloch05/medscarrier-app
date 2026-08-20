import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      brightness: Brightness.light,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      brightness: Brightness.dark,
    );
  }
}
