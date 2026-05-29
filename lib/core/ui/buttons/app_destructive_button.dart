// Destructive button. Always pair with AppConfirmDialog before executing
// the action. See guide 27 §5.4.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
class AppDestructiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  const AppDestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = FilledButton.styleFrom(
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
    );

    final Widget button = FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon ?? Symbols.delete),
      label: Text(label),
    );

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
