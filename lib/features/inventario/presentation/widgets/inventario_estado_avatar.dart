// Avatar de un activo de inventario (material/vehículo) en los listados.
//
// Lleva el icono del TIPO en el centro y comunica el ESTADO así:
//   - operativo / en uso: avatar base, sin marca de estado. Son estados que
//     no requieren atención; teñir toda la lista de color añadiría ruido.
//   - averiado / perdido: avatar teñido con el color semántico del estado MÁS
//     una insignia con el icono del estado. El icono es el segundo canal no
//     cromático exigido por WCAG 1.4.1 (no comunicar solo por color).
//
// El estado se anuncia SIEMPRE por `Semantics`, porque el listado ya no
// muestra el badge de texto (el nombre completo del estado vive en la ficha,
// y los filtros superiores permiten segmentar por estado). Así el lector de
// pantalla no pierde el estado al haberse retirado el badge de la fila.

import 'package:flutter/material.dart';

import '../../../../core/ui/theme/extensions/app_semantic_colors.dart';
import '../../domain/entities/estado_inventario.dart';
import 'inventario_estado_badge.dart';

class InventarioEstadoAvatar extends StatelessWidget {
  /// Icono del tipo de activo (p.ej. inventory_2 para material,
  /// directions_car para vehículo). Permanece en el centro del avatar.
  final IconData tipoIcon;
  final EstadoInventario estado;

  const InventarioEstadoAvatar({
    super.key,
    required this.tipoIcon,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    final visual = inventarioEstadoVisual(estado);
    final resalta = estado == EstadoInventario.averiado ||
        estado == EstadoInventario.perdido;

    final Widget avatar;
    if (!resalta) {
      avatar = CircleAvatar(child: Icon(tipoIcon));
    } else {
      final semantic = context.semanticColors;
      final scheme = Theme.of(context).colorScheme;
      // Mismo color que la variante del badge: danger para averiado, neutral
      // (superficie) para perdido. Mantiene la coherencia con la ficha.
      final (Color bg, Color fg) = estado == EstadoInventario.averiado
          ? (semantic.danger, semantic.onDanger)
          : (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            backgroundColor: bg,
            child: Icon(tipoIcon, color: fg),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              // Halo con el color de superficie para despegar la insignia del
              // avatar y de las filas vecinas.
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 9,
                backgroundColor: bg,
                child: Icon(visual.icon, size: 11, color: fg),
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      label: 'Estado: ${visual.label}',
      child: ExcludeSemantics(child: avatar),
    );
  }
}
