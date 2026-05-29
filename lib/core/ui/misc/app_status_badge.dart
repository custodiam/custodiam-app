// AppStatusBadge: átomo que comunica el estado de una entidad (material,
// vehículo, disponibilidad...) por TRES canales simultáneos —color de
// fondo semántico, icono y texto— para no transmitir información solo por
// color (WCAG 1.4.1, requisito de daltonismo). El color procede de
// `context.semanticColors`; el componente nunca hardcodea un Color.
// Promueve a componente reutilizable el `_EstadoBadge` que estaba
// duplicado en varias fichas de feature. Ver guía 27 §5.18.

import 'package:flutter/material.dart';

import '../theme/extensions/app_semantic_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

enum AppStatusVariant { neutral, info, success, warning, danger }

class AppStatusBadge extends StatelessWidget {
  /// Texto del estado. La a11y lo lee automáticamente del `Text`.
  final String label;

  /// Icono que refuerza el significado del estado (segundo canal además
  /// del color, exigido por WCAG 1.4.1).
  final IconData icon;

  /// Variante semántica. Mapea a `context.semanticColors`; el `neutral`
  /// cae en la superficie de Material para estados sin carga semántica.
  final AppStatusVariant variant;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    this.variant = AppStatusVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final (Color bg, Color fg) = switch (variant) {
      AppStatusVariant.neutral => (
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      AppStatusVariant.info => (semantic.info, semantic.onInfo),
      AppStatusVariant.success => (semantic.success, semantic.onSuccess),
      AppStatusVariant.warning => (semantic.warning, semantic.onWarning),
      AppStatusVariant.danger => (semantic.danger, semantic.onDanger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style:
                  Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
