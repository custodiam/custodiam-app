import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_create.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/crear_servicio.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/alta_servicio_view_model.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

class _FakeServicioCreate extends Fake implements ServicioCreate {}

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      crearServicioProvider.overrideWithValue(CrearServicio(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeServicioCreate());
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('estado inicial es AsyncData(null)', () async {
    final container = _container(repo);
    final state = await container
        .read(altaServicioViewModelProvider.future)
        .then<AsyncValue<Servicio?>>(
          (_) => container.read(altaServicioViewModelProvider),
        );
    expect(state, isA<AsyncData<Servicio?>>());
    expect(state.value, isNull);
  });

  test('submit() resuelve AsyncData con el servicio en Success', () async {
    final created = Servicio(
      id: 'new-1',
      titulo: 'X',
      tipo: TipoServicio.preventivo,
      estado: EstadoServicio.borrador,
      fechaInicio: DateTime.utc(2026, 6, 10),
      ubicacion: 'Zuera',
    );
    when(() => repo.create(any())).thenAnswer((_) async => Success(created));
    final container = _container(repo);
    await container.read(altaServicioViewModelProvider.future);

    await container
        .read(altaServicioViewModelProvider.notifier)
        .submit(ServicioCreate(
          titulo: 'X',
          tipo: TipoServicio.preventivo,
          fechaInicio: DateTime.utc(2026, 6, 10),
          ubicacion: 'Zuera',
        ));

    final state = container.read(altaServicioViewModelProvider);
    expect(state, isA<AsyncData<Servicio?>>());
    expect(state.value?.id, 'new-1');
  });

  test('submit() resuelve AsyncError en Fail', () async {
    when(() => repo.create(any())).thenAnswer(
      (_) async => const Fail(NetworkFailure.serverError(500)),
    );
    final container = _container(repo);
    await container.read(altaServicioViewModelProvider.future);

    await container
        .read(altaServicioViewModelProvider.notifier)
        .submit(ServicioCreate(
          titulo: 'X',
          tipo: TipoServicio.preventivo,
          fechaInicio: DateTime.utc(2026, 6, 10),
          ubicacion: 'Zuera',
        ));

    final state = container.read(altaServicioViewModelProvider);
    expect(state, isA<AsyncError<Servicio?>>());
    expect(state.error, isA<NetworkFailure>());
  });
}
