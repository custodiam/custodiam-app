import 'package:custodiam/features/historial/domain/entities/evento_voluntario.dart';
import 'package:custodiam/features/historial/domain/entities/historial_page.dart';
import 'package:custodiam/features/historial/domain/entities/tipo_evento_voluntario.dart';
import 'package:custodiam/features/historial/domain/repositories/historial_repository.dart';
import 'package:custodiam/features/historial/presentation/viewmodels/historial_di.dart';
import 'package:custodiam/features/historial/presentation/viewmodels/mi_historial_view_model.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements HistorialRepository {}

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      historialRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

EventoVoluntario _evento({
  String id = 'ev-1',
  TipoEventoVoluntario tipo = TipoEventoVoluntario.fichajeEntrada,
}) =>
    EventoVoluntario(
      id: id,
      voluntarioId: 'vol-1',
      tipo: tipo,
      payload: const {'servicio_id': 'svc-1'},
      actorKeycloakId: 'kc-1',
      createdAt: DateTime.utc(2026, 5, 28, 10),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('build carga la primera página', () async {
    when(() => repo.obtenerHistorial(
          skip: 0,
          limit: 50,
          tipos: null,
          since: null,
          until: null,
        )).thenAnswer((_) async => Success(HistorialPage(
          eventos: [_evento(id: 'a'), _evento(id: 'b')],
          total: 2,
          skip: 0,
          limit: 50,
        )));

    final container = _container(repo);
    final estado = await container.read(miHistorialViewModelProvider.future);

    expect(estado.eventos, hasLength(2));
    expect(estado.total, 2);
    expect(estado.hayMas, isFalse);
    expect(estado.filtroTipos, isEmpty);
  });

  test('loadMore concatena la siguiente página y avanza skip', () async {
    when(() => repo.obtenerHistorial(
          skip: 0,
          limit: 50,
          tipos: null,
          since: null,
          until: null,
        )).thenAnswer((_) async => Success(HistorialPage(
          eventos: List.generate(50, (i) => _evento(id: 'a-$i')),
          total: 75,
          skip: 0,
          limit: 50,
        )));

    final container = _container(repo);
    await container.read(miHistorialViewModelProvider.future);

    when(() => repo.obtenerHistorial(
          skip: 50,
          limit: 50,
          tipos: null,
          since: null,
          until: null,
        )).thenAnswer((_) async => Success(HistorialPage(
          eventos: List.generate(25, (i) => _evento(id: 'b-$i')),
          total: 75,
          skip: 50,
          limit: 50,
        )));

    await container.read(miHistorialViewModelProvider.notifier).loadMore();

    final estado = container.read(miHistorialViewModelProvider).value!;
    expect(estado.eventos, hasLength(75));
    expect(estado.skip, 75);
    expect(estado.hayMas, isFalse);
  });

  test('loadMore es no-op si no hay más eventos por cargar', () async {
    when(() => repo.obtenerHistorial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          tipos: any(named: 'tipos'),
          since: any(named: 'since'),
          until: any(named: 'until'),
        )).thenAnswer((_) async => Success(HistorialPage(
          eventos: [_evento()],
          total: 1,
          skip: 0,
          limit: 50,
        )));

    final container = _container(repo);
    await container.read(miHistorialViewModelProvider.future);

    await container.read(miHistorialViewModelProvider.notifier).loadMore();

    verify(() => repo.obtenerHistorial(
          skip: 0,
          limit: 50,
          tipos: null,
          since: null,
          until: null,
        )).called(1);
  });

  test('setFiltroTipos resetea la paginación y recarga', () async {
    when(() => repo.obtenerHistorial(
          skip: 0,
          limit: 50,
          tipos: null,
          since: null,
          until: null,
        )).thenAnswer((_) async => Success(HistorialPage(
          eventos: List.generate(3, (i) => _evento(id: 'x-$i')),
          total: 3,
          skip: 0,
          limit: 50,
        )));
    final container = _container(repo);
    await container.read(miHistorialViewModelProvider.future);

    const tipos = [TipoEventoVoluntario.asignacionMaterial];
    when(() => repo.obtenerHistorial(
          skip: 0,
          limit: 50,
          tipos: tipos,
          since: null,
          until: null,
        )).thenAnswer((_) async => Success(HistorialPage(
          eventos: [_evento(tipo: TipoEventoVoluntario.asignacionMaterial)],
          total: 1,
          skip: 0,
          limit: 50,
        )));

    await container
        .read(miHistorialViewModelProvider.notifier)
        .setFiltroTipos(tipos);

    final estado = container.read(miHistorialViewModelProvider).value!;
    expect(estado.filtroTipos, equals(tipos));
    expect(estado.eventos, hasLength(1));
    expect(estado.eventos.first.tipo, TipoEventoVoluntario.asignacionMaterial);
  });

  test('setRangoFechas propaga since/until al use case', () async {
    when(() => repo.obtenerHistorial(
          skip: 0,
          limit: 50,
          tipos: null,
          since: null,
          until: null,
        )).thenAnswer((_) async => const Success(HistorialPage(
          eventos: [],
          total: 0,
          skip: 0,
          limit: 50,
        )));
    final container = _container(repo);
    await container.read(miHistorialViewModelProvider.future);

    final desde = DateTime.utc(2026, 1, 1);
    final hasta = DateTime.utc(2026, 6, 30);
    when(() => repo.obtenerHistorial(
          skip: 0,
          limit: 50,
          tipos: null,
          since: desde,
          until: hasta,
        )).thenAnswer((_) async => Success(HistorialPage(
          eventos: [_evento(id: 'rango-1')],
          total: 1,
          skip: 0,
          limit: 50,
        )));

    await container
        .read(miHistorialViewModelProvider.notifier)
        .setRangoFechas(desde: desde, hasta: hasta);

    final estado = container.read(miHistorialViewModelProvider).value!;
    expect(estado.desde, desde);
    expect(estado.hasta, hasta);
    expect(estado.eventos, hasLength(1));
    verify(() => repo.obtenerHistorial(
          skip: 0,
          limit: 50,
          tipos: null,
          since: desde,
          until: hasta,
        )).called(1);
  });

  test('setRangoFechas() sin args limpia desde/hasta y recarga', () async {
    when(() => repo.obtenerHistorial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          tipos: any(named: 'tipos'),
          since: any(named: 'since'),
          until: any(named: 'until'),
        )).thenAnswer((_) async => Success(HistorialPage(
          eventos: [_evento()],
          total: 1,
          skip: 0,
          limit: 50,
        )));
    final container = _container(repo);
    await container.read(miHistorialViewModelProvider.future);

    // Primero aplicamos un filtro para tener algo que limpiar.
    final desde = DateTime.utc(2026, 1, 1);
    await container
        .read(miHistorialViewModelProvider.notifier)
        .setRangoFechas(desde: desde, hasta: DateTime.utc(2026, 6, 30));
    expect(container.read(miHistorialViewModelProvider).value!.desde, desde);

    // Y ahora lo limpiamos.
    await container
        .read(miHistorialViewModelProvider.notifier)
        .setRangoFechas();

    final estado = container.read(miHistorialViewModelProvider).value!;
    expect(estado.desde, isNull);
    expect(estado.hasta, isNull);
  });

  test('build con fallo expone Failure en AsyncError', () async {
    when(() => repo.obtenerHistorial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          tipos: any(named: 'tipos'),
          since: any(named: 'since'),
          until: any(named: 'until'),
        )).thenAnswer((_) async => const Fail(VoluntariosFailure.notFound()));

    final container = _container(repo);
    final captured = await container
        .read(miHistorialViewModelProvider.future)
        .then<Object?>((_) => null)
        .onError((e, _) => e);

    expect(captured, isA<VoluntarioNotFound>());
  });
}
