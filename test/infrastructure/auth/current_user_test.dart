import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/auth/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrentUser', () {
    test('fullName concatena given + family', () {
      const u = CurrentUser(
        sub: '1',
        email: 'a@b.com',
        givenName: 'María',
        familyName: 'García',
      );
      expect(u.fullName, 'María García');
    });

    test('fullName vacío si no hay nombres', () {
      const u = CurrentUser(sub: '1', email: 'a@b.com');
      expect(u.fullName, '');
    });

    test('hasRole y hasAnyRole', () {
      const u = CurrentUser(sub: '1', email: 'a@b.com', roles: ['voluntario']);
      expect(u.hasRole('voluntario'), isTrue);
      expect(u.hasRole('admin'), isFalse);
      expect(u.hasAnyRole(['admin', 'voluntario']), isTrue);
      expect(u.hasAnyRole(['admin', 'coordinador']), isFalse);
    });

    test('hasPermission deriva del mapa de roles', () {
      const u = CurrentUser(sub: '1', email: 'a@b.com', roles: ['voluntario']);
      expect(u.hasPermission(Permission.serviciosApuntarsePropio), isTrue);
      expect(u.hasPermission(Permission.voluntariosCrear), isFalse);
    });

    test('hasPermission para usuario con varios roles agrega', () {
      const u = CurrentUser(
        sub: '1',
        email: 'a@b.com',
        roles: ['admin', 'subjefe_agrupacion'],
      );
      expect(u.hasPermission(Permission.sistemaPanelAdmin), isTrue);
      expect(u.hasPermission(Permission.voluntariosCrear), isTrue);
    });

    test('hasAnyPermission devuelve true al primer match', () {
      const u = CurrentUser(sub: '1', email: 'a@b.com', roles: ['tesorero']);
      expect(
        u.hasAnyPermission([
          Permission.voluntariosCrear,
          Permission.economicoGestionar,
        ]),
        isTrue,
      );
      expect(
        u.hasAnyPermission([
          Permission.voluntariosCrear,
          Permission.sistemaBackups,
        ]),
        isFalse,
      );
    });

    test('lista de roles vacía no otorga permisos', () {
      const u = CurrentUser(sub: '1', email: 'a@b.com');
      expect(u.hasPermission(Permission.serviciosVerPublicados), isFalse);
    });
  });
}
