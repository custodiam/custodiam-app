import 'package:custodiam/features/servicios/data/models/servicio_inventario_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson parses material and vehiculos', () {
    final inv = ServicioInventarioModel.fromJson({
      'material': [
        {
          'id': 'a-1',
          'material_id': 'm-1',
          'material_nombre': 'Conos',
          'cantidad': 4,
          'fecha_asignacion': '2026-05-27T10:00:00',
        },
      ],
      'vehiculos': [
        {
          'id': 'a-2',
          'vehiculo_id': 'v-1',
          'codigo_interno': 'VEH-1',
          'matricula': '1234ABC',
          'fecha_asignacion': '2026-05-27T11:00:00',
        },
      ],
    });

    expect(inv.material, hasLength(1));
    expect(inv.material.first.id, 'a-1');
    expect(inv.material.first.materialNombre, 'Conos');
    expect(inv.material.first.cantidad, 4);
    expect(inv.vehiculos, hasLength(1));
    expect(inv.vehiculos.first.vehiculoId, 'v-1');
    expect(inv.vehiculos.first.codigoInterno, 'VEH-1');
    expect(inv.vehiculos.first.matricula, '1234ABC');
    expect(inv.isEmpty, isFalse);
  });

  test('fromJson with empty lists reports isEmpty', () {
    final inv = ServicioInventarioModel.fromJson({
      'material': <Map<String, dynamic>>[],
      'vehiculos': <Map<String, dynamic>>[],
    });

    expect(inv.material, isEmpty);
    expect(inv.vehiculos, isEmpty);
    expect(inv.isEmpty, isTrue);
  });
}
