import 'package:custodiam/features/inventario/data/models/vehiculo_item_model.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_asignacion.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fila base de detalle de vehículo SIN asignación — así llega un vehículo
/// libre o uno del listado (VehiculoSummary no lleva asignacion_actual).
Map<String, dynamic> _vehiculoRow() {
  return {
    'id': 'v-1',
    'codigo_interno': 'VH-01',
    'matricula': '1234ABC',
    'tipo': 'furgoneta',
    'marca_modelo': 'Renault Trafic',
    'fecha_itv': '2027-03-01',
    'foto_url': null,
    'observaciones': null,
    'ubicacion_base': 'Almacén 1',
    'estado': 'operativo',
    'observaciones_incidencia': null,
    'created_at': '2026-05-27T10:00:00',
    'updated_at': '2026-05-27T10:00:00',
  };
}

void main() {
  group('VehiculoItemModel.fromJson — trazabilidad (PR1)', () {
    test('parses asignacion_actual when present', () {
      final v = VehiculoItemModel.fromJson({
        ..._vehiculoRow(),
        'asignacion_actual': {
          'tipo': 'servicio',
          'servicio_id': 'srv-9',
          'servicio_titulo': 'Simulacro inundación',
          'cantidad': 1,
          'fecha_asignacion': '2026-05-29T07:00:00',
        },
      });

      expect(v.asignacionActual, isNotNull);
      expect(v.asignacionActual!.tipo, TipoAsignacion.servicio);
      expect(v.asignacionActual!.servicioTitulo, 'Simulacro inundación');
    });

    test('asignacion_actual is null when the vehicle is free', () {
      final v = VehiculoItemModel.fromJson(_vehiculoRow());

      expect(v.asignacionActual, isNull);
    });
  });

  group('VehiculoItemModel.fromJson — ubicación (PR2)', () {
    test('parsea ubicacion_base cuando viene como texto', () {
      final v = VehiculoItemModel.fromJson(_vehiculoRow());
      expect(v.ubicacionBase, 'Almacén 1');
    });

    test('tolera ubicacion_base nulo (texto opcional tras PR2)', () {
      final v = VehiculoItemModel.fromJson({
        ..._vehiculoRow(),
        'ubicacion_base': null,
      });
      expect(v.ubicacionBase, isNull);
    });
  });
}
