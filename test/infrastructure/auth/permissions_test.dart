// Espejo, en el cliente Flutter, del test_permissions.py del backend.
// Cubre las mismas decisiones de la matriz canónica
// (docs/trabajo/backlog/RBAC_v0.1.0.md) — si las dos capas dejan de
// coincidir, los tests fallan en cualquiera de los dos lados antes de
// que el bug llegue a producción.

import 'package:custodiam/infrastructure/auth/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('matriz canónica (decisiones 1-12)', () {
    test('admin es técnico puro sin operativa', () {
      final perms = kRolePermissions['admin']!;
      expect(perms.contains(Permission.voluntariosCrear), isFalse);
      expect(perms.contains(Permission.serviciosCrearPreventivo), isFalse);
      expect(perms.contains(Permission.serviciosConvocar), isFalse);
      expect(perms.contains(Permission.fichajeFicharPropio), isFalse);
      expect(perms.contains(Permission.inventarioRegistrarMaterial), isFalse);
      expect(perms.contains(Permission.sistemaPanelAdmin), isTrue);
      expect(perms.contains(Permission.sistemaBackups), isTrue);
    });

    test('admin + coordinador da operativa completa', () {
      final perms = permissionsForRoles(['admin', 'coordinador']);
      expect(perms.contains(Permission.sistemaPanelAdmin), isTrue);
      expect(perms.contains(Permission.serviciosCrearEmergencia), isTrue);
      expect(perms.contains(Permission.voluntariosCrear), isTrue);
    });

    test('coordinador equivale a jefe_agrupacion en operativa', () {
      expect(
        kRolePermissions['coordinador'],
        equals(kRolePermissions['jefe_agrupacion']),
      );
    });

    test('jefe_equipo puede crear servicios', () {
      final perms = kRolePermissions['jefe_equipo']!;
      expect(perms.contains(Permission.serviciosCrearPreventivo), isTrue);
      expect(perms.contains(Permission.serviciosCrearEmergencia), isTrue);
      expect(perms.contains(Permission.serviciosCerrar), isTrue);
    });

    test('jefe_equipo NO puede dar de alta voluntarios (decisión 4)', () {
      final perms = kRolePermissions['jefe_equipo']!;
      expect(perms.contains(Permission.voluntariosCrear), isFalse);
      expect(perms.contains(Permission.voluntariosEditar), isFalse);
      expect(perms.contains(Permission.voluntariosDarBaja), isFalse);
    });

    test('subjefe_agrupacion sí puede dar de alta voluntarios', () {
      final perms = kRolePermissions['subjefe_agrupacion']!;
      expect(perms.contains(Permission.voluntariosCrear), isTrue);
      expect(perms.contains(Permission.voluntariosDarBaja), isTrue);
    });

    test('voluntario_practicas puede apuntarse a servicios (decisión 5)', () {
      final perms = kRolePermissions['voluntario_practicas']!;
      expect(perms.contains(Permission.serviciosApuntarsePropio), isTrue);
    });

    test('voluntario_practicas recibe notificaciones de emergencia (decisión 6)', () {
      final perms = kRolePermissions['voluntario_practicas']!;
      expect(perms.contains(Permission.notificacionesRecibirEmergencia), isTrue);
    });

    test('admin puro no recibe notificaciones operativas', () {
      final perms = kRolePermissions['admin']!;
      expect(perms.contains(Permission.notificacionesRecibirEmergencia), isFalse);
      expect(perms.contains(Permission.notificacionesRecibirNuevoServicio), isFalse);
    });

    test('secretario escribe inventario pero no asigna (decisión 8)', () {
      final perms = kRolePermissions['secretario']!;
      expect(perms.contains(Permission.inventarioRegistrarMaterial), isTrue);
      expect(perms.contains(Permission.inventarioRegistrarVehiculo), isTrue);
      expect(perms.contains(Permission.inventarioAsignarAServicio), isFalse);
      expect(
        perms.contains(Permission.inventarioAsignarEquipamientoPersonal),
        isFalse,
      );
    });

    test('tesorero solo lectura en inventario + permiso económico paraguas', () {
      final perms = kRolePermissions['tesorero']!;
      expect(perms.contains(Permission.inventarioVer), isTrue);
      expect(perms.contains(Permission.inventarioRegistrarMaterial), isFalse);
      expect(perms.contains(Permission.economicoGestionar), isTrue);
    });

    test('registrar vehículo requiere jefe_unidad o superior (decisión 9)', () {
      expect(
        kRolePermissions['jefe_seccion']!.contains(
          Permission.inventarioRegistrarVehiculo,
        ),
        isFalse,
      );
      expect(
        kRolePermissions['jefe_unidad']!.contains(
          Permission.inventarioRegistrarVehiculo,
        ),
        isTrue,
      );
    });

    test('asignar equipamiento personal requiere jefe_seccion o superior (decisión 10)', () {
      expect(
        kRolePermissions['jefe_equipo']!.contains(
          Permission.inventarioAsignarEquipamientoPersonal,
        ),
        isFalse,
      );
      expect(
        kRolePermissions['jefe_seccion']!.contains(
          Permission.inventarioAsignarEquipamientoPersonal,
        ),
        isTrue,
      );
    });

    test('crear ubicación requiere jefe_seccion o superior (PR2)', () {
      // Lockstep con el backend: `ubicaciones.crear` vive en
      // `_baseJefeSeccion` y lo heredan jefe_unidad / subjefe /
      // jefe_agrupacion / coordinador. No lo tienen los jefes de
      // equipo/grupo ni los roles administrativos (admin/secretario/tesorero).
      for (final rol in [
        'voluntario',
        'voluntario_practicas',
        'jefe_equipo',
        'jefe_grupo',
        'secretario',
        'tesorero',
        'admin',
      ]) {
        expect(
          kRolePermissions[rol]!.contains(Permission.ubicacionesCrear),
          isFalse,
          reason: '$rol no debería poder crear ubicaciones',
        );
      }
      for (final rol in [
        'jefe_seccion',
        'jefe_unidad',
        'subjefe_agrupacion',
        'jefe_agrupacion',
        'coordinador',
      ]) {
        expect(
          kRolePermissions[rol]!.contains(Permission.ubicacionesCrear),
          isTrue,
          reason: '$rol debería poder crear ubicaciones',
        );
      }
    });

    test('reportar incidencia lo puede hacer cualquier rol humano (decisión 11)', () {
      for (final entry in kRolePermissions.entries) {
        if (entry.key == 'admin') continue;
        expect(
          entry.value.contains(Permission.inventarioReportarIncidencia),
          isTrue,
          reason: '${entry.key} debería poder reportar incidencias',
        );
      }
    });
  });

  group('permissionsForRoles', () {
    test('une los permisos de varios roles', () {
      final perms = permissionsForRoles(['voluntario', 'tesorero']);
      expect(perms.contains(Permission.serviciosApuntarsePropio), isTrue);
      expect(perms.contains(Permission.economicoGestionar), isTrue);
    });

    test('lista vacía no da permisos', () {
      expect(permissionsForRoles([]), isEmpty);
    });

    test('rol desconocido se ignora silenciosamente', () {
      final perms = permissionsForRoles(['rol_inexistente', 'voluntario']);
      expect(perms.contains(Permission.serviciosApuntarsePropio), isTrue);
    });
  });

  group('Permission enum value', () {
    test('el .value coincide con el del backend (StrEnum)', () {
      expect(Permission.voluntariosCrear.value, 'voluntarios.crear');
      expect(
        Permission.inventarioAsignarEquipamientoPersonal.value,
        'inventario.asignar_equipamiento_personal',
      );
      expect(Permission.ubicacionesCrear.value, 'ubicaciones.crear');
    });

    test('fromString redondea valores conocidos y null en desconocidos', () {
      expect(
        Permission.fromString('voluntarios.crear'),
        Permission.voluntariosCrear,
      );
      expect(Permission.fromString('no.existe'), isNull);
    });
  });

  group('cobertura', () {
    test('los 12 roles del realm están mapeados', () {
      const rolesRealm = {
        'voluntario_practicas',
        'voluntario',
        'jefe_equipo',
        'jefe_grupo',
        'jefe_seccion',
        'jefe_unidad',
        'subjefe_agrupacion',
        'jefe_agrupacion',
        'secretario',
        'tesorero',
        'coordinador',
        'admin',
      };
      expect(kRolePermissions.keys.toSet(), equals(rolesRealm));
    });
  });
}
