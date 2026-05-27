import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_summary.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntarios_page.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/list_voluntarios.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_di.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_list_view_model.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements VoluntariosRepository {}

VoluntarioSummary _v(String id, {String nombre = 'n'}) {
  return VoluntarioSummary(
    id: id,
    nombre: nombre,
    telefono: 't',
    municipio: 'm',
    estado: EstadoVoluntario.activo,
    conductorHabilitado: false,
  );
}

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      listVoluntariosProvider.overrideWithValue(ListVoluntarios(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AsyncValue<VoluntariosListState>> _settle(
  ProviderContainer container,
) async {
  await container.read(voluntariosListViewModelProvider.future).catchError(
        (_) => const VoluntariosListState(),
      );
  return container.read(voluntariosListViewModelProvider);
}

void main() {
  setUpAll(() {
    registerFallbackValue(EstadoVoluntario.activo);
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('VoluntariosListViewModel', () {
    test('build() resolves to AsyncData with first page on Success',
        () async {
      when(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => Success(VoluntariosPage(
            items: [_v('a'), _v('b')],
            total: 50,
          )));
      final container = _container(repo);

      final state = await _settle(container);

      expect(state, isA<AsyncData<VoluntariosListState>>());
      expect(state.value!.items, hasLength(2));
      expect(state.value!.total, 50);
      expect(state.value!.hasMore, isTrue);
    });

    test('build() resolves to AsyncError carrying the Failure on Fail',
        () async {
      when(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          )).thenAnswer(
        (_) async => const Fail(NetworkFailure.serverError(503)),
      );
      final container = _container(repo);

      final state = await _settle(container);

      expect(state, isA<AsyncError<VoluntariosListState>>());
      expect(state.error, isA<NetworkFailure>());
    });

    test('search() resets pagination, forwards the query, keeps estado',
        () async {
      when(() => repo.list(
            skip: 0,
            limit: VoluntariosListViewModel.pageSize,
            query: null,
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => Success(VoluntariosPage(
            items: [_v('a')],
            total: 1,
          )));
      when(() => repo.list(
            skip: 0,
            limit: VoluntariosListViewModel.pageSize,
            query: 'ana',
            estado: EstadoVoluntario.baja,
          )).thenAnswer((_) async => Success(VoluntariosPage(
            items: [_v('z', nombre: 'Ana')],
            total: 1,
          )));
      final container = _container(repo);
      await _settle(container);

      // Establish an estado filter first.
      await container
          .read(voluntariosListViewModelProvider.notifier)
          .filterByEstado(EstadoVoluntario.baja);
      await container
          .read(voluntariosListViewModelProvider.notifier)
          .search('ana');

      final state = container.read(voluntariosListViewModelProvider);
      expect(state.value!.query, 'ana');
      expect(state.value!.estado, EstadoVoluntario.baja);
      expect(state.value!.items.single.nombre, 'Ana');
    });

    test('filterByEstado() keeps the current query', () async {
      when(() => repo.list(
            skip: 0,
            limit: VoluntariosListViewModel.pageSize,
            query: null,
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => Success(VoluntariosPage(
            items: [_v('a')],
            total: 1,
          )));
      when(() => repo.list(
            skip: 0,
            limit: VoluntariosListViewModel.pageSize,
            query: 'bea',
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => Success(VoluntariosPage(
            items: [_v('b', nombre: 'Bea')],
            total: 1,
          )));
      final container = _container(repo);
      await _settle(container);
      await container
          .read(voluntariosListViewModelProvider.notifier)
          .search('bea');

      await container
          .read(voluntariosListViewModelProvider.notifier)
          .filterByEstado(EstadoVoluntario.suspendido);

      final state = container.read(voluntariosListViewModelProvider);
      expect(state.value!.query, 'bea');
      expect(state.value!.estado, EstadoVoluntario.suspendido);
    });

    test('loadMore() appends the next page when hasMore is true', () async {
      when(() => repo.list(
            skip: 0,
            limit: VoluntariosListViewModel.pageSize,
            query: null,
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => Success(VoluntariosPage(
            items: [_v('a'), _v('b')],
            total: 4,
          )));
      when(() => repo.list(
            skip: 2,
            limit: VoluntariosListViewModel.pageSize,
            query: null,
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => Success(VoluntariosPage(
            items: [_v('c'), _v('d')],
            total: 4,
          )));
      final container = _container(repo);
      await _settle(container);

      await container
          .read(voluntariosListViewModelProvider.notifier)
          .loadMore();

      final state = container.read(voluntariosListViewModelProvider);
      expect(state.value!.items, hasLength(4));
      expect(state.value!.hasMore, isFalse);
    });

    test('loadMore() is a no-op when hasMore is false', () async {
      when(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => Success(VoluntariosPage(
            items: [_v('a')],
            total: 1,
          )));
      final container = _container(repo);
      await _settle(container);

      await container
          .read(voluntariosListViewModelProvider.notifier)
          .loadMore();

      verify(() => repo.list(
            skip: 0,
            limit: VoluntariosListViewModel.pageSize,
            query: null,
            estado: null,
          )).called(1);
      verifyNever(() => repo.list(
            skip: 1,
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          ));
    });

    test('loadMore() surfaces AsyncError on Fail without losing items',
        () async {
      when(() => repo.list(
            skip: 0,
            limit: VoluntariosListViewModel.pageSize,
            query: null,
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => Success(VoluntariosPage(
            items: [_v('a')],
            total: 10,
          )));
      when(() => repo.list(
            skip: 1,
            limit: VoluntariosListViewModel.pageSize,
            query: null,
            estado: any(named: 'estado'),
          )).thenAnswer(
        (_) async => const Fail(NetworkFailure.serverError(500)),
      );
      final container = _container(repo);
      await _settle(container);

      await container
          .read(voluntariosListViewModelProvider.notifier)
          .loadMore();

      final state = container.read(voluntariosListViewModelProvider);
      expect(state, isA<AsyncError<VoluntariosListState>>());
      expect(state.error, isA<NetworkFailure>());
    });
  });
}
