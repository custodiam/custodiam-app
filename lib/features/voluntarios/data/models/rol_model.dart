// JSON ↔ domain mapper for Rol (catálogo entry). Mirrors RolResponse
// in custodiam-api (app/schemas/voluntario.py). `permisos` is not in
// the API response by design (ADR-013 RBAC lockstep), so no mapping
// needed.

import '../../domain/entities/rol.dart';

class RolModel {
  const RolModel._();

  static Rol fromJson(Map<String, dynamic> json) {
    return Rol(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      nivel: json['nivel'] as int,
      descripcion: json['descripcion'] as String?,
    );
  }
}
