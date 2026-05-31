// Mapa interactivo en web con flutter_map y tiles CARTO Voyager (sin
// key, sin billing — ADR-030). Traduce entre MapPoint (neutro) y el
// LatLng de latlong2 en el borde. Tap en el mapa notifica el punto.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:material_symbols_icons/symbols.dart';

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
    final theme = Theme.of(context);
    return FlutterMap(
      options: MapOptions(
        initialCenter: ll.LatLng(center.lat, center.lng),
        initialZoom: 15,
        onTap: (_, point) => onTap(MapPoint(point.latitude, point.longitude)),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'es.custodiam.app',
        ),
        if (marker != null)
          MarkerLayer(
            markers: [
              Marker(
                point: ll.LatLng(marker!.lat, marker!.lng),
                width: 40,
                height: 40,
                alignment: Alignment.topCenter,
                child: Icon(
                  Symbols.location_on,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
