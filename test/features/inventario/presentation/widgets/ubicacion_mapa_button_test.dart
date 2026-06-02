// Widget tests de UbicacionMapaButton: resuelve la ubicación base de un
// material/vehículo por id y muestra el botón "ver en el mapa" solo si la
// ubicación existe y tiene coordenadas. Cubre las cinco ramas: id ausente,
// carga en curso, fallo de resolución, ubicación sin coordenadas y ubicación
// con coordenadas (única que pinta el botón y lanza el deeplink).

import 'dart:async';

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/maps/maps_launcher.dart';
import 'package:custodiam/features/inventario/domain/entities/ubicacion.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/ubicaciones_di.dart';
import 'package:custodiam/features/inventario/presentation/widgets/ubicacion_mapa_button.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_utils/test_app.dart';

const _conCoords = Ubicacion(id: 'u-1', nombre: 'Base 1', lat: 41.0, lng: -0.5);
const _sinCoords = Ubicacion(id: 'u-2', nombre: 'Oficina');

class _FakeMapsLauncher extends MapsLauncher {
  _FakeMapsLauncher(this.captured);
  final List<Uri> captured;
  @override
  Future<bool> abrir(Uri uri) async {
    captured.add(uri);
    return true;
  }
}

void main() {
  testWidgets('id de ubicación nulo: no muestra el botón', (tester) async {
    await pumpRiverpod(
      tester,
      const UbicacionMapaButton(
        ubicacionBaseId: null,
        buttonKey: K.materialFichaAbrirMapaBtn,
      ),
    );

    expect(find.byKey(K.materialFichaAbrirMapaBtn), findsNothing);
  });

  testWidgets(
      'ubicación con coordenadas: muestra el botón y lanza el deeplink',
      (tester) async {
    final capturadas = <Uri>[];
    await pumpRiverpod(
      tester,
      const UbicacionMapaButton(
        ubicacionBaseId: 'u-1',
        buttonKey: K.materialFichaAbrirMapaBtn,
      ),
      overrides: [
        ubicacionPorIdProvider.overrideWith((ref, id) async => _conCoords),
        mapsLauncherProvider.overrideWithValue(_FakeMapsLauncher(capturadas)),
      ],
    );

    final boton = find.byKey(K.materialFichaAbrirMapaBtn);
    expect(boton, findsOneWidget);

    await tester.tap(boton);
    await tester.pumpAndSettle();

    expect(capturadas.single, mapsDirectionsUri(41.0, -0.5));
  });

  testWidgets('ubicación sin coordenadas: no muestra el botón',
      (tester) async {
    await pumpRiverpod(
      tester,
      const UbicacionMapaButton(
        ubicacionBaseId: 'u-2',
        buttonKey: K.materialFichaAbrirMapaBtn,
      ),
      overrides: [
        ubicacionPorIdProvider.overrideWith((ref, id) async => _sinCoords),
      ],
    );

    expect(find.byKey(K.materialFichaAbrirMapaBtn), findsNothing);
  });

  testWidgets('mientras la ubicación carga: no muestra el botón',
      (tester) async {
    final completer = Completer<Ubicacion>();
    await pumpRiverpod(
      tester,
      const UbicacionMapaButton(
        ubicacionBaseId: 'u-1',
        buttonKey: K.materialFichaAbrirMapaBtn,
      ),
      settle: false,
      overrides: [
        ubicacionPorIdProvider.overrideWith((ref, id) => completer.future),
      ],
    );

    expect(find.byKey(K.materialFichaAbrirMapaBtn), findsNothing);

    // Completa el future pendiente para no dejar timers vivos al cerrar.
    completer.complete(_conCoords);
    await tester.pumpAndSettle();
  });

  testWidgets('si la resolución de la ubicación falla: no muestra el botón',
      (tester) async {
    await pumpRiverpod(
      tester,
      const UbicacionMapaButton(
        ubicacionBaseId: 'u-1',
        buttonKey: K.materialFichaAbrirMapaBtn,
      ),
      overrides: [
        ubicacionPorIdProvider
            .overrideWith((ref, id) async => throw Exception('boom')),
      ],
    );

    expect(find.byKey(K.materialFichaAbrirMapaBtn), findsNothing);
  });
}
