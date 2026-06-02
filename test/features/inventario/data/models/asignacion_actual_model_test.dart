import 'package:custodiam/features/inventario/data/models/asignacion_actual_model.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_asignacion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AsignacionActualModel.fromJson', () {
    test('parses a personal assignment targeting a volunteer', () {
      final a = AsignacionActualModel.fromJson({
        'tipo': 'personal',
        'voluntario_id': 'vol-1',
        'servicio_id': null,
        'vehiculo_id': null,
        'servicio_titulo': null,
        'cantidad': 1,
        'fecha_asignacion': '2026-05-27T10:00:00',
      });

      expect(a.tipo, TipoAsignacion.personal);
      expect(a.voluntarioId, 'vol-1');
      expect(a.servicioId, isNull);
      expect(a.vehiculoId, isNull);
      expect(a.cantidad, 1);
      expect(a.fechaAsignacion, DateTime.parse('2026-05-27T10:00:00'));
    });

    test('parses a servicio assignment carrying servicio_titulo', () {
      final a = AsignacionActualModel.fromJson({
        'tipo': 'servicio',
        'servicio_id': 'srv-9',
        'servicio_titulo': 'Romería 2026',
        'cantidad': 3,
        'fecha_asignacion': '2026-05-28T08:30:00',
      });

      expect(a.tipo, TipoAsignacion.servicio);
      expect(a.servicioId, 'srv-9');
      expect(a.servicioTitulo, 'Romería 2026');
      expect(a.cantidad, 3);
    });

    test('parses the new dotacion_vehiculo type targeting a vehicle', () {
      final a = AsignacionActualModel.fromJson({
        'tipo': 'dotacion_vehiculo',
        'vehiculo_id': 'veh-2',
        'cantidad': 2,
        'fecha_asignacion': '2026-05-29T12:00:00',
      });

      expect(a.tipo, TipoAsignacion.dotacionVehiculo);
      expect(a.vehiculoId, 'veh-2');
      expect(a.voluntarioId, isNull);
    });

    test('defaults cantidad to 1 when absent', () {
      final a = AsignacionActualModel.fromJson({
        'tipo': 'prestamo',
        'voluntario_id': 'vol-7',
        'fecha_asignacion': '2026-05-29T12:00:00',
      });

      expect(a.tipo, TipoAsignacion.prestamo);
      expect(a.cantidad, 1);
    });

    test('throws FormatException on an unknown tipo', () {
      expect(
        () => AsignacionActualModel.fromJson({
          'tipo': 'inventado',
          'cantidad': 1,
          'fecha_asignacion': '2026-05-29T12:00:00',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('TipoAsignacion.fromWire', () {
    test('round-trips dotacion_vehiculo', () {
      expect(
        TipoAsignacion.fromWire('dotacion_vehiculo'),
        TipoAsignacion.dotacionVehiculo,
      );
      expect(TipoAsignacion.dotacionVehiculo.wire, 'dotacion_vehiculo');
    });
  });
}
