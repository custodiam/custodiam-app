import 'package:custodiam/features/inventario/domain/entities/tipo_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculo_create.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehiculoCreate.toJson (PR2)', () {
    test('manda ubicacion_base_id y ubicacion_base cuando se indican', () {
      final json = const VehiculoCreate(
        codigoInterno: 'VH-1',
        matricula: '1234ABC',
        tipo: TipoVehiculo.furgoneta,
        ubicacionBase: 'Base Zuera',
        ubicacionBaseId: 'u-1',
      ).toJson();

      expect(json['ubicacion_base'], 'Base Zuera');
      expect(json['ubicacion_base_id'], 'u-1');
    });

    test('omite los campos de ubicación cuando son null', () {
      final json = const VehiculoCreate(
        codigoInterno: 'VH-1',
        matricula: '1234ABC',
        tipo: TipoVehiculo.furgoneta,
      ).toJson();

      expect(json.containsKey('ubicacion_base'), isFalse);
      expect(json.containsKey('ubicacion_base_id'), isFalse);
    });
  });
}
