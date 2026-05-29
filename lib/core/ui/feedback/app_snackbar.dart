// Helper to surface SnackBars with consistent semantic variants
// (info/success/warning/danger). Reads colours from the
// AppSemanticColors ThemeExtension so dark/light render correctly.
// See guide 27 §5.13.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/extensions/app_semantic_colors.dart';
import '../tokens/app_spacing.dart';

enum AppSnackbarVariant { info, success, warning, danger }

class AppSnackbar {
  AppSnackbar._();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    AppSnackbarVariant variant = AppSnackbarVariant.info,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final semantic = context.semanticColors;
    final (Color bg, Color fg, IconData icon) = switch (variant) {
      AppSnackbarVariant.info => (
          semantic.info,
          semantic.onInfo,
          Symbols.info,
        ),
      AppSnackbarVariant.success => (
          semantic.success,
          semantic.onSuccess,
          Symbols.check_circle,
        ),
      AppSnackbarVariant.warning => (
          semantic.warning,
          semantic.onWarning,
          Symbols.warning_amber,
        ),
      AppSnackbarVariant.danger => (
          semantic.danger,
          semantic.onDanger,
          Symbols.error,
        ),
    };

    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        duration: duration,
        action: action,
        content: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: AppSpacing.smMd),
            Expanded(child: Text(message, style: TextStyle(color: fg))),
          ],
        ),
      ),
    );
  }
}
