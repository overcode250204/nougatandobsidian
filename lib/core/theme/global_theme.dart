import 'package:flutter/material.dart';

ThemeData getThemeDefault() {
    const bg = Color(0xFF13111E);
    const surface = Color(0xFF1E1B2E);
    const card = Color(0xFF2A2640);
    const primary = Color(0xFF7C3AED);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        surfaceContainerHighest: card,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: surface, elevation: 0),
    );
  }