// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Colores Protección Civil (naranja + azul)
  static const _seed = Color(0xFFFF6600); // Naranja PC

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seed,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seed,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      );
}
