import 'package:custodiam/features/servicios/domain/entities/servicio_create.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:flutter_test/flutter_test.dart';

ServicioCreate _base({double? lat, double? lng}) => ServicioCreate(
      titulo: 'Preventivo',
      tipo: TipoServicio.preventivo,
      fechaInicio: DateTime.utc(2026, 6, 10, 8),
      ubicacion: 'Zuera',
      ubicacionLat: lat,
      ubicacionLng: lng,
    );

void main() {
  group('ServicioCreate.toJson coordinates', () {
    test('includes ubicacion_lat/lng when both are present', () {
      final json = _base(lat: 41.8708, lng: -0.7895).toJson();

      expect(json['ubicacion_lat'], 41.8708);
      expect(json['ubicacion_lng'], -0.7895);
      expect(json['ubicacion'], 'Zuera');
    });

    test('omits coordinates when absent (text-only service)', () {
      final json = _base().toJson();

      expect(json.containsKey('ubicacion_lat'), isFalse);
      expect(json.containsKey('ubicacion_lng'), isFalse);
    });

    test('omits coordinates if only one is present (backend needs both)', () {
      expect(_base(lat: 41.0).toJson().containsKey('ubicacion_lat'), isFalse);
      expect(_base(lng: -0.8).toJson().containsKey('ubicacion_lng'), isFalse);
    });
  });
}
