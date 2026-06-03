// AltaMaterialPage (US-05-01) y edición de material (A6). Form completo del
// catálogo de material reutilizado para alta y edición: con `materialId` carga
// la ficha, precarga el formulario y, al guardar, hace PATCH parcial en lugar
// de POST. Gateada por `inventario.registrar_material`, el mismo permiso que el
// backend exige tanto para crear como para actualizar.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_breakpoints.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/catalogo/catalogo_recurso.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/material_create.dart';
import '../../domain/entities/tipo_material.dart';
import '../viewmodels/alta_material_view_model.dart';
import '../viewmodels/inventario_di.dart';
import '../viewmodels/materiales_list_view_model.dart';
import '../widgets/ubicacion_selector_field.dart';

class AltaMaterialPage extends ConsumerWidget {
  /// `null` ⇒ alta; con id ⇒ edición (se carga el material al entrar).
  final String? materialId;

  const AltaMaterialPage({super.key, this.materialId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPermissionGate(
      permission: Permission.inventarioRegistrarMaterial,
      fallback: const _ForbiddenScreen(),
      child: _AltaMaterialForm(materialId: materialId),
    );
  }
}

class _AltaMaterialForm extends ConsumerStatefulWidget {
  final String? materialId;

  const _AltaMaterialForm({this.materialId});

  bool get esEdicion => materialId != null;

  @override
  ConsumerState<_AltaMaterialForm> createState() =>
      _AltaMaterialFormState();
}

class _AltaMaterialFormState extends ConsumerState<_AltaMaterialForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _numeroSerieCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  TipoMaterial _tipo = TipoMaterial.prestable;
  CatalogoRecurso? _ubicacion;

