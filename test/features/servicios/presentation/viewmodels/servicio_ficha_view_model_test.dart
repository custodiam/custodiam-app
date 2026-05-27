import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/cerrar_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/convocar_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/desapuntarse_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_servicio_by_id.dart';
import 'package:custodiam/features/servicios/domain/usecases/inscribirse_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/publicar_servicio.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicio_ficha_view_model.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

Servicio _servicio({
  String id = 'id-1',
  EstadoServicio estado = EstadoServicio.publicado,
}) {
  return Servicio(
    id: id,
    titulo: 'Preventivo',
    tipo: TipoServicio.preventivo,
    estado: estado,
    fechaInicio: DateTime.utc(2026, 6, 10, 8),
    ubicacion: 'Zuera',
  );
}

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      getServicioByIdProvider.overrideWithValue(GetServicioById(repo)),
      inscribirseServicioProvider
          .overrideWithValue(InscribirseServicio(repo)),
      desapuntarseServicioProvider
          .overrideWithValue(DesapuntarseServicio(repo)),
      publicarServicioProvider.overrideWithValue(PublicarServicio(repo)),
      convocarServicioProvider.overrideWithValue(ConvocarServicio(repo)),
      cerrarServicioProvider.overrideWithValue(CerrarServicio(repo)),
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

  test('build resolves with the servicio on Success', () async {
    when(() => repo.getById('id-1'))
        .thenAnswer((_) async => Success(_servicio()));
    final container = _container(repo);

    final state = await container
        .read(servicioFichaViewModelProvider('id-1').future)
        .then<AsyncValue<Servicio>>(
          (s) => container.read(servicioFichaViewModelProvider('id-1')),
        );

    expect(state, isA<AsyncData<Servicio>>());
    expect(state.value!.id, 'id-1');
  });

  test('build resolves with AsyncError when getById fails', () async {
    when(() => repo.getById('missing')).thenAnswer(
      (_) async => const Fail(ServiciosFailure.notFound()),
    );
    final container = _container(repo);

    await container
        .read(servicioFichaViewModelProvider('missing').future)
        .catchError((_) => _servicio());

    final state = container.read(servicioFichaViewModelProvider('missing'));
    expect(state, isA<AsyncError<Servicio>>());
    expect(state.error, isA<ServiciosFailure>());
  });

  test('apuntarse() updates state with the new servicio on Success',
      () async {
    when(() => repo.getById('id-1')).thenAnswer(
      (_) async => Success(_servicio(estado: EstadoServicio.publicado)),
    );
    when(() => repo.inscribirse('id-1')).thenAnswer(
      (_) async => Success(_servicio(estado: EstadoServicio.publicado)),
    );
    final container = _container(repo);
    await container.read(servicioFichaViewModelProvider('id-1').future);

    await container
        .read(servicioFichaViewModelProvider('id-1').notifier)
        .apuntarse();

    verify(() => repo.inscribirse('id-1')).called(1);
    final state = container.read(servicioFichaViewModelProvider('id-1'));
    expect(state, isA<AsyncData<Servicio>>());
  });

  test('publicar() surfaces TransicionInvalida as AsyncError', () async {
    when(() => repo.getById('id-1')).thenAnswer(
      (_) async => Success(_servicio(estado: EstadoServicio.borrador)),
    );
    when(() => repo.publicar('id-1')).thenAnswer(
      (_) async =>
          const Fail(ServiciosFailure.transicionInvalida('detalle')),
    );
    final container = _container(repo);
    await container.read(servicioFichaViewModelProvider('id-1').future);

    await container
        .read(servicioFichaViewModelProvider('id-1').notifier)
        .publicar();

    final state = container.read(servicioFichaViewModelProvider('id-1'));
    expect(state, isA<AsyncError<Servicio>>());
    expect(state.error, isA<TransicionInvalida>());
  });

  test('convocarTodos() llama al repo con voluntarioIds = null',
      () async {
    when(() => repo.getById('id-1')).thenAnswer(
      (_) async => Success(_servicio(estado: EstadoServicio.publicado)),
    );
    when(() => repo.convocar('id-1', voluntarioIds: null)).thenAnswer(
      (_) async => Success(_servicio(estado: EstadoServicio.activo)),
    );
    final container = _container(repo);
    await container.read(servicioFichaViewModelProvider('id-1').future);

    await container
        .read(servicioFichaViewModelProvider('id-1').notifier)
        .convocarTodos();

    verify(() => repo.convocar('id-1', voluntarioIds: null)).called(1);
  });

  test('cerrar() pasa observaciones al repo', () async {
    when(() => repo.getById('id-1')).thenAnswer(
      (_) async => Success(_servicio(estado: EstadoServicio.activo)),
    );
    when(() => repo.cerrar('id-1', observaciones: 'ok')).thenAnswer(
      (_) async => Success(_servicio(estado: EstadoServicio.cerrado)),
    );
    final container = _container(repo);
    await container.read(servicioFichaViewModelProvider('id-1').future);

    await container
        .read(servicioFichaViewModelProvider('id-1').notifier)
        .cerrar(observaciones: 'ok');

    verify(() => repo.cerrar('id-1', observaciones: 'ok')).called(1);
  });
}
