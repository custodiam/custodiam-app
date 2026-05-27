import 'package:custodiam/features/voluntarios/data/models/voluntario_model.dart';
import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _baseJson() => <String, dynamic>{
      'id': 'b3b3c1d2-1111-2222-3333-444455556666',
      'keycloak_id': 'kc-uuid',
      'nombre': 'Ana Pérez',
      'telefono': '600000000',
      'municipio': 'Zuera',
      'fecha_nacimiento': '1990-05-10',
      'estado': 'activo',
      'fecha_alta': '2024-01-15',
      'conductor_habilitado': true,
      'dni': '12345678A',
      'email': 'ana@example.com',
      'direccion': 'Calle Mayor 1',
      'foto_url': 'https://example.com/ana.png',
    };

void main() {
  group('VoluntarioModel.fromJson', () {
    test('maps every field with snake_case wire keys', () {
      final v = VoluntarioModel.fromJson(_baseJson());

      expect(v.id, 'b3b3c1d2-1111-2222-3333-444455556666');
      expect(v.keycloakId, 'kc-uuid');
      expect(v.nombre, 'Ana Pérez');
      expect(v.telefono, '600000000');
      expect(v.municipio, 'Zuera');
      expect(v.fechaNacimiento, DateTime(1990, 5, 10));
      expect(v.estado, EstadoVoluntario.activo);
      expect(v.fechaAlta, DateTime(2024, 1, 15));
      expect(v.fechaBaja, isNull);
      expect(v.dni, '12345678A');
      expect(v.email, 'ana@example.com');
      expect(v.direccion, 'Calle Mayor 1');
      expect(v.fotoUrl, 'https://example.com/ana.png');
      expect(v.conductorHabilitado, isTrue);
    });

    test('keeps optional fields null when absent in the payload', () {
      final json = _baseJson();
      json.remove('dni');
      json.remove('email');
      json.remove('direccion');
      json.remove('foto_url');
      json.remove('keycloak_id');

      final v = VoluntarioModel.fromJson(json);

      expect(v.dni, isNull);
      expect(v.email, isNull);
      expect(v.direccion, isNull);
      expect(v.fotoUrl, isNull);
      expect(v.keycloakId, isNull);
    });

    test('parses fecha_baja when present', () {
      final json = _baseJson();
      json['fecha_baja'] = '2025-06-01';

      final v = VoluntarioModel.fromJson(json);

      expect(v.fechaBaja, DateTime(2025, 6, 1));
    });

    test('throws FormatException on unknown estado wire value', () {
      final json = _baseJson();
      json['estado'] = 'unknown';

      expect(
        () => VoluntarioModel.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
