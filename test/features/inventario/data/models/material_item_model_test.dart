import 'package:custodiam/features/inventario/data/models/material_item_model.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_asignacion.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fila base de detalle de material SIN los campos de trazabilidad — así
/// es como llega un material del listado (MaterialSummary no los lleva).
Map<String, dynamic> _materialRow() {
  return {
    'id': 'm-1',
    'nombre': 'Casco rojo',
    'descripcion': null,
    'codigo': 'CAS-001',
    'numero_serie': null,
    'tipo': 'personal',
    'categoria': 'EPI',
    'cantidad': 5,
    'ubicacion_base': 'Almacén 1',
    'fecha_adquisicion': null,
    'fecha_proxima_revision': null,
    'foto_url': null,
    'estado': 'operativo',
    'observaciones_incidencia': null,
    'created_at': '2026-05-27T10:00:00',
    'updated_at': '2026-05-27T10:00:00',
  };
}

void main() {
  group('MaterialItemModel.fromJson — trazabilidad (PR1)', () {
    test('parses asignaciones_activas + unidades_asignadas', () {
      final m = MaterialItemModel.fromJson({
        ..._materialRow(),
        'unidades_asignadas': 3,
        'asignaciones_activas': [
          {
            'tipo': 'personal',
            'voluntario_id': 'vol-1',
            'cantidad': 1,
            'fecha_asignacion': '2026-05-27T10:00:00',
          },
          {
            'tipo': 'servicio',
            'servicio_id': 'srv-2',
            'servicio_titulo': 'Romería 2026',
            'cantidad': 2,
            'fecha_asignacion': '2026-05-28T09:00:00',
          },
        ],
      });

      expect(m.unidadesAsignadas, 3);
      expect(m.asignacionesActivas, hasLength(2));
      expect(m.asignacionesActivas.first.tipo, TipoAsignacion.personal);
      expect(m.asignacionesActivas.first.voluntarioId, 'vol-1');
      expect(m.asignacionesActivas[1].servicioTitulo, 'Romería 2026');
    });

    test('defaults to empty list + 0 when the fields are absent (listado)', () {
      final m = MaterialItemModel.fromJson(_materialRow());

      expect(m.asignacionesActivas, isEmpty);
      expect(m.unidadesAsignadas, 0);
    });
  });

  group('MaterialItemModel.fromJson — ubicación (PR2)', () {
    test('parsea ubicacion_base cuando viene como texto', () {
      final m = MaterialItemModel.fromJson(_materialRow());
      expect(m.ubicacionBase, 'Almacén 1');
    });

    test('tolera ubicacion_base nulo (texto opcional tras PR2)', () {
      final m = MaterialItemModel.fromJson({
        ..._materialRow(),
        'ubicacion_base': null,
      });
      expect(m.ubicacionBase, isNull);
    });

    test('parsea ubicacion_base_id (FK del catálogo, E10)', () {
      final m = MaterialItemModel.fromJson({
        ..._materialRow(),
        'ubicacion_base_id': 'u-1',
      });
      expect(m.ubicacionBaseId, 'u-1');
    });

    test('tolera ubicacion_base_id ausente', () {
      final m = MaterialItemModel.fromJson(_materialRow());
      expect(m.ubicacionBaseId, isNull);
    });
  });
}
