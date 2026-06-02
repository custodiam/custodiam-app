// Stub del mapa para targets sin mapa nativo (tests VM, desktop). No
// renderiza un mapa real; muestra un marcador de posición accesible.
// El picker degrada a la alternativa no-mapa (campo de texto + lat/lng).

import 'package:flutter/material.dart';

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
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Text('Mapa no disponible en esta plataforma'),
      ),
    );
  }
}
