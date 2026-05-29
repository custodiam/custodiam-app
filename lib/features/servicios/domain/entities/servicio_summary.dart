// Compact projection used in paginated lists (US-03-07). Mirrors the
// ServicioSummary Pydantic schema in custodiam-api
// (app/schemas/servicio.py).

import 'estado_servicio.dart';
import 'tipo_servicio.dart';

class ServicioSummary {
  final String id;
  final String titulo;
  final TipoServicio tipo;
  final EstadoServicio estado;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String ubicacion;
  final int? numeroVoluntarios;

  /// Voluntarios actualmente inscritos (inscritos_count del backend,
  /// no nullable, default 0). Permite reflejar el aforo en el listado.
  final int inscritosCount;

  const ServicioSummary({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.estado,
    required this.fechaInicio,
    required this.ubicacion,
    required this.inscritosCount,
    this.fechaFin,
    this.numeroVoluntarios,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServicioSummary &&
        other.id == id &&
        other.titulo == titulo &&
        other.tipo == tipo &&
        other.estado == estado &&
        other.fechaInicio == fechaInicio &&
        other.fechaFin == fechaFin &&
        other.ubicacion == ubicacion &&
        other.numeroVoluntarios == numeroVoluntarios &&
        other.inscritosCount == inscritosCount;
  }

  @override
  int get hashCode => Object.hash(
        id,
        titulo,
        tipo,
        estado,
        fechaInicio,
        fechaFin,
        ubicacion,
        numeroVoluntarios,
        inscritosCount,
      );
}
