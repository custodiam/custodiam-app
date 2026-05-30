// MaterialFichaPage. Detalle de un material + acciones según permisos:
//
// - US-05-08 / US-05-09: reportar avería o pérdida
//   (inventario.reportar_incidencia)
// - US-05-03 / US-05-04: asignar a un voluntario, en modo PERSONAL o
//   PRESTAMO (permiso dinámico según tipo de asignación, el backend
//   exige el correcto; el cliente ya filtra los modos disponibles)
// - US-05-05: registrar devolución (inventario.registrar_devolucion)
//
// El selector de voluntario es un dialog con TextField de UUID por
// ahora — la documentación del PR lo declara como deuda técnica
// (TODO US-05-03 paso 2: integrar selector con catálogo /voluntarios).

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_destructive_button.dart';
import '../../../../core/ui/buttons/app_icon_button.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/buttons/app_text_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_dialog.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/entities/tipo_asignacion.dart';
import '../../domain/entities/tipo_material.dart';
import '../viewmodels/material_ficha_view_model.dart';
import '../viewmodels/materiales_list_view_model.dart';
import '../widgets/asignacion_actual_section.dart';
import '../widgets/inventario_estado_badge.dart';

class MaterialFichaPage extends ConsumerWidget {
  final String materialId;

  const MaterialFichaPage({super.key, required this.materialId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPermissionGate(
      permission: Permission.inventarioVer,
      fallback: const _ForbiddenScreen(),
      child: _MaterialFichaBody(materialId: materialId),
    );
  }
}

class _MaterialFichaBody extends ConsumerWidget {
  final String materialId;
  const _MaterialFichaBody({required this.materialId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState =
        ref.watch(materialFichaViewModelProvider(materialId));

    ref.listen(materialFichaViewModelProvider(materialId), (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'No se pudo completar la acción.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
      if (prev?.isLoading == true && next.hasValue) {
        ref.read(materialesListViewModelProvider.notifier).refresh();
      }
    });

    return asyncState.when(
      loading: () => const AppPageScaffold(
        title: 'Material',
        body: AppLoadingIndicator.fullScreen(),
      ),
      error: (error, _) => AppPageScaffold(
        title: 'Material',
        body: AppErrorState(
          title: 'No se pudo cargar el material',
          description: error is Failure ? error.message : null,
          onRetry: () => ref
              .read(materialFichaViewModelProvider(materialId).notifier)
              .refresh(),
        ),
      ),
      data: (material) => _LoadedMaterial(material: material),
    );
  }
}

class _LoadedMaterial extends ConsumerWidget {
  final MaterialItem material;
  const _LoadedMaterial({required this.material});

