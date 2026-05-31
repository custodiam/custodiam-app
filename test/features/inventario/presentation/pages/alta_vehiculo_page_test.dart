// Page test del formulario de alta de vehículo (US-05-02).
//
// Espejo del page test de alta_material. Cubre:
//   - gate RBAC (forbidden) cuando el rol no tiene inventario.registrar_vehiculo,
//   - validación (código / matrícula / ubicación) sin tocar el backend,
//   - botón submit deshabilitado mientras AsyncLoading (anti doble-submit),
//   - error de backend (snackbar danger + no navega + no refresca listado),
//   - camino feliz (snackbar success + refresh del listado + navegación a la
//     ficha) disparando el viewModel directo,
//   - regresión setState-during-build: cambiar el chip de tipo reconstruye el
//     Form que contiene UbicacionSelectorField sin lanzar excepción.
//
// Mocks: mocktail. Se mockea el REPOSITORY de dominio (InventarioRepository),
// no el ApiClient. Los use cases reales (CreateVehiculo, ListVehiculos) se
// inyectan vía overrideWithValue envolviendo el mismo mock repo. El viewModel
// lee su use case por getter (ref.read), así que el override surte efecto.

import 'dart:async';

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/buttons/app_primary_button.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculo_create.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculo_item.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculos_page.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/create_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_vehiculos.dart';
import 'package:custodiam/features/inventario/presentation/pages/alta_vehiculo_page.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/alta_vehiculo_view_model.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

// --- Dobles -----------------------------------------------------------------
class _MockRepo extends Mock implements InventarioRepository {}

class _MockAuth extends Mock implements AuthService {}

class _FakeVehiculoCreate extends Fake implements VehiculoCreate {}

// --- Builders de datos ------------------------------------------------------
VehiculoItem _vehiculo({String id = 'veh-1', String codigo = 'V-01'}) =>
    VehiculoItem(
      id: id,
      codigoInterno: codigo,
      matricula: '1234ABC',
      tipo: TipoVehiculo.furgoneta,
      estado: EstadoInventario.operativo,
    );

VehiculoCreate _validCreate() => const VehiculoCreate(
      codigoInterno: 'V-01',
      matricula: '1234ABC',
      tipo: TipoVehiculo.furgoneta,
      ubicacionBase: 'Base Zuera',
      ubicacionBaseId: 'u-1',
    );

_MockAuth _authWith(List<String> roles) {
  final auth = _MockAuth();
  when(() => auth.currentUser).thenReturn(
    CurrentUser(sub: 's', email: 'e@e', roles: roles),
  );
  when(() => auth.authStateListenable).thenReturn(ValueNotifier(true));
  return auth;
}

