// JSON ↔ domain mapper for the full Voluntario record returned by
// /voluntarios/me and /voluntarios/{id}. Mirrors the VoluntarioResponse
// Pydantic schema.

import '../../domain/entities/estado_voluntario.dart';
import '../../domain/entities/voluntario.dart';

class VoluntarioModel {
  const VoluntarioModel._();

  static Voluntario fromJson(Map<String, dynamic> json) {
    final estadoRaw = json['estado'] as String;
    final estado = EstadoVoluntario.fromWire(estadoRaw);
    if (estado == null) {
      throw FormatException('Unknown estado from API: $estadoRaw');
    }
    return Voluntario(
      id: json['id'] as String,
      keycloakId: json['keycloak_id'] as String?,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      municipio: json['municipio'] as String,
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento'] as String),
      estado: estado,
      fechaAlta: DateTime.parse(json['fecha_alta'] as String),
      fechaBaja: json['fecha_baja'] == null
          ? null
          : DateTime.parse(json['fecha_baja'] as String),
      dni: json['dni'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
      fotoUrl: json['foto_url'] as String?,
      conductorHabilitado: (json['conductor_habilitado'] as bool?) ?? false,
    );
  }
}