  String _tipoLabel(TipoMaterial t) => switch (t) {
        TipoMaterial.personal => 'Personal',
        TipoMaterial.prestable => 'Prestable',
        TipoMaterial.servicio => 'Servicio',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auditoría RBAC (29-may, hallazgo B3): la ficha leía los permisos
    // con `user.hasPermission` y los inlineaba en `if`s. Funciona pero
    // rompe la convención del repo (resto de pages envuelven en
    // `AppPermissionGate`). Migramos a `AppPermissionGate` para que un
    // grep por `AppPermissionGate` localice todas las superficies
    // gateadas, y que los tests genéricos por rol funcionen igual aquí
    // que en otras pages. El `if` por `estado`/`tipo` se conserva como
    // regla de dominio (no RBAC) — decide si el botón aparece en
    // absoluto; el `AppPermissionGate` decide si el usuario lo ve.

    return AppPageScaffold(
      title: material.nombre,
      actions: [
        AppIconButton(
          key: const ValueKey('material_ficha_refresh'),
          tooltip: 'Recargar',
          icon: Symbols.refresh,
          onPressed: () => ref
              .read(materialFichaViewModelProvider(material.id).notifier)
              .refresh(),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          InventarioEstadoBadge(estado: material.estado),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Symbols.category,
            label: 'Tipo',
            value: _tipoLabel(material.tipo),
          ),
          if (material.codigo != null)
            _InfoRow(
              icon: Symbols.tag,
              label: 'Código',
              value: material.codigo!,
            ),
          if (material.numeroSerie != null)
            _InfoRow(
              icon: Symbols.confirmation_number,
              label: 'Nº de serie',
              value: material.numeroSerie!,
            ),
          if (material.categoria != null)
            _InfoRow(
              icon: Symbols.label,
              label: 'Categoría',
              value: material.categoria!,
            ),
          _InfoRow(
            icon: Symbols.numbers,
            label: 'Cantidad',
            value: material.cantidad.toString(),
          ),
          _InfoRow(
            icon: Symbols.location_on,
            label: 'Ubicación',
            value: material.ubicacionBase ?? 'Sin ubicación',
          ),
          if (material.descripcion != null &&
              material.descripcion!.isNotEmpty)
            _InfoRow(
              icon: Symbols.description,
              label: 'Descripción',
              value: material.descripcion!,
            ),
          if (material.observacionesIncidencia != null &&
              material.observacionesIncidencia!.isNotEmpty)
            _InfoRow(
              icon: Symbols.warning_amber,
              label: 'Incidencia registrada',
              value: material.observacionesIncidencia!,
            ),
          AsignacionActualSection(asignaciones: material.asignacionesActivas),
          const SizedBox(height: AppSpacing.lg),

          // — Acciones de asignación / devolución (solo si operativo) —
          if (material.estado == EstadoInventario.operativo) ...[
            if (material.tipo == TipoMaterial.personal)
              AppPermissionGate(
                permission:
                    Permission.inventarioAsignarEquipamientoPersonal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppPrimaryButton(
                      key: const ValueKey('material_ficha_asignar_personal'),
                      label: 'Asignar como equipamiento personal',
                      icon: Symbols.person_add,
                      expanded: true,
                      onPressed: () => _abrirDialogAsignar(
                        context,
                        ref,
                        tipo: TipoAsignacion.personal,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            if (material.tipo == TipoMaterial.prestable)
              AppPermissionGate(
                permission: Permission.inventarioPrestarTemporal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppPrimaryButton(
                      key: const ValueKey('material_ficha_prestar'),
                      label: 'Prestar a un voluntario',
                      icon: Symbols.swap_horiz,
                      expanded: true,
                      onPressed: () => _abrirDialogAsignar(
                        context,
                        ref,
                        tipo: TipoAsignacion.prestamo,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            AppPermissionGate(
              permission: Permission.inventarioRegistrarDevolucion,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSecondaryButton(
                    key: const ValueKey('material_ficha_devolver'),
                    label: 'Registrar devolución',
                    icon: Symbols.assignment_return,
                    expanded: true,
                    onPressed: () => _abrirDialogDevolver(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ],

          // — Acciones de incidencia (siempre que el material no
          //   esté ya en estado final) —
          if (material.estado != EstadoInventario.averiado &&
              material.estado != EstadoInventario.perdido)
            AppPermissionGate(
              permission: Permission.inventarioReportarIncidencia,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDestructiveButton(
                    key: const ValueKey('material_ficha_averia'),
                    label: 'Reportar avería',
                    icon: Symbols.build,
                    expanded: true,
                    onPressed: () => _abrirDialogIncidencia(
                      context,
                      ref,
                      EstadoInventario.averiado,
                      'Reportar avería',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppDestructiveButton(
                    key: const ValueKey('material_ficha_perdida'),
                    label: 'Reportar pérdida',
                    icon: Symbols.report,
                    expanded: true,
                    onPressed: () => _abrirDialogIncidencia(
                      context,
                      ref,
                      EstadoInventario.perdido,
                      'Reportar pérdida',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _abrirDialogAsignar(
    BuildContext context,
    WidgetRef ref, {
    required TipoAsignacion tipo,
  }) async {
    final voluntarioCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController(text: '1');
    try {
      final ok = await AppDialog.show<bool>(
        context,
        title: tipo == TipoAsignacion.personal
            ? 'Asignar equipamiento personal'
            : 'Prestar material',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              key: const ValueKey('material_asignar_voluntario_id'),
              label: 'ID del voluntario (UUID)',
              controller: voluntarioCtrl,
              prefixIcon: Symbols.person,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('material_asignar_cantidad'),
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
            key: const ValueKey('material_asignar_confirm'),
            label: 'Asignar',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
      if (ok != true) return;
      if (!context.mounted) return;
      final voluntarioId = voluntarioCtrl.text.trim();
      final cantidad = int.tryParse(cantidadCtrl.text.trim()) ?? 1;
      if (voluntarioId.isEmpty) {
        AppSnackbar.show(
          context,
          message: 'Indica el ID del voluntario.',
          variant: AppSnackbarVariant.warning,
        );
        return;
      }
      final notifier =
          ref.read(materialFichaViewModelProvider(material.id).notifier);
      final success = await notifier.asignarAVoluntario(
        voluntarioId: voluntarioId,
        tipo: tipo,
        cantidad: cantidad,
      );
      if (!context.mounted) return;
      if (success) {
        AppSnackbar.show(
          context,
          message: 'Asignación registrada.',
          variant: AppSnackbarVariant.success,
        );
        await notifier.refresh();
      }
    } finally {
      voluntarioCtrl.dispose();
      cantidadCtrl.dispose();
    }
  }

  Future<void> _abrirDialogDevolver(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final voluntarioCtrl = TextEditingController();
    final observacionesCtrl = TextEditingController();
    try {
      final ok = await AppDialog.show<bool>(
        context,
        title: 'Registrar devolución',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              key: const ValueKey('material_devolver_voluntario_id'),
              label: 'ID del voluntario que devuelve',
              controller: voluntarioCtrl,
              prefixIcon: Symbols.person,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('material_devolver_observaciones'),
              label: 'Observaciones (opcional)',
              controller: observacionesCtrl,
              prefixIcon: Symbols.notes,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          AppTextButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppPrimaryButton(
            key: const ValueKey('material_devolver_confirm'),
            label: 'Devolver',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
      if (ok != true) return;
      if (!context.mounted) return;
      final voluntarioId = voluntarioCtrl.text.trim();
      if (voluntarioId.isEmpty) {
        AppSnackbar.show(
          context,
          message: 'Indica el ID del voluntario.',
          variant: AppSnackbarVariant.warning,
        );
        return;
      }
      final notifier =
          ref.read(materialFichaViewModelProvider(material.id).notifier);
      final success = await notifier.devolver(
        voluntarioId: voluntarioId,
        observaciones: observacionesCtrl.text.trim().isEmpty
            ? null
            : observacionesCtrl.text.trim(),
      );
      if (!context.mounted) return;
      if (success) {
        AppSnackbar.show(
          context,
          message: 'Devolución registrada.',
          variant: AppSnackbarVariant.success,
        );
        await notifier.refresh();
      }
    } finally {
      voluntarioCtrl.dispose();
      observacionesCtrl.dispose();
    }
  }

  Future<void> _abrirDialogIncidencia(
    BuildContext context,
    WidgetRef ref,
    EstadoInventario nuevoEstado,
    String title,
  ) async {
    final descripcionCtrl = TextEditingController();
    try {
      final ok = await AppDialog.show<bool>(
        context,
        title: title,
        content: AppTextField(
          key: const ValueKey('material_incidencia_descripcion'),
          label: 'Descripción de la incidencia',
          controller: descripcionCtrl,
          prefixIcon: Symbols.notes,
          maxLines: 4,
        ),
        actions: [
          AppTextButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppPrimaryButton(
            key: const ValueKey('material_incidencia_confirm'),
            label: 'Registrar',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
      if (ok != true) return;
      if (!context.mounted) return;
      final descripcion = descripcionCtrl.text.trim();
      if (descripcion.isEmpty) {
        AppSnackbar.show(
          context,
          message: 'La descripción es obligatoria.',
          variant: AppSnackbarVariant.warning,
        );
        return;
      }
      await ref
          .read(materialFichaViewModelProvider(material.id).notifier)
          .reportarIncidencia(
            nuevoEstado: nuevoEstado,
            descripcion: descripcion,
          );
    } finally {
      descripcionCtrl.dispose();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Material',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite consultar el inventario.',
        icon: Symbols.lock,
      ),
    );
  }
}
