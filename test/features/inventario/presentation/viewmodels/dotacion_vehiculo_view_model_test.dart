import 'package:custodiam/features/inventario/domain/entities/dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/asignar_dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/usecases/liberar_dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/usecases/listar_dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/dotacion_vehiculo_view_model.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements InventarioRepository {}

DotacionVehiculo _dotacion({String id = 'a-1'}) => DotacionVehiculo(
      id: id,
      materialId: 'm-1',
      materialNombre: 'Casco',
      cantidad: 1,
      fechaAsignacion: DateTime(2026, 5, 27),
    );

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      listarDotacionVehiculoProvider
          .overrideWithValue(ListarDotacionVehiculo(repo)),
      asignarDotacionVehiculoProvider
          .overrideWithValue(AsignarDotacionVehiculo(repo)),
      liberarDotacionVehiculoProvider
          .overrideWithValue(LiberarDotacionVehiculo(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('DotacionVehiculoViewModel', () {
    test('build loads the dotación list', () async {
      final repo = _MockRepo();
      when(() => repo.listarDotacionVehiculo('v-1'))
          .thenAnswer((_) async => Success([_dotacion()]));
      final container = _container(repo);

      final list =
          await container.read(dotacionVehiculoViewModelProvider('v-1').future);

      expect(list, hasLength(1));
      expect(list.first.materialNombre, 'Casco');
    });

    test('asignar success returns true and reloads the list', () async {
      final repo = _MockRepo();
      when(() => repo.listarDotacionVehiculo('v-1'))
          .thenAnswer((_) async => const Success(<DotacionVehiculo>[]));
      when(() => repo.asignarDotacionVehiculo(
            'v-1',
            materialId: any(named: 'materialId'),
            cantidad: any(named: 'cantidad'),
          )).thenAnswer((_) async => Success(_dotacion()));
      final container = _container(repo);
      await container.read(dotacionVehiculoViewModelProvider('v-1').future);

      final ok = await container
          .read(dotacionVehiculoViewModelProvider('v-1').notifier)
          .asignar(materialId: 'm-1');

      expect(ok, isTrue);
      verify(() => repo.listarDotacionVehiculo('v-1')).called(2);
    });

    test('asignar failure returns false and surfaces an error', () async {
      final repo = _MockRepo();
      when(() => repo.listarDotacionVehiculo('v-1'))
          .thenAnswer((_) async => const Success(<DotacionVehiculo>[]));
      when(() => repo.asignarDotacionVehiculo(
            'v-1',
            materialId: any(named: 'materialId'),
            cantidad: any(named: 'cantidad'),
          )).thenAnswer(
        (_) async => const Fail(InventarioFailure.materialNoOperativo()),
      );
      final container = _container(repo);
      await container.read(dotacionVehiculoViewModelProvider('v-1').future);

      final ok = await container
          .read(dotacionVehiculoViewModelProvider('v-1').notifier)
          .asignar(materialId: 'm-1');

      expect(ok, isFalse);
      expect(
        container.read(dotacionVehiculoViewModelProvider('v-1')),
        isA<AsyncError<List<DotacionVehiculo>>>(),
      );
    });
  });
}
