import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_inventario.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/asignar_material_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_inventario_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/quitar_material_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/quitar_vehiculo_servicio.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/features/servicios/presentation/widgets/recursos_asignados_section.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/catalogo/catalogo_recurso.dart';
import 'package:custodiam/infrastructure/catalogo/inventario_catalogo_service.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

class _MockCatalogo extends Mock implements InventarioCatalogoService {}

ServicioInventario _inv({bool vacio = false}) {
  if (vacio) {
    return const ServicioInventario(
      material: <MaterialAsignadoServicio>[],
      vehiculos: <VehiculoAsignadoServicio>[],
    );
  }
  return ServicioInventario(
    material: [
      MaterialAsignadoServicio(
        id: 'a-1',
        materialId: 'm-1',
        materialNombre: 'Conos',
        cantidad: 4,
        fechaAsignacion: DateTime(2026, 5, 27),
      ),
    ],
    vehiculos: [
      VehiculoAsignadoServicio(
        id: 'a-2',
        vehiculoId: 'v-1',
        codigoInterno: 'VEH-1',
        matricula: '1234ABC',
        fechaAsignacion: DateTime(2026, 5, 27),
      ),
    ],
  );
}

CurrentUser _user(List<String> roles) =>
    CurrentUser(sub: '1', email: 'a@b.com', roles: roles);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Future<void> pump(
    WidgetTester tester,
    CurrentUser user, {
    bool vacio = false,
    List<Override> extraOverrides = const [],
  }) async {
    when(
      () => repo.getInventario('s-1'),
    ).thenAnswer((_) async => Success(_inv(vacio: vacio)));
    await pumpRiverpod(
      tester,
      const RecursosAsignadosSection(servicioId: 's-1'),
      currentUser: user,
      overrides: [
        getInventarioServicioProvider.overrideWithValue(
          GetInventarioServicio(repo),
        ),
        ...extraOverrides,
      ],
      settle: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a manager sees the add action and the assigned resources', (
    tester,
  ) async {
    await pump(
      tester,
      _user(['jefe_equipo']),
    ); // tiene inventario.asignar_a_servicio

    expect(find.text('Recursos asignados'), findsOneWidget);
    expect(find.byKey(K.servicioRecursosAnadirBtn), findsOneWidget);
    expect(find.text('Conos'), findsOneWidget);
    expect(find.textContaining('VEH-1 · 1234ABC'), findsOneWidget);
  });

  testWidgets('a viewer without the permission sees the list read-only', (
    tester,
  ) async {
    await pump(tester, _user(['voluntario'])); // NO tiene el permiso

    expect(find.text('Conos'), findsOneWidget);
    expect(find.byKey(K.servicioRecursosAnadirBtn), findsNothing);
  });

  testWidgets('shows an empty hint when there are no assigned resources', (
    tester,
  ) async {
    await pump(tester, _user(['jefe_equipo']), vacio: true);

    expect(find.text('Sin recursos asignados.'), findsOneWidget);
  });

  testWidgets('tapping add opens the resource-type chooser', (tester) async {
    await pump(tester, _user(['jefe_equipo']));

    await tester.tap(find.byKey(K.servicioRecursosAnadirBtn));
    await tester.pumpAndSettle();

    expect(find.byKey(K.servicioRecursosTipoMaterialBtn), findsOneWidget);
    expect(find.byKey(K.servicioRecursosTipoVehiculoBtn), findsOneWidget);
  });

  // -- Flujo completo "asignar material" (picker → cantidad) ----------------
  // Cubre _pedirCantidad: su diálogo de cantidad posee y libera el controller
  // en State.dispose(); confirmar/cancelar lo desmonta durante la animación de
  // cierre — el camino donde se manifestaba el use-after-dispose.

  Future<void> abrirDialogoCantidad(WidgetTester tester) async {
    await tester.tap(find.byKey(K.servicioRecursosAnadirBtn));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.servicioRecursosTipoMaterialBtn));
    await tester.pumpAndSettle();
    // El picker cargó el catálogo (buscarMaterial); elegir el material.
    await tester.tap(find.text('Conos disponibles'));
    await tester.pumpAndSettle();
  }

  testWidgets('asignar material: picker → cantidad → confirmar llama al repo', (
    tester,
  ) async {
    final catalogo = _MockCatalogo();
    when(
      () => catalogo.buscarMaterial(
        any(),
        any(),
        servicioId: any(named: 'servicioId'),
      ),
    ).thenAnswer(
      (_) async => [
        const CatalogoRecurso(id: 'm-1', label: 'Conos disponibles'),
      ],
    );
    when(
      () => repo.asignarMaterial('s-1', materialId: 'm-1', cantidad: 3),
    ).thenAnswer((_) async => const Success(null));

    await pump(
      tester,
      _user(['jefe_equipo']),
      extraOverrides: [
        inventarioCatalogoServiceProvider.overrideWithValue(catalogo),
        asignarMaterialServicioProvider.overrideWithValue(
          AsignarMaterialServicio(repo),
        ),
      ],
    );

    await abrirDialogoCantidad(tester);

    expect(find.byKey(K.servicioRecursosCantidadField), findsOneWidget);
    await tester.enterText(find.byKey(K.servicioRecursosCantidadField), '3');
    await tester.tap(find.byKey(K.servicioRecursosCantidadConfirmBtn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(
      () => repo.asignarMaterial('s-1', materialId: 'm-1', cantidad: 3),
    ).called(1);
    expect(find.text('Material asignado al servicio.'), findsOneWidget);
  });

  testWidgets('cancelar el diálogo de cantidad no asigna material', (
    tester,
  ) async {
    final catalogo = _MockCatalogo();
    when(
      () => catalogo.buscarMaterial(
        any(),
        any(),
        servicioId: any(named: 'servicioId'),
      ),
    ).thenAnswer(
      (_) async => [
        const CatalogoRecurso(id: 'm-1', label: 'Conos disponibles'),
      ],
    );

    await pump(
      tester,
      _user(['jefe_equipo']),
      extraOverrides: [
        inventarioCatalogoServiceProvider.overrideWithValue(catalogo),
        asignarMaterialServicioProvider.overrideWithValue(
          AsignarMaterialServicio(repo),
        ),
      ],
    );

    await abrirDialogoCantidad(tester);

    expect(find.byKey(K.servicioRecursosCantidadField), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byKey(K.servicioRecursosCantidadField), findsNothing);
    verifyNever(
      () => repo.asignarMaterial(
        any(),
        materialId: any(named: 'materialId'),
        cantidad: any(named: 'cantidad'),
      ),
    );
  });

  testWidgets('cantidad 0 (menor que 1) cae al clamp de 1 unidad', (
    tester,
  ) async {
    final catalogo = _MockCatalogo();
    when(
      () => catalogo.buscarMaterial(
        any(),
        any(),
        servicioId: any(named: 'servicioId'),
      ),
    ).thenAnswer(
      (_) async => [
        const CatalogoRecurso(id: 'm-1', label: 'Conos disponibles'),
      ],
    );
    when(
      () => repo.asignarMaterial('s-1', materialId: 'm-1', cantidad: 1),
    ).thenAnswer((_) async => const Success(null));

    await pump(
      tester,
      _user(['jefe_equipo']),
      extraOverrides: [
        inventarioCatalogoServiceProvider.overrideWithValue(catalogo),
        asignarMaterialServicioProvider.overrideWithValue(
          AsignarMaterialServicio(repo),
        ),
      ],
    );

    await abrirDialogoCantidad(tester);

    // '0' parsea pero es < 1 → `cantidad < 1 ? 1 : cantidad` lo lleva a 1.
    // Es la rama del clamp propia de servicios, ausente en material/dotación.
    await tester.enterText(find.byKey(K.servicioRecursosCantidadField), '0');
    await tester.tap(find.byKey(K.servicioRecursosCantidadConfirmBtn));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(
      () => repo.asignarMaterial('s-1', materialId: 'm-1', cantidad: 1),
    ).called(1);
  });

  // -- BUG C: una asignación rechazada (409) muestra el motivo por snackbar y
  // NO tumba la sección a "Reintentar recursos" (la lista sigue en pantalla).
  testWidgets(
    'asignación fallida muestra snackbar con el motivo y la sección NO se cae',
    (tester) async {
      final catalogo = _MockCatalogo();
      when(
        () => catalogo.buscarMaterial(
          any(),
          any(),
          servicioId: any(named: 'servicioId'),
        ),
      ).thenAnswer(
        (_) async => [
          const CatalogoRecurso(id: 'm-1', label: 'Conos disponibles'),
        ],
      );
      when(
        () => repo.asignarMaterial('s-1', materialId: 'm-1', cantidad: 1),
      ).thenAnswer(
        (_) async => const Fail(
          InventarioFailure.recursoSolapado('Solape con otro servicio'),
        ),
      );

      await pump(
        tester,
        _user(['jefe_equipo']),
        extraOverrides: [
          inventarioCatalogoServiceProvider.overrideWithValue(catalogo),
          asignarMaterialServicioProvider.overrideWithValue(
            AsignarMaterialServicio(repo),
          ),
        ],
      );

      await abrirDialogoCantidad(tester);
      await tester.enterText(find.byKey(K.servicioRecursosCantidadField), '1');
      await tester.tap(find.byKey(K.servicioRecursosCantidadConfirmBtn));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // El motivo real del backend se muestra por snackbar...
      expect(find.text('Solape con otro servicio'), findsOneWidget);
      // ...la sección sigue mostrando la lista (cabecera + recurso ya asignado),
      // no degrada a "Reintentar recursos".
      expect(find.text('Recursos asignados'), findsOneWidget);
      expect(find.text('Conos'), findsOneWidget);
      expect(find.text('Reintentar recursos'), findsNothing);
    },
  );

  // -- BUG D: el picker pide el catálogo filtrado por disponibilidad para ESTE
  // servicio (query disponible_para_servicio = servicioId).
  testWidgets('el catálogo se pide filtrado por disponible_para_servicio', (
    tester,
  ) async {
    final catalogo = _MockCatalogo();
    when(
      () => catalogo.buscarMaterial(
        any(),
        any(),
        servicioId: any(named: 'servicioId'),
      ),
    ).thenAnswer(
      (_) async => [
        const CatalogoRecurso(id: 'm-1', label: 'Conos disponibles'),
      ],
    );

    await pump(
      tester,
      _user(['jefe_equipo']),
      extraOverrides: [
        inventarioCatalogoServiceProvider.overrideWithValue(catalogo),
        asignarMaterialServicioProvider.overrideWithValue(
          AsignarMaterialServicio(repo),
        ),
      ],
    );

    // Abrir el picker de material dispara la carga del catálogo.
    await tester.tap(find.byKey(K.servicioRecursosAnadirBtn));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.servicioRecursosTipoMaterialBtn));
    await tester.pumpAndSettle();

    verify(
      () => catalogo.buscarMaterial(any(), any(), servicioId: 's-1'),
    ).called(greaterThanOrEqualTo(1));
  });

  // -- Quitar un recurso del servicio (inversa de asignar) ------------------
  testWidgets('el mando ve el botón de quitar en cada recurso', (tester) async {
    await pump(tester, _user(['jefe_equipo']));

    expect(find.byKey(K.servicioRecursoQuitarBtn('a-1')), findsOneWidget);
    expect(find.byKey(K.servicioRecursoQuitarBtn('a-2')), findsOneWidget);
  });

  testWidgets('el visor sin permiso NO ve el botón de quitar', (tester) async {
    await pump(tester, _user(['voluntario']));

    expect(find.byKey(K.servicioRecursoQuitarBtn('a-1')), findsNothing);
    expect(find.byKey(K.servicioRecursoQuitarBtn('a-2')), findsNothing);
  });

  testWidgets('quitar material: confirmar llama al repo y avisa por snackbar', (
    tester,
  ) async {
    when(
      () => repo.quitarMaterial('s-1', asignacionId: 'a-1'),
    ).thenAnswer((_) async => const Success(null));

    await pump(
      tester,
      _user(['jefe_equipo']),
      extraOverrides: [
        quitarMaterialServicioProvider.overrideWithValue(
          QuitarMaterialServicio(repo),
        ),
      ],
    );

    await tester.tap(find.byKey(K.servicioRecursoQuitarBtn('a-1')));
    await tester.pumpAndSettle();
    // Confirmación destructiva: el botón "Quitar" del AppConfirmDialog.
    await tester.tap(find.text('Quitar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => repo.quitarMaterial('s-1', asignacionId: 'a-1')).called(1);
    expect(find.text('Material quitado del servicio.'), findsOneWidget);
  });

  testWidgets('quitar vehículo: confirmar llama al repo', (tester) async {
    when(
      () => repo.quitarVehiculo('s-1', asignacionId: 'a-2'),
    ).thenAnswer((_) async => const Success(null));

    await pump(
      tester,
      _user(['jefe_equipo']),
      extraOverrides: [
        quitarVehiculoServicioProvider.overrideWithValue(
          QuitarVehiculoServicio(repo),
        ),
      ],
    );

    await tester.tap(find.byKey(K.servicioRecursoQuitarBtn('a-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => repo.quitarVehiculo('s-1', asignacionId: 'a-2')).called(1);
  });

  testWidgets('cancelar la confirmación NO quita el recurso', (tester) async {
    await pump(
      tester,
      _user(['jefe_equipo']),
      extraOverrides: [
        quitarMaterialServicioProvider.overrideWithValue(
          QuitarMaterialServicio(repo),
        ),
      ],
    );

    await tester.tap(find.byKey(K.servicioRecursoQuitarBtn('a-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(
      () =>
          repo.quitarMaterial(any(), asignacionId: any(named: 'asignacionId')),
    );
  });
}
