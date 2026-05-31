// Reverse-geocoding (coordenada → dirección legible) para el picker de
// ubicación. Stack diferenciado por plataforma (ADR-030):
//   - móvil: geocoder nativo del SO (paquete `geocoding`), gratis e
//     ilimitado. Vive en native_reverse_geocoder_io.dart, cargado por
//     conditional import para no arrastrar el plugin al build web.
//   - web: Nominatim (OSM público), sin key. Rate limit ~1 req/s, de
//     sobra para el puñado de personas que crean servicios.
//
// La sugerencia es best-effort: si falla (sin red, timeout, sin POI,
// rate limit), devolvemos null y el picker no bloquea (caso D del flujo).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'map_point.dart';
import 'native_reverse_geocoder.dart';

abstract class ReverseGeocoder {
  /// Dirección legible del punto, o `null` si no se pudo resolver.
  Future<String?> direccionDe(MapPoint point);
}

/// URL de la API reverse de Nominatim para un punto, en español.
Uri nominatimReverseUri(MapPoint point) => Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'format': 'jsonv2',
        'lat': point.lat.toString(),
        'lon': point.lng.toString(),
        'accept-language': 'es',
        'zoom': '18',
      },
    );

/// Extrae `display_name` de la respuesta jsonv2 de Nominatim. Devuelve
/// `null` si el cuerpo no es el objeto esperado o no trae dirección.
String? parseNominatimAddress(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final name = decoded['display_name'];
      if (name is String && name.trim().isNotEmpty) return name;
    }
  } catch (_) {
    // Cuerpo no-JSON o inesperado → sin sugerencia.
  }
  return null;
}

/// Reverse-geocoder de web vía Nominatim. Nominatim exige un User-Agent
/// identificable por su política de uso.
class NominatimReverseGeocoder implements ReverseGeocoder {
  final http.Client _client;

  const NominatimReverseGeocoder(this._client);

  @override
  Future<String?> direccionDe(MapPoint point) async {
    try {
      final resp = await _client.get(
        nominatimReverseUri(point),
        headers: const {'User-Agent': 'custodiam-app (proteccioncivil)'},
      );
      if (resp.statusCode != 200) return null;
      return parseNominatimAddress(resp.body);
    } catch (_) {
      return null;
    }
  }
}

/// Selecciona la implementación según plataforma: Nominatim en web,
/// geocoder nativo del SO en móvil. Inyectable para tests.
final reverseGeocoderProvider = Provider<ReverseGeocoder>((ref) {
  if (kIsWeb) {
    return NominatimReverseGeocoder(http.Client());
  }
  return createNativeReverseGeocoder();
});
