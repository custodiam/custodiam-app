// Sección "Material asignado al vehículo" de la ficha de vehículo (PR3).
// Muestra la dotación fija (material asignado permanentemente al vehículo)
// y, para quien tiene `inventario.gestionar_dotacion_vehiculo`, permite
// añadir y quitar líneas. Quien sólo puede ver el inventario ve la lista
// en modo lectura (y nada si está vacía).
//
// El selector de material es un campo de UUID por ahora, igual que el de
// voluntario en la ficha de material: el catálogo con buscador queda
// diferido hasta que `AppCatalogSearchPicker` se materialice.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_icon_button.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_text_button.dart';
import '../../../../core/ui/feedback/app_dialog.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/dotacion_vehiculo.dart';
import '../viewmodels/dotacion_vehiculo_view_model.dart';

class DotacionVehiculoSection extends ConsumerWidget {
  final String vehiculoId;

  const DotacionVehiculoSection({super.key, required this.vehiculoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = dotacionVehiculoViewModelProvider(vehiculoId);
    final async = ref.watch(provider);

    ref.listen(provider, (prev, next) {
      if (next is AsyncError) {
        final error = next.error;
        AppSnackbar.show(
          context,
          message: error is Failure
              ? (error.message ?? 'No se pudo completar la acción.')
              : 'No se pudo completar la acción.',
          variant: AppSnackbarVariant.danger,
        );
      }
    });

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => AppPermissionGate(
        permission: Permission.inventarioGestionarDotacionVehiculo,
        fallback: const SizedBox.shrink(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: AppTextButton(
            label: 'Reintentar dotación',
            onPressed: () => ref.read(provider.notifier).refresh(),
          ),
        ),
      ),
      data: (items) => AppPermissionGate(
        permission: Permission.inventarioGestionarDotacionVehiculo,
        fallback: items.isEmpty
            ? const SizedBox.shrink()
            : _DotacionBody(
                vehiculoId: vehiculoId,
                items: items,
                canManage: false,
              ),
        child: _DotacionBody(
          vehiculoId: vehiculoId,
          items: items,
          canManage: true,
        ),
      ),
    );
  }
}

class _DotacionBody extends ConsumerWidget {
  final String vehiculoId;
  final List<DotacionVehiculo> items;
  final bool canManage;

  const _DotacionBody({
    required this.vehiculoId,
    required this.items,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Material asignado al vehículo',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
            if (canManage)
              AppIconButton(
                key: const ValueKey('dotacion_anadir'),
                icon: Symbols.add,
                tooltip: 'Añadir material a la dotación',
                onPressed: () => _abrirAlta(context, ref),
              ),
          ],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'Sin material en dotación.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final dotacion in items)
            _DotacionTile(
              dotacion: dotacion,
              onQuitar: canManage
                  ? () => _confirmarBaja(context, ref, dotacion)
                  : null,
            ),
      ],
    );
  }

  Future<void> _abrirAlta(BuildContext context, WidgetRef ref) async {
    final materialCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController(text: '1');
    try {
      final ok = await AppDialog.show<bool>(
        context,
        title: 'Añadir material a la dotación',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              key: const ValueKey('dotacion_material_id'),
              label: 'ID del material (UUID)',
              controller: materialCtrl,
              prefixIcon: Symbols.inventory_2,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('dotacion_cantidad'),
              label: 'Cantidad',
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Symbols.numbers,
            ),
          ],
        ),
        actions: [
          AppTextButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppPrimaryButton(
            key: const ValueKey('dotacion_anadir_confirm'),
            label: 'Añadir',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
      if (ok != true) return;
      if (!context.mounted) return;
      final materialId = materialCtrl.text.trim();
      final cantidad = int.tryParse(cantidadCtrl.text.trim()) ?? 1;
      if (materialId.isEmpty) {
        AppSnackbar.show(
          context,
          message: 'Indica el ID del material.',
          variant: AppSnackbarVariant.warning,
        );
        return;
      }
      final exito = await ref
          .read(dotacionVehiculoViewModelProvider(vehiculoId).notifier)
          .asignar(materialId: materialId, cantidad: cantidad);
      if (!context.mounted) return;
      if (exito) {
        AppSnackbar.show(
          context,
          message: 'Material añadido a la dotación.',
          variant: AppSnackbarVariant.success,
        );
      }
    } finally {
      materialCtrl.dispose();
      cantidadCtrl.dispose();
    }
  }

  Future<void> _confirmarBaja(
    BuildContext context,
    WidgetRef ref,
    DotacionVehiculo dotacion,
  ) async {
    final ok = await AppDialog.show<bool>(
      context,
      title: 'Quitar de la dotación',
      content: Text(
        '¿Quitar "${dotacion.materialNombre}" de la dotación fija de este '
        'vehículo?',
      ),
      actions: [
        AppTextButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppPrimaryButton(
          key: const ValueKey('dotacion_quitar_confirm'),
          label: 'Quitar',
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final exito = await ref
        .read(dotacionVehiculoViewModelProvider(vehiculoId).notifier)
        .liberar(asignacionId: dotacion.id);
    if (!context.mounted) return;
    if (exito) {
      AppSnackbar.show(
        context,
        message: 'Material retirado de la dotación.',
        variant: AppSnackbarVariant.success,
      );
    }
  }
}

class _DotacionTile extends StatelessWidget {
  final DotacionVehiculo dotacion;
  final VoidCallback? onQuitar;

  const _DotacionTile({required this.dotacion, this.onQuitar});

  static String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unidades =
        dotacion.cantidad == 1 ? '1 unidad' : '${dotacion.cantidad} unidades';
    final detalle = '$unidades · desde ${_formatDate(dotacion.fechaAsignacion)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Symbols.inventory_2,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dotacion.materialNombre, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onQuitar != null)
            AppIconButton(
              icon: Symbols.close,
              tooltip: 'Quitar de la dotación',
              onPressed: onQuitar,
            ),
        ],
      ),
    );
  }
}
