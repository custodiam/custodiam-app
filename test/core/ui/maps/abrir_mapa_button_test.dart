// Widget tests de AbrirMapaButton: el botón reutilizable de "ver en el mapa"
// extraído de la ficha de servicio. Cubre el lanzamiento del deeplink en
// móvil (la VM corre con kIsWeb == false → ruta navegable) y el aviso de
// error cuando el launcher no puede abrir la app de mapas.

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/maps/abrir_mapa_button.dart';
import 'package:custodiam/core/ui/maps/maps_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

/// Captura las URLs en lugar de abrir mapas reales y simula el resultado.
class _FakeMapsLauncher extends MapsLauncher {
  _FakeMapsLauncher({List<Uri>? captured, this.result = true})
      : captured = captured ?? <Uri>[];

  final List<Uri> captured;
  final bool result;

  @override
  Future<bool> abrir(Uri uri) async {
    captured.add(uri);
    return result;
  }
}

/// Simula un plugin de plataforma que lanza al intentar abrir la URL.
class _ThrowingMapsLauncher extends MapsLauncher {
  @override
  Future<bool> abrir(Uri uri) async => throw Exception('plugin failure');
}

void main() {
  testWidgets(
      'en móvil muestra "Cómo llegar" y lanza el deeplink de direcciones',
      (tester) async {
    final launcher = _FakeMapsLauncher();
    await pumpRiverpod(
      tester,
      const AbrirMapaButton(
        lat: 41.8708,
        lng: -0.7895,
        buttonKey: K.servicioFichaAbrirMapaBtn,
      ),
      overrides: [
        mapsLauncherProvider.overrideWithValue(launcher),
      ],
    );

    expect(find.text('Cómo llegar'), findsOneWidget);

    await tester.tap(find.byKey(K.servicioFichaAbrirMapaBtn));
    await tester.pumpAndSettle();

    expect(launcher.captured, hasLength(1));
    expect(launcher.captured.single, mapsDirectionsUri(41.8708, -0.7895));
  });

  testWidgets('si el launcher devuelve false avisa con un SnackBar de error',
      (tester) async {
    await pumpRiverpod(
      tester,
      const AbrirMapaButton(
        lat: 0,
        lng: 0,
        buttonKey: K.servicioFichaAbrirMapaBtn,
      ),
      overrides: [
        mapsLauncherProvider
            .overrideWithValue(_FakeMapsLauncher(result: false)),
      ],
    );

    await tester.tap(find.byKey(K.servicioFichaAbrirMapaBtn));
    await tester.pump(); // resuelve el future de abrir()
    await tester.pump(); // monta el SnackBar

    expect(find.text('No se pudo abrir el mapa.'), findsOneWidget);
  });

  testWidgets('si el launcher lanza una excepción también avisa con SnackBar',
      (tester) async {
    await pumpRiverpod(
      tester,
      const AbrirMapaButton(
        lat: 0,
        lng: 0,
        buttonKey: K.servicioFichaAbrirMapaBtn,
      ),
      overrides: [
        mapsLauncherProvider.overrideWithValue(_ThrowingMapsLauncher()),
      ],
    );

    await tester.tap(find.byKey(K.servicioFichaAbrirMapaBtn));
    await tester.pump();
    await tester.pump();

    expect(find.text('No se pudo abrir el mapa.'), findsOneWidget);
  });
}
