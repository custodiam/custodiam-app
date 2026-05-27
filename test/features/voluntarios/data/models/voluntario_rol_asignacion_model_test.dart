import 'package:custodiam/features/voluntarios/data/models/voluntario_rol_asignacion_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoluntarioRolAsignacionModel.fromJson', () {
    test('maps all fields including rol_nombre and fechas opcionales', () {
      final json = <String, dynamic>{
        'id': 'asig-1',
        'voluntario_id': 'vol-1',
        'rol_id': 'rol-1',
        'rol_nombre': 'voluntario',
        'fecha_desde': '2025-01-15',
        'fecha_hasta': null,
      };

      final a = VoluntarioRolAsignacionModel.fromJson(json);

      expect(a.id, 'asig-1');
      expect(a.voluntarioId, 'vol-1');
      expect(a.rolId, 'rol-1');
      expect(a.rolNombre, 'voluntario');
      expect(a.fechaDesde, DateTime(2025, 1, 15));
      expect(a.fechaHasta, isNull);
    });

    test('parses fecha_hasta when populated (closed assignment)', () {
      final json = <String, dynamic>{
        'id': 'asig-2',
        'voluntario_id': 'vol-1',
        'rol_id': 'rol-1',
        'rol_nombre': 'voluntario',
        'fecha_desde': '2024-01-01',
        'fecha_hasta': '2025-06-30',
      };

      final a = VoluntarioRolAsignacionModel.fromJson(json);

      expect(a.fechaHasta, DateTime(2025, 6, 30));
    });

    test('tolerates absent fecha_desde', () {
      final json = <String, dynamic>{
        'id': 'asig-3',
        'voluntario_id': 'vol-1',
        'rol_id': 'rol-1',
        'rol_nombre': 'voluntario',
      };

      final a = VoluntarioRolAsignacionModel.fromJson(json);

      expect(a.fechaDesde, isNull);
      expect(a.fechaHasta, isNull);
    });
  });
}
