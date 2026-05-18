// ThemeExtension exposing semantic colors that Material's ColorScheme
// does not model (success/warning/danger/info). Each slot carries its
// "on" variant so foreground contrast is explicit. See guide 27 §4.
//
// Usage:
//   final colors = context.semanticColors;
//   color: colors.success

import 'package:flutter/material.dart';

import '../app_colors.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color info;
  final Color onInfo;

  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.info,
    required this.onInfo,
  });

  static const AppSemanticColors light = AppSemanticColors(
    success: AppColors.successLight,
    onSuccess: Colors.white,
    warning: AppColors.warningLight,
    onWarning: Colors.black,
    danger: AppColors.dangerLight,
    onDanger: Colors.white,
    info: AppColors.infoLight,
    onInfo: Colors.white,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: AppColors.successDark,
    onSuccess: Colors.black,
    warning: AppColors.warningDark,
    onWarning: Colors.black,
    danger: AppColors.dangerDark,
    onDanger: Colors.black,
    info: AppColors.infoDark,
    onInfo: Colors.black,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
    Color? info,
    Color? onInfo,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
    );
  }
}

/// Shortcut: `context.semanticColors.success`
extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
