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
  // Etiqueta legacy opcional de ubicación (PR2): la referencia canónica es
  // el FK del backend; el texto puede no venir.
  final String? ubicacionBase;
  // FK a la ubicación del catálogo (E10). Es la referencia canónica desde la
  // que se resuelven las coordenadas para "ver en el mapa"; puede ser null si
  // el material no tiene ubicación asignada.
  final String? ubicacionBaseId;
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
    this.ubicacionBase,
    this.ubicacionBaseId,
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
