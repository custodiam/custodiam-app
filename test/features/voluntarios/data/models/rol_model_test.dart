import 'package:custodiam/features/voluntarios/data/models/rol_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RolModel.fromJson', () {
    test('maps id, nombre, nivel and optional descripcion', () {
      final json = <String, dynamic>{
        'id': 'aaa-bbb-ccc',
        'nombre': 'jefe_equipo',
        'nivel': 3,
        'descripcion': 'Mando intermedio',
      };

      final r = RolModel.fromJson(json);

      expect(r.id, 'aaa-bbb-ccc');
      expect(r.nombre, 'jefe_equipo');
      expect(r.nivel, 3);
      expect(r.descripcion, 'Mando intermedio');
    });

    test('keeps descripcion null when absent', () {
      final json = <String, dynamic>{
        'id': 'a',
        'nombre': 'voluntario',
        'nivel': 1,
      };

      final r = RolModel.fromJson(json);

      expect(r.descripcion, isNull);
    });
  });
}
