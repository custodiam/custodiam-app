// Widget de mapa interactivo con conditional import (ADR-030):
//   - móvil (dart.library.io)        → google_maps_flutter
//   - web   (dart.library.js_interop) → flutter_map + tiles CARTO
//   - resto/tests                     → stub (placeholder, no plataforma)
//
// Todas las variantes exponen la MISMA API (`LocationMap`) hablando en
// MapPoint, de modo que el picker es agnóstico del proveedor. El render
// real no se testea (canvas opaco); en tests se mockea a nivel superior.

export 'location_map_stub.dart'
    if (dart.library.io) 'location_map_io.dart'
    if (dart.library.js_interop) 'location_map_web.dart';
