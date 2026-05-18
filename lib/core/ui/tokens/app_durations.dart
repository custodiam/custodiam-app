// Animation durations. See guide 27 §3.

class AppDurations {
  AppDurations._();

  /// 100ms — micro-interactions (toggle on/off)
  static const Duration fast = Duration(milliseconds: 100);

  /// 200ms — standard transitions (snackbar, ripple)
  static const Duration medium = Duration(milliseconds: 200);

  /// 300ms — noticeable transitions (page, dialog open)
  static const Duration slow = Duration(milliseconds: 300);

  /// 500ms — major state changes
  static const Duration extraSlow = Duration(milliseconds: 500);
}
