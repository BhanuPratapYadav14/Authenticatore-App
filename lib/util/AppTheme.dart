// lib/util/AppTheme.dart

import 'package:flutter/material.dart';

/// Centralised light and dark theme definitions for the app.
class AppThemes {
  AppThemes._();

  static const Color _seed = Colors.black;

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

/// The supported theme options. The stored string in SettingsModel matches
/// [label].
enum AppThemeOption {
  system('System', ThemeMode.system, Icons.brightness_auto_outlined),
  light('Light', ThemeMode.light, Icons.light_mode_outlined),
  dark('Dark', ThemeMode.dark, Icons.dark_mode_outlined);

  const AppThemeOption(this.label, this.mode, this.icon);

  final String label;
  final ThemeMode mode;
  final IconData icon;

  /// Resolves a stored theme string to an option, defaulting to [system].
  static AppThemeOption fromLabel(String label) {
    return AppThemeOption.values.firstWhere(
      (o) => o.label == label,
      orElse: () => AppThemeOption.system,
    );
  }
}
