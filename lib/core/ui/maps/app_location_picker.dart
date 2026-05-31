// AppLocationPicker (guía 27 §5.20): elegir/editar la ubicación de un
// servicio sobre un mapa, devolviendo coordenadas exactas + una etiqueta
// de dirección. Diferenciado por plataforma vía conditional import
// (google_maps_flutter en móvil, flutter_map+CARTO en web); aquí solo se
// orquesta la UI y el flujo de sugerencias (LocationPickerController).
//
// a11y (guía 28): el campo de texto es la alternativa no-mapa SIEMPRE
// válida (se puede confirmar sin tocar el mapa si ya hay coords, o
// cancelar y escribir solo texto). Las sugerencias se anuncian con
// SemanticsService.announce. El render del mapa es un canvas opaco: no
// se valida con meetsGuideline (excepción documentada).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../buttons/app_icon_button.dart';
import '../feedback/app_snackbar.dart';
import '../inputs/app_text_field.dart';
import '../tokens/app_spacing.dart';
import 'geocoding_service.dart';
import 'location_map.dart';
import 'location_pick_result.dart';
import 'location_picker_controller.dart';
import 'map_point.dart';

/// Centro por defecto cuando no hay GPS ni ubicación previa: Zaragoza
/// (sede del piloto, Protección Civil Bajo Gállego). La sede configurable
/// de la agrupación es un enabler aparte.
const MapPoint _centroAragon = MapPoint(41.6488, -0.8891);

/// Abre el picker a pantalla completa. Devuelve `null` si se cancela.
/// [inicial] preselecciona el marcador (edición de un servicio que ya
/// tiene coordenadas); [textoInicial] es la etiqueta de ubicación actual.
Future<LocationPickResult?> showAppLocationPicker(
  BuildContext context,
  WidgetRef ref, {
  MapPoint? inicial,
  String textoInicial = '',
}) {
  final geocoder = ref.read(reverseGeocoderProvider);
  return Navigator.of(context).push<LocationPickResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _LocationPickerPage(
        geocoder: geocoder,
        inicial: inicial,
        textoInicial: textoInicial,
      ),
    ),
  );
}

class _LocationPickerPage extends StatefulWidget {
  final ReverseGeocoder geocoder;
  final MapPoint? inicial;
  final String textoInicial;

  const _LocationPickerPage({
    required this.geocoder,
    required this.inicial,
    required this.textoInicial,
  });

  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  late final LocationPickerController _controller;
  late final TextEditingController _textCtrl;
  MapPoint? _center;
  bool _resolviendoCentro = true;

  @override
  void initState() {
    super.initState();
    _controller = LocationPickerController(
      geocoder: widget.geocoder,
      textoInicial: widget.textoInicial,
      puntoInicial: widget.inicial,
    );
    _textCtrl = TextEditingController(text: widget.textoInicial);
    _controller.addListener(_sincronizarTexto);
    _textCtrl.addListener(_sincronizarControlador);
    _resolverCentro();
  }

