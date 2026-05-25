// Decoder ligero del payload de un JWT.
//
// El backend valida la firma del token (PyJWKClient contra Keycloak,
// ver custodiam-api/app/core/security.py). En cliente solo necesitamos
// extraer claims para decidir qué pintar — no autenticamos a nadie con
// esta función.
//
// Devuelve null en lugar de lanzar para que un token con forma rara
// degrade a "sin usuario", no a un crash.

import 'dart:convert';

import 'current_user.dart';

/// Decode the payload (middle segment) of a JWS. Returns null if the
/// token is not a well-formed three-part base64url JWT.
Map<String, dynamic>? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final normalized = base64Url.normalize(parts[1]);
    final jsonStr = utf8.decode(base64Url.decode(normalized));
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  } catch (_) {
    return null;
  }
}

/// Build a CurrentUser from a Keycloak access token. Roles are expected
/// in the top-level "roles" claim, as configured by the custodiam-roles
/// client scope in EN-01-01 (see realm-custodiam.json).
CurrentUser? currentUserFromToken(String token) {
  final claims = decodeJwtPayload(token);
  if (claims == null) return null;

  final sub = claims['sub'];
  if (sub is! String || sub.isEmpty) return null;

  final rawRoles = claims['roles'];
  final roles = <String>[
    if (rawRoles is List)
      for (final r in rawRoles)
        if (r is String) r,
  ];

  return CurrentUser(
    sub: sub,
    email: claims['email'] as String? ?? '',
    preferredUsername: claims['preferred_username'] as String? ?? '',
    roles: roles,
    givenName: claims['given_name'] as String? ?? '',
    familyName: claims['family_name'] as String? ?? '',
  );
}
