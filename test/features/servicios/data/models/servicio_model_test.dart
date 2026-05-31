import 'package:custodiam/features/servicios/data/models/servicio_model.dart';
import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({Object? lat, Object? lng}) {
  return {
    'id': 'id-1',
    'titulo': 'Preventivo carrera',
    'descripcion': 'Carrera popular',
    'tipo': 'preventivo',
    'estado': 'publicado',
    'fecha_inicio': '2026-06-10T08:00:00',
    'fecha_fin': '2026-06-10T14:00:00',
    'ubicacion': 'Zuera',
    'ubicacion_lat': lat,
    'ubicacion_lng': lng,
    'numero_voluntarios': 12,
    'inscritos_count': 0,
    'notas_material': null,
    'notas_vehiculos': null,
    'observaciones_cierre': null,
    'creado_por_keycloak_id': 'kc-1',
    'fecha_cierre': null,
    'created_at': '2026-05-27T10:00:00',
    'updated_at': '2026-05-27T10:00:00',
  };
}

void main() {
  group('ServicioModel.fromJson coordinates', () {
    test('maps ubicacion_lat/lng when present', () {
      final servicio = ServicioModel.fromJson(_row(lat: 41.8708, lng: -0.7895));

      expect(servicio.ubicacionLat, 41.8708);
      expect(servicio.ubicacionLng, -0.7895);
      // El resto del mapeo no se ve afectado.
      expect(servicio.ubicacion, 'Zuera');
      expect(servicio.tipo, TipoServicio.preventivo);
      expect(servicio.estado, EstadoServicio.publicado);
    });

    test('leaves coordinates null when the backend omits them', () {
      final servicio = ServicioModel.fromJson(_row());

      expect(servicio.ubicacionLat, isNull);
      expect(servicio.ubicacionLng, isNull);
    });

    test('coerces integer JSON numbers to double', () {
      // Un servicio justo en un meridiano/paralelo entero llega como int
      // en JSON; el mapper no debe petar con un cast directo a double.
      final servicio = ServicioModel.fromJson(_row(lat: 41, lng: 0));

      expect(servicio.ubicacionLat, 41.0);
      expect(servicio.ubicacionLng, 0.0);
    });
  });
}
