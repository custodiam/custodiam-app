// Icon-only button with mandatory tooltip and a tap target that meets
// WCAG 2.5.5 (48x48 minimum). Wraps Flutter's IconButton to enforce
// the tooltip + minimum size in a single place, so feature pages do
// not need to remember either constraint.
//
// Guide 27 §5 prescribes App* prefixes for every interactive surface;
// guide 28 §1 requires a tooltip on every icon-only button (screen
// reader label + hover hint) and tappable area ≥ 48dp. This component
// is the canonical implementation.

import 'package:flutter/material.dart';

class AppIconButton extends StatelessWidget {
  /// Symbolic icon. Use Material outlined variants where possible to
  /// stay consistent with the rest of the design system.
  final IconData icon;

  /// Human-readable hint. Mandatory: it is both the screen reader
  /// label and the hover tooltip. Use a verb in infinitive ("Recargar",
  /// "Cerrar", "Editar").
  final String tooltip;

  /// `null` to render a disabled button (greyed, no tap).
  final VoidCallback? onPressed;

  /// Optional explicit color (falls back to theme.iconTheme).
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      // 48x48 mínimo según WCAG 2.5.5. Flutter por defecto usa 40, lo
      // forzamos al estándar del design system de Custodiam.
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }
}
