// Compact projection para listas paginadas (US-05-10).

import 'estado_inventario.dart';
import 'tipo_material.dart';

class MaterialSummary {
  final String id;
  final String nombre;
  final String? codigo;
  final TipoMaterial tipo;
  final String? categoria;
  final EstadoInventario estado;
  final int cantidad;
  final String? ubicacionBase;

  const MaterialSummary({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.estado,
    required this.cantidad,
    this.ubicacionBase,
    this.codigo,
    this.categoria,
  });
}
