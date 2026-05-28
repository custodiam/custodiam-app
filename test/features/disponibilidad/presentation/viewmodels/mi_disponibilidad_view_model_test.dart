import 'package:custodiam/features/disponibilidad/domain/entities/dia_disponibilidad.dart';
import 'package:custodiam/features/disponibilidad/domain/entities/mes_disponibilidad.dart';
import 'package:custodiam/features/disponibilidad/domain/repositories/disponibilidad_repository.dart';
import 'package:custodiam/features/disponibilidad/presentation/viewmodels/disponibilidad_di.dart';
import 'package:custodiam/features/disponibilidad/presentation/viewmodels/mi_disponibilidad_view_model.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements DisponibilidadRepository {}

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      disponibilidadRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

MesDisponibilidad _mesVacio({int year = 2026, int month = 6}) =>
    MesDisponibilidad(year: year, month: month, dias: const []);

MesDisponibilidad _mesConDia15Disponible({
  int year = 2026,
  int month = 6,
}) =>
    MesDisponibilidad(year: year, month: month, dias: [
      DiaDisponibilidad(
        id: 'dia-1',
        voluntarioId: 'vol-1',
        fecha: DateTime(year, month, 15),
        disponible: true,
      ),
    ]);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('build carga el mes actual desde el repositorio', () async {
    when(() => repo.obtenerMes(
          year: any(named: 'year'),
          month: any(named: 'month'),
        )).thenAnswer((_) async => Success(_mesConDia15Disponible()));

    final container = _container(repo);
    final mes =
        await container.read(miDisponibilidadViewModelProvider.future);

    expect(mes.dias, hasLength(1));
    expect(mes.estaDisponible(15), isTrue);
  });

  test('cambiarMes recarga con el nuevo year/month', () async {
    when(() => repo.obtenerMes(
          year: any(named: 'year'),
          month: any(named: 'month'),
        )).thenAnswer((_) async => Success(_mesVacio()));
    final container = _container(repo);
    await container.read(miDisponibilidadViewModelProvider.future);

    when(() => repo.obtenerMes(year: 2027, month: 1))
        .thenAnswer((_) async => Success(_mesConDia15Disponible(
              year: 2027,
              month: 1,
            )));

    await container
        .read(miDisponibilidadViewModelProvider.notifier)
        .cambiarMes(year: 2027, month: 1);

    final state = container.read(miDisponibilidadViewModelProvider);
    expect(state.value!.year, 2027);
    expect(state.value!.month, 1);
    expect(state.value!.estaDisponible(15), isTrue);
  });

  test('toggleDia aplica cambio optimista y confirma con backend', () async {
    when(() => repo.obtenerMes(
          year: any(named: 'year'),
          month: any(named: 'month'),
        )).thenAnswer((_) async => Success(_mesVacio()));
    final container = _container(repo);
    await container.read(miDisponibilidadViewModelProvider.future);

    final fechaFutura = DateTime(2099, 12, 31);
    when(() => repo.marcarDia(fecha: fechaFutura, disponible: true))
        .thenAnswer((_) async => Success(DiaDisponibilidad(
              id: 'nuevo-id',
              voluntarioId: 'vol-1',
              fecha: fechaFutura,
              disponible: true,
            )));

    final failure = await container
        .read(miDisponibilidadViewModelProvider.notifier)
        .toggleDia(fechaFutura);

    expect(failure, isNull);
    final mes = container.read(miDisponibilidadViewModelProvider).value!;
    expect(mes.dias, hasLength(1));
    expect(mes.dias.first.id, 'nuevo-id');
    expect(mes.dias.first.disponible, isTrue);
  });

  test('toggleDia revierte el estado si el backend falla', () async {
    final mesInicial = _mesConDia15Disponible(year: 2026, month: 6);
    when(() => repo.obtenerMes(
          year: any(named: 'year'),
          month: any(named: 'month'),
        )).thenAnswer((_) async => Success(mesInicial));
    final container = _container(repo);
    await container.read(miDisponibilidadViewModelProvider.future);

    when(() => repo.marcarDia(
          fecha: any(named: 'fecha'),
          disponible: any(named: 'disponible'),
        )).thenAnswer((_) async => const Fail(DisponibilidadFailure.fechaPasada()));

    final failure = await container
        .read(miDisponibilidadViewModelProvider.notifier)
        .toggleDia(DateTime(2020, 6, 15));

    expect(failure, isA<FechaPasada>());
    // El estado debe haber vuelto al original: día 15 sigue disponible.
    final mes = container.read(miDisponibilidadViewModelProvider).value!;
    expect(mes.estaDisponible(15), isTrue);
  });

  test('error en build se expone como AsyncError envolviendo el Failure',
      () async {
    when(() => repo.obtenerMes(
          year: any(named: 'year'),
          month: any(named: 'month'),
        )).thenAnswer((_) async => const Fail(VoluntariosFailure.notFound()));

    final container = _container(repo);
    final state = await container
        .read(miDisponibilidadViewModelProvider.future)
        .then<Object?>((_) => null)
        .onError((e, _) => e);

    expect(state, isA<VoluntarioNotFound>());
  });
}
