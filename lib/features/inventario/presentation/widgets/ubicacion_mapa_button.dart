// Botón "ver en el mapa" para la ubicación base de un material o vehículo.
//
// El detalle de inventario solo trae el FK de la ubicación, no sus
// coordenadas (estas viven en el catálogo de ubicaciones, E10), así que las
// resolvemos bajo demanda con [ubicacionPorIdProvider]. El botón solo aparece
// si la ubicación existe y tiene coordenadas; mientras carga, si la
// resolución falla o si la ubicación no tiene coordenadas, no se muestra nada
// — la fila de texto "Ubicación" de la ficha ya informa al usuario y "ver en
// el mapa" es una acción opcional que no debe romper la lectura de la ficha.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/maps/abrir_mapa_button.dart';
import '../viewmodels/ubicaciones_di.dart';

class UbicacionMapaButton extends ConsumerWidget {
  final String? ubicacionBaseId;

  /// Key reenviada al botón interno para que los tests lo localicen.
  final Key? buttonKey;

  const UbicacionMapaButton({
    super.key,
    required this.ubicacionBaseId,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ubicacionBaseId;
    if (id == null) return const SizedBox.shrink();
    return ref.watch(ubicacionPorIdProvider(id)).maybeWhen(
          data: (ubicacion) => ubicacion.tieneCoordenadas
              ? AbrirMapaButton(
                  buttonKey: buttonKey,
                  lat: ubicacion.lat!,
                  lng: ubicacion.lng!,
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        );
  }
}
