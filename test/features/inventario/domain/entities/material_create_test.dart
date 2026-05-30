import 'package:custodiam/features/inventario/domain/entities/material_create.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MaterialCreate.toJson (PR2)', () {
    test('manda ubicacion_base_id y ubicacion_base cuando se indican', () {
      final json = const MaterialCreate(
        nombre: 'Casco',
        tipo: TipoMaterial.prestable,
        ubicacionBase: 'Base Zuera',
        ubicacionBaseId: 'u-1',
      ).toJson();

      expect(json['ubicacion_base'], 'Base Zuera');
      expect(json['ubicacion_base_id'], 'u-1');
    });

    test('omite los campos de ubicación cuando son null', () {
      final json = const MaterialCreate(
        nombre: 'Casco',
        tipo: TipoMaterial.prestable,
      ).toJson();

      expect(json.containsKey('ubicacion_base'), isFalse);
      expect(json.containsKey('ubicacion_base_id'), isFalse);
    });
  });
}
