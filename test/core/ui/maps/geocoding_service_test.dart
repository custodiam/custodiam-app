import 'package:custodiam/core/ui/maps/geocoding_service.dart';
import 'package:custodiam/core/ui/maps/map_point.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('nominatimReverseUri', () {
    test('builds the reverse endpoint with lat/lon and Spanish locale', () {
      final uri = nominatimReverseUri(const MapPoint(41.8708, -0.7895));

      expect(uri.scheme, 'https');
      expect(uri.host, 'nominatim.openstreetmap.org');
      expect(uri.path, '/reverse');
      expect(uri.queryParameters['format'], 'jsonv2');
      expect(uri.queryParameters['lat'], '41.8708');
      expect(uri.queryParameters['lon'], '-0.7895');
      expect(uri.queryParameters['accept-language'], 'es');
    });
  });

  group('parseNominatimAddress', () {
    test('extracts display_name', () {
      const body = '{"display_name":"Calle Mayor 1, Zuera, Zaragoza"}';
      expect(parseNominatimAddress(body), 'Calle Mayor 1, Zuera, Zaragoza');
    });

    test('returns null when display_name is missing or empty', () {
      expect(parseNominatimAddress('{"error":"Unable to geocode"}'), isNull);
      expect(parseNominatimAddress('{"display_name":"   "}'), isNull);
    });

    test('returns null on non-JSON body', () {
      expect(parseNominatimAddress('<html>nope</html>'), isNull);
    });
  });

  group('NominatimReverseGeocoder', () {
    late _MockClient client;
    late NominatimReverseGeocoder geocoder;

    setUp(() {
      client = _MockClient();
      geocoder = NominatimReverseGeocoder(client);
    });

    test('returns the address on 200', () async {
      when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
        (_) async => http.Response('{"display_name":"Plaza de España, Zaragoza"}', 200),
      );

      final result = await geocoder.direccionDe(const MapPoint(41.65, -0.88));

      expect(result, 'Plaza de España, Zaragoza');
      // Nominatim exige User-Agent identificable.
      final headers = verify(
        () => client.get(any(), headers: captureAny(named: 'headers')),
      ).captured.single as Map<String, String>;
      expect(headers['User-Agent'], isNotEmpty);
    });

    test('returns null on non-200', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('rate limited', 429));

      expect(await geocoder.direccionDe(const MapPoint(0, 0)), isNull);
    });

    test('returns null when the request throws (offline)', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('no network'));

      expect(await geocoder.direccionDe(const MapPoint(0, 0)), isNull);
    });
  });
}
