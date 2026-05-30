import 'package:custodiam/features/inventario/data/models/dotacion_vehiculo_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotacionVehiculoModel.fromJson', () {
    test('parses the curated dotación fields', () {
      final d = DotacionVehiculoModel.fromJson({
        'id': 'a-1',
        'material_id': 'm-9',
        'material_nombre': 'Casco rojo',
        'cantidad': 4,
        'fecha_asignacion': '2026-05-27T10:00:00',
      });

      expect(d.id, 'a-1');
      expect(d.materialId, 'm-9');
      expect(d.materialNombre, 'Casco rojo');
      expect(d.cantidad, 4);
      expect(d.fechaAsignacion, DateTime.parse('2026-05-27T10:00:00'));
    });
  });
}
