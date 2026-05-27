import 'package:custodiam/features/voluntarios/data/models/voluntario_summary_model.dart';
import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoluntarioSummaryModel.fromJson', () {
    test('maps every field with snake_case wire keys', () {
      final json = <String, dynamic>{
        'id': 'b3b3c1d2-1111-2222-3333-444455556666',
        'nombre': 'Ana Pérez',
        'telefono': '600000000',
        'municipio': 'Zuera',
        'estado': 'activo',
        'conductor_habilitado': true,
      };

      final v = VoluntarioSummaryModel.fromJson(json);

      expect(v.id, 'b3b3c1d2-1111-2222-3333-444455556666');
      expect(v.nombre, 'Ana Pérez');
      expect(v.telefono, '600000000');
      expect(v.municipio, 'Zuera');
      expect(v.estado, EstadoVoluntario.activo);
      expect(v.conductorHabilitado, isTrue);
    });

    test('decodes each estado variant the backend exposes', () {
      for (final estado in EstadoVoluntario.values) {
        final json = <String, dynamic>{
          'id': 'x',
          'nombre': 'n',
          'telefono': 't',
          'municipio': 'm',
          'estado': estado.wire,
          'conductor_habilitado': false,
        };
        expect(
          VoluntarioSummaryModel.fromJson(json).estado,
          estado,
          reason: 'wire ${estado.wire}',
        );
      }
    });

    test('throws FormatException on unknown estado wire value', () {
      final json = <String, dynamic>{
        'id': 'x',
        'nombre': 'n',
        'telefono': 't',
        'municipio': 'm',
        'estado': 'unknown_state',
        'conductor_habilitado': false,
      };

      expect(
        () => VoluntarioSummaryModel.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
