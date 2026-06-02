// AltaServicioPage (US-03-01 / US-03-02). Formulario para crear un
// servicio. El permiso a aplicar depende del tipo seleccionado; el
// gate de entrada acepta cualquiera de los dos (anyOf) para que el
// usuario al menos llegue, y validamos al enviar.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/maps/app_location_picker.dart';
import '../../../../core/ui/maps/map_point.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/tokens/app_breakpoints.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/servicio_create.dart';
import '../../domain/entities/tipo_servicio.dart';
import '../viewmodels/alta_servicio_view_model.dart';
import '../viewmodels/servicios_list_view_model.dart';

class AltaServicioPage extends ConsumerWidget {
  /// Tipo preseleccionado al abrir la página. Si `null`, arranca en
  /// `preventivo`. Se propaga desde el query param `?tipo=` del router
  /// para que la quick action "Crear emergencia" del home aterrice ya
  /// con `emergencia` marcado.
  final TipoServicio? tipoInicial;

  const AltaServicioPage({super.key, this.tipoInicial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPermissionGate.anyOf(
      anyOf: const [
        Permission.serviciosCrearPreventivo,
        Permission.serviciosCrearEmergencia,
      ],
      fallback: const _ForbiddenScreen(),
      child: _AltaServicioForm(tipoInicial: tipoInicial),
    );
  }
}

class _AltaServicioForm extends ConsumerStatefulWidget {
  final TipoServicio? tipoInicial;

  const _AltaServicioForm({this.tipoInicial});

  @override
  ConsumerState<_AltaServicioForm> createState() => _AltaServicioFormState();
}

class _AltaServicioFormState extends ConsumerState<_AltaServicioForm> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _numeroVoluntariosCtrl = TextEditingController();
  final _notasMaterialCtrl = TextEditingController();
  final _notasVehiculosCtrl = TextEditingController();
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();
  late TipoServicio _tipo = widget.tipoInicial ?? TipoServicio.preventivo;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  double? _ubicacionLat;
  double? _ubicacionLng;
  // Texto que corresponde a las coordenadas fijadas. Si el usuario edita el
  // campo de dirección y deja de coincidir, se sueltan las coords (coherencia
  // texto↔punto de la Opción 3): texto y coordenadas nunca describen lugares
  // distintos.
  String? _ubicacionTextoFijado;

  @override
  void initState() {
    super.initState();
    _ubicacionCtrl.addListener(_onUbicacionTextChanged);
  }

  /// Si hay coords fijadas y el usuario escribe un texto que ya no coincide
  /// con el de esas coords, las suelta: el texto pasa a ser la fuente de
  /// verdad (no hay forward-geocoding que recoloque el punto).
  void _onUbicacionTextChanged() {
    if (_ubicacionLat == null) return;
    if (_ubicacionCtrl.text.trim() != _ubicacionTextoFijado) {
      setState(() {
        _ubicacionLat = null;
        _ubicacionLng = null;
        _ubicacionTextoFijado = null;
      });
    }
  }

  @override
  void dispose() {
    _ubicacionCtrl.removeListener(_onUbicacionTextChanged);
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    _numeroVoluntariosCtrl.dispose();
    _notasMaterialCtrl.dispose();
    _notasVehiculosCtrl.dispose();
    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    super.dispose();
  }

