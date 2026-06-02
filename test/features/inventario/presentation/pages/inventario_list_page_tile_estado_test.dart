// Cableado fila → avatar en el listado de inventario. Verifica el contrato
// que introdujo mover el estado del trailing badge al leading avatar:
//   - la fila usa InventarioEstadoAvatar y YA NO un InventarioEstadoBadge,
//   - un material averiado muestra la insignia (icono build) + 'Estado:
//     Averiado' por Semantics,
//   - un material operativo no muestra insignia de estado.
// Cubre el ensamblaje ListTile+avatar que el test aislado del avatar no toca.

import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/domain/entities/material_summary.dart';
import 'package:custodiam/features/inventario/domain/entities/materiales_page.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_material.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculos_page.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_materiales.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_vehiculos.dart';
import 'package:custodiam/features/inventario/presentation/pages/inventario_list_page.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/features/inventario/presentation/widgets/inventario_estado_avatar.dart';
import 'package:custodiam/features/inventario/presentation/widgets/inventario_estado_badge.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockInventarioRepo extends Mock implements InventarioRepository {}

CurrentUser _user(List<String> roles) =>
    CurrentUser(sub: '1', email: 'a@b.com', roles: roles);

void main() {
  late _MockInventarioRepo repo;

  setUp(() {
    repo = _MockInventarioRepo();
    // La pestaña Vehículos comparte el TabBarView; la dejamos vacía.
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

  Future<void> pumpConMaterial(
    WidgetTester tester,
    EstadoInventario estado,
  ) async {
    when(() => repo.listMaterial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
          categoria: any(named: 'categoria'),
        )).thenAnswer(
      (_) async => Success(
        MaterialesPage(
          items: [
            MaterialSummary(
              id: 'm-1',
              nombre: 'Taladro',
              tipo: TipoMaterial.prestable,
              estado: estado,
              cantidad: 1,
            ),
          ],
          total: 1,
        ),
      ),
    );
    await pumpRiverpod(
      tester,
      const InventarioListPage(),
      wrapInScaffold: false,
      // jefe_equipo tiene inventario.ver (ve Material/Vehículos) pero no
      // ubicaciones.crear, así que el TabBar queda en 2 pestañas.
      currentUser: _user(['jefe_equipo']),
      overrides: [
        listMaterialesProvider.overrideWithValue(ListMateriales(repo)),
        listVehiculosProvider.overrideWithValue(ListVehiculos(repo)),
      ],
      settle: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'la fila de material comunica el estado en el avatar, no en un badge',
      (tester) async {
    await pumpConMaterial(tester, EstadoInventario.averiado);

    // El estado vive ahora en el leading avatar; el badge de texto se retiró.
    expect(find.byType(InventarioEstadoAvatar), findsOneWidget);
    expect(find.byType(InventarioEstadoBadge), findsNothing);
    // Averiado: insignia con icono de estado + anuncio por Semantics. El
    // ListTile fusiona el label del avatar con el de la fila, así que el
    // estado aparece como parte del label combinado (RegExp, no match exacto).
    expect(find.byIcon(Symbols.build), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Estado: Averiado')), findsOneWidget);
  });

  testWidgets('un material operativo no muestra insignia de estado',
      (tester) async {
    await pumpConMaterial(tester, EstadoInventario.operativo);

    expect(find.byType(InventarioEstadoAvatar), findsOneWidget);
    expect(find.byIcon(Symbols.build), findsNothing);
    expect(find.byIcon(Symbols.report), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Estado: Operativo')), findsOneWidget);
  });
}
