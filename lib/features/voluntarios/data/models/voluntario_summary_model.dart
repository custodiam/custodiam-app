// JSON ↔ domain mapper for VoluntarioSummary. Kept as a thin static
// helper rather than a wrapper class because the wire schema is
// closed (defined by the FastAPI Pydantic model) and we never need
// an in-memory instance of the DTO; conversion happens at the data
// layer boundary only.

import '../../domain/entities/estado_voluntario.dart';
import '../../domain/entities/voluntario_summary.dart';

class VoluntarioSummaryModel {
  const VoluntarioSummaryModel._();

  static VoluntarioSummary fromJson(Map<String, dynamic> json) {
    final estadoRaw = json['estado'] as String;
    final estado = EstadoVoluntario.fromWire(estadoRaw);
    if (estado == null) {
      throw FormatException('Unknown estado from API: $estadoRaw');
    }
    return VoluntarioSummary(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      municipio: json['municipio'] as String,
      estado: estado,
      conductorHabilitado: json['conductor_habilitado'] as bool,
    );
  }
}
