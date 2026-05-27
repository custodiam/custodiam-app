// Full volunteer record returned by GET /voluntarios/me and
// GET /voluntarios/{id}. Mirrors the VoluntarioResponse Pydantic
// schema in custodiam-api. Nested relations (acreditaciones, tallas,
// contactos de emergencia) are not modelled yet; they will land
// alongside the catalogue/sizes/emergency-contact features.

import 'estado_voluntario.dart';

class Voluntario {
  final String id;
  final String? keycloakId;
  final String nombre;
  final String telefono;
  final String municipio;
  final DateTime fechaNacimiento;
  final EstadoVoluntario estado;
  final DateTime fechaAlta;
  final DateTime? fechaBaja;
  final String? dni;
  final String? email;
  final String? direccion;
  final String? fotoUrl;
  final bool conductorHabilitado;

  const Voluntario({
    required this.id,
    this.keycloakId,
    required this.nombre,
    required this.telefono,
    required this.municipio,
    required this.fechaNacimiento,
    required this.estado,
    required this.fechaAlta,
    this.fechaBaja,
    this.dni,
    this.email,
    this.direccion,
    this.fotoUrl,
    this.conductorHabilitado = false,
  });
}
