// AppTheme builds the Material 3 ThemeData for light and dark modes
// and registers the ThemeExtensions used across the app (semantic
// colors, spacing). Per ADR-018. See guide 27 §4.
//
// Default minimum sizes for buttons ensure WCAG AA tap targets ≥48 dp
// (see guide 28 §2).

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'extensions/app_semantic_colors.dart';
import 'extensions/app_spacing_extension.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: AppTypography.of(brightness),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        brightness == Brightness.light
            ? AppSemanticColors.light
            : AppSemanticColors.dark,
        AppSpacingExtension.standard,
      ],
    );
  }
}
