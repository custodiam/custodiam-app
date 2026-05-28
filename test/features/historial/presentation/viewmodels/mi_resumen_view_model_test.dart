import 'package:custodiam/features/historial/domain/entities/resumen_voluntario.dart';
import 'package:custodiam/features/historial/domain/repositories/historial_repository.dart';
import 'package:custodiam/features/historial/presentation/viewmodels/historial_di.dart';
import 'package:custodiam/features/historial/presentation/viewmodels/mi_resumen_view_model.dart';
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

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  test('build carga el resumen desde el repositorio', () async {
    when(() => repo.obtenerResumen()).thenAnswer(
      (_) async => const Success(ResumenVoluntario(
        horasTotales: 42,
        segundosTotales: 42 * 3600,
        serviciosRealizados: 7,
        ultimoServicio: null,
      )),
    );

    final container = _container(repo);
    final resumen = await container.read(miResumenViewModelProvider.future);

    expect(resumen.horasTotales, 42);
    expect(resumen.serviciosRealizados, 7);
    expect(resumen.ultimoServicio, isNull);
  });

  test('build con fallo expone Failure', () async {
    when(() => repo.obtenerResumen())
        .thenAnswer((_) async => const Fail(VoluntariosFailure.notFound()));

    final container = _container(repo);
    final captured = await container
        .read(miResumenViewModelProvider.future)
        .then<Object?>((_) => null)
        .onError((e, _) => e);

    expect(captured, isA<VoluntarioNotFound>());
  });
}
