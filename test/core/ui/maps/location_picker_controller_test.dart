import 'package:custodiam/core/ui/maps/geocoding_service.dart';
import 'package:custodiam/core/ui/maps/location_picker_controller.dart';
import 'package:custodiam/core/ui/maps/map_point.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGeocoder implements ReverseGeocoder {
  _FakeGeocoder(this.respuesta);
  String? respuesta;
  MapPoint? ultimoPunto;
  int llamadas = 0;

  @override
  Future<String?> direccionDe(MapPoint point) async {
    llamadas++;
    ultimoPunto = point;
    return respuesta;
  }
}

void main() {
  const punto = MapPoint(41.65, -0.88);

  group('moverMarcador', () {
    test('caso A: con el texto vacío autorellena con la sugerencia', () async {
      final geo = _FakeGeocoder('Plaza del Pilar, Zaragoza');
      final c = LocationPickerController(geocoder: geo);

      await c.moverMarcador(punto);

      expect(c.point, punto);
      expect(c.texto, 'Plaza del Pilar, Zaragoza');
      expect(c.sugerenciaPendiente, isNull);
      expect(c.cargandoSugerencia, isFalse);
    });

    test('caso B: con texto del usuario no sobrescribe, deja pendiente',
        () async {
      final geo = _FakeGeocoder('Plaza del Pilar, Zaragoza');
      final c = LocationPickerController(
        geocoder: geo,
        textoInicial: 'Entrada lateral del polideportivo',
      );

      await c.moverMarcador(punto);

      expect(c.texto, 'Entrada lateral del polideportivo');
      expect(c.sugerenciaPendiente, 'Plaza del Pilar, Zaragoza');
    });

    test('caso D: si el geocoder falla, conserva coords y no sugiere',
        () async {
      final geo = _FakeGeocoder(null);
      final c = LocationPickerController(geocoder: geo);

      await c.moverMarcador(punto);

      expect(c.point, punto);
      expect(c.texto, '');
      expect(c.sugerenciaPendiente, isNull);
      expect(c.puedeConfirmar, isTrue);
    });
  });

  group('sugerencia pendiente', () {
    test('aceptarSugerencia copia la sugerencia al texto', () async {
      final geo = _FakeGeocoder('Av. de Cataluña 5');
      final c = LocationPickerController(geocoder: geo, textoInicial: 'algo');
      await c.moverMarcador(punto);

      c.aceptarSugerencia();

      expect(c.texto, 'Av. de Cataluña 5');
      expect(c.sugerenciaPendiente, isNull);
    });

    test('descartarSugerencia mantiene el texto del usuario', () async {
      final geo = _FakeGeocoder('Av. de Cataluña 5');
      final c = LocationPickerController(geocoder: geo, textoInicial: 'algo');
      await c.moverMarcador(punto);

      c.descartarSugerencia();

      expect(c.texto, 'algo');
      expect(c.sugerenciaPendiente, isNull);
    });
  });

  group('caso C: recargarSugerencia', () {
    test('vuelve a geocodificar el punto actual', () async {
      final geo = _FakeGeocoder('Calle A');
      final c = LocationPickerController(geocoder: geo, textoInicial: 'mi sitio');
      await c.moverMarcador(punto);
      expect(geo.llamadas, 1);

      geo.respuesta = 'Calle B';
      await c.recargarSugerencia();

      expect(geo.llamadas, 2);
      expect(c.sugerenciaPendiente, 'Calle B');
    });

    test('no hace nada sin punto seleccionado', () async {
      final geo = _FakeGeocoder('x');
      final c = LocationPickerController(geocoder: geo);

      await c.recargarSugerencia();

      expect(geo.llamadas, 0);
    });
  });

  group('construirResultado', () {
    test('null si no hay punto', () {
      final c = LocationPickerController(geocoder: _FakeGeocoder(null));
      expect(c.construirResultado(), isNull);
      expect(c.puedeConfirmar, isFalse);
    });

    test('devuelve lat/lng y la dirección recortada', () async {
      final geo = _FakeGeocoder('  Calle Mayor  ');
      final c = LocationPickerController(geocoder: geo);
      await c.moverMarcador(punto);

      final r = c.construirResultado()!;
      expect(r.lat, 41.65);
      expect(r.lng, -0.88);
      expect(r.direccion, 'Calle Mayor');
    });

    test('direccion null cuando el texto queda vacío', () {
      final c = LocationPickerController(
        geocoder: _FakeGeocoder(null),
        puntoInicial: punto,
      );
      expect(c.construirResultado()!.direccion, isNull);
    });
  });
}
