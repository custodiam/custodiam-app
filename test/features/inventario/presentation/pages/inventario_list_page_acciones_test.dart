// Acciones editar/borrar por fila en el listado de inventario (A6).
// El listado lo ve todo el que tiene `inventario.ver` (incluido el tesorero
// solo-lectura); el menú de acciones (Editar/Borrar) se ofrece solo a quien
// tiene `inventario.registrar_material` (material) o
// `inventario.registrar_vehiculo` (vehículo). Este test fija:
//  - tesorero (solo inventario.ver) NO ve el menú de acciones en material ni
//    en vehículo,
//  - jefe_equipo (registrar_material pero NO registrar_vehiculo) ve el menú en
//    material y NO en vehículo,
//  - jefe_unidad (ambos permisos) ve el menú en material y en vehículo,
//  - borrar: PopupMenu -> Eliminar -> confirmar llama a deleteMaterial y
//    muestra snackbar de éxito,
//  - cancelar el diálogo no llama al repo,
//  - editar navega a la ruta de edición.
//
// Material/Vehículos se alimentan de InventarioRepository (overrideado con
// mock). settle:false porque los AsyncNotifier arrancan en AsyncLoading.

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/domain/entities/material_summary.dart';
import 'package:custodiam/features/inventario/domain/entities/materiales_page.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_material.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculo_summary.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculos_page.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/eliminar_material.dart';
import 'package:custodiam/features/inventario/domain/usecases/eliminar_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_materiales.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_vehiculos.dart';
import 'package:custodiam/features/inventario/presentation/pages/inventario_list_page.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements InventarioRepository {}

CurrentUser _user(List<String> roles) =>
    CurrentUser(sub: '1', email: 'a@b.com', roles: roles);

MaterialSummary _m(String id) => MaterialSummary(
      id: id,
      nombre: 'Casco $id',
      tipo: TipoMaterial.personal,
      estado: EstadoInventario.operativo,
      cantidad: 1,
    );

