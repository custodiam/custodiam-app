// Sección "Recursos asignados" de la ficha de servicio (R1 / Opción 1B).
// Muestra el material y los vehículos asignados al servicio y, para quien
// tiene `inventario.asignar_a_servicio`, permite asignar nuevos eligiéndolos
// del catálogo con AppCatalogSearchPicker.
//
// El catálogo se carga vía InventarioCatalogoService (infrastructure), así
// que esta feature no importa features/inventario (guía 26 §1). No hay acción
// de "quitar": el backend libera los recursos al cerrar el servicio. Si el
// recurso ya está comprometido en un intervalo solapado, el 409 del backend
// llega como InventarioFailure.recursoSolapado y se muestra por snackbar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_icon_button.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_text_button.dart';
import '../../../../core/ui/feedback/app_dialog.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_catalog_search_picker.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/catalogo/catalogo_recurso.dart';
import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/servicio_inventario.dart';
import '../viewmodels/servicio_inventario_view_model.dart';

class RecursosAsignadosSection extends ConsumerWidget {
  final String servicioId;

  const RecursosAsignadosSection({super.key, required this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = servicioInventarioViewModelProvider(servicioId);
    final async = ref.watch(provider);

    ref.listen(provider, (prev, next) {
      if (next is AsyncError) {
        final error = next.error;
        AppSnackbar.show(
          context,
          message: error is Failure
              ? (error.message ?? 'No se pudo asignar el recurso.')
              : 'No se pudo asignar el recurso.',
          variant: AppSnackbarVariant.danger,
        );
      }
    });

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => AppPermissionGate(
        permission: Permission.inventarioAsignarAServicio,
        fallback: const SizedBox.shrink(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: AppTextButton(
            label: 'Reintentar recursos',
            onPressed: () => ref.read(provider.notifier).refresh(),
          ),
        ),
      ),
      data: (inv) => _Body(servicioId: servicioId, inv: inv),
    );
  }
}

class _Body extends ConsumerWidget {
  final String servicioId;
  final ServicioInventario inv;

