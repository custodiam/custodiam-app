import 'package:custodiam/features/servicios/domain/entities/servicio_inventario.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/asignar_material_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/asignar_vehiculo_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_inventario_servicio.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicio_inventario_view_model.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

const _empty = ServicioInventario(
  material: <MaterialAsignadoServicio>[],
  vehiculos: <VehiculoAsignadoServicio>[],
);

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      getInventarioServicioProvider
          .overrideWithValue(GetInventarioServicio(repo)),
      asignarMaterialServicioProvider
          .overrideWithValue(AsignarMaterialServicio(repo)),
      asignarVehiculoServicioProvider
          .overrideWithValue(AsignarVehiculoServicio(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ServicioInventarioViewModel', () {
    test('build loads the servicio inventory', () async {
      final repo = _MockRepo();
      when(() => repo.getInventario('s-1'))
          .thenAnswer((_) async => const Success(_empty));
      final container = _container(repo);

      final inv = await container
          .read(servicioInventarioViewModelProvider('s-1').future);

      expect(inv.isEmpty, isTrue);
    });

    test('asignarMaterial success returns true and reloads', () async {
      final repo = _MockRepo();
      when(() => repo.getInventario('s-1'))
          .thenAnswer((_) async => const Success(_empty));
      when(
        () => repo.asignarMaterial(
          's-1',
          materialId: any(named: 'materialId'),
          cantidad: any(named: 'cantidad'),
        ),
      ).thenAnswer((_) async => const Success<void>(null));
      final container = _container(repo);
      await container.read(servicioInventarioViewModelProvider('s-1').future);

      final ok = await container
          .read(servicioInventarioViewModelProvider('s-1').notifier)
          .asignarMaterial(materialId: 'm-1');

      expect(ok, isTrue);
      verify(() => repo.getInventario('s-1')).called(2);
    });

    test('asignarMaterial failure returns false and surfaces AsyncError',
        () async {
      final repo = _MockRepo();
      when(() => repo.getInventario('s-1'))
          .thenAnswer((_) async => const Success(_empty));
      when(
        () => repo.asignarMaterial(
          's-1',
          materialId: any(named: 'materialId'),
          cantidad: any(named: 'cantidad'),
        ),
      ).thenAnswer(
        (_) async => const Fail(InventarioFailure.recursoSolapado()),
      );
      final container = _container(repo);
      await container.read(servicioInventarioViewModelProvider('s-1').future);

      final ok = await container
          .read(servicioInventarioViewModelProvider('s-1').notifier)
          .asignarMaterial(materialId: 'm-1');

      expect(ok, isFalse);
      expect(
        container.read(servicioInventarioViewModelProvider('s-1')),
        isA<AsyncError<ServicioInventario>>(),
      );
    });
  });
}