// --- pumpPage: GoRouter REAL (la page navega con context.go tras éxito) ------
// `jefe_unidad` es el rol más limpio que SÍ tiene
// Permission.inventarioRegistrarVehiculo (ver kRolePermissions en
// permissions.dart). `voluntario` no lo tiene.
Future<void> pumpPage(
  WidgetTester tester,
  InventarioRepository repo, {
  List<String> roles = const ['jefe_unidad'],
}) async {
  final router = GoRouter(
    initialLocation: '/inventario/vehiculos/alta',
    routes: [
      GoRoute(
        path: '/inventario',
        builder: (_, _) => const Scaffold(body: Text('inventario-stub')),
      ),
      GoRoute(
        path: '/inventario/vehiculos/alta',
        builder: (_, _) => const AltaVehiculoPage(),
      ),
      GoRoute(
        path: '/inventario/vehiculos/:id',
        builder: (_, _) =>
            const Scaffold(body: Text('vehiculo-ficha-stub')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        createVehiculoProvider.overrideWithValue(CreateVehiculo(repo)),
        // CRÍTICO: el ref.listen success llama vehiculosListViewModelProvider
        // .refresh(), que resuelve listVehiculos sobre el repo. Se inyecta el
        // use case real con el mismo mock y se stubea listVehiculos en setUp,
        // o el refresh lanza unstubbed-mock. Es la prueba del acoplamiento
        // alta -> listado.
        listVehiculosProvider.overrideWithValue(ListVehiculos(repo)),
        authServiceProvider.overrideWithValue(_authWith(roles)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(); // NO settle: AppPermissionGate + Form montan síncrono.
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeVehiculoCreate());
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    // Stub por defecto del refresh del listado: en el camino feliz el
    // ref.listen success dispara vehiculosListViewModelProvider.refresh().
    when(() => repo.listVehiculos(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).thenAnswer(
      (_) async => const Success(VehiculosPage(items: [], total: 0)),
    );
  });

  testWidgets('forbidden: rol sin inventario.registrar_vehiculo ve "Sin acceso"',
      (tester) async {
    await pumpPage(tester, repo, roles: const ['voluntario']);
    await tester.pumpAndSettle();

    expect(find.text('Sin acceso'), findsOneWidget);
    expect(find.byKey(K.altaVehiculoSubmit), findsNothing);
    verifyNever(() => repo.createVehiculo(any()));
  });

  testWidgets('validación: form vacío bloquea submit y muestra los 3 errores',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(K.altaVehiculoSubmit));
    await tester.pump();

    expect(find.text('Código obligatorio'), findsOneWidget);
    expect(find.text('Matrícula obligatorio'), findsOneWidget);
    expect(find.text('Ubicación obligatoria'), findsOneWidget);
    verifyNever(() => repo.createVehiculo(any()));
  });

  testWidgets(
      'validación: con código y matrícula pero sin ubicación sigue bloqueado',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(K.altaVehiculoCodigo), 'V-01');
    await tester.enterText(find.byKey(K.altaVehiculoMatricula), '1234ABC');
    await tester.tap(find.byKey(K.altaVehiculoSubmit));
    await tester.pump();

    expect(find.text('Código obligatorio'), findsNothing);
    expect(find.text('Matrícula obligatorio'), findsNothing);
    // La ubicación es obligatoria y no se ha seleccionado.
    expect(find.text('Ubicación obligatoria'), findsOneWidget);
    verifyNever(() => repo.createVehiculo(any()));
  });

  testWidgets('submit deshabilitado mientras AsyncLoading (anti doble submit)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Completer que no resuelve -> el estado se queda en AsyncLoading.
    final pending = Completer<Result<VehiculoItem>>();
    when(() => repo.createVehiculo(any())).thenAnswer((_) => pending.future);

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AltaVehiculoPage)),
    );
    // Disparar directo: el form con ubicación/fecha no es trivial de rellenar
    // por UI (date picker + picker de catálogo). Esto ejercita el wiring de
    // estado (AsyncLoading -> botón deshabilitado) igual que un tap real.
    unawaited(
      container
          .read(altaVehiculoViewModelProvider.notifier)
          .submit(_validCreate()),
    );
    await tester.pump(); // AsyncLoading aplicado.

    final btn = tester.widget<AppPrimaryButton>(
      find.byKey(K.altaVehiculoSubmit),
    );
    expect(btn.onPressed, isNull, reason: 'botón deshabilitado en loading');

    // Liberar el create y dejar que el ref.listen success complete (refresh +
    // navegación) sin excepciones pendientes.
    pending.complete(Success(_vehiculo()));
    await tester.pumpAndSettle();

    verify(() => repo.createVehiculo(any())).called(1);
  });

  testWidgets('error backend: snackbar danger, NO navega y NO refresca listado',
      (tester) async {
    when(() => repo.createVehiculo(any())).thenAnswer(
      (_) async => const Fail(InventarioFailure.recursoSolapado()),
    );

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AltaVehiculoPage)),
    );
    await container
        .read(altaVehiculoViewModelProvider.notifier)
        .submit(_validCreate());
    await tester.pump(); // un frame inserta el SnackBar.

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('reservado'), findsOneWidget);
    // No navega a la ficha en error.
    expect(find.text('vehiculo-ficha-stub'), findsNothing);
    // El listado no se refresca en error.
    verifyNever(() => repo.listVehiculos(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        ));
  });

  testWidgets(
      'éxito: construye el DTO, refresca el listado y navega a la ficha',
      (tester) async {
    when(() => repo.createVehiculo(any()))
        .thenAnswer((_) async => Success(_vehiculo()));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AltaVehiculoPage)),
    );
    await container
        .read(altaVehiculoViewModelProvider.notifier)
        .submit(_validCreate());
    await tester.pumpAndSettle();

    // Navegación ocurrida (context.go a /inventario/vehiculos/<id>).
    expect(find.text('vehiculo-ficha-stub'), findsOneWidget);

    // El alta se envió con el DTO esperado.
    final captured = verify(() => repo.createVehiculo(captureAny()))
        .captured
        .single as VehiculoCreate;
    expect(captured.codigoInterno, 'V-01');
    expect(captured.matricula, '1234ABC');
    expect(captured.tipo, TipoVehiculo.furgoneta);
    expect(captured.ubicacionBaseId, 'u-1');

    // BUG-HUNT (acoplamiento alta -> listado): el ref.listen success disparó
    // vehiculosListViewModelProvider.refresh(). Leer .notifier construye el
    // listado (build() -> listVehiculos) y refresh() vuelve a llamarlo, así
    // que listVehiculos se ejercita al menos una vez. Si no se hubiese
    // stubeado, el refresh habría lanzado y ensuciado este test.
    verify(() => repo.listVehiculos(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        ));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'regresión setState-during-build: cambiar el chip de tipo no lanza',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    // Cambiar el chip de tipo fuerza setState() que reconstruye el Form, que
    // contiene UbicacionSelectorField (su didUpdateWidget asigna texto al
    // controller). Replica la condición del crash conocido sin necesitar el
    // picker de catálogo. El fix vive en ubicacion_selector_field.dart
    // (addPostFrameCallback); revertirlo reintroduce el crash aquí.
    await tester.tap(find.byKey(K.altaVehiculoTipoChip(
      TipoVehiculo.ambulancia.wire,
    )));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar navega a /inventario sin crear nada', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(K.altaVehiculoCancel));
    await tester.pumpAndSettle();

    expect(find.text('inventario-stub'), findsOneWidget);
    verifyNever(() => repo.createVehiculo(any()));
  });
}