  bool _cargando = false;
  bool _guardando = false;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _codigoCtrl.dispose();
    _numeroSerieCtrl.dispose();
    _categoriaCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final result =
        await ref.read(getMaterialProvider).call(widget.materialId!);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        _nombreCtrl.text = value.nombre;
        _descripcionCtrl.text = value.descripcion ?? '';
        _codigoCtrl.text = value.codigo ?? '';
        _numeroSerieCtrl.text = value.numeroSerie ?? '';
        _categoriaCtrl.text = value.categoria ?? '';
        _cantidadCtrl.text = value.cantidad.toString();
        setState(() {
          _tipo = value.tipo;
          // La ficha trae el FK y el texto de la ubicación; reconstruimos el
          // CatalogoRecurso que el selector espera. Si falta el FK dejamos la
          // selección vacía (el validador exigirá fijar una al guardar).
          _ubicacion = (value.ubicacionBaseId != null)
              ? CatalogoRecurso(
                  id: value.ubicacionBaseId!,
                  label: value.ubicacionBase ?? value.ubicacionBaseId!,
                )
              : null;
          _cargando = false;
        });
      case Fail(:final failure):
        setState(() {
          _cargando = false;
          _errorCarga = failure.message ?? 'No se pudo cargar el material.';
        });
    }
  }

  String? _normalize(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _validateRequired(String? raw, String field) {
    if (raw == null || raw.trim().isEmpty) return '$field obligatorio';
    return null;
  }

  String? _validateCantidad(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Cantidad obligatoria';
    final n = int.tryParse(raw.trim());
    if (n == null || n < 0) return 'Cantidad no válida';
    return null;
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.esEdicion) {
      _actualizar();
    } else {
      _crear();
    }
  }

  void _crear() {
    final data = MaterialCreate(
      nombre: _nombreCtrl.text.trim(),
      tipo: _tipo,
      cantidad: int.parse(_cantidadCtrl.text.trim()),
      ubicacionBase: _ubicacion?.label,
      ubicacionBaseId: _ubicacion?.id,
      descripcion: _normalize(_descripcionCtrl.text),
      codigo: _normalize(_codigoCtrl.text),
      numeroSerie: _normalize(_numeroSerieCtrl.text),
      categoria: _normalize(_categoriaCtrl.text),
    );
    ref.read(altaMaterialViewModelProvider.notifier).submit(data);
  }

  Future<void> _actualizar() async {
    setState(() => _guardando = true);
    // Cuerpo parcial PATCH: enviamos los campos editables siempre (incluido
    // null para limpiar los opcionales borrados), igual que la edición de
    // ubicación. El backend aplica el patch con exclude_unset, así que una
    // clave con null limpia la columna.
    final campos = <String, dynamic>{
      'nombre': _nombreCtrl.text.trim(),
      'tipo': _tipo.wire,
      'cantidad': int.parse(_cantidadCtrl.text.trim()),
      'ubicacion_base_id': _ubicacion?.id,
      'ubicacion_base': _ubicacion?.label,
      'descripcion': _normalize(_descripcionCtrl.text),
      'codigo': _normalize(_codigoCtrl.text),
      'numero_serie': _normalize(_numeroSerieCtrl.text),
      'categoria': _normalize(_categoriaCtrl.text),
    };
    final result = await ref
        .read(actualizarMaterialProvider)
        .call(widget.materialId!, campos);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        ref.read(materialesListViewModelProvider.notifier).refresh();
        AppSnackbar.show(
          context,
          message: 'Material "${value.nombre}" actualizado.',
          variant: AppSnackbarVariant.success,
        );
        context.go('/inventario/material/${value.id}');
      case Fail(:final failure):
        setState(() => _guardando = false);
        AppSnackbar.show(
          context,
          message: failure.message ?? 'No se pudo actualizar el material.',
          variant: AppSnackbarVariant.danger,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubmit = ref.watch(altaMaterialViewModelProvider);
    final titulo = widget.esEdicion ? 'Editar material' : 'Nuevo material';
    // En alta el spinner del botón lo gobierna el AsyncNotifier; en edición,
    // el flag local _guardando del PATCH directo.
    final isBusy = widget.esEdicion ? _guardando : asyncSubmit.isLoading;

    // El AsyncNotifier de alta solo gobierna el modo creación; al editar el
    // PATCH va por _actualizar y este listener no debe reaccionar.
    ref.listen(altaMaterialViewModelProvider, (prev, next) {
      if (widget.esEdicion) return;
      next.whenOrNull(
        data: (created) {
          if (created == null) return;
          AppSnackbar.show(
            context,
            message: 'Material "${created.nombre}" registrado.',
            variant: AppSnackbarVariant.success,
          );
          ref.read(materialesListViewModelProvider.notifier).refresh();
          context.go('/inventario/material/${created.id}');
        },
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'No se pudo registrar el material.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
    });

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
          title: 'No se pudo cargar el material',
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
            Text(
              'Tipo de material',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: TipoMaterial.values.map((t) {
                final label = switch (t) {
                  TipoMaterial.personal => 'Personal',
                  TipoMaterial.prestable => 'Prestable',
                  TipoMaterial.servicio => 'Servicio',
                };
                return ChoiceChip(
                  key: K.altaMaterialTipoChip(t.wire),
                  label: Text(label),
                  selected: _tipo == t,
                  onSelected: (_) => setState(() => _tipo = t),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Datos obligatorios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: K.altaMaterialNombre,
              label: 'Nombre',
              controller: _nombreCtrl,
              autofocus: !widget.esEdicion,
              prefixIcon: Symbols.label,
              validator: (v) => _validateRequired(v, 'Nombre'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.altaMaterialCantidad,
              label: 'Cantidad',
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Symbols.numbers,
              validator: _validateCantidad,
            ),
            const SizedBox(height: AppSpacing.md),
            UbicacionSelectorField(
              fieldKey: K.altaMaterialUbicacion,
              value: _ubicacion,
              onChanged: (u) => setState(() => _ubicacion = u),
              validator: (v) => v == null ? 'Ubicación obligatoria' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Datos opcionales',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: K.altaMaterialDescripcion,
              label: 'Descripción',
              controller: _descripcionCtrl,
              prefixIcon: Symbols.description,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.altaMaterialCodigo,
              label: 'Código (se genera automático si lo dejas vacío)',
              controller: _codigoCtrl,
              prefixIcon: Symbols.tag,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.altaMaterialNumeroSerie,
              label: 'Número de serie',
              controller: _numeroSerieCtrl,
              prefixIcon: Symbols.confirmation_number,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.altaMaterialCategoria,
              label: 'Categoría (ej. uniformidad, hidráulica…)',
              controller: _categoriaCtrl,
              prefixIcon: Symbols.category,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              key: K.altaMaterialSubmit,
              label: widget.esEdicion
                  ? 'Guardar cambios'
                  : 'Registrar material',
              icon: widget.esEdicion ? Symbols.save : Symbols.add_box,
              expanded: true,
              isLoading: isBusy,
              onPressed: isBusy ? null : _onSubmit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              key: K.altaMaterialCancel,
              label: 'Cancelar',
              expanded: true,
              onPressed: isBusy
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
      title: 'Nuevo material',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite registrar material.',
        icon: Symbols.lock,
      ),
    );
  }
}
