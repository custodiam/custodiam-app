// Catálogo de roles del realm. Mirrors RolResponse en custodiam-api
// (app/schemas/voluntario.py). `permisos` NO se expone aquí — la
// matriz canónica vive en lib/infrastructure/auth/permissions.dart
// (ADR-013 RBAC lockstep).

class Rol {
  final String id;
  final String nombre;
  final int nivel;
  final String? descripcion;

  const Rol({
    required this.id,
    required this.nombre,
    required this.nivel,
    this.descripcion,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rol && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
