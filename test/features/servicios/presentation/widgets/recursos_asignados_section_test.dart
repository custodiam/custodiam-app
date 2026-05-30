import 'package:custodiam/features/servicios/domain/entities/servicio_inventario.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_inventario_servicio.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/features/servicios/presentation/widgets/recursos_asignados_section.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

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
  }) async {
    when(() => repo.getInventario('s-1'))
        .thenAnswer((_) async => Success(_inv(vacio: vacio)));
    await pumpRiverpod(
      tester,
      const RecursosAsignadosSection(servicioId: 's-1'),
      currentUser: user,
      overrides: [
        getInventarioServicioProvider
            .overrideWithValue(GetInventarioServicio(repo)),
      ],
      settle: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a manager sees the add action and the assigned resources',
      (tester) async {
    await pump(tester, _user(['jefe_equipo'])); // tiene inventario.asignar_a_servicio

    expect(find.text('Recursos asignados'), findsOneWidget);
    expect(find.byKey(const ValueKey('recursos_anadir')), findsOneWidget);
    expect(find.text('Conos'), findsOneWidget);
    expect(find.textContaining('VEH-1 · 1234ABC'), findsOneWidget);
  });

  testWidgets('a viewer without the permission sees the list read-only',
      (tester) async {
    await pump(tester, _user(['voluntario'])); // NO tiene el permiso

    expect(find.text('Conos'), findsOneWidget);
    expect(find.byKey(const ValueKey('recursos_anadir')), findsNothing);
  });

  testWidgets('shows an empty hint when there are no assigned resources',
      (tester) async {
    await pump(tester, _user(['jefe_equipo']), vacio: true);

    expect(find.text('Sin recursos asignados.'), findsOneWidget);
  });

  testWidgets('tapping add opens the resource-type chooser', (tester) async {
    await pump(tester, _user(['jefe_equipo']));

    await tester.tap(find.byKey(const ValueKey('recursos_anadir')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recursos_tipo_material')), findsOneWidget);
    expect(find.byKey(const ValueKey('recursos_tipo_vehiculo')), findsOneWidget);
  });
}
