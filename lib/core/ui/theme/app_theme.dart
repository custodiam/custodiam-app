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
    final isDark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    );

    // Dark polish (ver `app_colors.dart` para el porqué del brand
    // forzado): el primary derivado del seed pierde saturación para
    // cumplir contraste; lo sobrescribimos con un naranja más vivo y
    // forzamos `onPrimary` negro para mantener legibilidad sobre el
    // tono claro.
    final colorScheme = isDark
        ? baseScheme.copyWith(
            primary: AppColors.brandDark,
            onPrimary: Colors.black,
          )
        : baseScheme;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: AppTypography.of(brightness),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        // Jerarquía visual en dark: el AppBar sale del mismo `surface`
        // que el body por defecto y queda plano. Subir un escalón de
        // surface lo separa sin recurrir a elevation (que en M3
        // tendría que pintar overlay y se ve sucio).
        backgroundColor: isDark ? colorScheme.surfaceContainer : null,
      ),
      cardTheme: isDark
          ? CardThemeData(
              color: colorScheme.surfaceContainerHigh,
              elevation: 0,
            )
          : null,
      dividerTheme: isDark
          ? DividerThemeData(
              color: colorScheme.outline,
              thickness: 1,
            )
          : null,
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
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        filled: true,
        // En dark el borde sin foco usa `outlineVariant` (apenas
        // visible). Subimos a `outline` para que cards y formularios
        // tengan límites claros.
        enabledBorder: isDark
            ? OutlineInputBorder(
                borderSide: BorderSide(color: colorScheme.outline),
              )
            : null,
      ),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        isDark ? AppSemanticColors.dark : AppSemanticColors.light,
        AppSpacingExtension.standard,
      ],
    );
  }
}
