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

class InventarioEstadoBadge extends StatelessWidget {
  final EstadoInventario estado;

  const InventarioEstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (AppStatusVariant variant, IconData icon, String label) =
        switch (estado) {
      EstadoInventario.operativo => (
          AppStatusVariant.success,
          Symbols.check_circle,
          'Operativo',
        ),
      EstadoInventario.enUso => (
          AppStatusVariant.info,
          Symbols.handyman,
          'En uso',
        ),
      EstadoInventario.averiado => (
          AppStatusVariant.danger,
          Symbols.build,
          'Averiado',
        ),
      EstadoInventario.perdido => (
          AppStatusVariant.neutral,
          Symbols.report,
          'Perdido',
        ),
    };
    return AppStatusBadge(label: label, icon: icon, variant: variant);
  }
}
