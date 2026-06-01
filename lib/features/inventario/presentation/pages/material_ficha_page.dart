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

import '../../../../app/test_keys.dart';
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
          key: K.materialFichaRefresh,
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
                      key: K.materialFichaAsignarPersonal,
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
                      key: K.materialFichaPrestar,
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
                    key: K.materialFichaDevolver,
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
                    key: K.materialFichaAveria,
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
                    key: K.materialFichaPerdida,
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
    // El diálogo es un StatefulWidget que posee y libera sus propios
    // TextEditingController en su State.dispose(). Así la liberación se
    // ancla al ciclo de vida del subárbol del diálogo y no a un `finally`
    // que se ejecutaría mientras la animación de cierre todavía rebuildea
    // los campos con un controller ya liberado.
    final result = await AppDialog.showBuilder<_AsignarResult>(
      context,
      builder: (_) => _AsignarDialog(tipo: tipo),
    );
    if (result == null) return;
    if (!context.mounted) return;
    final voluntarioId = result.voluntarioId.trim();
    final cantidad = int.tryParse(result.cantidad.trim()) ?? 1;
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
  }

  Future<void> _abrirDialogDevolver(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await AppDialog.showBuilder<_DevolverResult>(
      context,
      builder: (_) => const _DevolverDialog(),
    );
    if (result == null) return;
    if (!context.mounted) return;
    final voluntarioId = result.voluntarioId.trim();
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
    final observaciones = result.observaciones.trim();
    final success = await notifier.devolver(
      voluntarioId: voluntarioId,
      observaciones: observaciones.isEmpty ? null : observaciones,
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
  }

  Future<void> _abrirDialogIncidencia(
    BuildContext context,
    WidgetRef ref,
    EstadoInventario nuevoEstado,
    String title,
  ) async {
    final descripcionRaw = await AppDialog.showBuilder<String>(
      context,
      builder: (_) => _IncidenciaDialog(title: title),
    );
    if (descripcionRaw == null) return;
    if (!context.mounted) return;
    final descripcion = descripcionRaw.trim();
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
  }
}

/// Valores capturados por el diálogo de asignación/préstamo.
class _AsignarResult {
  final String voluntarioId;
  final String cantidad;
  const _AsignarResult(this.voluntarioId, this.cantidad);
}

/// Valores capturados por el diálogo de devolución.
class _DevolverResult {
  final String voluntarioId;
  final String observaciones;
  const _DevolverResult(this.voluntarioId, this.observaciones);
}

/// Diálogo de asignación/préstamo. Es un StatefulWidget para que los
/// controllers se liberen en dispose() — atado al ciclo de vida del
/// diálogo — y no en un `finally` que corre durante la animación de cierre.
class _AsignarDialog extends StatefulWidget {
  final TipoAsignacion tipo;
  const _AsignarDialog({required this.tipo});

  @override
  State<_AsignarDialog> createState() => _AsignarDialogState();
}

class _AsignarDialogState extends State<_AsignarDialog> {
  final _voluntarioCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _voluntarioCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.tipo == TipoAsignacion.personal
          ? 'Asignar equipamiento personal'
          : 'Prestar material',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            key: K.materialAsignarVoluntarioId,
            label: 'ID del voluntario (UUID)',
            controller: _voluntarioCtrl,
            prefixIcon: Symbols.person,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: K.materialAsignarCantidad,
            label: 'Cantidad',
            controller: _cantidadCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Symbols.numbers,
          ),
        ],
      ),
      actions: [
        AppTextButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(
          key: K.materialAsignarConfirm,
          label: 'Asignar',
          onPressed: () => Navigator.of(context).pop(
            _AsignarResult(_voluntarioCtrl.text, _cantidadCtrl.text),
          ),
        ),
      ],
    );
  }
}

/// Diálogo de devolución. Ver nota de ciclo de vida en [_AsignarDialog].
class _DevolverDialog extends StatefulWidget {
  const _DevolverDialog();

  @override
  State<_DevolverDialog> createState() => _DevolverDialogState();
}

class _DevolverDialogState extends State<_DevolverDialog> {
  final _voluntarioCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  @override
  void dispose() {
    _voluntarioCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Registrar devolución',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            key: K.materialDevolverVoluntarioId,
            label: 'ID del voluntario que devuelve',
            controller: _voluntarioCtrl,
            prefixIcon: Symbols.person,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: K.materialDevolverObservaciones,
            label: 'Observaciones (opcional)',
            controller: _observacionesCtrl,
            prefixIcon: Symbols.notes,
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        AppTextButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(
          key: K.materialDevolverConfirm,
          label: 'Devolver',
          onPressed: () => Navigator.of(context).pop(
            _DevolverResult(_voluntarioCtrl.text, _observacionesCtrl.text),
          ),
        ),
      ],
    );
  }
}

/// Diálogo de incidencia (avería/pérdida). Devuelve la descripción cruda;
/// la validación de vacío la hace la página tras cerrar. Ver nota de ciclo
/// de vida en [_AsignarDialog].
class _IncidenciaDialog extends StatefulWidget {
  final String title;
  const _IncidenciaDialog({required this.title});

  @override
  State<_IncidenciaDialog> createState() => _IncidenciaDialogState();
}

class _IncidenciaDialogState extends State<_IncidenciaDialog> {
  final _descripcionCtrl = TextEditingController();

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      content: AppTextField(
        key: K.materialIncidenciaDescripcion,
        label: 'Descripción de la incidencia',
        controller: _descripcionCtrl,
        prefixIcon: Symbols.notes,
        maxLines: 4,
      ),
      actions: [
        AppTextButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppPrimaryButton(
          key: K.materialIncidenciaConfirm,
          label: 'Registrar',
          onPressed: () => Navigator.of(context).pop(_descripcionCtrl.text),
        ),
      ],
    );
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
