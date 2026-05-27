// Patch payload accepted by PATCH /voluntarios/me (CU-11 A). Mirrors
// the VoluntarioUpdateSelf schema: every field is optional and the
// backend rejects anything outside this set. Nulls mean "do not
// change"; empty strings are not used as sentinel — the form code
// turns blank inputs into nulls before instantiating the payload.

class MiPerfilUpdate {
  final String? telefono;
  final String? email;
  final String? municipio;
  final String? direccion;
  final String? fotoUrl;

  const MiPerfilUpdate({
    this.telefono,
    this.email,
    this.municipio,
    this.direccion,
    this.fotoUrl,
  });

  bool get isEmpty =>
      telefono == null &&
      email == null &&
      municipio == null &&
      direccion == null &&
      fotoUrl == null;

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    if (telefono != null) out['telefono'] = telefono;
    if (email != null) out['email'] = email;
    if (municipio != null) out['municipio'] = municipio;
    if (direccion != null) out['direccion'] = direccion;
    if (fotoUrl != null) out['foto_url'] = fotoUrl;
    return out;
  }
}
