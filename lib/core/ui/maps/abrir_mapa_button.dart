// Botón "ver en el mapa" / "cómo llegar" para un punto con coordenadas
// (Corte 1 de geolocalización, ADR-030). Reutilizable: la ficha de servicio
// lo usa con las coordenadas del propio servicio, y las fichas de inventario
// con las de la ubicación del catálogo. La lógica de elegir el deeplink
// (escritorio/web → mostrar el punto; móvil → ruta navegable que la app de
// mapas enruta desde el GPS) y de avisar si falla vive aquí una sola vez.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../buttons/app_secondary_button.dart';
import '../feedback/app_snackbar.dart';
import '../tokens/app_spacing.dart';
import 'maps_launcher.dart';

class AbrirMapaButton extends ConsumerWidget {
  final double? lat;
  final double? lng;

  /// Dirección textual de respaldo (Opción 3): si no hay coordenadas pero sí
  /// texto, la ruta/búsqueda se resuelve por el texto, que la app de mapas
  /// geocodifica. Cuando hay coordenadas, mandan ellas (ADR-030).
  final String? texto;

  /// Key del botón en sí, para que los tests lo localicen con precisión
  /// (la key del widget raíz caería sobre el `Align`, no sobre el botón).
  final Key? buttonKey;

  const AbrirMapaButton({
    super.key,
    this.lat,
    this.lng,
    this.texto,
    this.buttonKey,
  }) : assert(
          (lat != null && lng != null) || (texto != null && texto != ''),
          'AbrirMapaButton necesita coordenadas o un texto de dirección',
        );

  bool get _tieneCoords => lat != null && lng != null;

  Future<void> _abrir(BuildContext context, WidgetRef ref, bool esWeb) async {
    final launcher = ref.read(mapsLauncherProvider);
    final Uri uri;
    if (_tieneCoords) {
      uri = esWeb ? mapsShowUri(lat!, lng!) : mapsDirectionsUri(lat!, lng!);
    } else {
      uri = esWeb ? mapsShowUriTexto(texto!) : mapsDirectionsUriTexto(texto!);
    }
    var ok = false;
    try {
      ok = await launcher.abrir(uri);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      AppSnackbar.show(
        context,
        message: 'No se pudo abrir el mapa.',
        variant: AppSnackbarVariant.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // En escritorio/web solo "ver en el mapa"; en móvil, ruta navegable
    // que la app de mapas enruta desde el GPS del usuario (ADR-030 §2).
    const esWeb = kIsWeb;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AppSecondaryButton(
          key: buttonKey,
          label: esWeb ? 'Ver en el mapa' : 'Cómo llegar',
          icon: esWeb ? Symbols.map : Symbols.directions,
          onPressed: () => _abrir(context, ref, esWeb),
        ),
      ),
    );
  }
}
