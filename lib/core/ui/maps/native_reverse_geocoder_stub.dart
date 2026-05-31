// Stub del reverse-geocoder nativo para targets sin `dart:io` (web,
// donde el provider usa Nominatim en su lugar). No debería instanciarse
// en runtime; si ocurre, devuelve siempre `null` (sin sugerencia).

import 'geocoding_service.dart';
import 'map_point.dart';

ReverseGeocoder createNativeReverseGeocoder() => const _NullReverseGeocoder();

class _NullReverseGeocoder implements ReverseGeocoder {
  const _NullReverseGeocoder();

  @override
  Future<String?> direccionDe(MapPoint point) async => null;
}
