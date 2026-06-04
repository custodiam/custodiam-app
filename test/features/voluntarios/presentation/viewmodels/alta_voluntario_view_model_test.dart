import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_create.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/create_voluntario.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/alta_voluntario_view_model.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_di.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements VoluntariosRepository {}

class _FakeCreate extends Fake implements VoluntarioCreate {}

VoluntarioCreate _data() => VoluntarioCreate(
      nombre: 'Carlos',
      telefono: '600',
      municipio: 'Villanueva',
      fechaNacimiento: DateTime(1995, 6, 20),
      email: 'carlos@example.com',
    );

Voluntario _profile() => Voluntario(
      id: 'new-id',
      nombre: 'Carlos',
      telefono: '600',
      municipio: 'Villanueva',
      fechaNacimiento: DateTime(1995, 6, 20),
      estado: EstadoVoluntario.activo,
      fechaAlta: DateTime(2026, 5, 27),
    );

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      createVoluntarioProvider.overrideWithValue(CreateVoluntario(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCreate());
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('initial state resolves to AsyncData(null)', () async {
    final container = _container(repo);

    await container.read(altaVoluntarioViewModelProvider.future);

    final state = container.read(altaVoluntarioViewModelProvider);
    expect(state, isA<AsyncData<Voluntario?>>());
    expect(state.value, isNull);
  });

  test('submit Success resolves to AsyncData carrying the new profile',
      () async {
    when(() => repo.create(any()))
        .thenAnswer((_) async => Success(_profile()));
    final container = _container(repo);
    await container.read(altaVoluntarioViewModelProvider.future);

    await container
        .read(altaVoluntarioViewModelProvider.notifier)
        .submit(_data());

    final state = container.read(altaVoluntarioViewModelProvider);
    expect(state.value!.nombre, 'Carlos');
  });

  test('submit Fail (DniOrEmailDuplicado) resolves to AsyncError', () async {
    when(() => repo.create(any())).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.dniOrEmailDuplicado()),
    );
    final container = _container(repo);
    await container.read(altaVoluntarioViewModelProvider.future);

    await container
        .read(altaVoluntarioViewModelProvider.notifier)
        .submit(_data());

    final state = container.read(altaVoluntarioViewModelProvider);
    expect(state, isA<AsyncError<Voluntario?>>());
    expect(state.error, isA<DniOrEmailDuplicado>());
  });

  test('submit Fail (KeycloakSyncFailed) resolves to AsyncError', () async {
    when(() => repo.create(any())).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.keycloakSyncFailed()),
    );
    final container = _container(repo);
    await container.read(altaVoluntarioViewModelProvider.future);

    await container
        .read(altaVoluntarioViewModelProvider.notifier)
        .submit(_data());

    final state = container.read(altaVoluntarioViewModelProvider);
    expect(state, isA<AsyncError<Voluntario?>>());
    expect(state.error, isA<KeycloakSyncFailed>());
  });
}
