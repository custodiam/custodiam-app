// ThemeExtension that exposes spacing tokens via `context.spacing.md`
// without forcing the consumer to import AppSpacing directly. See
// guide 27 §4.

import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';

@immutable
class AppSpacingExtension extends ThemeExtension<AppSpacingExtension> {
  final double xs;
  final double sm;
  final double smMd;
  final double md;
  final double mdLg;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  const AppSpacingExtension({
    required this.xs,
    required this.sm,
    required this.smMd,
    required this.md,
    required this.mdLg,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
  });

  static const AppSpacingExtension standard = AppSpacingExtension(
    xs: AppSpacing.xs,
    sm: AppSpacing.sm,
    smMd: AppSpacing.smMd,
    md: AppSpacing.md,
    mdLg: AppSpacing.mdLg,
    lg: AppSpacing.lg,
    xl: AppSpacing.xl,
    xxl: AppSpacing.xxl,
    xxxl: AppSpacing.xxxl,
  );

  @override
  AppSpacingExtension copyWith({
    double? xs,
    double? sm,
    double? smMd,
    double? md,
    double? mdLg,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
  }) {
    return AppSpacingExtension(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      smMd: smMd ?? this.smMd,
      md: md ?? this.md,
      mdLg: mdLg ?? this.mdLg,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      xxxl: xxxl ?? this.xxxl,
    );
  }

  @override
  AppSpacingExtension lerp(ThemeExtension<AppSpacingExtension>? other, double t) {
    // Spacing values are static; no interpolation needed between themes.
    return this;
  }
}

/// Shortcut: `context.spacing.md`
extension AppSpacingContext on BuildContext {
  AppSpacingExtension get spacing =>
      Theme.of(this).extension<AppSpacingExtension>()!;
}
