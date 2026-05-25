import 'package:custodiam/core/ui/auth/app_permission_gate.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/auth/permissions.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../test_utils/test_app.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  group('AppPermissionGate', () {
    late _MockAuthService auth;

    setUp(() {
      auth = _MockAuthService();
    });

    Future<void> pump(WidgetTester tester, Widget child) =>
        pumpRiverpod(
          tester,
          child,
          overrides: [authServiceProvider.overrideWithValue(auth)],
        );

    testWidgets('renders child if user has the required permission',
        (tester) async {
      when(() => auth.currentUser).thenReturn(
        const CurrentUser(sub: '1', email: 'a@b.com', roles: ['voluntario']),
      );

      await pump(
        tester,
        const AppPermissionGate(
          permission: Permission.serviciosApuntarsePropio,
          child: Text('VISIBLE'),
        ),
      );

      expect(find.text('VISIBLE'), findsOneWidget);
    });

    testWidgets('renders fallback if user lacks the permission',
        (tester) async {
      when(() => auth.currentUser).thenReturn(
        const CurrentUser(sub: '1', email: 'a@b.com', roles: ['voluntario']),
      );

      await pump(
        tester,
        const AppPermissionGate(
          permission: Permission.voluntariosCrear,
          fallback: Text('HIDDEN'),
          child: Text('VISIBLE'),
        ),
      );

      expect(find.text('VISIBLE'), findsNothing);
      expect(find.text('HIDDEN'), findsOneWidget);
    });

    testWidgets('renders fallback when there is no authenticated user',
        (tester) async {
      when(() => auth.currentUser).thenReturn(null);

      await pump(
        tester,
        const AppPermissionGate(
          permission: Permission.voluntariosListar,
          child: Text('VISIBLE'),
        ),
      );

      expect(find.text('VISIBLE'), findsNothing);
    });

    testWidgets('anyOf renders child when at least one permission matches',
        (tester) async {
      when(() => auth.currentUser).thenReturn(
        const CurrentUser(sub: '1', email: 'a@b.com', roles: ['tesorero']),
      );

      await pump(
        tester,
        const AppPermissionGate.anyOf(
          anyOf: [
            Permission.voluntariosCrear, // no la tiene
            Permission.economicoGestionar, // sí
          ],
          child: Text('VISIBLE'),
        ),
      );

      expect(find.text('VISIBLE'), findsOneWidget);
    });

    testWidgets('anyOf renders fallback when none matches', (tester) async {
      when(() => auth.currentUser).thenReturn(
        const CurrentUser(sub: '1', email: 'a@b.com', roles: ['voluntario']),
      );

      await pump(
        tester,
        const AppPermissionGate.anyOf(
          anyOf: [
            Permission.voluntariosCrear,
            Permission.sistemaBackups,
          ],
          fallback: Text('HIDDEN'),
          child: Text('VISIBLE'),
        ),
      );

      expect(find.text('HIDDEN'), findsOneWidget);
    });

    testWidgets('admin puro NO ve botones operativos (decisión 1)',
        (tester) async {
      when(() => auth.currentUser).thenReturn(
        const CurrentUser(sub: '1', email: 'a@b.com', roles: ['admin']),
      );

      await pump(
        tester,
        const AppPermissionGate(
          permission: Permission.serviciosCrearEmergencia,
          child: Text('VISIBLE'),
        ),
      );

      expect(find.text('VISIBLE'), findsNothing);
    });

    testWidgets('admin + coordinador SÍ ve botones operativos', (tester) async {
      when(() => auth.currentUser).thenReturn(
        const CurrentUser(
          sub: '1',
          email: 'a@b.com',
          roles: ['admin', 'coordinador'],
        ),
      );

      await pump(
        tester,
        const AppPermissionGate(
          permission: Permission.serviciosCrearEmergencia,
          child: Text('VISIBLE'),
        ),
      );

      expect(find.text('VISIBLE'), findsOneWidget);
    });
  });
}
