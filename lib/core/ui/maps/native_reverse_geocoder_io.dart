// Reverse-geocoder nativo para móvil: usa los servicios del SO vía el
// paquete `geocoding` (Geocoder en Android, CLGeocoder en iOS). Gratis,
// sin key. En Android depende de Google Play Services; si no están, la
// llamada falla y devolvemos null (el picker no bloquea — caso D).

import 'package:geocoding/geocoding.dart';

import 'geocoding_service.dart';
import 'map_point.dart';

ReverseGeocoder createNativeReverseGeocoder() => const NativeReverseGeocoder();

class NativeReverseGeocoder implements ReverseGeocoder {
  const NativeReverseGeocoder();

  @override
  Future<String?> direccionDe(MapPoint point) async {
    try {
      final placemarks = await placemarkFromCoordinates(point.lat, point.lng);
      if (placemarks.isEmpty) return null;
      return _formatear(placemarks.first);
    } catch (_) {
      return null;
    }
  }

  /// Construye una dirección legible a partir de los campos no vacíos del
  /// placemark, en orden calle → localidad → región.
  String? _formatear(Placemark p) {
    final partes = <String?>[
      [p.street, p.subThoroughfare].where(_lleno).join(' '),
      p.locality,
      p.subAdministrativeArea,
      p.administrativeArea,
    ].where(_lleno).cast<String>().toList();
    if (partes.isEmpty) return null;
    return partes.join(', ');
  }

  bool _lleno(String? s) => s != null && s.trim().isNotEmpty;
}
