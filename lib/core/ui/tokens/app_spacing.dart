// Spacing scale (8pt grid relaxed). Use these constants for padding,
// margin and gaps instead of hardcoded numbers. See guide 27 §3.
//
// Also accessible via context.spacing.md through AppSpacingExtension.

class AppSpacing {
  AppSpacing._();

  /// 4dp — ultra-compact (icon-to-text in chips)
  static const double xs = 4.0;

  /// 8dp — compact (gap inside the same element)
  static const double sm = 8.0;

  /// 12dp — intermediate
  static const double smMd = 12.0;

  /// 16dp — base (standard page/card padding)
  static const double md = 16.0;

  /// 20dp — intermediate
  static const double mdLg = 20.0;

  /// 24dp — generous (separation between sections)
  static const double lg = 24.0;

  /// 32dp — extra (separation between large blocks)
  static const double xl = 32.0;

  /// 48dp — maximum (hero areas, tap targets)
  static const double xxl = 48.0;

  /// 64dp — desktop layouts and large headers only
  static const double xxxl = 64.0;
}
