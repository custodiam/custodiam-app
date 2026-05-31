// Apertura de mapas externos (Corte 1 de geolocalización, ADR-030).
//
// La consistencia de la ubicación la garantiza el modelo de datos
// (lat/lng exactas en BD); aquí solo se abre la app/navegador externos
// con un deeplink universal, sin proveedor de tiles propio ni API key.
//
// La construcción de la URL se separa de la invocación: las funciones
// `mapsDirectionsUri`/`mapsShowUri` son puras y testeables, y
// [MapsLauncher] (inyectado vía [mapsLauncherProvider]) encapsula la
// llamada a `url_launcher` para poder sustituirlo en tests.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Deeplink universal de "cómo llegar": direcciones hacia el destino.
/// La app de mapas del dispositivo (Google Maps, Apple Maps, Waze)
/// resuelve el origen con el GPS, así que no necesitamos `geolocator`.
/// Si no hay app instalada, `url_launcher` cae al navegador.
Uri mapsDirectionsUri(double lat, double lng) => Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

/// Deeplink universal de "ver en el mapa": centra el mapa en el punto.
/// En escritorio/web abre el navegador (no hay GPS que enrutar).
Uri mapsShowUri(double lat, double lng) => Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

/// Abre una URL de mapa en la app/navegador externos. Thin wrapper sobre
/// `url_launcher`; se inyecta para que los tests capturen la URL sin
/// tocar plugins de plataforma.
class MapsLauncher {
  const MapsLauncher();

  /// Devuelve `false` si la plataforma no pudo abrir la URL; lanza si el
  /// plugin falla. El llamante decide cómo avisar al usuario.
  Future<bool> abrir(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

final mapsLauncherProvider = Provider<MapsLauncher>(
  (ref) => const MapsLauncher(),
);
