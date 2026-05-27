// Payload to POST /voluntarios. Mirrors the VoluntarioCreate Pydantic
// schema: 4 required base fields + 5 optionals. Rol/formación/talla
// are not part of the create payload (assigned via separate endpoints
// in later iterations).

class VoluntarioCreate {
  // Required
  final String nombre;
  final String telefono;
  final String municipio;
  final DateTime fechaNacimiento;

  // Optional
  final String? dni;
  final String? email;
  final String? direccion;
  final String? fotoUrl;
  final bool conductorHabilitado;

  const VoluntarioCreate({
    required this.nombre,
    required this.telefono,
    required this.municipio,
    required this.fechaNacimiento,
    this.dni,
    this.email,
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
      'conductor_habilitado': conductorHabilitado,
    };
    if (dni != null) out['dni'] = dni;
    if (email != null) out['email'] = email;
    if (direccion != null) out['direccion'] = direccion;
    if (fotoUrl != null) out['foto_url'] = fotoUrl;
    return out;
  }
}
