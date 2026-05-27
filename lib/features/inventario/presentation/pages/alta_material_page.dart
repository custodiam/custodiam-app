// AltaMaterialPage (US-05-01). Form completo del catálogo de material.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/material_create.dart';
import '../../domain/entities/tipo_material.dart';
import '../viewmodels/alta_material_view_model.dart';
import '../viewmodels/materiales_list_view_model.dart';

class AltaMaterialPage extends ConsumerWidget {
  const AltaMaterialPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.inventarioRegistrarMaterial,
      fallback: _ForbiddenScreen(),
      child: _AltaMaterialForm(),
    );
  }
}

class _AltaMaterialForm extends ConsumerStatefulWidget {
  const _AltaMaterialForm();

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
  final _ubicacionCtrl = TextEditingController();
  TipoMaterial _tipo = TipoMaterial.prestable;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _codigoCtrl.dispose();
    _numeroSerieCtrl.dispose();
    _categoriaCtrl.dispose();
    _cantidadCtrl.dispose();
    _ubicacionCtrl.dispose();
    super.dispose();
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
    final data = MaterialCreate(
      nombre: _nombreCtrl.text.trim(),
      tipo: _tipo,
      cantidad: int.parse(_cantidadCtrl.text.trim()),
      ubicacionBase: _ubicacionCtrl.text.trim(),
      descripcion: _normalize(_descripcionCtrl.text),
      codigo: _normalize(_codigoCtrl.text),
      numeroSerie: _normalize(_numeroSerieCtrl.text),
      categoria: _normalize(_categoriaCtrl.text),
    );
    ref.read(altaMaterialViewModelProvider.notifier).submit(data);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubmit = ref.watch(altaMaterialViewModelProvider);

    ref.listen(altaMaterialViewModelProvider, (prev, next) {
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

    return AppPageScaffold(
      title: 'Nuevo material',
      body: Form(
        key: _formKey,
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
                  key: ValueKey('alta_material_tipo_${t.wire}'),
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
              key: const ValueKey('alta_material_nombre'),
              label: 'Nombre',
              controller: _nombreCtrl,
              autofocus: true,
              prefixIcon: Icons.label_outline,
              validator: (v) => _validateRequired(v, 'Nombre'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_material_cantidad'),
              label: 'Cantidad',
              controller: _cantidadCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.numbers,
              validator: _validateCantidad,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_material_ubicacion'),
              label: 'Ubicación base',
              controller: _ubicacionCtrl,
              prefixIcon: Icons.location_on_outlined,
              validator: (v) => _validateRequired(v, 'Ubicación'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Datos opcionales',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: const ValueKey('alta_material_descripcion'),
              label: 'Descripción',
              controller: _descripcionCtrl,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_material_codigo'),
              label: 'Código (se genera automático si lo dejas vacío)',
              controller: _codigoCtrl,
              prefixIcon: Icons.tag,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_material_numero_serie'),
              label: 'Número de serie',
              controller: _numeroSerieCtrl,
              prefixIcon: Icons.confirmation_number_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_material_categoria'),
              label: 'Categoría (ej. uniformidad, hidráulica…)',
              controller: _categoriaCtrl,
              prefixIcon: Icons.category_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              key: const ValueKey('alta_material_submit'),
              label: 'Registrar material',
              icon: Icons.add_box_outlined,
              expanded: true,
              isLoading: asyncSubmit.isLoading,
              onPressed: asyncSubmit.isLoading ? null : _onSubmit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              key: const ValueKey('alta_material_cancel'),
              label: 'Cancelar',
              expanded: true,
              onPressed: asyncSubmit.isLoading
                  ? null
                  : () => context.go('/inventario'),
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
        icon: Icons.lock_outline,
      ),
    );
  }
}