  String? _normalize(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDateTime(DateTime f) {
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    final hh = f.hour.toString().padLeft(2, '0');
    final mi = f.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${f.year} $hh:$mi';
  }

  Future<DateTime?> _pickDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final base = initial ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Selecciona fecha',
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: 'Selecciona hora',
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickUbicacion() async {
    final inicial = (_ubicacionLat != null && _ubicacionLng != null)
        ? MapPoint(_ubicacionLat!, _ubicacionLng!)
        : null;
    final result = await showAppLocationPicker(
      context,
      ref,
      inicial: inicial,
      textoInicial: _ubicacionCtrl.text.trim(),
    );
    if (result == null || !mounted) return;
    final nuevoTexto = result.direccion ?? '';
    setState(() {
      _ubicacionLat = result.lat;
      _ubicacionLng = result.lng;
      // Fijar el texto de referencia ANTES de escribir en el controller, para
      // que el listener de coherencia no malinterprete este cambio
      // programático como una edición manual y suelte las coords recién
      // fijadas.
      _ubicacionTextoFijado = result.lat != null ? nuevoTexto.trim() : null;
      if (nuevoTexto.isNotEmpty) {
        _ubicacionCtrl.text = nuevoTexto;
      }
    });
  }

  Future<void> _pickFechaInicio() async {
    final picked = await _pickDateTime(initial: _fechaInicio);
    if (picked == null) return;
    setState(() {
      _fechaInicio = picked;
      _fechaInicioCtrl.text = _formatDateTime(picked);
    });
  }

  Future<void> _pickFechaFin() async {
    final picked = await _pickDateTime(initial: _fechaFin ?? _fechaInicio);
    if (picked == null) return;
    setState(() {
      _fechaFin = picked;
      _fechaFinCtrl.text = _formatDateTime(picked);
    });
  }

  String? _validateRequired(String? raw, String field) {
    if (raw == null || raw.trim().isEmpty) return '$field obligatorio';
    return null;
  }

  String? _validateNumeroVoluntarios(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final n = int.tryParse(raw.trim());
    if (n == null || n < 0) return 'Número no válido';
    return null;
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fechaInicio == null) {
      AppSnackbar.show(
        context,
        message: 'Selecciona la fecha de inicio.',
        variant: AppSnackbarVariant.warning,
      );
      return;
    }
    final user = ref.read(authServiceProvider).currentUser;
    final permisoNecesario = _tipo == TipoServicio.emergencia
        ? Permission.serviciosCrearEmergencia
        : Permission.serviciosCrearPreventivo;
    if (user == null || !user.hasPermission(permisoNecesario)) {
      AppSnackbar.show(
        context,
        message: _tipo == TipoServicio.emergencia
            ? 'Tu rol no permite crear emergencias.'
            : 'Tu rol no permite crear servicios de este tipo.',
        variant: AppSnackbarVariant.danger,
      );
      return;
    }
    final numeroVoluntariosRaw = _numeroVoluntariosCtrl.text.trim();
    final data = ServicioCreate(
      titulo: _tituloCtrl.text.trim(),
      descripcion: _normalize(_descripcionCtrl.text),
      tipo: _tipo,
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin,
      ubicacion: _ubicacionCtrl.text.trim(),
      ubicacionLat: _ubicacionLat,
      ubicacionLng: _ubicacionLng,
      numeroVoluntarios:
          numeroVoluntariosRaw.isEmpty ? null : int.parse(numeroVoluntariosRaw),
      notasMaterial: _normalize(_notasMaterialCtrl.text),
      notasVehiculos: _normalize(_notasVehiculosCtrl.text),
    );
    ref.read(altaServicioViewModelProvider.notifier).submit(data);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubmit = ref.watch(altaServicioViewModelProvider);

    ref.listen(altaServicioViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (created) {
          if (created == null) return;
          AppSnackbar.show(
            context,
            message: 'Servicio "${created.titulo}" creado correctamente.',
            variant: AppSnackbarVariant.success,
          );
          ref.read(serviciosListViewModelProvider.notifier).refresh();
          context.go('/servicios/${created.id}');
        },
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'No se pudo crear el servicio.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
    });

