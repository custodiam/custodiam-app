// Tests de los use cases ActualizarServicio (A5) y EliminarServicio (A7).
// Son pass-throughs delgados: verifican que delegan al repositorio con los
// argumentos correctos y que devuelven su Result tal cual.

import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/actualizar_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/eliminar_servicio.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

Servicio _servicio() => Servicio(
      id: 'id-1',
      titulo: 'Preventivo',
      tipo: TipoServicio.preventivo,
      estado: EstadoServicio.borrador,
      fechaInicio: DateTime.utc(2026, 6, 10, 8),
      ubicacion: 'Zuera',
      inscritosCount: 0,
    );

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  group('ActualizarServicio', () {
    test('delega update(id, campos) en el repositorio y devuelve su Result',
        () async {
      final servicio = _servicio();
      when(() => repo.update('id-1', any()))
          .thenAnswer((_) async => Success(servicio));

      final result =
          await ActualizarServicio(repo).call('id-1', {'titulo': 'Nuevo'});

      expect(result, isA<Success<Servicio>>());
      verify(() => repo.update('id-1', {'titulo': 'Nuevo'})).called(1);
    });

    test('propaga el Fail del repositorio (409 tieneActividad)', () async {
      when(() => repo.update('id-1', any())).thenAnswer(
        (_) async => const Fail(ServiciosFailure.tieneActividad('detalle')),
      );

      final result = await ActualizarServicio(repo).call('id-1', const {});

      expect(result, isA<Fail<Servicio>>());
    });
  });

  group('EliminarServicio', () {
    test('delega delete(id) en el repositorio y devuelve su Result', () async {
      when(() => repo.delete('id-1'))
          .thenAnswer((_) async => const Success(null));

      final result = await EliminarServicio(repo).call('id-1');

      expect(result, isA<Success<void>>());
      verify(() => repo.delete('id-1')).called(1);
    });

    test('propaga el Fail del repositorio (409 tieneActividad)', () async {
      when(() => repo.delete('id-1')).thenAnswer(
        (_) async => const Fail(ServiciosFailure.tieneActividad('detalle')),
      );

      final result = await EliminarServicio(repo).call('id-1');

      expect(result, isA<Fail<void>>());
    });
  });
}
