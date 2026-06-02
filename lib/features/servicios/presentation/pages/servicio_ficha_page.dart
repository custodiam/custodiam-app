// ServicioFichaPage: detalle del servicio + acciones según permisos.
//
// - Voluntarios: ver, apuntarse (US-03-08), desapuntarse (US-03-09).
// - Mandos: publicar (US-03-03), convocar a todos los disponibles
//   (US-03-04), cerrar (US-03-10).
// - La US-03-05/06 (convocar selección concreta / ampliar) se cubre
//   parcialmente desde aquí ofreciendo "convocar a todos los activos";
//   selección granular llegará con la sección de voluntarios cuando
//   el cliente reúna el catálogo paginado en un selector.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_destructive_button.dart';
import '../../../../core/ui/buttons/app_icon_button.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/maps/abrir_mapa_button.dart';
import '../../../../core/ui/buttons/app_text_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_confirm_dialog.dart';
import '../../../../core/ui/feedback/app_dialog.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_radius.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/estado_servicio.dart';
import '../../domain/entities/servicio.dart';
import '../../domain/entities/tipo_servicio.dart';
import '../viewmodels/servicio_ficha_view_model.dart';
import '../viewmodels/servicios_list_view_model.dart';
import '../widgets/recursos_asignados_section.dart';

class ServicioFichaPage extends ConsumerWidget {
  final String servicioId;

  const ServicioFichaPage({super.key, required this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPermissionGate(
      permission: Permission.serviciosVerPublicados,
      fallback: const _ForbiddenScreen(),
      child: _ServicioFichaBody(servicioId: servicioId),
    );
  }
}

class _ServicioFichaBody extends ConsumerWidget {
  final String servicioId;

  const _ServicioFichaBody({required this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState =
        ref.watch(servicioFichaViewModelProvider(servicioId));

    ref.listen(servicioFichaViewModelProvider(servicioId), (prev, next) {
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
      // Cuando una acción se completa con éxito (estado AsyncData
      // distinto al inicial), refrescamos también la lista en caché
      // para que al volver atrás vea el estado actualizado.
      if (prev?.isLoading == true && next.hasValue) {
        ref.read(serviciosListViewModelProvider.notifier).refresh();
      }
    });

    return asyncState.when(
      loading: () => const AppPageScaffold(
        title: 'Servicio',
        body: AppLoadingIndicator.fullScreen(),
      ),
      error: (error, _) => AppPageScaffold(
        title: 'Servicio',
        body: AppErrorState(
          title: 'No se pudo cargar el servicio',
          description: error is Failure
              ? error.message
              : 'Vuelve a intentarlo en unos segundos.',
          onRetry: () => ref
              .read(servicioFichaViewModelProvider(servicioId).notifier)
              .refresh(),
        ),
      ),
      data: (servicio) => _LoadedFicha(servicio: servicio),
    );
  }
}

class _LoadedFicha extends ConsumerWidget {
  final Servicio servicio;

  const _LoadedFicha({required this.servicio});

