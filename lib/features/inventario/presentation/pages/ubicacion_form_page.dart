// Alta / edición de una ubicación del catálogo (E10). Formulario con nombre
// (obligatorio, único en backend), descripción (opcional) y coordenadas
// opcionales fijadas con el AppLocationPicker (arrastrando el pin en el mapa).
// Gateada por `ubicaciones.crear`, el mismo permiso que el backend exige para
// POST/PATCH. Al guardar refresca la lista de la pestaña y vuelve atrás.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/maps/app_location_picker.dart';
import '../../../../core/ui/maps/map_point.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_breakpoints.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/result.dart';
import '../viewmodels/ubicaciones_di.dart';
import '../viewmodels/ubicaciones_list_view_model.dart';

class UbicacionFormPage extends ConsumerWidget {
  /// `null` ⇒ alta; con id ⇒ edición (se carga la ubicación al entrar).
  final String? ubicacionId;

  const UbicacionFormPage({super.key, this.ubicacionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPermissionGate(
      permission: Permission.ubicacionesCrear,
      fallback: const _ForbiddenScreen(),
      child: _UbicacionForm(ubicacionId: ubicacionId),
    );
  }
}

class _UbicacionForm extends ConsumerStatefulWidget {
  final String? ubicacionId;

  const _UbicacionForm({this.ubicacionId});

  bool get esEdicion => ubicacionId != null;

  @override
  ConsumerState<_UbicacionForm> createState() => _UbicacionFormState();
}

class _UbicacionFormState extends ConsumerState<_UbicacionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  double? _lat;
  double? _lng;
  bool _cargando = false;
  bool _guardando = false;
  String? _errorCarga;

  bool get _tieneCoords => _lat != null && _lng != null;

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final result =
        await ref.read(obtenerUbicacionProvider).call(widget.ubicacionId!);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        _nombreCtrl.text = value.nombre;
        _descripcionCtrl.text = value.descripcion ?? '';
        setState(() {
          _lat = value.lat;
          _lng = value.lng;
          _cargando = false;
        });
      case Fail(:final failure):
        setState(() {
          _cargando = false;
          _errorCarga = failure.message ?? 'No se pudo cargar la ubicación.';
        });
    }
  }

  Future<void> _fijarEnMapa() async {
    final inicial = _tieneCoords ? MapPoint(_lat!, _lng!) : null;
    final result = await showAppLocationPicker(
      context,
      ref,
      inicial: inicial,
      textoInicial: _nombreCtrl.text.trim(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.lat;
      _lng = result.lng;
    });
  }

  String? _validarNombre(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'El nombre es obligatorio';
    return null;
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _guardando = true);
    final nombre = _nombreCtrl.text.trim();
    final desc = _descripcionCtrl.text.trim();
    final descripcion = desc.isEmpty ? null : desc;

    final result = widget.esEdicion
        ? await ref.read(actualizarUbicacionProvider).call(
              widget.ubicacionId!,
              nombre: nombre,
              descripcion: descripcion,
              lat: _lat,
              lng: _lng,
            )
        : await ref.read(crearUbicacionProvider).call(
              nombre: nombre,
              descripcion: descripcion,
              lat: _lat,
              lng: _lng,
            );
    if (!mounted) return;
    switch (result) {
      case Success():
        ref.read(ubicacionesListViewModelProvider.notifier).refresh();
        AppSnackbar.show(
          context,
          message: widget.esEdicion
              ? 'Ubicación actualizada.'
              : 'Ubicación creada.',
          variant: AppSnackbarVariant.success,
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/inventario');
        }
      case Fail(:final failure):
        setState(() => _guardando = false);
        AppSnackbar.show(
          context,
          message: failure.message ?? 'No se pudo guardar la ubicación.',
          variant: AppSnackbarVariant.danger,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titulo = widget.esEdicion ? 'Editar ubicación' : 'Nueva ubicación';

    if (_cargando) {
      return AppPageScaffold(
        title: titulo,
        body: const AppLoadingIndicator.fullScreen(),
      );
    }
    if (_errorCarga != null) {
      return AppPageScaffold(
        title: titulo,
        body: AppErrorState(
          title: 'No se pudo cargar la ubicación',
          description: _errorCarga,
          onRetry: _cargar,
        ),
      );
    }

    return AppPageScaffold(
      maxContentWidth: AppBreakpoints.formMaxWidth,
      title: titulo,
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppTextField(
              key: K.ubicacionFormNombre,
              label: 'Nombre',
              controller: _nombreCtrl,
              autofocus: !widget.esEdicion,
              prefixIcon: Symbols.location_on,
              validator: _validarNombre,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.ubicacionFormDescripcion,
              label: 'Descripción (opcional)',
              controller: _descripcionCtrl,
              prefixIcon: Symbols.description,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Ubicación en el mapa (opcional)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Fija las coordenadas para poder ver esta ubicación en el mapa '
              'desde el material o los vehículos que la usen.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  _tieneCoords ? Symbols.my_location : Symbols.location_off,
                  size: 18,
                  color: _tieneCoords
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _tieneCoords
                        ? 'Coordenadas fijadas'
                        : 'Sin coordenadas',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (_tieneCoords)
                  TextButton(
                    onPressed: _guardando
                        ? null
                        : () => setState(() {
                              _lat = null;
                              _lng = null;
                            }),
                    child: const Text('Quitar'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              key: K.ubicacionFormMapaBtn,
              label: _tieneCoords ? 'Cambiar en el mapa' : 'Fijar en el mapa',
              icon: Symbols.map,
              expanded: true,
              onPressed: _guardando ? null : _fijarEnMapa,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              key: K.ubicacionFormSubmit,
              label: widget.esEdicion ? 'Guardar cambios' : 'Crear ubicación',
              icon: Symbols.save,
              expanded: true,
              isLoading: _guardando,
              onPressed: _guardando ? null : _onSubmit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: 'Cancelar',
              expanded: true,
              onPressed: _guardando
                  ? null
                  : () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/inventario');
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Ubicación',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite gestionar ubicaciones.',
        icon: Symbols.lock,
      ),
    );
  }
}
