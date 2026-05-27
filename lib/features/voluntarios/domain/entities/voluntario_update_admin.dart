// Patch payload accepted by PATCH /voluntarios/{id} (CU-11 B).
// Mirrors VoluntarioUpdateAdmin: every field is optional and the
// backend only updates what arrives. Nulls mean "do not change";
// the form code turns blank inputs into nulls before instantiating
// the payload.

import 'estado_voluntario.dart';

class VoluntarioUpdateAdmin {
  final String? nombre;
  final String? telefono;
  final String? municipio;
  final DateTime? fechaNacimiento;
  final String? dni;
  final String? email;
  final String? direccion;
  final String? fotoUrl;
  final bool? conductorHabilitado;
  final EstadoVoluntario? estado;

  const VoluntarioUpdateAdmin({
    this.nombre,
    this.telefono,
    this.municipio,
    this.fechaNacimiento,
    this.dni,
    this.email,
    this.direccion,
    this.fotoUrl,
    this.conductorHabilitado,
    this.estado,
  });

  bool get isEmpty =>
      nombre == null &&
      telefono == null &&
      municipio == null &&
      fechaNacimiento == null &&
      dni == null &&
      email == null &&
      direccion == null &&
      fotoUrl == null &&
      conductorHabilitado == null &&
      estado == null;

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    if (nombre != null) out['nombre'] = nombre;
    if (telefono != null) out['telefono'] = telefono;
    if (municipio != null) out['municipio'] = municipio;
    if (fechaNacimiento != null) {
      out['fecha_nacimiento'] =
          fechaNacimiento!.toIso8601String().split('T').first;
    }
    if (dni != null) out['dni'] = dni;
    if (email != null) out['email'] = email;
    if (direccion != null) out['direccion'] = direccion;
    if (fotoUrl != null) out['foto_url'] = fotoUrl;
    if (conductorHabilitado != null) {
      out['conductor_habilitado'] = conductorHabilitado;
    }
    if (estado != null) out['estado'] = estado!.wire;
    return out;
  }
}
