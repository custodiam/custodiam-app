// Custodiam palette: brand seed + semantic colors per ADR-018.
// See guide 27 §4 and 09_CALIDAD §Accessibility for contrast notes.
//
// Note: brand orange (#FF6600) on white yields 3.16:1 contrast, which
// passes WCAG AA for large text only. Never use it as text color on
// light backgrounds; use it as fill on AppPrimaryButton instead.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Civil Protection brand orange (light theme primary).
  static const Color brand = Color(0xFFFF6600);

  /// Brand orange tuned for dark surfaces. The `ColorScheme.fromSeed`
  /// derivation pulls the M3 primary toward a desaturated, low-chroma
  /// tone that meets WCAG contrast on dark but loses the PC identity.
  /// `#FF8533` (≈ brand at L≈70) keeps full saturation while pushing
  /// luminance to ~70, which yields ≥4.5:1 against `surfaceContainer`
  /// in the dark scheme without bleaching the orange.
  static const Color brandDark = Color(0xFFFF8533);

  /// Optional institutional secondary (blue).
  static const Color brandSecondary = Color(0xFF1565C0);

  // ── Semantic — light theme ─────────────────────────────────────

  static const Color successLight = Color(0xFF2E7D32);
  static const Color warningLight = Color(0xFFF57C00);
  static const Color dangerLight = Color(0xFFC62828);
  static const Color infoLight = Color(0xFF0277BD);

  // ── Semantic — dark theme ──────────────────────────────────────

  static const Color successDark = Color(0xFF66BB6A);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color dangerDark = Color(0xFFEF5350);
  static const Color infoDark = Color(0xFF4FC3F7);
}
