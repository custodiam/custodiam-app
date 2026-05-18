// Primary call-to-action button. At most one per screen. See guide 27 §5.1.
//
// FilledButton.icon is only used when there is a leading widget so a label
// without icon does not leave a parasitic gap.

import 'package:flutter/material.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expanded;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? leading = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon != null ? Icon(icon) : null);

    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    final Widget button = leading != null
        ? FilledButton.icon(
            onPressed: effectiveOnPressed,
            icon: leading,
            label: Text(label),
          )
        : FilledButton(
            onPressed: effectiveOnPressed,
            child: Text(label),
          );

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