  String _formatDateTime(DateTime f) {
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    final hh = f.hour.toString().padLeft(2, '0');
    final mi = f.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${f.year} · $hh:$mi';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return AppPageScaffold(
      title: servicio.titulo,
      actions: [
        AppIconButton(
          key: K.servicioFichaRefreshBtn,
          tooltip: 'Recargar',
          icon: Symbols.refresh,
          onPressed: () => ref
              .read(servicioFichaViewModelProvider(servicio.id).notifier)
              .refresh(),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              _EstadoBadge(estado: servicio.estado),
              const SizedBox(width: AppSpacing.sm),
              _TipoBadge(tipo: servicio.tipo),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (servicio.descripcion != null &&
              servicio.descripcion!.isNotEmpty) ...[
            Text(servicio.descripcion!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
          ],
          const Divider(height: 1),
          _InfoRow(
            icon: Symbols.location_on,
            label: 'Ubicación',
            value: servicio.ubicacion,
          ),
          if (servicio.ubicacionLat != null && servicio.ubicacionLng != null)
            AbrirMapaButton(
              buttonKey: K.servicioFichaAbrirMapaBtn,
              lat: servicio.ubicacionLat!,
              lng: servicio.ubicacionLng!,
            ),
          _InfoRow(
            icon: Symbols.calendar_today,
            label: 'Inicio',
            value: _formatDateTime(servicio.fechaInicio),
          ),
          if (servicio.fechaFin != null)
            _InfoRow(
              icon: Symbols.event,
              label: 'Fin previsto',
              value: _formatDateTime(servicio.fechaFin!),
            ),
          if (servicio.numeroVoluntarios != null)
            _InfoRow(
              icon: Symbols.groups,
              label: 'Plazas',
              value:
                  '${servicio.inscritosCount}/${servicio.numeroVoluntarios}',
            ),
          if (servicio.notasMaterial != null &&
              servicio.notasMaterial!.isNotEmpty)
            _InfoRow(
              icon: Symbols.inventory_2,
              label: 'Material',
              value: servicio.notasMaterial!,
            ),
          if (servicio.notasVehiculos != null &&
              servicio.notasVehiculos!.isNotEmpty)
            _InfoRow(
              icon: Symbols.directions_car,
              label: 'Vehículos',
              value: servicio.notasVehiculos!,
            ),
          if (servicio.fechaCierre != null)
            _InfoRow(
              icon: Symbols.lock_clock,
              label: 'Cerrado el',
              value: _formatDateTime(servicio.fechaCierre!),
            ),
          if (servicio.observacionesCierre != null &&
              servicio.observacionesCierre!.isNotEmpty)
            _InfoRow(
              icon: Symbols.notes,
              label: 'Observaciones',
              value: servicio.observacionesCierre!,
            ),
          // — Recursos asignados al servicio (R1 / Opción 1B) —
          RecursosAsignadosSection(servicioId: servicio.id),
          const SizedBox(height: AppSpacing.lg),
          // — Acciones para voluntarios (self-service) —
          _SelfServiceActions(servicio: servicio),
          // — Acciones para mandos (transiciones de estado) —
          _AdminActions(servicio: servicio),
          // — Acceso a sección de fichaje (US-04-04 / US-04-01-02) —
          _FichajeShortcut(servicio: servicio),
        ],
      ),
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

class _SelfServiceActions extends ConsumerWidget {
  final Servicio servicio;

  const _SelfServiceActions({required this.servicio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState =
        ref.watch(servicioFichaViewModelProvider(servicio.id));
    final loading = asyncState.isLoading;
    // El backend admite inscripción mientras el servicio está
    // publicado o activo (CU-04 / EN-03-04). En cerrado/borrador no.
    final puedeApuntarse = servicio.estado == EstadoServicio.publicado ||
        servicio.estado == EstadoServicio.activo;

    // Gate de aforo (UI-only). null = aforo ilimitado → siempre
    // habilitado. El backend revalida la capacidad en la petición; esta
    // puerta solo evita ofrecer una acción que terminaría en 4xx.
    final aforoLleno = servicio.numeroVoluntarios != null &&
        servicio.inscritosCount >= servicio.numeroVoluntarios!;
    final canApuntarse = puedeApuntarse && !aforoLleno;

    return Column(
      children: [
        if (puedeApuntarse)
          AppPermissionGate(
            permission: Permission.serviciosApuntarsePropio,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Semantics(
                // AppPrimaryButton solo se deshabilita vía onPressed null
                // y no expone un slot de etiqueta accesible, así que
                // anunciamos el motivo aquí para el lector de pantalla.
                label: aforoLleno ? 'Aforo completo' : null,
                child: AppPrimaryButton(
                  key: K.servicioFichaApuntarseBtn,
                  label: 'Apuntarme',
                  icon: Symbols.check_circle,
                  expanded: true,
                  isLoading: loading,
                  onPressed: (loading || !canApuntarse)
                      ? null
                      : () => ref
                          .read(servicioFichaViewModelProvider(servicio.id)
                              .notifier)
                          .apuntarse(),
                ),
              ),
            ),
          ),
        if (puedeApuntarse)
          AppPermissionGate(
            permission: Permission.serviciosDesapuntarsePropio,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: AppSecondaryButton(
                key: K.servicioFichaDesapuntarseBtn,
                label: 'Darme de baja',
                icon: Symbols.cancel,
                expanded: true,
                onPressed: loading
                    ? null
                    : () async {
                        final ok = await AppConfirmDialog.show(
                          context,
                          title: 'Darse de baja',
                          message:
                              '¿Seguro que quieres darte de baja de "${servicio.titulo}"? '
                              'Otros voluntarios podrán ocupar tu plaza.',
                          confirmLabel: 'Darme de baja',
                          isDestructive: true,
                        );
                        if (!ok) return;
                        await ref
                            .read(servicioFichaViewModelProvider(servicio.id)
                                .notifier)
                            .desapuntarse();
                      },
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminActions extends ConsumerWidget {
  final Servicio servicio;

  const _AdminActions({required this.servicio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState =
        ref.watch(servicioFichaViewModelProvider(servicio.id));
    final loading = asyncState.isLoading;

    final items = <Widget>[];

    if (servicio.estado == EstadoServicio.borrador) {
      items.add(AppPermissionGate(
        permission: Permission.serviciosPublicar,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: AppPrimaryButton(
            key: K.servicioFichaPublicarBtn,
            label: 'Publicar servicio',
            icon: Symbols.public,
            expanded: true,
            isLoading: loading,
            onPressed: loading
                ? null
                : () => ref
                    .read(servicioFichaViewModelProvider(servicio.id)
                        .notifier)
                    .publicar(),
          ),
        ),
      ));
    }

    if (servicio.estado == EstadoServicio.publicado ||
        servicio.estado == EstadoServicio.activo) {
      items.add(AppPermissionGate(
        permission: Permission.serviciosConvocar,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: AppSecondaryButton(
            key: K.servicioFichaConvocarBtn,
            label: 'Convocar voluntarios disponibles',
            icon: Symbols.campaign,
            expanded: true,
            onPressed: loading
                ? null
                : () async {
                    final ok = await AppConfirmDialog.show(
                      context,
                      title: 'Convocar voluntarios',
                      message:
                          'Se convocará a todos los voluntarios activos disponibles. '
                          '¿Continuar?',
                      confirmLabel: 'Convocar',
                    );
                    if (!ok) return;
                    await ref
                        .read(servicioFichaViewModelProvider(servicio.id)
                            .notifier)
                        .convocarTodos();
                  },
          ),
        ),
      ));
    }

    if (servicio.estado == EstadoServicio.activo) {
      items.add(AppPermissionGate(
        permission: Permission.serviciosCerrar,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: AppDestructiveButton(
            key: K.servicioFichaCerrarBtn,
            label: 'Cerrar servicio',
            icon: Symbols.lock,
            expanded: true,
            onPressed: loading
                ? null
                : () => _abrirCerrarDialog(context, ref, servicio.id),
          ),
        ),
      ));
    }

    return Column(children: items);
  }

  Future<void> _abrirCerrarDialog(
    BuildContext context,
    WidgetRef ref,
    String servicioId,
  ) async {
    // El diálogo es un StatefulWidget que posee y libera su controller en
    // State.dispose(); devuelve el texto de observaciones en el pop (null si
    // se cancela). Antes el controller era local y no se liberaba nunca (leak).
    final observacionesRaw = await AppDialog.showBuilder<String>(
      context,
      builder: (_) => const _CerrarServicioDialog(),
    );
    if (observacionesRaw == null) return;
    final obs = observacionesRaw.trim();
    await ref
        .read(servicioFichaViewModelProvider(servicioId).notifier)
        .cerrar(observaciones: obs.isEmpty ? null : obs);
  }
}

/// Diálogo de cierre de servicio. StatefulWidget para liberar el controller
/// de observaciones en dispose(), atado al ciclo de vida del diálogo;
/// devuelve el texto en el pop (null al cancelar).
class _CerrarServicioDialog extends StatefulWidget {
  const _CerrarServicioDialog();

  @override
  State<_CerrarServicioDialog> createState() => _CerrarServicioDialogState();
}

class _CerrarServicioDialogState extends State<_CerrarServicioDialog> {
  final _observacionesCtrl = TextEditingController();

  @override
  void dispose() {
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Cerrar servicio',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'El servicio quedará cerrado y se sellarán automáticamente '
            'los fichajes que sigan abiertos.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: K.servicioFichaCerrarObservacionesField,
            label: 'Observaciones (opcional)',
            controller: _observacionesCtrl,
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
          key: K.servicioFichaCerrarConfirmBtn,
          label: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(_observacionesCtrl.text),
        ),
      ],
    );
  }
}

class _FichajeShortcut extends ConsumerWidget {
  final Servicio servicio;

  const _FichajeShortcut({required this.servicio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final esActivo = servicio.estado == EstadoServicio.activo;
    final puedeFichar = esActivo &&
        (user?.hasPermission(Permission.fichajeFicharPropio) ?? false);
    final puedeVerVoluntarios =
        user?.hasPermission(Permission.fichajeVerVoluntariosEnServicio) ??
            false;

    if (!puedeFichar && !puedeVerVoluntarios) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Fichaje',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppPrimaryButton(
            key: K.servicioFichaFichajeAccesoBtn,
            label: puedeFichar
                ? 'Fichar entrada / salida'
                : 'Ver voluntarios fichados',
            icon: puedeFichar ? Symbols.fingerprint : Symbols.list_alt,
            expanded: true,
            onPressed: () =>
                context.go('/servicios/${servicio.id}/fichaje'),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoServicio estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Guía 28 §WCAG 1.4.1: icono + color + texto, no solo color.
    final (Color bg, Color fg, IconData icon, String label) = switch (estado) {
      EstadoServicio.borrador => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          Symbols.edit_note,
          'Borrador',
        ),
      EstadoServicio.publicado => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
          Symbols.campaign,
          'Publicado',
        ),
      EstadoServicio.activo => (
          theme.colorScheme.tertiaryContainer,
          theme.colorScheme.onTertiaryContainer,
          Symbols.play_circle,
          'Activo',
        ),
      EstadoServicio.cerrado => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          Symbols.lock,
          'Cerrado',
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

class _TipoBadge extends StatelessWidget {
  final TipoServicio tipo;
  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Guía 28 §WCAG 1.4.1: icono + color + texto, no solo color.
    final (Color bg, Color fg, IconData icon, String label) = switch (tipo) {
      TipoServicio.emergencia => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
          Symbols.warning_amber,
          'Emergencia',
        ),
      TipoServicio.preventivo => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
          Symbols.shield,
          'Preventivo',
        ),
      TipoServicio.formacion => (
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
          Symbols.school,
          'Formación',
        ),
      TipoServicio.otro => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          Symbols.event,
          'Otro',
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
      title: 'Servicio',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite consultar este servicio.',
        icon: Symbols.lock,
      ),
    );
  }
}
