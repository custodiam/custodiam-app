import 'package:custodiam/features/fichaje/domain/entities/fichaje.dart';
import 'package:custodiam/features/fichaje/domain/repositories/fichaje_repository.dart';
import 'package:custodiam/features/fichaje/domain/usecases/fichar_entrada.dart';
import 'package:custodiam/features/fichaje/domain/usecases/fichar_salida.dart';
import 'package:custodiam/features/fichaje/domain/usecases/get_mis_fichajes.dart';
import 'package:custodiam/features/fichaje/presentation/viewmodels/fichaje_di.dart';
import 'package:custodiam/features/fichaje/presentation/viewmodels/fichaje_en_servicio_view_model.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements FichajeRepository {}

Fichaje _fichaje({
  String id = 'f-1',
  String servicioId = 'svc-1',
  DateTime? horaSalida,
  DateTime? horaEntrada,
}) {
  return Fichaje(
    id: id,
    servicioId: servicioId,
    voluntarioId: 'v-1',
    horaEntrada: horaEntrada ?? DateTime.utc(2026, 6, 10, 8),
    horaSalida: horaSalida,
    automatico: false,
    duracionSegundos: horaSalida
        ?.difference(horaEntrada ?? DateTime.utc(2026, 6, 10, 8))
        .inSeconds,
  );
}

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      getMisFichajesProvider.overrideWithValue(GetMisFichajes(repo)),
      ficharEntradaProvider.overrideWithValue(FicharEntrada(repo)),
      ficharSalidaProvider.overrideWithValue(FicharSalida(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('build picks the open fichaje for the given servicio', () async {
    when(() => repo.misFichajes()).thenAnswer((_) async => Success([
          _fichaje(id: 'old-svc', servicioId: 'svc-other'),
          _fichaje(
            id: 'open-here',
            servicioId: 'svc-1',
            horaEntrada: DateTime.utc(2026, 6, 10, 8),
          ),
        ]));
    final container = _container(repo);

    await container
        .read(fichajeEnServicioViewModelProvider('svc-1').future);
    final state = container
        .read(fichajeEnServicioViewModelProvider('svc-1'))
        .value!;

    expect(state.fichaje?.id, 'open-here');
    expect(state.tieneEntradaAbierta, isTrue);
  });

  test('build falls back to the latest closed fichaje when none is open',
      () async {
    when(() => repo.misFichajes()).thenAnswer((_) async => Success([
          _fichaje(
            id: 'closed-old',
            servicioId: 'svc-1',
            horaEntrada: DateTime.utc(2026, 6, 1, 8),
            horaSalida: DateTime.utc(2026, 6, 1, 10),
          ),
          _fichaje(
            id: 'closed-new',
            servicioId: 'svc-1',
            horaEntrada: DateTime.utc(2026, 6, 8, 8),
            horaSalida: DateTime.utc(2026, 6, 8, 10),
          ),
        ]));
    final container = _container(repo);

    await container
        .read(fichajeEnServicioViewModelProvider('svc-1').future);
    final state = container
        .read(fichajeEnServicioViewModelProvider('svc-1'))
        .value!;

    expect(state.fichaje?.id, 'closed-new');
    expect(state.tieneEntradaAbierta, isFalse);
    expect(state.yaFichadoYCerrado, isTrue);
  });

  test('build returns null when there is no fichaje for the servicio',
      () async {
    when(() => repo.misFichajes())
        .thenAnswer((_) async => const Success(<Fichaje>[]));
    final container = _container(repo);

    await container
        .read(fichajeEnServicioViewModelProvider('svc-1').future);
    final state = container
        .read(fichajeEnServicioViewModelProvider('svc-1'))
        .value!;

    expect(state.fichaje, isNull);
  });

  test('ficharEntrada sets the new fichaje on Success', () async {
    when(() => repo.misFichajes())
        .thenAnswer((_) async => const Success(<Fichaje>[]));
    when(() => repo.ficharEntrada('svc-1'))
        .thenAnswer((_) async => Success(_fichaje(id: 'fresh')));
    final container = _container(repo);
    await container
        .read(fichajeEnServicioViewModelProvider('svc-1').future);

    await container
        .read(fichajeEnServicioViewModelProvider('svc-1').notifier)
        .ficharEntrada();

    expect(
      container.read(fichajeEnServicioViewModelProvider('svc-1')).value!
          .fichaje
          ?.id,
      'fresh',
    );
  });

  test('ficharSalida surfaces SinFichajeAbierto as AsyncError', () async {
    when(() => repo.misFichajes()).thenAnswer((_) async => Success([
          _fichaje(servicioId: 'svc-1'),
        ]));
    when(() => repo.ficharSalida('svc-1')).thenAnswer(
      (_) async => const Fail(FichajeFailure.sinFichajeAbierto()),
    );
    final container = _container(repo);
    await container
        .read(fichajeEnServicioViewModelProvider('svc-1').future);

    await container
        .read(fichajeEnServicioViewModelProvider('svc-1').notifier)
        .ficharSalida();

    final state =
        container.read(fichajeEnServicioViewModelProvider('svc-1'));
    expect(state, isA<AsyncError<FichajeEnServicioState>>());
    expect(state.error, isA<FichajeFailure>());
  });
}
