// Base TextTheme for Custodiam. Material 3 defaults are kept; this
// indirection is reserved for future per-style adjustments without
// touching app_theme.dart. See guide 27 §4.

import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  /// Returns the TextTheme used by AppTheme.light()/dark().
  ///
  /// For MVP we rely on the Material 3 defaults derived from
  /// ColorScheme.fromSeed; this method exists so future tweaks
  /// (e.g. system font overrides, Mi Sans / HarmonyOS Sans
  /// considerations) have a single place to live.
  static TextTheme of(Brightness brightness) {
    final base = brightness == Brightness.light
        ? Typography.material2021(platform: TargetPlatform.android).black
        : Typography.material2021(platform: TargetPlatform.android).white;
    return base;
  }
}
