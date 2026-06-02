// Responsive breakpoints aligned with guide 29 and 09_CALIDAD §Responsive.
// Use these instead of magic numbers in LayoutBuilder / MediaQuery checks.

class AppBreakpoints {
  AppBreakpoints._();

  /// Mobile: layouts < 600 dp. BottomNavigationBar, fullscreen dialogs.
  static const double mobile = 600.0;

  /// Tablet: 600–900 dp. (F3) Compact NavigationRail, centered modals.
  static const double tablet = 900.0;

  /// Desktop: ≥ 900 dp. (F3) Extended NavigationRail, multi-column layouts.
  /// Aligned with guía 29 §2 (was 1200 before; the doc-comment already
  /// said ≥ 900 but the numeric value diverged).
  static const double desktop = 900.0;

  /// Maximum textual content width (readability).
  static const double contentMaxWidth = 720.0;

  /// Maximum width for centered forms.
  static const double formMaxWidth = 480.0;

  /// Maximum width for centered lists in desktop.
  static const double listMaxWidth = 960.0;
}
