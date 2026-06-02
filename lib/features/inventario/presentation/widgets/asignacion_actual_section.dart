// Sección "Asignación actual" de una ficha de inventario (PR1). Pinta la
// trazabilidad de a quién / a qué está asignado ahora mismo el activo. Si
// no hay asignaciones activas no ocupa espacio (SizedBox.shrink).
//
// Sirve tanto al material (que puede tener varias asignaciones a la vez)
// como al vehículo (asignación singular, que la ficha pasa como una lista
// de cero o un elemento). No resuelve nombres de voluntario: el catálogo
// con buscador queda diferido (deuda registrada en el roadmap), así que
// solo se muestra el tipo, la cantidad, la fecha y —cuando el backend lo
// adjunta— el título del servicio.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/ui/tokens/app_spacing.dart';
import '../../domain/entities/asignacion_actual.dart';
import '../../domain/entities/tipo_asignacion.dart';

class AsignacionActualSection extends StatelessWidget {
  final List<AsignacionActual> asignaciones;

  const AsignacionActualSection({super.key, required this.asignaciones});

  @override
  Widget build(BuildContext context) {
    if (asignaciones.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          header: true,
          child: Text('Asignación actual', style: theme.textTheme.titleSmall),
        ),
        for (final asignacion in asignaciones)
          _AsignacionTile(asignacion: asignacion),
      ],
    );
  }
}

class _AsignacionTile extends StatelessWidget {
  final AsignacionActual asignacion;

  const _AsignacionTile({required this.asignacion});

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, String label) = switch (asignacion.tipo) {
      TipoAsignacion.personal => (Symbols.person, 'Equipamiento personal'),
      TipoAsignacion.prestamo => (Symbols.swap_horiz, 'Préstamo a voluntario'),
      TipoAsignacion.servicio => (
          Symbols.event,
          asignacion.servicioTitulo ?? 'Asignado a un servicio',
        ),
      TipoAsignacion.dotacionVehiculo => (
          Symbols.directions_car,
          'Dotación de vehículo',
        ),
    };
    final unidades = asignacion.cantidad == 1
        ? '1 unidad'
        : '${asignacion.cantidad} unidades';
    final detalle = '$unidades · desde ${_formatDate(asignacion.fechaAsignacion)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
