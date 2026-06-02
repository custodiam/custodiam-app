import 'package:custodiam/core/ui/maps/maps_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapsDirectionsUri', () {
    test('builds a universal directions deeplink to the destination', () {
      final uri = mapsDirectionsUri(41.8708, -0.7895);

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], '41.8708,-0.7895');
      // El origen lo resuelve la app de mapas con el GPS: no lo enviamos.
      expect(uri.queryParameters.containsKey('origin'), isFalse);
    });
  });

  group('mapsShowUri', () {
    test('builds a universal search deeplink centred on the point', () {
      final uri = mapsShowUri(41.8708, -0.7895);

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['query'], '41.8708,-0.7895');
    });

    test('keeps negative and zero coordinates intact', () {
      final uri = mapsShowUri(0, -3.0);
      expect(uri.queryParameters['query'], '0.0,-3.0');
    });
  });

  group('variantes por texto (Opción 3)', () {
    test('mapsDirectionsUriTexto enruta por la dirección escrita', () {
      final uri = mapsDirectionsUriTexto('Pabellón municipal, Zuera');

      expect(uri.path, '/maps/dir/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['destination'], 'Pabellón municipal, Zuera');
    });

    test('mapsShowUriTexto busca la dirección escrita', () {
      final uri = mapsShowUriTexto('Calle Mayor 1 & 2');

      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters['query'], 'Calle Mayor 1 & 2');
    });
  });
}