    return AppPageScaffold(
      maxContentWidth: AppBreakpoints.formMaxWidth,
      title: 'Crear servicio',
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Tipo de servicio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _TipoSelector(
              selected: _tipo,
              onChanged: (t) => setState(() => _tipo = t),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Datos obligatorios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: K.altaServicioTitulo,
              label: 'Título',
              controller: _tituloCtrl,
              autofocus: true,
              prefixIcon: Symbols.title,
              validator: (v) => _validateRequired(v, 'Título'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.altaServicioUbicacion,
              label: 'Ubicación',
              controller: _ubicacionCtrl,
              prefixIcon: Symbols.location_on,
              validator: (v) => _validateRequired(v, 'Ubicación'),
              // Alternativa no-mapa: el campo sigue siendo texto libre; el
              // mapa es opcional para fijar coordenadas exactas (ADR-030).
              suffixIcon: IconButton(
                key: K.altaServicioUbicacionMapaBtn,
                icon: const Icon(Symbols.map),
                tooltip: 'Elegir en el mapa',
                onPressed: _pickUbicacion,
              ),
            ),
            if (_ubicacionLat != null && _ubicacionLng != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Symbols.my_location,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Ubicación fijada en el mapa',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton(
                      key: K.altaServicioQuitarCoordsBtn,
                      onPressed: () => setState(() {
                        _ubicacionLat = null;
                        _ubicacionLng = null;
                        _ubicacionTextoFijado = null;
                      }),
                      child: const Text('Quitar'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            // Guía 28 §WCAG 4.1.2: rol real = botón que abre date+time
            // picker, no TextField. Semantics fuerza la interpretación
            // para el screen reader.
            Semantics(
              label: 'Fecha y hora de inicio',
              button: true,
              child: GestureDetector(
                key: K.altaServicioFechaInicioBtn,
                onTap: _pickFechaInicio,
                child: AbsorbPointer(
                  child: AppTextField(
                    label: 'Fecha y hora de inicio',
                    controller: _fechaInicioCtrl,
                    prefixIcon: Symbols.calendar_today,
                    validator: (_) =>
                        _fechaInicio == null ? 'Fecha obligatoria' : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Datos opcionales',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: K.altaServicioDescripcion,
              label: 'Descripción',
              controller: _descripcionCtrl,
              prefixIcon: Symbols.description,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Fecha y hora de fin',
              button: true,
              child: GestureDetector(
                key: K.altaServicioFechaFinBtn,
                onTap: _pickFechaFin,
                child: AbsorbPointer(
                  child: AppTextField(
                    label: 'Fecha y hora de fin',
                    controller: _fechaFinCtrl,
                    prefixIcon: Symbols.event,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.altaServicioNumeroVoluntarios,
              label: 'Número de voluntarios necesarios',
              controller: _numeroVoluntariosCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Symbols.groups,
              validator: _validateNumeroVoluntarios,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.altaServicioNotasMaterial,
              label: 'Notas sobre material',
              controller: _notasMaterialCtrl,
              prefixIcon: Symbols.inventory_2,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.altaServicioNotasVehiculos,
              label: 'Notas sobre vehículos',
              controller: _notasVehiculosCtrl,
              prefixIcon: Symbols.directions_car,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              key: K.altaServicioSubmitBtn,
              label: _tipo == TipoServicio.emergencia
                  ? 'Crear emergencia'
                  : 'Crear servicio',
              icon: _tipo == TipoServicio.emergencia
                  ? Symbols.warning_amber
                  : Symbols.event_available,
              expanded: true,
              isLoading: asyncSubmit.isLoading,
              onPressed: asyncSubmit.isLoading ? null : _onSubmit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              key: K.altaServicioCancelBtn,
              label: 'Cancelar',
              expanded: true,
              onPressed: asyncSubmit.isLoading
                  ? null
                  : () => context.go('/servicios'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipoSelector extends ConsumerWidget {
  final TipoServicio selected;
  final ValueChanged<TipoServicio> onChanged;

  const _TipoSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auditoría RBAC (29-may, hallazgo A4): `secretario` entra al alta
    // por tener `serviciosCrearPreventivo` (gate `anyOf` exterior) pero
    // no tiene `serviciosCrearEmergencia` (Decisión 4 RBAC). El selector
    // ofrecía los cuatro tipos y al pulsar "Crear emergencia" recibía
    // un snackbar danger (defensa en profundidad correcta, ver
    // _AltaServicioFormState._submit). Mejor UX: no surfacear la
    // opción inválida en origen. El snackbar se conserva por si el
    // JWT cambia mid-sesión.
    final user = ref.watch(authServiceProvider).currentUser;
    final canEmergencia =
        user?.hasPermission(Permission.serviciosCrearEmergencia) ?? false;
    final tipos = TipoServicio.values
        .where((t) => t != TipoServicio.emergencia || canEmergencia)
        .toList(growable: false);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: tipos.map((t) {
        return ChoiceChip(
          key: K.altaServicioTipoChip(t.wire),
          label: Text(_label(t)),
          selected: selected == t,
          onSelected: (_) => onChanged(t),
        );
      }).toList(growable: false),
    );
  }

  String _label(TipoServicio t) => switch (t) {
        TipoServicio.preventivo => 'Preventivo',
        TipoServicio.emergencia => 'Emergencia',
        TipoServicio.formacion => 'Formación',
        TipoServicio.otro => 'Otro',
      };
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Crear servicio',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite crear servicios.',
        icon: Symbols.lock,
      ),
    );
  }
}
