// Tests del método eliminar de VehiculosListViewModel (A6). Espeja
// materiales_list_view_model_test.

import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculo_summary.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculos_page.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/eliminar_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_vehiculos.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/vehiculos_list_view_model.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements InventarioRepository {}

VehiculoSummary _v(String id) => VehiculoSummary(
      id: id,
      codigoInterno: 'VH-$id',
      matricula: '1234ABC',
      tipo: TipoVehiculo.furgoneta,
      estado: EstadoInventario.operativo,
    );

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      listVehiculosProvider.overrideWithValue(ListVehiculos(repo)),
      eliminarVehiculoProvider.overrideWithValue(EliminarVehiculo(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle(ProviderContainer container) async {
  await container
      .read(vehiculosListViewModelProvider.future)
      .catchError((_) => const VehiculosListState());
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  setUpAll(() {
    registerFallbackValue(EstadoInventario.operativo);
    registerFallbackValue(TipoVehiculo.furgoneta);
  });

  void stubList(VehiculosPage page) {
    when(() => repo.listVehiculos(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).thenAnswer((_) async => Success(page));
  }

  test('eliminar con éxito devuelve null y refresca (vuelve a listar)',
      () async {
    stubList(VehiculosPage(items: [_v('a')], total: 1));
    when(() => repo.deleteVehiculo('a'))
        .thenAnswer((_) async => const Success<void>(null));
    final container = _container(repo);
    await _settle(container);

    final failure = await container
        .read(vehiculosListViewModelProvider.notifier)
        .eliminar('a');

    expect(failure, isNull);
    verify(() => repo.deleteVehiculo('a')).called(1);
    verify(() => repo.listVehiculos(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).called(2);
  });

  test('eliminar con Fail(RecursoEnUso) devuelve ese Failure y no rompe el '
      'estado de datos', () async {
    stubList(VehiculosPage(items: [_v('a')], total: 1));
    when(() => repo.deleteVehiculo('a')).thenAnswer(
      (_) async => const Fail(InventarioFailure.enUso()),
    );
    final container = _container(repo);
    await _settle(container);

    final failure = await container
        .read(vehiculosListViewModelProvider.notifier)
        .eliminar('a');

    expect(failure, isA<RecursoEnUso>());
    final state = container.read(vehiculosListViewModelProvider);
    expect(state, isA<AsyncData<VehiculosListState>>());
    expect(state.value!.items, hasLength(1));
    verify(() => repo.deleteVehiculo('a')).called(1);
    verify(() => repo.listVehiculos(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).called(1);
  });
}
