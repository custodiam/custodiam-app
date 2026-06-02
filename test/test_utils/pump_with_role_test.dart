// Smoke tests of the pumpWithRole helper. The real RBAC widget tests
// per page live in their feature folders and use this helper.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:custodiam/core/ui/auth/app_permission_gate.dart';
import 'package:custodiam/infrastructure/auth/permissions.dart';

import 'pump_with_role.dart';

void main() {
  group('pumpWithRole + AppPermissionGate', () {
    testWidgets('voluntario sees what voluntario can do', (tester) async {
      await pumpWithRole(
        tester,
        role: 'voluntario',
        child: const AppPermissionGate(
          permission: Permission.serviciosApuntarsePropio,
          child: Text('JOIN_BUTTON'),
        ),
      );
      expect(find.text('JOIN_BUTTON'), findsOneWidget);
    });

    testWidgets('voluntario does NOT see jefe-only surfaces', (tester) async {
      await pumpWithRole(
        tester,
        role: 'voluntario',
        child: const AppPermissionGate(
          permission: Permission.serviciosCrearEmergencia,
          child: Text('CREATE_EMERGENCY'),
        ),
      );
      expect(find.text('CREATE_EMERGENCY'), findsNothing);
    });

    testWidgets('jefe_equipo sees jefe-only surfaces', (tester) async {
      await pumpWithRole(
        tester,
        role: 'jefe_equipo',
        child: const AppPermissionGate(
          permission: Permission.serviciosCrearEmergencia,
          child: Text('CREATE_EMERGENCY'),
        ),
      );
      expect(find.text('CREATE_EMERGENCY'), findsOneWidget);
    });

    testWidgets('anyOf gate is permissive when ANY held', (tester) async {
      await pumpWithRole(
        tester,
        role: 'secretario',
        child: const AppPermissionGate.anyOf(
          anyOf: [
            Permission.serviciosCrearPreventivo,
            Permission.serviciosCrearEmergencia,
          ],
          child: Text('CREATE_SERVICE_ENTRY'),
        ),
      );
      // secretario has preventivo, lacks emergencia — anyOf should still match.
      expect(find.text('CREATE_SERVICE_ENTRY'), findsOneWidget);
    });

    testWidgets('admin (technical role) does not see operative surfaces',
        (tester) async {
      await pumpWithRole(
        tester,
        role: 'admin',
        child: const AppPermissionGate(
          permission: Permission.voluntariosListar,
          child: Text('VOLUNTARIOS_LIST'),
        ),
      );
      // admin is the technical role, no humano-operativo permissions.
      expect(find.text('VOLUNTARIOS_LIST'), findsNothing);
    });
  });
}
