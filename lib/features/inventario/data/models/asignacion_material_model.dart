import '../../domain/entities/asignacion_material.dart';
import '../../domain/entities/tipo_asignacion.dart';

class AsignacionMaterialModel {
  const AsignacionMaterialModel._();

  static AsignacionMaterial fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipo'] as String;
    final tipo = TipoAsignacion.fromWire(tipoRaw);
    if (tipo == null) {
      throw FormatException('Unknown tipo de asignación: $tipoRaw');
    }
    return AsignacionMaterial(
      id: json['id'] as String,
      materialId: json['material_id'] as String,
      voluntarioId: json['voluntario_id'] as String?,
      servicioId: json['servicio_id'] as String?,
      tipo: tipo,
      cantidad: json['cantidad'] as int,
      fechaAsignacion: DateTime.parse(json['fecha_asignacion'] as String),
      fechaDevolucion: json['fecha_devolucion'] != null
          ? DateTime.parse(json['fecha_devolucion'] as String)
          : null,
      observacionesDevolucion: json['observaciones_devolucion'] as String?,
      activa: json['activa'] as bool,
    );
  }
}
