import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_summary.dart';
import 'package:custodiam/features/servicios/domain/entities/servicios_page.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/list_servicios.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_list_view_model.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

ServicioSummary _s(String id, {String titulo = 'Servicio'}) {
  return ServicioSummary(
    id: id,
    titulo: titulo,
    tipo: TipoServicio.preventivo,
    estado: EstadoServicio.publicado,
    fechaInicio: DateTime.utc(2026, 6, 10, 8),
    ubicacion: 'Zuera',
    inscritosCount: 0,
  );
}

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      listServiciosProvider.overrideWithValue(ListServicios(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AsyncValue<ServiciosListState>> _settle(
  ProviderContainer container,
) async {
  await container.read(serviciosListViewModelProvider.future).catchError(
        (_) => const ServiciosListState(),
      );
  return container.read(serviciosListViewModelProvider);
}

void main() {
  setUpAll(() {
    registerFallbackValue(EstadoServicio.publicado);
    registerFallbackValue(TipoServicio.preventivo);
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('ServiciosListViewModel', () {
    test('build resolves to AsyncData on Success', () async {
      when(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenAnswer((_) async => Success(ServiciosPage(
            items: [_s('a'), _s('b')],
            total: 50,
          )));
      final container = _container(repo);

      final state = await _settle(container);

      expect(state, isA<AsyncData<ServiciosListState>>());
      expect(state.value!.items, hasLength(2));
      expect(state.value!.total, 50);
      expect(state.value!.hasMore, isTrue);
    });

    test('build resolves to AsyncError on Fail', () async {
      when(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenAnswer(
        (_) async => const Fail(NetworkFailure.serverError(503)),
      );
      final container = _container(repo);

      final state = await _settle(container);

      expect(state, isA<AsyncError<ServiciosListState>>());
      expect(state.error, isA<NetworkFailure>());
    });

    test('search forwards the query and keeps estado', () async {
      when(() => repo.list(
            skip: 0,
            limit: ServiciosListViewModel.pageSize,
            query: null,
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenAnswer((_) async => Success(ServiciosPage(
            items: [_s('a')],
            total: 1,
          )));
      when(() => repo.list(
            skip: 0,
            limit: ServiciosListViewModel.pageSize,
            query: 'feria',
            estado: EstadoServicio.publicado,
            tipo: any(named: 'tipo'),
          )).thenAnswer((_) async => Success(ServiciosPage(
            items: [_s('z', titulo: 'Feria')],
            total: 1,
          )));
      final container = _container(repo);
      await _settle(container);

      await container
          .read(serviciosListViewModelProvider.notifier)
          .filterByEstado(EstadoServicio.publicado);
      await container
          .read(serviciosListViewModelProvider.notifier)
          .search('feria');

      final state = container.read(serviciosListViewModelProvider);
      expect(state.value!.query, 'feria');
      expect(state.value!.estado, EstadoServicio.publicado);
    });

    test('filterByDateRange forwards the range and keeps other filters',
        () async {
      when(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
            desde: any(named: 'desde'),
            hasta: any(named: 'hasta'),
          )).thenAnswer((_) async => Success(ServiciosPage(
            items: [_s('a')],
            total: 1,
          )));
      final container = _container(repo);
      await _settle(container);
      await container
          .read(serviciosListViewModelProvider.notifier)
          .filterByEstado(EstadoServicio.publicado);

      final desde = DateTime(2026, 6, 1);
      final hasta = DateTime(2026, 6, 30);
      await container
          .read(serviciosListViewModelProvider.notifier)
          .filterByDateRange(desde: desde, hasta: hasta);

      final state = container.read(serviciosListViewModelProvider);
      expect(state.value!.desde, desde);
      expect(state.value!.hasta, hasta);
      expect(state.value!.tieneRangoFechas, isTrue);
      // El rango no descarta el estado ya activo.
      expect(state.value!.estado, EstadoServicio.publicado);
      verify(() => repo.list(
            skip: 0,
            limit: ServiciosListViewModel.pageSize,
            query: null,
            estado: EstadoServicio.publicado,
            tipo: any(named: 'tipo'),
            desde: desde,
            hasta: hasta,
          )).called(1);
    });

    test('filterByDateRange with no args clears the range', () async {
      when(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
            desde: any(named: 'desde'),
            hasta: any(named: 'hasta'),
          )).thenAnswer((_) async => Success(ServiciosPage(
            items: [_s('a')],
            total: 1,
          )));
      final container = _container(repo);
      await _settle(container);
      await container
          .read(serviciosListViewModelProvider.notifier)
          .filterByDateRange(
            desde: DateTime(2026, 6, 1),
            hasta: DateTime(2026, 6, 30),
          );

      await container
          .read(serviciosListViewModelProvider.notifier)
          .filterByDateRange();

      final state = container.read(serviciosListViewModelProvider);
      expect(state.value!.desde, isNull);
      expect(state.value!.hasta, isNull);
      expect(state.value!.tieneRangoFechas, isFalse);
    });

    test('loadMore appends a second page', () async {
      when(() => repo.list(
            skip: 0,
            limit: ServiciosListViewModel.pageSize,
            query: null,
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenAnswer((_) async => Success(ServiciosPage(
            items: [_s('a'), _s('b')],
            total: 4,
          )));
      when(() => repo.list(
            skip: 2,
            limit: ServiciosListViewModel.pageSize,
            query: null,
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
          )).thenAnswer((_) async => Success(ServiciosPage(
            items: [_s('c'), _s('d')],
            total: 4,
          )));
      final container = _container(repo);
      await _settle(container);

      await container
          .read(serviciosListViewModelProvider.notifier)
          .loadMore();

      final state = container.read(serviciosListViewModelProvider);
      expect(state.value!.items, hasLength(4));
      expect(state.value!.hasMore, isFalse);
    });

    test('reloadSilently refreshes keeping the active filters', () async {
      when(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
            desde: any(named: 'desde'),
            hasta: any(named: 'hasta'),
          )).thenAnswer((_) async => Success(ServiciosPage(
            items: [_s('a')],
            total: 1,
          )));
      final container = _container(repo);
      await _settle(container);
      await container
          .read(serviciosListViewModelProvider.notifier)
          .search('feria');
      await container
          .read(serviciosListViewModelProvider.notifier)
          .filterByEstado(EstadoServicio.publicado);

      await container
          .read(serviciosListViewModelProvider.notifier)
          .reloadSilently();

      // A diferencia de build(), reloadSilently NO resetea los filtros.
      final state = container.read(serviciosListViewModelProvider);
      expect(state, isA<AsyncData<ServiciosListState>>());
      expect(state.value!.query, 'feria');
      expect(state.value!.estado, EstadoServicio.publicado);
    });
  });
}
