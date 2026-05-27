import 'package:custodiam/features/notificaciones/domain/entities/notificacion_payload.dart';
import 'package:custodiam/features/notificaciones/domain/entities/preferencias_notificaciones.dart';
import 'package:custodiam/features/notificaciones/domain/repositories/notificaciones_repository.dart';
import 'package:custodiam/features/notificaciones/domain/usecases/get_preferencias_notificaciones.dart';
import 'package:custodiam/features/notificaciones/domain/usecases/update_preferencias_notificaciones.dart';
import 'package:custodiam/features/notificaciones/presentation/viewmodels/notificaciones_ajustes_view_model.dart';
import 'package:custodiam/features/notificaciones/presentation/viewmodels/notificaciones_di.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements NotificacionesRepository {}

class _FakePrefs extends Fake implements PreferenciasNotificaciones {}

class _FakePayload extends Fake implements NotificacionPayload {}

ProviderContainer _container(_MockRepo repo) {
  final container = ProviderContainer(
    overrides: [
      getPreferenciasNotificacionesProvider
          .overrideWithValue(GetPreferenciasNotificaciones(repo)),
      updatePreferenciasNotificacionesProvider
          .overrideWithValue(UpdatePreferenciasNotificaciones(repo)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePrefs());
    registerFallbackValue(_FakePayload());
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('build() loads preferences from the repository', () async {
    when(() => repo.getPreferencias()).thenAnswer(
      (_) async => const PreferenciasNotificaciones(
        nuevosServicios: false,
        recordatorios: true,
      ),
    );
    final container = _container(repo);

    final prefs = await container
        .read(notificacionesAjustesViewModelProvider.future);

    expect(prefs.nuevosServicios, isFalse);
    expect(prefs.recordatorios, isTrue);
    expect(prefs.emergencias, isTrue);
  });

  test('setNuevosServicios updates state and persists', () async {
    when(() => repo.getPreferencias())
        .thenAnswer((_) async => PreferenciasNotificaciones.defaults);
    when(() => repo.setPreferencias(any())).thenAnswer((_) async {});
    final container = _container(repo);
    await container.read(notificacionesAjustesViewModelProvider.future);

    await container
        .read(notificacionesAjustesViewModelProvider.notifier)
        .setNuevosServicios(false);

    final state = container.read(notificacionesAjustesViewModelProvider);
    expect(state.value!.nuevosServicios, isFalse);
    expect(state.value!.recordatorios, isTrue);
    expect(state.value!.emergencias, isTrue);
    verify(() => repo.setPreferencias(any())).called(1);
  });

  test('setRecordatorios updates state and persists', () async {
    when(() => repo.getPreferencias())
        .thenAnswer((_) async => PreferenciasNotificaciones.defaults);
    when(() => repo.setPreferencias(any())).thenAnswer((_) async {});
    final container = _container(repo);
    await container.read(notificacionesAjustesViewModelProvider.future);

    await container
        .read(notificacionesAjustesViewModelProvider.notifier)
        .setRecordatorios(false);

    final state = container.read(notificacionesAjustesViewModelProvider);
    expect(state.value!.recordatorios, isFalse);
    expect(state.value!.nuevosServicios, isTrue);
  });

  test('emergencias stay fixed to true after toggling other prefs',
      () async {
    when(() => repo.getPreferencias())
        .thenAnswer((_) async => PreferenciasNotificaciones.defaults);
    when(() => repo.setPreferencias(any())).thenAnswer((_) async {});
    final container = _container(repo);
    await container.read(notificacionesAjustesViewModelProvider.future);

    await container
        .read(notificacionesAjustesViewModelProvider.notifier)
        .setNuevosServicios(false);
    await container
        .read(notificacionesAjustesViewModelProvider.notifier)
        .setRecordatorios(false);

    final state = container.read(notificacionesAjustesViewModelProvider);
    expect(state.value!.emergencias, isTrue);
  });
}
