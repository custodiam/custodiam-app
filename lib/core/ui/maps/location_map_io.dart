// Mapa interactivo en móvil con google_maps_flutter (Maps SDK Android/
// iOS). Traduce entre MapPoint (neutro) y LatLng de Google en el borde.
// El marcador es arrastrable; tap o arrastre notifican el nuevo punto.

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'map_point.dart';

class LocationMap extends StatelessWidget {
  final MapPoint center;
  final MapPoint? marker;
  final void Function(MapPoint point) onTap;

  const LocationMap({
    super.key,
    required this.center,
    required this.marker,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(center.lat, center.lng),
        zoom: 15,
      ),
      onTap: (pos) => onTap(MapPoint(pos.latitude, pos.longitude)),
      markers: {
        if (marker != null)
          gmaps.Marker(
            markerId: const gmaps.MarkerId('seleccion'),
            position: gmaps.LatLng(marker!.lat, marker!.lng),
            draggable: true,
            onDragEnd: (pos) => onTap(MapPoint(pos.latitude, pos.longitude)),
          ),
      },
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
    );
  }
}
