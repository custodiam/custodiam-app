// Entidad inmutable que representa al usuario autenticado en cliente.
// Se construye a partir de los claims del access token JWT de Keycloak
// (ver jwt_claims.dart). El backend valida la firma del JWT; en cliente
// solo decodificamos la parte payload para extraer claims, sin
// pretender verificar nada.
//
// Provee helpers de RBAC equivalentes a CurrentUser de custodiam-api:
// hasRole / hasAnyRole / hasPermission. La lista de permisos se deriva
// del mapa kRolePermissions (lib/infrastructure/auth/permissions.dart).

import 'permissions.dart';

class CurrentUser {
  const CurrentUser({
    required this.sub,
    required this.email,
    this.preferredUsername = '',
    this.roles = const [],
    this.givenName = '',
    this.familyName = '',
  });

  final String sub;
  final String email;
  final String preferredUsername;
  final List<String> roles;
  final String givenName;
  final String familyName;

  String get fullName => '$givenName $familyName'.trim();

  bool hasRole(String role) => roles.contains(role);

  bool hasAnyRole(List<String> candidates) {
    for (final r in roles) {
      if (candidates.contains(r)) return true;
    }
    return false;
  }

  bool hasPermission(Permission permission) {
    for (final role in roles) {
      final perms = kRolePermissions[role];
      if (perms != null && perms.contains(permission)) return true;
    }
    return false;
  }

  bool hasAnyPermission(List<Permission> candidates) {
    for (final p in candidates) {
      if (hasPermission(p)) return true;
    }
    return false;
  }
}
