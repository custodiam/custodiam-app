// JSON ↔ domain mapper for ServicioSummary.

import '../../domain/entities/estado_servicio.dart';
import '../../domain/entities/servicio_summary.dart';
import '../../domain/entities/tipo_servicio.dart';

class ServicioSummaryModel {
  const ServicioSummaryModel._();

  static ServicioSummary fromJson(Map<String, dynamic> json) {
    final tipoRaw = json['tipo'] as String;
    final tipo = TipoServicio.fromWire(tipoRaw);
    if (tipo == null) {
      throw FormatException('Unknown tipo from API: $tipoRaw');
    }
    final estadoRaw = json['estado'] as String;
    final estado = EstadoServicio.fromWire(estadoRaw);
    if (estado == null) {
      throw FormatException('Unknown estado from API: $estadoRaw');
    }
    return ServicioSummary(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      tipo: tipo,
      estado: estado,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'] as String)
          : null,
      ubicacion: json['ubicacion'] as String,
      numeroVoluntarios: json['numero_voluntarios'] as int?,
    );
  }
}
