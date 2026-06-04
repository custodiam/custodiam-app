// Payload to POST /voluntarios. Mirrors the VoluntarioCreate Pydantic
// schema: nombre/telefono/municipio/fechaNacimiento/email are required
// (email is the onboarding key — the backend sends the Keycloak
// set-password invitation there), dni/direccion/fotoUrl are optional.
// Rol/formación/talla are not part of the create payload (assigned via
// separate endpoints in later iterations).

class VoluntarioCreate {
  // Required
  final String nombre;
  final String telefono;
  final String municipio;
  final DateTime fechaNacimiento;
  final String email;

  // Optional
  final String? dni;
  final String? direccion;
  final String? fotoUrl;
  final bool conductorHabilitado;

  const VoluntarioCreate({
    required this.nombre,
    required this.telefono,
    required this.municipio,
    required this.fechaNacimiento,
    required this.email,
    this.dni,
    this.direccion,
    this.fotoUrl,
    this.conductorHabilitado = false,
  });

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{
      'nombre': nombre,
      'telefono': telefono,
      'municipio': municipio,
      // Pydantic accepts ISO 8601 date for date fields.
      'fecha_nacimiento':
          fechaNacimiento.toIso8601String().split('T').first,
      'email': email,
      'conductor_habilitado': conductorHabilitado,
    };
    if (dni != null) out['dni'] = dni;
    if (direccion != null) out['direccion'] = direccion;
    if (fotoUrl != null) out['foto_url'] = fotoUrl;
    return out;
  }
}
