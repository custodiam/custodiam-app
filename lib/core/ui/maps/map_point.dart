// Punto geográfico neutro, independiente de google_maps_flutter (LatLng)
// y de latlong2 (LatLng). El AppLocationPicker habla en MapPoint y cada
// implementación de plataforma traduce a su tipo nativo en el borde, de
// modo que el resto de la app nunca importa un paquete de mapas.

import 'package:flutter/foundation.dart';

@immutable
class MapPoint {
  final double lat;
  final double lng;

  const MapPoint(this.lat, this.lng);

  @override
  bool operator ==(Object other) =>
      other is MapPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'MapPoint($lat, $lng)';
}
