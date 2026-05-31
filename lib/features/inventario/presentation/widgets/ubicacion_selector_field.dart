// Campo de selección de ubicación para las altas de inventario (PR2).
//
// Encapsula, para que material y vehículo lo reutilicen con dos líneas:
//   - un campo de formulario de solo lectura que muestra la ubicación elegida
//     y participa en la validación del Form (patrón a11y del campo ITV: rol
//     real = botón, no TextField — guía 28 §WCAG 4.1.2);
//   - al pulsarlo, abre el `AppCatalogSearchPicker` contra el catálogo de
//     ubicaciones;
//   - el footer "crear" del picker (gateado por `ubicaciones.crear`) abre un
//     diálogo de alta rápida que crea la ubicación sin salir del formulario y
//     la deja seleccionada (opción A acordada con el PO).
//
// Es un widget controlado: el estado de la selección vive en el formulario
// padre (`value` + `onChanged`), de modo que el padre valida y construye el
// payload con `ubicacion_base_id`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/feedback/app_dialog.dart';
import '../../../../core/ui/inputs/app_catalog_search_picker.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/catalogo/catalogo_recurso.dart';
import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/network/api_client.dart';

class UbicacionSelectorField extends ConsumerStatefulWidget {
  final CatalogoRecurso? value;
  final ValueChanged<CatalogoRecurso?> onChanged;
  final String label;

  /// Validador sobre la selección (no sobre el texto mostrado): permite al
  /// formulario padre exigir una ubicación al pulsar "registrar".
  final String? Function(CatalogoRecurso? value)? validator;

  /// Key del contenedor tappable, para localizarlo en widget tests.
  final Key? fieldKey;

  const UbicacionSelectorField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Ubicación base',
    this.validator,
    this.fieldKey,
  });

  @override
  ConsumerState<UbicacionSelectorField> createState() =>
      _UbicacionSelectorFieldState();
}

class _UbicacionSelectorFieldState
    extends ConsumerState<UbicacionSelectorField> {
  late final TextEditingController _displayCtrl;

  @override
  void initState() {
    super.initState();
    _displayCtrl = TextEditingController(text: widget.value?.label ?? '');
  }

  @override
  void didUpdateWidget(covariant UbicacionSelectorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.value?.label ?? '') == _displayCtrl.text) return;
    // Asignar `controller.text` notifica a los listeners del controller (el
    // EditableText interno del campo). Si didUpdateWidget corre mientras un
    // ancestro se está construyendo —p. ej. el Form al hacer setState en el
    // submit—, esa notificación dispara markNeedsBuild durante el build y
    // Flutter lanza "setState() called during build". Diferir la
    // sincronización al final del frame evita la colisión.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final text = widget.value?.label ?? '';
      if (_displayCtrl.text != text) _displayCtrl.text = text;
    });
  }

  @override
  void dispose() {
    _displayCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirPicker() async {
    final catalogo = ref.read(ubicacionesCatalogoServiceProvider);
    final elegida = await AppCatalogSearchPicker.show<CatalogoRecurso>(
      context,
      title: 'Ubicaciones',
      searchHint: 'Buscar ubicación…',
      onLoadPage: catalogo.buscarUbicaciones,
      labelOf: (r) => r.label,
      createPermission: Permission.ubicacionesCrear,
      createLabel: 'Nueva ubicación',
      onCreate: _crearUbicacion,
    );
    // El picker resuelve con la selección o con `null` (cerrado / "crear").
    // El alta de una ubicación nueva la notifica `_crearUbicacion`.
    if (elegida != null) widget.onChanged(elegida);
  }

  Future<void> _crearUbicacion() async {
    if (!mounted) return;
    final nueva = await AppDialog.show<CatalogoRecurso>(
      context,
      title: 'Nueva ubicación',
      content: const _CrearUbicacionForm(),
      actions: const [],
    );
    if (nueva != null) widget.onChanged(nueva);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      child: GestureDetector(
        key: widget.fieldKey,
        onTap: _abrirPicker,
        child: AbsorbPointer(
          child: AppTextField(
            label: widget.label,
            controller: _displayCtrl,
            prefixIcon: Symbols.location_on,
            validator: widget.validator == null
                ? null
                : (_) => widget.validator!(widget.value),
          ),
        ),
      ),
    );
  }
}

/// Contenido del diálogo de alta rápida de ubicación. Crea vía
/// `POST /ubicaciones` y cierra el diálogo devolviendo el `CatalogoRecurso`
/// creado. Sus propios botones cierran el diálogo (de ahí `actions: const []`
/// en el `AppDialog` que lo envuelve).
class _CrearUbicacionForm extends ConsumerStatefulWidget {
  const _CrearUbicacionForm();

  @override
  ConsumerState<_CrearUbicacionForm> createState() =>
      _CrearUbicacionFormState();
}

class _CrearUbicacionFormState extends ConsumerState<_CrearUbicacionForm> {
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'El nombre es obligatorio.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final nueva = await ref
          .read(ubicacionesCatalogoServiceProvider)
          .crear(nombre: nombre, descripcion: _descripcionCtrl.text);
      if (!mounted) return;
      Navigator.of(context).pop(nueva);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.statusCode == 409
            ? 'Ya existe una ubicación con ese nombre.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo crear la ubicación.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const ValueKey('crear_ubicacion_nombre'),
          label: 'Nombre',
          controller: _nombreCtrl,
          autofocus: true,
          prefixIcon: Symbols.location_on,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const ValueKey('crear_ubicacion_descripcion'),
          label: 'Descripción (opcional)',
          controller: _descripcionCtrl,
          prefixIcon: Symbols.description,
          maxLines: 2,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          key: const ValueKey('crear_ubicacion_submit'),
          label: 'Crear',
          icon: Symbols.add_location,
          expanded: true,
          isLoading: _loading,
          onPressed: _loading ? null : _crear,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          key: const ValueKey('crear_ubicacion_cancel'),
          label: 'Cancelar',
          expanded: true,
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
