import 'dart:convert';

import 'package:custodiam/infrastructure/auth/jwt_claims.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build a fake JWT with the given payload. Header and signature are
/// dummy placeholders — the parser does not validate them.
String _fakeJwt(Map<String, dynamic> payload) {
  String b64(String src) =>
      base64Url.encode(utf8.encode(src)).replaceAll('=', '');
  final header = b64('{"alg":"RS256","typ":"JWT"}');
  final body = b64(jsonEncode(payload));
  return '$header.$body.signature-placeholder';
}

void main() {
  group('decodeJwtPayload', () {
    test('extrae el payload de un JWT bien formado', () {
      final token = _fakeJwt({'sub': 'abc', 'foo': 'bar'});
      final claims = decodeJwtPayload(token);
      expect(claims, isNotNull);
      expect(claims!['sub'], 'abc');
      expect(claims['foo'], 'bar');
    });

    test('devuelve null si el token no tiene 3 segmentos', () {
      expect(decodeJwtPayload('not-a-jwt'), isNull);
      expect(decodeJwtPayload('a.b'), isNull);
      expect(decodeJwtPayload(''), isNull);
    });

    test('devuelve null si el segmento payload no es base64 válido', () {
      expect(decodeJwtPayload('header.\$\$\$.sig'), isNull);
    });

    test('devuelve null si el payload no decodifica a un objeto JSON', () {
      // Payload válido base64 pero contenido = lista JSON, no objeto.
      final notObjectBody =
          base64Url.encode(utf8.encode('[1,2,3]')).replaceAll('=', '');
      expect(decodeJwtPayload('h.$notObjectBody.s'), isNull);
    });
  });

  group('currentUserFromToken', () {
    test('construye CurrentUser a partir de claims típicos de Keycloak', () {
      final token = _fakeJwt({
        'sub': '1234-uuid',
        'email': 'admin@custodiam.es',
        'preferred_username': 'admin',
        'roles': ['admin', 'coordinador'],
        'given_name': 'Admin',
        'family_name': 'Custodiam',
      });
      final user = currentUserFromToken(token);
      expect(user, isNotNull);
      expect(user!.sub, '1234-uuid');
      expect(user.email, 'admin@custodiam.es');
      expect(user.preferredUsername, 'admin');
      expect(user.roles, equals(['admin', 'coordinador']));
      expect(user.givenName, 'Admin');
      expect(user.familyName, 'Custodiam');
      expect(user.fullName, 'Admin Custodiam');
    });

    test('campos opcionales se quedan vacíos si no vienen', () {
      final token = _fakeJwt({'sub': 's', 'email': 'a@b.com'});
      final user = currentUserFromToken(token);
      expect(user!.givenName, '');
      expect(user.familyName, '');
      expect(user.preferredUsername, '');
      expect(user.roles, isEmpty);
    });

    test('roles que no son string se filtran silenciosamente', () {
      final token = _fakeJwt({
        'sub': 's',
        'email': 'a@b.com',
        'roles': ['voluntario', 42, null, 'admin'],
      });
      final user = currentUserFromToken(token);
      expect(user!.roles, equals(['voluntario', 'admin']));
    });

    test('devuelve null si falta el claim sub', () {
      final token = _fakeJwt({'email': 'sin-sub@b.com'});
      expect(currentUserFromToken(token), isNull);
    });

    test('devuelve null para token malformado', () {
      expect(currentUserFromToken('basura'), isNull);
    });
  });
}
