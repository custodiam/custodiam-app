// Compact volunteer projection used by paginated lists (US-02-09).
// Mirrors the VoluntarioSummary Pydantic schema in custodiam-api
// (app/schemas/voluntario.py). The full record (acreditaciones,
// tallas, etc.) lives in the Voluntario entity returned by the ficha
// detallada endpoint (CU-13 / CU-11 B).

import 'estado_voluntario.dart';

class VoluntarioSummary {
  final String id;
  final String nombre;
  final String telefono;
  final String municipio;
  final EstadoVoluntario estado;
  final bool conductorHabilitado;

  const VoluntarioSummary({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.municipio,
    required this.estado,
    required this.conductorHabilitado,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoluntarioSummary &&
        other.id == id &&
        other.nombre == nombre &&
        other.telefono == telefono &&
        other.municipio == municipio &&
        other.estado == estado &&
        other.conductorHabilitado == conductorHabilitado;
  }

  @override
  int get hashCode => Object.hash(
        id,
        nombre,
        telefono,
        municipio,
        estado,
        conductorHabilitado,
      );
}
