import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/entities/tipo_material.dart';
import 'asignacion_actual_model.dart';

class MaterialItemModel {
  const MaterialItemModel._();

  static MaterialItem fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipo'] as String;
    final tipo = TipoMaterial.fromWire(tipoRaw);
    if (tipo == null) {
      throw FormatException('Unknown tipo de material: $tipoRaw');
    }
    final estadoRaw = json['estado'] as String;
    final estado = EstadoInventario.fromWire(estadoRaw);
    if (estado == null) {
      throw FormatException('Unknown estado de inventario: $estadoRaw');
    }
    return MaterialItem(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      codigo: json['codigo'] as String?,
      numeroSerie: json['numero_serie'] as String?,
      tipo: tipo,
      categoria: json['categoria'] as String?,
      cantidad: json['cantidad'] as int,
      ubicacionBase: json['ubicacion_base'] as String,
      fechaAdquisicion: _date(json['fecha_adquisicion']),
      fechaProximaRevision: _date(json['fecha_proxima_revision']),
      fotoUrl: json['foto_url'] as String?,
      estado: estado,
      observacionesIncidencia: json['observaciones_incidencia'] as String?,
      createdAt: _dateTime(json['created_at']),
      updatedAt: _dateTime(json['updated_at']),
      asignacionesActivas: ((json['asignaciones_activas'] as List<dynamic>?) ??
              const [])
          .map((e) =>
              AsignacionActualModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      unidadesAsignadas: (json['unidades_asignadas'] as int?) ?? 0,
    );
  }

  static DateTime? _date(Object? raw) =>
      raw == null ? null : DateTime.parse(raw as String);

  static DateTime? _dateTime(Object? raw) =>
      raw == null ? null : DateTime.parse(raw as String);
}
