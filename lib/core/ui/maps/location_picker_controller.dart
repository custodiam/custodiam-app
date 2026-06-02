// Lógica del AppLocationPicker, separada de la UI para poder testear el
// flujo de sugerencias (casos A–D de la decisión técnica de mapas) sin
// renderizar el mapa nativo:
//
//   A — campo vacío + mueves el marcador → autorellena con la sugerencia.
//   B — campo con texto + mueves el marcador → NO sobrescribe; deja la
//       sugerencia pendiente para que el usuario la acepte o la ignore.
//   C — recargar sugerencia → vuelve a geocodificar el punto actual.
//   D — el reverse-geocoding falla → no hay sugerencia, las coordenadas
//       se conservan y el picker no se bloquea.

import 'package:flutter/foundation.dart';

import 'geocoding_service.dart';
import 'map_point.dart';
import 'location_pick_result.dart';

class LocationPickerController extends ChangeNotifier {
  final ReverseGeocoder _geocoder;

  MapPoint? _point;
  String _texto;
  String? _sugerenciaPendiente;
  bool _cargandoSugerencia = false;

  LocationPickerController({
    required ReverseGeocoder geocoder,
    String textoInicial = '',
    MapPoint? puntoInicial,
  })  : _geocoder = geocoder,
        _texto = textoInicial,
        _point = puntoInicial;

  MapPoint? get point => _point;
  String get texto => _texto;
  String? get sugerenciaPendiente => _sugerenciaPendiente;
  bool get cargandoSugerencia => _cargandoSugerencia;
  // Opción 3: se puede confirmar con un punto fijado O con texto libre. Lo
  // único inválido es no tener ni punto ni texto.
  bool get puedeConfirmar => _point != null || _texto.trim().isNotEmpty;

  void editarTexto(String value) {
    _texto = value;
    // Opción 3 (coherencia forzada): editar el texto a mano lo convierte en la
    // fuente de verdad y suelta el punto, porque no hay forward-geocoding que
    // recoloque el marcador sobre el texto nuevo. Así el resultado nunca lleva
    // un punto y un texto que describan lugares distintos. Re-fijar el marcador
    // vuelve a establecer el punto (y reautorrellena el texto, caso A).
    _point = null;
    _sugerenciaPendiente = null;
    notifyListeners();
  }

  /// Mueve el marcador a [p] (tap o arrastre) y pide reverse-geocoding.
  /// Aplica los casos A/B/D según haya o no texto del usuario.
  Future<void> moverMarcador(MapPoint p) async {
    _point = p;
    _sugerenciaPendiente = null;
    _cargandoSugerencia = true;
    notifyListeners();

    final sugerencia = await _geocoder.direccionDe(p);

    _cargandoSugerencia = false;
    if (sugerencia == null) {
      notifyListeners(); // caso D: sin sugerencia, coords conservadas
      return;
    }
    if (_texto.trim().isEmpty) {
      _texto = sugerencia; // caso A: autorelleno
    } else {
      _sugerenciaPendiente = sugerencia; // caso B: ofrecer sin pisar
    }
    notifyListeners();
  }

  /// Caso C: vuelve a geocodificar el punto actual y ofrece la sugerencia
  /// aunque ya hubiera texto.
  Future<void> recargarSugerencia() async {
    final actual = _point;
    if (actual == null) return;
    _cargandoSugerencia = true;
    notifyListeners();
    final sugerencia = await _geocoder.direccionDe(actual);
    _cargandoSugerencia = false;
    if (sugerencia == null) {
      notifyListeners();
      return;
    }
    if (_texto.trim().isEmpty) {
      _texto = sugerencia;
    } else {
      _sugerenciaPendiente = sugerencia;
    }
    notifyListeners();
  }

  void aceptarSugerencia() {
    final s = _sugerenciaPendiente;
    if (s == null) return;
    _texto = s;
    _sugerenciaPendiente = null;
    notifyListeners();
  }

  void descartarSugerencia() {
    _sugerenciaPendiente = null;
    notifyListeners();
  }

  LocationPickResult? construirResultado() {
    final p = _point;
    final t = _texto.trim();
    // Inválido solo si no hay ni punto ni texto.
    if (p == null && t.isEmpty) return null;
    return LocationPickResult(
      lat: p?.lat,
      lng: p?.lng,
      direccion: t.isEmpty ? null : t,
    );
  }
}
