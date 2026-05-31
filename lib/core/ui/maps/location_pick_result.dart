// Resultado de elegir una ubicación en el AppLocationPicker: la
// coordenada exacta (fuente de verdad en BD) y, opcionalmente, una
// etiqueta de dirección legible para mostrar y guardar como texto.

import 'package:flutter/foundation.dart';

@immutable
class LocationPickResult {
  final double lat;
  final double lng;
  final String? direccion;

  const LocationPickResult({
    required this.lat,
    required this.lng,
    this.direccion,
  });

  @override
  bool operator ==(Object other) =>
      other is LocationPickResult &&
      other.lat == lat &&
      other.lng == lng &&
      other.direccion == direccion;

  @override
  int get hashCode => Object.hash(lat, lng, direccion);
}