  const _Body({required this.servicioId, required this.inv});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Recursos asignados',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
            AppPermissionGate(
              permission: Permission.inventarioAsignarAServicio,
              child: AppIconButton(
                key: K.servicioRecursosAnadirBtn,
                icon: Symbols.add,
                tooltip: 'Asignar un recurso al servicio',
                onPressed: () => _elegirTipo(context, ref),
              ),
            ),
          ],
        ),
        if (inv.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'Sin recursos asignados.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          for (final m in inv.material)
            _RecursoTile(
              icon: Symbols.inventory_2,
              titulo: m.materialNombre,
              detalle: _detalleMaterial(m),
            ),
          for (final v in inv.vehiculos)
            _RecursoTile(
              icon: Symbols.directions_car,
              titulo: '${v.codigoInterno} · ${v.matricula}',
              detalle: 'Vehículo · desde ${_fecha(v.fechaAsignacion)}',
            ),
        ],
      ],
    );
  }

  String _detalleMaterial(MaterialAsignadoServicio m) {
    final uds = m.cantidad == 1 ? '1 unidad' : '${m.cantidad} unidades';
    return '$uds · desde ${_fecha(m.fechaAsignacion)}';
  }

  static String _fecha(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<void> _elegirTipo(BuildContext context, WidgetRef ref) async {
    final tipo = await AppDialog.show<String>(
      context,
      title: 'Asignar recurso',
      content: const Text('¿Qué tipo de recurso quieres asignar al servicio?'),
      actions: [
        AppTextButton(
          key: K.servicioRecursosTipoMaterialBtn,
          label: 'Material',
          icon: Symbols.inventory_2,
          onPressed: () => Navigator.of(context).pop('material'),
        ),
        AppTextButton(
          key: K.servicioRecursosTipoVehiculoBtn,
          label: 'Vehículo',
          icon: Symbols.directions_car,
          onPressed: () => Navigator.of(context).pop('vehiculo'),
        ),
      ],
    );
    if (tipo == null) return;
    if (!context.mounted) return;
    if (tipo == 'material') {
      await _asignarMaterial(context, ref);
    } else {
      await _asignarVehiculo(context, ref);
    }
  }

  Future<void> _asignarMaterial(BuildContext context, WidgetRef ref) async {
    final catalogo = ref.read(inventarioCatalogoServiceProvider);
    final recurso = await AppCatalogSearchPicker.show<CatalogoRecurso>(
      context,
      title: 'Material disponible',
      searchHint: 'Buscar material…',
      onLoadPage: catalogo.buscarMaterial,
      labelOf: (r) => r.label,
    );
    if (recurso == null) return;
    if (!context.mounted) return;
    final cantidad = await _pedirCantidad(context);
    if (cantidad == null) return;
    if (!context.mounted) return;
    final ok = await ref
        .read(servicioInventarioViewModelProvider(servicioId).notifier)
        .asignarMaterial(materialId: recurso.id, cantidad: cantidad);
    if (!context.mounted) return;
    if (ok) {
      AppSnackbar.show(
        context,
        message: 'Material asignado al servicio.',
        variant: AppSnackbarVariant.success,
      );
    }
  }

  Future<void> _asignarVehiculo(BuildContext context, WidgetRef ref) async {
    final catalogo = ref.read(inventarioCatalogoServiceProvider);
    final recurso = await AppCatalogSearchPicker.show<CatalogoRecurso>(
      context,
      title: 'Vehículos disponibles',
      searchHint: 'Buscar vehículo…',
      onLoadPage: catalogo.buscarVehiculos,
      labelOf: (r) => r.label,
    );
    if (recurso == null) return;
    if (!context.mounted) return;
    final ok = await ref
        .read(servicioInventarioViewModelProvider(servicioId).notifier)
        .asignarVehiculo(vehiculoId: recurso.id);
    if (!context.mounted) return;
    if (ok) {
      AppSnackbar.show(
        context,
        message: 'Vehículo asignado al servicio.',
        variant: AppSnackbarVariant.success,
      );
    }
  }

  Future<int?> _pedirCantidad(BuildContext context) async {
    // El diálogo es un StatefulWidget que posee y libera su controller en
    // State.dispose(), atado al ciclo de vida del subárbol del diálogo;
    // devuelve el texto crudo en el pop (el controller ya no existe al
    // volver del await). Cancelar/descartar devuelve null.
    final cantidadRaw = await AppDialog.showBuilder<String>(
      context,
      builder: (_) => const _CantidadDialog(),
    );
    if (cantidadRaw == null) return null;
    final cantidad = int.tryParse(cantidadRaw.trim()) ?? 1;
    return cantidad < 1 ? 1 : cantidad;
  }
}

/// Diálogo de cantidad al asignar material a un servicio. StatefulWidget
/// para liberar el controller en dispose() en vez de en un `finally` que
/// correría durante la animación de cierre, con el campo aún reconstruyéndose
/// con un controller ya liberado.
class _CantidadDialog extends StatefulWidget {
  const _CantidadDialog();

  @override
  State<_CantidadDialog> createState() => _CantidadDialogState();
}

class _CantidadDialogState extends State<_CantidadDialog> {
  final _cantidadCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Cantidad',
      content: AppTextField(
        key: K.servicioRecursosCantidadField,
        label: 'Unidades',
        controller: _cantidadCtrl,
        keyboardType: TextInputType.number,
        prefixIcon: Symbols.numbers,
      ),
      actions: [
        AppTextButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(
          key: K.servicioRecursosCantidadConfirmBtn,
          label: 'Asignar',
          onPressed: () => Navigator.of(context).pop(_cantidadCtrl.text),
        ),
      ],
    );
  }
}

class _RecursoTile extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String detalle;

  const _RecursoTile({
    required this.icon,
    required this.titulo,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: theme.textTheme.bodyMedium),
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
        ],
      ),
    );
  }
}
