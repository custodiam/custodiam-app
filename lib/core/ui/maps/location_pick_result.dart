// Resultado de elegir una ubicación en el AppLocationPicker. Puede ser:
//  - punto + etiqueta: coordenadas exactas (fuente de verdad en BD) más la
//    dirección legible (reverse-geocodificada o escrita por el usuario), que
//    SIEMPRE describen el mismo lugar (coherencia forzada en el controller);
//  - solo texto: el usuario escribió una dirección libre sin fijar punto, así
//    que `lat`/`lng` son null y la ruta se resolverá por búsqueda del texto.

import 'package:flutter/foundation.dart';

@immutable
class LocationPickResult {
  final double? lat;
  final double? lng;
  final String? direccion;

  const LocationPickResult({
    this.lat,
    this.lng,
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
