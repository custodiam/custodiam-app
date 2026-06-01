// Tests del AsyncNotifier de la pestaña Ubicaciones (E10). Mismo patrón que
// servicios_list_view_model_test: ProviderContainer con los providers de
// use case overrideados sobre un repo mock (mocktail). Verifica:
//  - build carga la lista (AsyncData con items/total),
//  - build resuelve a AsyncError en Fail,
//  - search recarga y forwarda el query,
//  - loadMore añade la segunda página,
//  - eliminar con éxito devuelve null y refresca (vuelve a listar),
//  - eliminar con Fail(UbicacionEnUso) devuelve ese Failure sin romper el
//    estado de datos.

import 'package:custodiam/features/inventario/domain/entities/ubicacion.dart';
import 'package:custodiam/features/inventario/domain/entities/ubicaciones_page.dart';
import 'package:custodiam/features/inventario/domain/repositories/ubicaciones_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/eliminar_ubicacion.dart';
import 'package:custodiam/features/inventario/domain/usecases/listar_ubicaciones.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/ubicaciones_di.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/ubicaciones_list_view_model.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements UbicacionesRepository {}

Ubicacion _u(String id, {String nombre = 'Base'}) =>
    Ubicacion(id: id, nombre: nombre);

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      listarUbicacionesProvider.overrideWithValue(ListarUbicaciones(repo)),
      eliminarUbicacionProvider.overrideWithValue(EliminarUbicacion(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AsyncValue<UbicacionesListState>> _settle(
  ProviderContainer container,
) async {
  await container
      .read(ubicacionesListViewModelProvider.future)
      .catchError((_) => const UbicacionesListState());
  return container.read(ubicacionesListViewModelProvider);
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('UbicacionesListViewModel', () {
    test('build resuelve a AsyncData en Success', () async {
      when(() => repo.listar(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
          )).thenAnswer((_) async => UbicacionesPage(
            items: [_u('a', nombre: 'Base A'), _u('b')],
            total: 5,
          ).asSuccess());
      final container = _container(repo);

      final state = await _settle(container);

      expect(state, isA<AsyncData<UbicacionesListState>>());
      expect(state.value!.items, hasLength(2));
      expect(state.value!.total, 5);
      expect(state.value!.hasMore, isTrue);
    });

    test('build resuelve a AsyncError en Fail', () async {
      when(() => repo.listar(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
          )).thenAnswer(
        (_) async => const Fail(NetworkFailure.serverError(503)),
      );
      final container = _container(repo);

      final state = await _settle(container);

      expect(state, isA<AsyncError<UbicacionesListState>>());
      expect(state.error, isA<NetworkFailure>());
    });

    test('search recarga la primera página y forwarda el query', () async {
      when(() => repo.listar(
            skip: 0,
            limit: UbicacionesListViewModel.pageSize,
            query: null,
          )).thenAnswer(
        (_) async =>
            const UbicacionesPage(items: <Ubicacion>[], total: 0).asSuccess(),
      );
      when(() => repo.listar(
            skip: 0,
            limit: UbicacionesListViewModel.pageSize,
            query: 'zuera',
          )).thenAnswer((_) async => UbicacionesPage(
            items: [_u('z', nombre: 'Zuera')],
            total: 1,
          ).asSuccess());
      final container = _container(repo);
      await _settle(container);

      await container
          .read(ubicacionesListViewModelProvider.notifier)
          .search('zuera');

      final state = container.read(ubicacionesListViewModelProvider);
      expect(state.value!.query, 'zuera');
      expect(state.value!.items, hasLength(1));
      expect(state.value!.items.single.nombre, 'Zuera');
      verify(() => repo.listar(
            skip: 0,
            limit: UbicacionesListViewModel.pageSize,
            query: 'zuera',
          )).called(1);
    });

    test('loadMore añade la segunda página', () async {
      when(() => repo.listar(
            skip: 0,
            limit: UbicacionesListViewModel.pageSize,
            query: null,
          )).thenAnswer((_) async => UbicacionesPage(
            items: [_u('a'), _u('b')],
            total: 4,
          ).asSuccess());
      when(() => repo.listar(
            skip: 2,
            limit: UbicacionesListViewModel.pageSize,
            query: null,
          )).thenAnswer((_) async => UbicacionesPage(
            items: [_u('c'), _u('d')],
            total: 4,
          ).asSuccess());
      final container = _container(repo);
      await _settle(container);

      await container
          .read(ubicacionesListViewModelProvider.notifier)
          .loadMore();

      final state = container.read(ubicacionesListViewModelProvider);
      expect(state.value!.items, hasLength(4));
      expect(state.value!.hasMore, isFalse);
    });

    test('eliminar con éxito devuelve null y refresca (vuelve a listar)',
        () async {
      when(() => repo.listar(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
          )).thenAnswer((_) async => UbicacionesPage(
            items: [_u('a')],
            total: 1,
          ).asSuccess());
      when(() => repo.eliminar('a'))
          .thenAnswer((_) async => const Success<void>(null));
      final container = _container(repo);
      await _settle(container);

      final failure = await container
          .read(ubicacionesListViewModelProvider.notifier)
          .eliminar('a');

      expect(failure, isNull);
      verify(() => repo.eliminar('a')).called(1);
      // build (1) + refresh tras el borrado (1) = listar llamado dos veces.
      verify(() => repo.listar(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
          )).called(2);
    });

    test('eliminar con Fail(UbicacionEnUso) devuelve ese Failure y no rompe '
        'el estado de datos', () async {
      when(() => repo.listar(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
          )).thenAnswer((_) async => UbicacionesPage(
            items: [_u('a')],
            total: 1,
          ).asSuccess());
      when(() => repo.eliminar('a')).thenAnswer(
        (_) async => const Fail(UbicacionesFailure.enUso()),
      );
      final container = _container(repo);
      await _settle(container);

      final failure = await container
          .read(ubicacionesListViewModelProvider.notifier)
          .eliminar('a');

      expect(failure, isA<UbicacionEnUso>());
      // El fallo de borrado no refresca: el estado sigue siendo AsyncData.
      final state = container.read(ubicacionesListViewModelProvider);
      expect(state, isA<AsyncData<UbicacionesListState>>());
      expect(state.value!.items, hasLength(1));
      verify(() => repo.eliminar('a')).called(1);
      verify(() => repo.listar(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
          )).called(1);
    });
  });
}

extension on UbicacionesPage {
  Success<UbicacionesPage> asSuccess() => Success(this);
}
