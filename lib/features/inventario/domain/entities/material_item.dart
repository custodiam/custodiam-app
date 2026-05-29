// Ficha completa de un material (MaterialResponse del backend).

import 'asignacion_actual.dart';
import 'estado_inventario.dart';
import 'tipo_material.dart';

class MaterialItem {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? codigo;
  final String? numeroSerie;
  final TipoMaterial tipo;
  final String? categoria;
  final int cantidad;
  final String ubicacionBase;
  final DateTime? fechaAdquisicion;
  final DateTime? fechaProximaRevision;
  final String? fotoUrl;
  final EstadoInventario estado;
  final String? observacionesIncidencia;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Asignaciones activas del material (PR1). Un material puede tener
  /// varias a la vez (préstamo parcial, dotación de vehículo...). Solo
  /// llega en el detalle; en el listado siempre es la lista vacía.
  final List<AsignacionActual> asignacionesActivas;

  /// Suma de unidades comprometidas en las asignaciones activas (PR1).
  final int unidadesAsignadas;

  const MaterialItem({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.estado,
    required this.cantidad,
    required this.ubicacionBase,
    this.descripcion,
    this.codigo,
    this.numeroSerie,
    this.categoria,
    this.fechaAdquisicion,
    this.fechaProximaRevision,
    this.fotoUrl,
    this.observacionesIncidencia,
    this.createdAt,
    this.updatedAt,
    this.asignacionesActivas = const [],
    this.unidadesAsignadas = 0,
  });
}
