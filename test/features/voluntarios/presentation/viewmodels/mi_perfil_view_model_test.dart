import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/get_my_profile.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/mi_perfil_view_model.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_di.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements VoluntariosRepository {}

Voluntario _profile({String nombre = 'Ana'}) {
  return Voluntario(
    id: 'id-1',
    nombre: nombre,
    telefono: '600',
    municipio: 'Zuera',
    fechaNacimiento: DateTime(1990, 5, 10),
    estado: EstadoVoluntario.activo,
    fechaAlta: DateTime(2024, 1, 15),
  );
}

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      getMyProfileProvider.overrideWithValue(GetMyProfile(repo)),
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

  test('build() resolves to AsyncData on Success', () async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));
    final container = _container(repo);

    final value = await container
        .read(miPerfilViewModelProvider.future)
        .catchError((_) => _profile(nombre: 'fallback'));

    expect(value.nombre, 'Ana');
  });

  test('build() throws the Failure on Fail', () async {
    when(() => repo.getMyProfile()).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.notFound()),
    );
    final container = _container(repo);

    // Trigger the notifier, then read state.
    await container
        .read(miPerfilViewModelProvider.future)
        .catchError((_) => _profile());

    final state = container.read(miPerfilViewModelProvider);
    expect(state, isA<AsyncError<Voluntario>>());
    expect(state.error, isA<VoluntarioNotFound>());
  });

  test('setProfile updates the state without re-fetching', () async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));
    final container = _container(repo);
    await container
        .read(miPerfilViewModelProvider.future)
        .catchError((_) => _profile());

    container
        .read(miPerfilViewModelProvider.notifier)
        .setProfile(_profile(nombre: 'Bea'));

    final state = container.read(miPerfilViewModelProvider);
    expect(state.value!.nombre, 'Bea');
    // getMyProfile was called only once during build, not again here.
    verify(() => repo.getMyProfile()).called(1);
  });

  test('refresh re-runs getMyProfile', () async {
    var counter = 0;
    when(() => repo.getMyProfile()).thenAnswer((_) async {
      counter++;
      return Success(_profile(nombre: 'call-$counter'));
    });
    final container = _container(repo);
    await container
        .read(miPerfilViewModelProvider.future)
        .catchError((_) => _profile());

    await container.read(miPerfilViewModelProvider.notifier).refresh();

    final state = container.read(miPerfilViewModelProvider);
    expect(state.value!.nombre, 'call-2');
  });
}
