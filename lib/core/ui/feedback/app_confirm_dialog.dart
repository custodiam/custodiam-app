// Confirmation dialog. The destructive variant swaps the confirm button
// for AppDestructiveButton so the colour matches the action's severity.
// Always pair with destructive actions before executing them. See guide 27
// §5.12.

import 'package:flutter/material.dart';

import '../buttons/app_destructive_button.dart';
import '../buttons/app_primary_button.dart';
import '../buttons/app_text_button.dart';

class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Cancelar',
    this.isDestructive = false,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        AppTextButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        if (isDestructive)
          AppDestructiveButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          )
        else
          AppPrimaryButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          ),
      ],
    );
  }
}
