// Gateo RBAC de la pestaña "Ubicaciones" del listado de inventario (E10).
// InventarioListPage construye un TabBar de 2 o 3 pestañas según el rol:
// Material y Vehículos para todo el que tiene inventario.ver; Ubicaciones
// solo para quien además tiene ubicaciones.crear (jefe_seccion+, NO
// jefe_equipo). Este test fija ese contrato:
//  - jefe_seccion ve las 3 pestañas (incluida Ubicaciones),
//  - jefe_equipo ve solo Material y Vehículos (sin Ubicaciones),
//  - un rol sin inventario.ver ve la pantalla 'Sin acceso'.
//
// Las pestañas Material/Vehículos se alimentan de
// listMaterialesProvider/listVehiculosProvider -> InventarioRepository, y la
// de Ubicaciones de listarUbicacionesProvider -> UbicacionesRepository. Se
// overridean todos con mocks (mocktail) para no tocar la red. settle:false
// porque los AsyncNotifier arrancan en AsyncLoading.

import 'package:custodiam/features/inventario/domain/entities/materiales_page.dart';
import 'package:custodiam/features/inventario/domain/entities/ubicaciones_page.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculos_page.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/repositories/ubicaciones_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_materiales.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_vehiculos.dart';
import 'package:custodiam/features/inventario/domain/usecases/listar_ubicaciones.dart';
import 'package:custodiam/features/inventario/presentation/pages/inventario_list_page.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/ubicaciones_di.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockInventarioRepo extends Mock implements InventarioRepository {}

class _MockUbicacionesRepo extends Mock implements UbicacionesRepository {}

CurrentUser _user(List<String> roles) =>
    CurrentUser(sub: '1', email: 'a@b.com', roles: roles);

void main() {
  late _MockInventarioRepo inventarioRepo;
  late _MockUbicacionesRepo ubicacionesRepo;

  setUp(() {
    inventarioRepo = _MockInventarioRepo();
    ubicacionesRepo = _MockUbicacionesRepo();

    when(() => inventarioRepo.listMaterial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
          categoria: any(named: 'categoria'),
        )).thenAnswer(
      (_) async => const Success(MaterialesPage(items: [], total: 0)),
    );
    when(() => inventarioRepo.listVehiculos(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).thenAnswer(
      (_) async => const Success(VehiculosPage(items: [], total: 0)),
    );
    when(() => ubicacionesRepo.listar(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
        )).thenAnswer(
      (_) async => const Success(UbicacionesPage(items: [], total: 0)),
    );
  });

  Future<void> pump(WidgetTester tester, CurrentUser user) async {
    await pumpRiverpod(
      tester,
      const InventarioListPage(),
      wrapInScaffold: false,
      currentUser: user,
      overrides: [
        listMaterialesProvider
            .overrideWithValue(ListMateriales(inventarioRepo)),
        listVehiculosProvider
            .overrideWithValue(ListVehiculos(inventarioRepo)),
        listarUbicacionesProvider
            .overrideWithValue(ListarUbicaciones(ubicacionesRepo)),
      ],
      settle: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('jefe_seccion (con ubicaciones.crear) ve la pestaña Ubicaciones',
      (tester) async {
    await pump(tester, _user(['jefe_seccion']));

    expect(find.text('Material'), findsOneWidget);
    expect(find.text('Vehículos'), findsOneWidget);
    expect(find.text('Ubicaciones'), findsOneWidget);
  });

  testWidgets('jefe_equipo (sin ubicaciones.crear) NO ve la pestaña '
      'Ubicaciones pero sí Material y Vehículos', (tester) async {
    await pump(tester, _user(['jefe_equipo']));

    expect(find.text('Material'), findsOneWidget);
    expect(find.text('Vehículos'), findsOneWidget);
    expect(find.text('Ubicaciones'), findsNothing);
  });

  testWidgets('un rol sin inventario.ver ve la pantalla Sin acceso',
      (tester) async {
    await pump(tester, _user(['voluntario']));

    expect(find.text('Sin acceso'), findsOneWidget);
    expect(find.text('Ubicaciones'), findsNothing);
    // El gate corta antes del cuerpo: no se listan recursos.
    verifyNever(() => inventarioRepo.listMaterial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
          categoria: any(named: 'categoria'),
        ));
  });
}