  @override
  void dispose() {
    _controller.removeListener(_sincronizarTexto);
    _textCtrl.removeListener(_sincronizarControlador);
    _controller.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  /// Refleja en el campo los cambios que hace el controller (autorelleno
  /// del caso A, aceptar sugerencia). La guarda evita pisar la edición
  /// manual y rompe el ciclo con [_sincronizarControlador].
  void _sincronizarTexto() {
    if (_textCtrl.text != _controller.texto) {
      _textCtrl.value = TextEditingValue(
        text: _controller.texto,
        selection: TextSelection.collapsed(offset: _controller.texto.length),
      );
    }
  }

  /// Propaga al controller lo que el usuario teclea en el campo.
  void _sincronizarControlador() {
    if (_controller.texto != _textCtrl.text) {
      _controller.editarTexto(_textCtrl.text);
    }
  }

  Future<void> _resolverCentro() async {
    if (widget.inicial != null) {
      setState(() {
        _center = widget.inicial;
        _resolviendoCentro = false;
      });
      return;
    }
    final gps = await _intentarGps();
    if (!mounted) return;
    setState(() {
      _center = gps ?? _centroAragon;
      _resolviendoCentro = false;
    });
  }

  /// Lee la posición actual con permiso "en uso". Devuelve null si el
  /// usuario lo deniega o si falla (no bloquea: caemos al centro por
  /// defecto y el usuario coloca el marcador a mano).
  Future<MapPoint?> _intentarGps() async {
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition();
      return MapPoint(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  void _confirmar() {
    final resultado = _controller.construirResultado();
    if (resultado == null) {
      AppSnackbar.show(
        context,
        message: 'Toca el mapa para fijar la ubicación.',
        variant: AppSnackbarVariant.warning,
      );
      return;
    }
    Navigator.of(context).pop(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegir ubicación'),
        actions: [
          AppIconButton(
            key: const ValueKey('location_picker_confirmar'),
            tooltip: 'Confirmar ubicación',
            icon: Symbols.check,
            onPressed: _confirmar,
          ),
        ],
      ),
      body: _resolviendoCentro
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) => LocationMap(
                      center: _center!,
                      marker: _controller.point,
                      onTap: (p) => _controller.moverMarcador(p),
                    ),
                  ),
                ),
                _PanelInferior(
                  controller: _controller,
                  textController: _textCtrl,
                  onRecargar: _controller.recargarSugerencia,
                  onAceptarSugerencia: _controller.aceptarSugerencia,
                  onDescartarSugerencia: _controller.descartarSugerencia,
                  onConfirmar: _confirmar,
                ),
              ],
            ),
    );
  }
}

class _PanelInferior extends StatelessWidget {
  final LocationPickerController controller;
  final TextEditingController textController;
  final Future<void> Function() onRecargar;
  final VoidCallback onAceptarSugerencia;
  final VoidCallback onDescartarSugerencia;
  final VoidCallback onConfirmar;

  const _PanelInferior({
    required this.controller,
    required this.textController,
    required this.onRecargar,
    required this.onAceptarSugerencia,
    required this.onDescartarSugerencia,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final sugerencia = controller.sugerenciaPendiente;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    key: const ValueKey('location_picker_direccion'),
                    label: 'Dirección',
                    controller: textController,
                    prefixIcon: Symbols.location_on,
                  ),
                  if (controller.point != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Lat ${controller.point!.lat.toStringAsFixed(5)}, '
                            'Lng ${controller.point!.lng.toStringAsFixed(5)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        AppIconButton(
                          key: const ValueKey('location_picker_recargar'),
                          tooltip: 'Recargar dirección sugerida del punto',
                          icon: Symbols.refresh,
                          onPressed: controller.cargandoSugerencia
                              ? null
                              : () => onRecargar(),
                        ),
                      ],
                    ),
                  ],
                  if (controller.cargandoSugerencia)
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: LinearProgressIndicator(),
                    ),
                  if (sugerencia != null)
                    _SugerenciaBanner(
                      sugerencia: sugerencia,
                      onUsar: onAceptarSugerencia,
                      onMantener: onDescartarSugerencia,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    key: const ValueKey('location_picker_confirmar_btn'),
                    onPressed: controller.puedeConfirmar ? onConfirmar : null,
                    icon: const Icon(Symbols.check),
                    label: const Text('Confirmar ubicación'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SugerenciaBanner extends StatelessWidget {
  final String sugerencia;
  final VoidCallback onUsar;
  final VoidCallback onMantener;

  const _SugerenciaBanner({
    required this.sugerencia,
    required this.onUsar,
    required this.onMantener,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // liveRegion: el lector de pantalla anuncia la sugerencia en
          // cuanto aparece (sustituye al SemanticsService.announce, ahora
          // deprecado, y cumple la a11y del flujo B).
          Semantics(
            liveRegion: true,
            child: Text(
              'Dirección sugerida del punto: $sugerencia',
              style: theme.textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 2),
          Text(sugerencia, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const ValueKey('location_picker_mantener'),
                onPressed: onMantener,
                child: const Text('Mantener mi texto'),
              ),
              const SizedBox(width: AppSpacing.xs),
              FilledButton(
                key: const ValueKey('location_picker_usar_sugerencia'),
                onPressed: onUsar,
                child: const Text('Usar sugerencia'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
