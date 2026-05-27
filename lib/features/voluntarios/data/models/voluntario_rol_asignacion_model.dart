// JSON ↔ domain mapper for VoluntarioRolAsignacion. Mirrors
// VoluntarioRolResponse in custodiam-api.

import '../../domain/entities/voluntario_rol_asignacion.dart';

class VoluntarioRolAsignacionModel {
  const VoluntarioRolAsignacionModel._();

  static VoluntarioRolAsignacion fromJson(Map<String, dynamic> json) {
    return VoluntarioRolAsignacion(
      id: json['id'] as String,
      voluntarioId: json['voluntario_id'] as String,
      rolId: json['rol_id'] as String,
      rolNombre: json['rol_nombre'] as String,
      fechaDesde: json['fecha_desde'] == null
          ? null
          : DateTime.parse(json['fecha_desde'] as String),
      fechaHasta: json['fecha_hasta'] == null
          ? null
          : DateTime.parse(json['fecha_hasta'] as String),
    );
  }
}
