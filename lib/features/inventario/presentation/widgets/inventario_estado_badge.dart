// Badge de estado de un activo de inventario (material o vehículo).
//
// Mapea [EstadoInventario] al átomo [AppStatusBadge] del design system,
// centralizando en un único sitio la correspondencia estado →
// variante/icono/etiqueta que antes estaba triplicada (ficha de material,
// ficha de vehículo y listado). La variante semántica refuerza el estado:
// operativo=success, en uso=info, averiado=danger, perdido=neutral.

import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/ui/misc/app_status_badge.dart';
import '../../domain/entities/estado_inventario.dart';

/// Correspondencia única estado de inventario → presentación (variante
/// semántica de color, icono y etiqueta). La comparten el badge de las fichas
/// (texto + color + icono) y el avatar de los listados (color + icono +
/// Semantics), para que el mapeo viva en un solo sitio y no vuelva a
/// duplicarse. La variante semántica refuerza el estado: operativo=success,
/// en uso=info, averiado=danger, perdido=neutral.
({AppStatusVariant variant, IconData icon, String label})
    inventarioEstadoVisual(EstadoInventario estado) => switch (estado) {
          EstadoInventario.operativo => (
              variant: AppStatusVariant.success,
              icon: Symbols.check_circle,
              label: 'Operativo',
            ),
          EstadoInventario.enUso => (
              variant: AppStatusVariant.info,
              icon: Symbols.handyman,
              label: 'En uso',
            ),
          EstadoInventario.averiado => (
              variant: AppStatusVariant.danger,
              icon: Symbols.build,
              label: 'Averiado',
            ),
          EstadoInventario.perdido => (
              variant: AppStatusVariant.neutral,
              icon: Symbols.report,
              label: 'Perdido',
            ),
        };

class InventarioEstadoBadge extends StatelessWidget {
  final EstadoInventario estado;

  const InventarioEstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final visual = inventarioEstadoVisual(estado);
    return AppStatusBadge(
      label: visual.label,
      icon: visual.icon,
      variant: visual.variant,
    );
  }
}
