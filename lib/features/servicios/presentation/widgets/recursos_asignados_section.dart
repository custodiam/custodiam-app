// Sección "Recursos asignados" de la ficha de servicio (R1 / Opción 1B).
// Muestra el material y los vehículos asignados al servicio y, para quien
// tiene `inventario.asignar_a_servicio`, permite asignar nuevos eligiéndolos
// del catálogo con AppCatalogSearchPicker.
//
// El catálogo se carga vía InventarioCatalogoService (infrastructure), así
// que esta feature no importa features/inventario (guía 26 §1). El picker pide
// el catálogo filtrado por disponibilidad para ESTE servicio (query
// `disponible_para_servicio`), de modo que solo ofrece recursos asignables en
// su intervalo. No hay acción de "quitar": el backend libera los recursos al
// cerrar el servicio.
//
// Un rechazo al asignar (recurso ya comprometido, servicio cerrado, material
// no operativo, etc.) llega como una Failure DEVUELTA por el ViewModel —no
// como AsyncError—, así que se muestra por snackbar con el motivo real sin
// tumbar la lista ya cargada. La rama `error:` de `async.when` queda reservada
// para el fallo de CARGA de la lista.

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

    return async.when(
      loading: () => const SizedBox.shrink(),
      // Solo se llega aquí si falla la CARGA de la lista (build/refresh). Los
      // fallos de asignación NO pasan por AsyncError: el ViewModel los devuelve
      // y se muestran por snackbar sin perder la lista (ver _asignarMaterial /
      // _asignarVehiculo más abajo).
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
      // actionsBuilder (no actions): el pop debe ir al navigator del diálogo
      // (raíz), no al de la rama Servicios del shell. Ver AppDialog.show.
      actionsBuilder: (dialogContext) => [
        AppTextButton(
          key: K.servicioRecursosTipoMaterialBtn,
          label: 'Material',
          icon: Symbols.inventory_2,
          onPressed: () => Navigator.of(dialogContext).pop('material'),
        ),
        AppTextButton(
          key: K.servicioRecursosTipoVehiculoBtn,
          label: 'Vehículo',
          icon: Symbols.directions_car,
          onPressed: () => Navigator.of(dialogContext).pop('vehiculo'),
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
      // Filtra el catálogo a lo disponible para el intervalo de ESTE servicio.
      onLoadPage: (query, page) =>
          catalogo.buscarMaterial(query, page, servicioId: servicioId),
      labelOf: (r) => r.label,
    );
    if (recurso == null) return;
    if (!context.mounted) return;
    final cantidad = await _pedirCantidad(context);
    if (cantidad == null) return;
    if (!context.mounted) return;
    final failure = await ref
        .read(servicioInventarioViewModelProvider(servicioId).notifier)
        .asignarMaterial(materialId: recurso.id, cantidad: cantidad);
    if (!context.mounted) return;
    _mostrarResultado(
      context,
      failure: failure,
      mensajeExito: 'Material asignado al servicio.',
    );
  }

  Future<void> _asignarVehiculo(BuildContext context, WidgetRef ref) async {
    final catalogo = ref.read(inventarioCatalogoServiceProvider);
    final recurso = await AppCatalogSearchPicker.show<CatalogoRecurso>(
      context,
      title: 'Vehículos disponibles',
      searchHint: 'Buscar vehículo…',
      // Filtra el catálogo a lo disponible para el intervalo de ESTE servicio.
      onLoadPage: (query, page) =>
          catalogo.buscarVehiculos(query, page, servicioId: servicioId),
      labelOf: (r) => r.label,
    );
    if (recurso == null) return;
    if (!context.mounted) return;
    final failure = await ref
        .read(servicioInventarioViewModelProvider(servicioId).notifier)
        .asignarVehiculo(vehiculoId: recurso.id);
    if (!context.mounted) return;
    _mostrarResultado(
      context,
      failure: failure,
      mensajeExito: 'Vehículo asignado al servicio.',
    );
  }

  /// Surface el resultado de una asignación: snackbar de éxito si [failure] es
  /// `null`, o snackbar de error con el motivo real del backend en caso
  /// contrario. La lista NO se toca: sigue en pantalla con su contenido.
  void _mostrarResultado(
    BuildContext context, {
    required Failure? failure,
    required String mensajeExito,
  }) {
    if (failure == null) {
      AppSnackbar.show(
        context,
        message: mensajeExito,
        variant: AppSnackbarVariant.success,
      );
      return;
    }
    AppSnackbar.show(
      context,
      message: failure.message ?? 'No se pudo asignar el recurso.',
      variant: AppSnackbarVariant.danger,
    );
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
