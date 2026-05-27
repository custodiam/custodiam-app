import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/mi_perfil_update.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/update_my_profile.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/editar_mi_perfil_view_model.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_di.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements VoluntariosRepository {}

class _FakePatch extends Fake implements MiPerfilUpdate {}

Voluntario _profile() => Voluntario(
      id: 'id-1',
      nombre: 'Ana',
      telefono: '600',
      municipio: 'Zuera',
      fechaNacimiento: DateTime(1990, 5, 10),
      estado: EstadoVoluntario.activo,
      fechaAlta: DateTime(2024, 1, 15),
    );

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      updateMyProfileProvider.overrideWithValue(UpdateMyProfile(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePatch());
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('initial state resolves to AsyncData(null) — nothing edited yet',
      () async {
    final container = _container(repo);

    await container.read(editarMiPerfilViewModelProvider.future);

    final state = container.read(editarMiPerfilViewModelProvider);
    expect(state, isA<AsyncData<Voluntario?>>());
    expect(state.value, isNull);
  });

  test('submit Success resolves to AsyncData carrying the updated profile',
      () async {
    when(() => repo.updateMyProfile(any()))
        .thenAnswer((_) async => Success(_profile()));
    final container = _container(repo);

    await container
        .read(editarMiPerfilViewModelProvider.notifier)
        .submit(const MiPerfilUpdate(telefono: '699'));

    final state = container.read(editarMiPerfilViewModelProvider);
    expect(state.value!.nombre, 'Ana');
  });

  test('submit Fail with EmailDuplicado resolves to AsyncError', () async {
    when(() => repo.updateMyProfile(any())).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.emailDuplicado()),
    );
    final container = _container(repo);

    await container
        .read(editarMiPerfilViewModelProvider.notifier)
        .submit(const MiPerfilUpdate(email: 'taken@example.com'));

    final state = container.read(editarMiPerfilViewModelProvider);
    expect(state, isA<AsyncError<Voluntario?>>());
    expect(state.error, isA<EmailDuplicado>());
  });

  test('submit Fail with generic NetworkFailure resolves to AsyncError',
      () async {
    when(() => repo.updateMyProfile(any())).thenAnswer(
      (_) async => const Fail(NetworkFailure.serverError(500)),
    );
    final container = _container(repo);

    await container
        .read(editarMiPerfilViewModelProvider.notifier)
        .submit(const MiPerfilUpdate(telefono: '699'));

    final state = container.read(editarMiPerfilViewModelProvider);
    expect(state, isA<AsyncError<Voluntario?>>());
    expect(state.error, isA<NetworkFailure>());
  });
}
