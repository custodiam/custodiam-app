// VehiculoFichaPage. Detalle de un vehículo + acción "reportar
// incidencia" (US-05-08/09 para vehículos).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_destructive_button.dart';
import '../../../../core/ui/buttons/app_icon_button.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_text_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_dialog.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_radius.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/tipo_vehiculo.dart';
import '../../domain/entities/vehiculo_item.dart';
import '../viewmodels/vehiculo_ficha_view_model.dart';
import '../viewmodels/vehiculos_list_view_model.dart';

class VehiculoFichaPage extends ConsumerWidget {
  final String vehiculoId;

  const VehiculoFichaPage({super.key, required this.vehiculoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPermissionGate(
      permission: Permission.inventarioVer,
      fallback: const _ForbiddenScreen(),
      child: _VehiculoFichaBody(vehiculoId: vehiculoId),
    );
  }
}

class _VehiculoFichaBody extends ConsumerWidget {
  final String vehiculoId;
  const _VehiculoFichaBody({required this.vehiculoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState =
        ref.watch(vehiculoFichaViewModelProvider(vehiculoId));

    ref.listen(vehiculoFichaViewModelProvider(vehiculoId), (prev, next) {
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
        ref.read(vehiculosListViewModelProvider.notifier).refresh();
      }
    });

    return asyncState.when(
      loading: () => const AppPageScaffold(
        title: 'Vehículo',
        body: AppLoadingIndicator.fullScreen(),
      ),
      error: (error, _) => AppPageScaffold(
        title: 'Vehículo',
        body: AppErrorState(
          title: 'No se pudo cargar el vehículo',
          description: error is Failure ? error.message : null,
          onRetry: () => ref
              .read(vehiculoFichaViewModelProvider(vehiculoId).notifier)
              .refresh(),
        ),
      ),
      data: (vehiculo) => _LoadedVehiculo(vehiculo: vehiculo),
    );
  }
}

class _LoadedVehiculo extends ConsumerWidget {
  final VehiculoItem vehiculo;
  const _LoadedVehiculo({required this.vehiculo});

  String _tipoLabel(TipoVehiculo t) => switch (t) {
        TipoVehiculo.furgoneta => 'Furgoneta',
        TipoVehiculo.pickUp => 'Pick-up',
        TipoVehiculo.ambulancia => 'Ambulancia',
        TipoVehiculo.remolque => 'Remolque',
      };

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auditoría RBAC (29-may, hallazgo B3): se migra el check inline
    // por permiso a `AppPermissionGate` para unificar el patrón con el
    // resto de pages. El `if` por `estado` se conserva como regla de
    // dominio (no RBAC).
    return AppPageScaffold(
      title: '${vehiculo.codigoInterno} · ${vehiculo.matricula}',
      actions: [
        AppIconButton(
          key: const ValueKey('vehiculo_ficha_refresh'),
          tooltip: 'Recargar',
          icon: Icons.refresh,
          onPressed: () => ref
              .read(vehiculoFichaViewModelProvider(vehiculo.id).notifier)
              .refresh(),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _EstadoBadge(estado: vehiculo.estado),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.commute_outlined,
            label: 'Tipo',
            value: _tipoLabel(vehiculo.tipo),
          ),
          if (vehiculo.marcaModelo != null)
            _InfoRow(
              icon: Icons.directions_car_outlined,
              label: 'Marca y modelo',
              value: vehiculo.marcaModelo!,
            ),
          if (vehiculo.fechaItv != null)
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Próxima ITV',
              value: _formatDate(vehiculo.fechaItv!),
            ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Ubicación',
            value: vehiculo.ubicacionBase,
          ),
          if (vehiculo.observaciones != null &&
              vehiculo.observaciones!.isNotEmpty)
            _InfoRow(
              icon: Icons.notes_outlined,
              label: 'Observaciones',
              value: vehiculo.observaciones!,
            ),
          if (vehiculo.observacionesIncidencia != null &&
              vehiculo.observacionesIncidencia!.isNotEmpty)
            _InfoRow(
              icon: Icons.warning_amber_outlined,
              label: 'Incidencia registrada',
              value: vehiculo.observacionesIncidencia!,
            ),
          const SizedBox(height: AppSpacing.lg),
          if (vehiculo.estado != EstadoInventario.averiado &&
              vehiculo.estado != EstadoInventario.perdido)
            AppPermissionGate(
              permission: Permission.inventarioReportarIncidencia,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDestructiveButton(
                    key: const ValueKey('vehiculo_ficha_averia'),
                    label: 'Reportar avería',
                    icon: Icons.build_outlined,
                    expanded: true,
                    onPressed: () => _abrirIncidencia(
                      context,
                      ref,
                      EstadoInventario.averiado,
                      'Reportar avería',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppDestructiveButton(
                    key: const ValueKey('vehiculo_ficha_perdida'),
                    label: 'Reportar pérdida',
                    icon: Icons.report_outlined,
                    expanded: true,
                    onPressed: () => _abrirIncidencia(
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

  Future<void> _abrirIncidencia(
    BuildContext context,
    WidgetRef ref,
    EstadoInventario nuevoEstado,
    String title,
  ) async {
    final descripcionCtrl = TextEditingController();
    final ok = await AppDialog.show<bool>(
      context,
      title: title,
      content: AppTextField(
        key: const ValueKey('vehiculo_incidencia_descripcion'),
        label: 'Descripción de la incidencia',
        controller: descripcionCtrl,
        prefixIcon: Icons.notes_outlined,
        maxLines: 4,
      ),
      actions: [
        AppTextButton(
          label: 'Cancelar',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppPrimaryButton(
          key: const ValueKey('vehiculo_incidencia_confirm'),
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
        .read(vehiculoFichaViewModelProvider(vehiculo.id).notifier)
        .reportarIncidencia(
          nuevoEstado: nuevoEstado,
          descripcion: descripcion,
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

class _EstadoBadge extends StatelessWidget {
  final EstadoInventario estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Guía 28 §WCAG 1.4.1: icono + color + texto, no solo color.
    final (Color bg, Color fg, IconData icon, String label) = switch (estado) {
      EstadoInventario.operativo => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
          Icons.check_circle_outline,
          'Operativo',
        ),
      EstadoInventario.averiado => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
          Icons.build_outlined,
          'Averiado',
        ),
      EstadoInventario.perdido => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          Icons.report_outlined,
          'Perdido',
        ),
      EstadoInventario.enUso => (
          theme.colorScheme.tertiaryContainer,
          theme.colorScheme.onTertiaryContainer,
          Icons.handyman_outlined,
          'En uso',
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: TextStyle(color: fg)),
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
      title: 'Vehículo',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite consultar el inventario.',
        icon: Icons.lock_outline,
      ),
    );
  }
}
