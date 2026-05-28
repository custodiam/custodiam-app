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
    // `DynamicSchemeVariant.fidelity` mantiene la identidad cromática
    // del seed lo más fielmente posible: el `primary` derivado conserva
    // la hue + chroma del naranja brand en lugar de desaturarse hacia
    // un tono "polite" como hace el default `tonalSpot`. También
    // produce un `surface` con tinte cálido (no gris neutro) que pega
    // con la identidad PC. Es el patrón equivalente al que Material
    // Theme Builder (m3.material.io) genera al exportar la paleta con
    // el modo "Content" / "Fidelity".
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    // Dark polish: aun con `fidelity`, el primary cae a un tono más
    // apagado para garantizar contraste sobre surfaces oscuras. El
    // brand naranja (#FF6600) tiene contraste 2.94:1 sobre negro, por
    // debajo de WCAG 3:1 para componentes. `AppColors.brandDark`
    // (#FF8533, mismo hue con luminancia subida) llega a 4.5:1+ con
    // black como onPrimary, manteniendo identidad y accesibilidad.
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