VehiculoSummary _v(String id) => VehiculoSummary(
      id: id,
      codigoInterno: 'VH-$id',
      matricula: '1234ABC',
      tipo: TipoVehiculo.furgoneta,
      estado: EstadoInventario.operativo,
    );

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.listMaterial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
          categoria: any(named: 'categoria'),
        )).thenAnswer(
      (_) async => Success(MaterialesPage(items: [_m('a')], total: 1)),
    );
    when(() => repo.listVehiculos(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).thenAnswer(
      (_) async => Success(VehiculosPage(items: [_v('a')], total: 1)),
    );
  });

  List<Override> buildOverrides() => [
        listMaterialesProvider.overrideWithValue(ListMateriales(repo)),
        listVehiculosProvider.overrideWithValue(ListVehiculos(repo)),
        eliminarMaterialProvider.overrideWithValue(EliminarMaterial(repo)),
        eliminarVehiculoProvider.overrideWithValue(EliminarVehiculo(repo)),
      ];

  Future<void> pump(WidgetTester tester, CurrentUser user) async {
    await pumpRiverpod(
      tester,
      const InventarioListPage(),
      wrapInScaffold: false,
      currentUser: user,
      overrides: buildOverrides(),
      settle: false,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVehiculosTab(WidgetTester tester) async {
    await tester.tap(find.text('Vehículos'));
    await tester.pumpAndSettle();
  }

  testWidgets('tesorero (solo inventario.ver) NO ve el menú de acciones en '
      'material ni en vehículo', (tester) async {
    await pump(tester, _user(['tesorero']));

    expect(find.byKey(K.inventarioMaterialItem('a')), findsOneWidget);
    expect(find.byKey(K.inventarioMaterialAccionesBtn('a')), findsNothing);

    await tapVehiculosTab(tester);
    expect(find.byKey(K.inventarioVehiculoAccionesBtn('a')), findsNothing);
  });

  testWidgets('jefe_equipo (registrar_material, NO registrar_vehiculo) ve el '
      'menú en material pero NO en vehículo', (tester) async {
    await pump(tester, _user(['jefe_equipo']));

    expect(find.byKey(K.inventarioMaterialAccionesBtn('a')), findsOneWidget);

    await tapVehiculosTab(tester);
    expect(find.byKey(K.inventarioVehiculoAccionesBtn('a')), findsNothing);
  });

  testWidgets('jefe_unidad (ambos permisos) ve el menú en material y en '
      'vehículo', (tester) async {
    await pump(tester, _user(['jefe_unidad']));

    expect(find.byKey(K.inventarioMaterialAccionesBtn('a')), findsOneWidget);

    await tapVehiculosTab(tester);
    expect(find.byKey(K.inventarioVehiculoAccionesBtn('a')), findsOneWidget);
  });

  testWidgets('borrar material: PopupMenu -> Eliminar -> confirmar llama al '
      'repo y muestra snackbar de éxito', (tester) async {
    when(() => repo.deleteMaterial('a'))
        .thenAnswer((_) async => const Success<void>(null));

    await pump(tester, _user(['jefe_equipo']));

    await tester.tap(find.byKey(K.inventarioMaterialAccionesBtn('a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.inventarioMaterialBorrarItem));
    await tester.pumpAndSettle();

    // AppConfirmDialog destructivo.
    expect(find.text('Eliminar material'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    // Borrado -> refresh -> snackbar. Sin pumpAndSettle (el SnackBar tiene
    // auto-dismiss de 4 s y colgaría).
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => repo.deleteMaterial('a')).called(1);
    expect(find.text('Material eliminado.'), findsOneWidget);
  });

  testWidgets('cancelar el diálogo de borrado no llama al repo',
      (tester) async {
    await pump(tester, _user(['jefe_equipo']));

    await tester.tap(find.byKey(K.inventarioMaterialAccionesBtn('a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.inventarioMaterialBorrarItem));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar material'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar material'), findsNothing);
    verifyNever(() => repo.deleteMaterial(any()));
  });

  testWidgets('borrar vehículo con 409 enUso muestra el snackbar de error con '
      'el mensaje del backend', (tester) async {
    when(() => repo.deleteVehiculo('a')).thenAnswer(
      (_) async => const Fail(
        InventarioFailure.enUso('El vehículo tiene una asignación activa.'),
      ),
    );

    await pump(tester, _user(['jefe_unidad']));
    await tapVehiculosTab(tester);

    await tester.tap(find.byKey(K.inventarioVehiculoAccionesBtn('a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.inventarioVehiculoBorrarItem));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar vehículo'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => repo.deleteVehiculo('a')).called(1);
    expect(
      find.text('El vehículo tiene una asignación activa.'),
      findsOneWidget,
    );
  });

  testWidgets('editar material navega a la ruta de edición', (tester) async {
    String? navegadoA;
    final router = GoRouter(
      initialLocation: '/inventario',
      routes: [
        GoRoute(
          path: '/inventario',
          builder: (_, _) => const InventarioListPage(),
          routes: [
            GoRoute(
              path: 'material/:id/editar',
              builder: (_, state) {
                navegadoA = state.uri.toString();
                return const Scaffold(body: Text('EDITAR MATERIAL'));
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider
              .overrideWithValue(_FakeAuth(_user(['jefe_equipo']))),
          ...buildOverrides(),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(K.inventarioMaterialAccionesBtn('a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(K.inventarioMaterialEditarItem));
    await tester.pumpAndSettle();

    expect(navegadoA, '/inventario/material/a/editar');
    expect(find.text('EDITAR MATERIAL'), findsOneWidget);
  });
}

/// AuthService falso para el test de navegación (el de pumpRiverpod es
/// privado). Devuelve el usuario dado y se reporta autenticado.
class _FakeAuth implements AuthService {
  _FakeAuth(this._user) : _notifier = ValueNotifier(true);

  final CurrentUser _user;
  final ValueNotifier<bool> _notifier;

  @override
  Future<void> init() async {}

  @override
  bool get isAuthenticated => true;

  @override
  String? get accessToken => 'fake-token';

  @override
  CurrentUser? get currentUser => _user;

  @override
  Listenable get authStateListenable => _notifier;

  @override
  bool consumeExpiredFlag() => false;

  @override
  Future<Result<void>> login() async => const Success(null);

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<Result<String>> getValidAccessToken() async =>
      const Success('fake-token');
}
