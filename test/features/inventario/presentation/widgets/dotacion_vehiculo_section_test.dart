import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/features/inventario/domain/entities/dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/listar_dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/features/inventario/presentation/widgets/dotacion_vehiculo_section.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements InventarioRepository {}

DotacionVehiculo _dotacion() => DotacionVehiculo(
      id: 'a-1',
      materialId: 'm-1',
      materialNombre: 'Casco',
      cantidad: 2,
      fechaAsignacion: DateTime(2026, 5, 27),
    );

CurrentUser _user(List<String> roles) =>
    CurrentUser(sub: '1', email: 'a@b.com', roles: roles);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  // El ViewModel real construye la lista desde el use case listar; lo
  // sobreescribimos con un repo mock para no tocar la red. El gate RBAC
  // se ejercita a través del CurrentUser inyectado por pumpRiverpod.
  Future<void> pump(WidgetTester tester, CurrentUser user) {
    return pumpRiverpod(
      tester,
      const DotacionVehiculoSection(vehiculoId: 'v-1'),
      currentUser: user,
      overrides: [
        listarDotacionVehiculoProvider
            .overrideWithValue(ListarDotacionVehiculo(repo)),
      ],
    );
  }

  testWidgets('a manager (jefe_seccion) sees the add and remove actions',
      (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));

    await pump(tester, _user(['jefe_seccion']));

    expect(find.text('Casco'), findsOneWidget);
    expect(find.byKey(K.dotacionAnadir), findsOneWidget);
    expect(find.byTooltip('Quitar de la dotación'), findsOneWidget);
  });

  testWidgets('a viewer without the permission sees the list read-only',
      (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));

    await pump(tester, _user(['voluntario']));

    expect(find.text('Casco'), findsOneWidget);
    expect(find.byKey(K.dotacionAnadir), findsNothing);
    expect(find.byTooltip('Quitar de la dotación'), findsNothing);
  });

  testWidgets('a viewer sees nothing at all when the dotación is empty',
      (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => const Success(<DotacionVehiculo>[]));

    await pump(tester, _user(['voluntario']));

    expect(find.text('Material asignado al vehículo'), findsNothing);
    expect(find.byKey(K.dotacionAnadir), findsNothing);
  });
}
