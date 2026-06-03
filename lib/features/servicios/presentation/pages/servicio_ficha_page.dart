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
import '../widgets/personal_servicio_section.dart';
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
    final asyncState = ref.watch(servicioFichaViewModelProvider(servicioId));

    ref.listen(servicioFichaViewModelProvider(servicioId), (prev, next) {
      // Cuando una acción se completa con éxito, el view model reemplaza el
      // AsyncData por uno nuevo (el servicio que devuelve el backend con el
      // estado/inscripción ya actualizado). Recargamos también la lista en
      // caché —de forma silenciosa, sin spinner— para que al volver atrás se
      // vea el estado actualizado sin parpadeo. Las acciones ya no emiten
      // AsyncError, así que el feedback de error lo pinta cada handler con la
      // Failure devuelta; aquí no duplicamos snackbars.
      if (prev?.hasValue == true &&
          next.hasValue &&
          !identical(prev!.value, next.value)) {
        ref.read(serviciosListViewModelProvider.notifier).reloadSilently();
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
        // A5 Editar: mismo permiso que el PATCH del backend
        // (servicios.crear_preventivo).
        AppPermissionGate(
          permission: Permission.serviciosCrearPreventivo,
          child: AppIconButton(
            key: K.servicioFichaEditarBtn,
            tooltip: 'Editar',
            icon: Symbols.edit,
            onPressed: () => context.go('/servicios/${servicio.id}/editar'),
          ),
        ),
        AppIconButton(
          key: K.servicioFichaRefreshBtn,
          tooltip: 'Recargar',
          icon: Symbols.refresh,
          onPressed: () => ref
              .read(servicioFichaViewModelProvider(servicio.id).notifier)
              .refresh(),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(servicioFichaViewModelProvider(servicio.id).notifier)
            .refresh(),
        child: ListView(
          // AlwaysScrollable para que el gesto de pull-to-refresh funcione
          // aunque el contenido no llene la pantalla (patrón de las listas).
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _EstadoBadge(estado: servicio.estado),
                _TipoBadge(tipo: servicio.tipo),
                // A8: indicador visible de inscripción propia. Icono + texto
                // (no solo color, guía 28 §WCAG 1.4.1).
                if (servicio.estoyInscrito) const _InscritoChip(),
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
            if ((servicio.ubicacionLat != null &&
                    servicio.ubicacionLng != null) ||
                servicio.ubicacion.trim().isNotEmpty)
              AbrirMapaButton(
                buttonKey: K.servicioFichaAbrirMapaBtn,
                // Con coordenadas mandan ellas; si solo hay texto, la ruta se
                // resuelve por búsqueda de la dirección escrita (Opción 3).
                lat: servicio.ubicacionLat,
                lng: servicio.ubicacionLng,
                texto: servicio.ubicacion,
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
            // — Personal del servicio (A9) — todos los operativos pueden verlo
            // (servicios.ver_publicados); el backend recorta el teléfono según
            // el rol de quien consulta.
            AppPermissionGate(
              permission: Permission.serviciosVerPublicados,
              child: PersonalServicioSection(servicioId: servicio.id),
            ),
            const SizedBox(height: AppSpacing.lg),
            // — Acciones para voluntarios (self-service) —
            _SelfServiceActions(servicio: servicio),
            // — Acciones para mandos (transiciones de estado) —
            _AdminActions(servicio: servicio),
            // — Acceso a sección de fichaje (US-04-04 / US-04-01-02) —
            _FichajeShortcut(servicio: servicio),
            // — Borrar servicio (A7), acción secundaria al pie de la ficha —
            _BorrarAction(servicio: servicio),
          ],
        ),
      ),
    );
  }
}

/// A7 Borrar. Acción destructiva al pie de la ficha (no es la acción primaria:
/// va separada y en estilo destructivo). Gateada por
/// `servicios.crear_preventivo` —mismo permiso que el DELETE del backend—.
/// Tras confirmar, si el borrado tiene éxito navega a la lista; si el backend
/// devuelve 409 (servicio con actividad: "ciérralo en lugar de borrarlo")
/// muestra el mensaje y NO navega.
class _BorrarAction extends ConsumerStatefulWidget {
  final Servicio servicio;

  const _BorrarAction({required this.servicio});

  @override
  ConsumerState<_BorrarAction> createState() => _BorrarActionState();
}

class _BorrarActionState extends ConsumerState<_BorrarAction> {
  // Flag local de "borrado en curso": deshabilita el botón mientras corre el
  // DELETE, sin depender del AsyncLoading global (que ya no usan las acciones).
  bool _enCurso = false;

  @override
  Widget build(BuildContext context) {
    final loading = _enCurso;
    return AppPermissionGate(
      permission: Permission.serviciosCrearPreventivo,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: AppDestructiveButton(
          key: K.servicioFichaBorrarBtn,
          label: 'Borrar servicio',
          icon: Symbols.delete,
          expanded: true,
          onPressed: loading ? null : _borrar,
        ),
      ),
    );
  }

  Future<void> _borrar() async {
    final servicio = widget.servicio;
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Borrar servicio',
      message:
          '¿Seguro que quieres borrar "${servicio.titulo}"? Esta acción no se '
          'puede deshacer y desconvocará al personal asignado, además de '
          'liberar el material y los vehículos reservados para este servicio. '
          'Si el servicio ya tiene actividad, ciérralo en lugar de borrarlo.',
      confirmLabel: 'Borrar',
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _enCurso = true);
    final Failure? failure;
    try {
      failure = await ref
          .read(servicioFichaViewModelProvider(servicio.id).notifier)
          .eliminar();
    } finally {
      if (mounted) setState(() => _enCurso = false);
    }
    if (!mounted) return;
    if (failure == null) {
      // Éxito: refrescamos la lista en caché y volvemos a ella.
      ref.read(serviciosListViewModelProvider.notifier).reloadSilently();
      AppSnackbar.show(
        context,
        message: 'Servicio borrado.',
        variant: AppSnackbarVariant.success,
      );
      context.go('/servicios');
      return;
    }
    // Fallo (incluido el 409 ServicioTieneActividad): mostramos el mensaje del
    // backend y permanecemos en la ficha.
    AppSnackbar.show(
      context,
      message: failure.message ?? 'No se pudo borrar el servicio.',
      variant: AppSnackbarVariant.danger,
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

class _SelfServiceActions extends ConsumerStatefulWidget {
  final Servicio servicio;

  const _SelfServiceActions({required this.servicio});

  @override
  ConsumerState<_SelfServiceActions> createState() =>
      _SelfServiceActionsState();
}

class _SelfServiceActionsState extends ConsumerState<_SelfServiceActions> {
  // Flag local de "acción en curso": al ya no haber AsyncLoading global por
  // acción (que tumbaría el detalle), gobernamos el spinner/disabled de los
  // botones aquí, sin afectar al resto de la ficha.
  bool _enCurso = false;

  @override
  Widget build(BuildContext context) {
    final servicio = widget.servicio;
    final loading = _enCurso;
    // El backend admite inscripción mientras el servicio está
    // publicado o activo (CU-04 / EN-03-04). En cerrado/borrador no.
    final puedeApuntarse =
        servicio.estado == EstadoServicio.publicado ||
        servicio.estado == EstadoServicio.activo;

    // Gate de aforo (UI-only). null = aforo ilimitado → siempre
    // habilitado. El backend revalida la capacidad en la petición; esta
    // puerta solo evita ofrecer una acción que terminaría en 4xx.
    final aforoLleno =
        servicio.numeroVoluntarios != null &&
        servicio.inscritosCount >= servicio.numeroVoluntarios!;
    final canApuntarse = puedeApuntarse && !aforoLleno;

    // A8: "Apuntarme" solo si NO está ya inscrito; "Darme de baja" solo si
    // SÍ lo está. Antes ambos botones aparecían a la vez en cuanto el estado
    // admitía inscripción, sin reflejar la inscripción propia.
    final mostrarApuntarse = puedeApuntarse && !servicio.estoyInscrito;
    final mostrarDarseBaja = puedeApuntarse && servicio.estoyInscrito;

    return Column(
      children: [
        if (mostrarApuntarse)
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
                      : () => _ejecutar(
                          () => ref
                              .read(
                                servicioFichaViewModelProvider(
                                  servicio.id,
                                ).notifier,
                              )
                              .apuntarse(),
                          'Te has apuntado al servicio.',
                        ),
                ),
              ),
            ),
          ),
        if (mostrarDarseBaja)
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
                        if (!ok || !mounted) return;
                        await _ejecutar(
                          () => ref
                              .read(
                                servicioFichaViewModelProvider(
                                  servicio.id,
                                ).notifier,
                              )
                              .desapuntarse(),
                          'Te has dado de baja del servicio.',
                        );
                      },
              ),
            ),
          ),
      ],
    );
  }

  /// Lanza una acción self-service del view model gestionando el flag local de
  /// progreso y el feedback: snackbar de éxito si la acción devuelve `null`, o
  /// snackbar de error con el mensaje real de la [Failure] sin tumbar la ficha.
  Future<void> _ejecutar(
    Future<Failure?> Function() accion,
    String mensajeExito,
  ) async {
    setState(() => _enCurso = true);
    final Failure? failure;
    try {
      failure = await accion();
    } finally {
      if (mounted) setState(() => _enCurso = false);
    }
    if (!mounted) return;
    if (failure == null) {
      AppSnackbar.show(
        context,
        message: mensajeExito,
        variant: AppSnackbarVariant.success,
      );
    } else {
      AppSnackbar.show(
        context,
        message: failure.message ?? 'No se pudo completar la acción.',
        variant: AppSnackbarVariant.danger,
      );
    }
  }
}

class _AdminActions extends ConsumerStatefulWidget {
  final Servicio servicio;

  const _AdminActions({required this.servicio});

  @override
  ConsumerState<_AdminActions> createState() => _AdminActionsState();
}

class _AdminActionsState extends ConsumerState<_AdminActions> {
  // Flag local de "transición en curso": gobierna el spinner/disabled de las
  // acciones de mando sin tocar el estado global de la ficha.
  bool _enCurso = false;

  @override
  Widget build(BuildContext context) {
    final servicio = widget.servicio;
    final loading = _enCurso;

    final items = <Widget>[];

    if (servicio.estado == EstadoServicio.borrador) {
      items.add(
        AppPermissionGate(
          permission: Permission.serviciosPublicar,
          // Sin permiso de publicar, en vez de ocultar el botón en silencio
          // (que se percibe como "no sale el botón / se queda en borrador"),
          // explicamos por qué no puede publicarlo este rol.
          fallback: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Este servicio está en borrador. Debe publicarlo un responsable '
              'con permiso de publicación.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
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
                  : () => _ejecutar(
                      () => ref
                          .read(
                            servicioFichaViewModelProvider(
                              servicio.id,
                            ).notifier,
                          )
                          .publicar(),
                      'Servicio publicado.',
                    ),
            ),
          ),
        ),
      );
    }

    if (servicio.estado == EstadoServicio.publicado ||
        servicio.estado == EstadoServicio.activo) {
      items.add(
        AppPermissionGate(
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
                      if (!ok || !mounted) return;
                      await _ejecutar(
                        () => ref
                            .read(
                              servicioFichaViewModelProvider(
                                servicio.id,
                              ).notifier,
                            )
                            .convocarTodos(),
                        'Voluntarios convocados.',
                      );
                    },
            ),
          ),
        ),
      );
    }

    if (servicio.estado == EstadoServicio.activo) {
      items.add(
        AppPermissionGate(
          permission: Permission.serviciosCerrar,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: AppDestructiveButton(
              key: K.servicioFichaCerrarBtn,
              label: 'Cerrar servicio',
              icon: Symbols.lock,
              expanded: true,
              onPressed: loading ? null : () => _abrirCerrarDialog(servicio.id),
            ),
          ),
        ),
      );
    }

    return Column(children: items);
  }

  Future<void> _abrirCerrarDialog(String servicioId) async {
    // El diálogo es un StatefulWidget que posee y libera su controller en
    // State.dispose(); devuelve el texto de observaciones en el pop (null si
    // se cancela). Antes el controller era local y no se liberaba nunca (leak).
    final observacionesRaw = await AppDialog.showBuilder<String>(
      context,
      builder: (_) => const _CerrarServicioDialog(),
    );
    if (observacionesRaw == null || !mounted) return;
    final obs = observacionesRaw.trim();
    await _ejecutar(
      () => ref
          .read(servicioFichaViewModelProvider(servicioId).notifier)
          .cerrar(observaciones: obs.isEmpty ? null : obs),
      'Servicio cerrado.',
    );
  }

  /// Lanza una transición de mando del view model gestionando el flag local de
  /// progreso y el feedback: snackbar de éxito si la acción devuelve `null`, o
  /// snackbar de error con el mensaje real de la [Failure] sin tumbar la ficha.
  Future<void> _ejecutar(
    Future<Failure?> Function() accion,
    String mensajeExito,
  ) async {
    setState(() => _enCurso = true);
    final Failure? failure;
    try {
      failure = await accion();
    } finally {
      if (mounted) setState(() => _enCurso = false);
    }
    if (!mounted) return;
    if (failure == null) {
      AppSnackbar.show(
        context,
        message: mensajeExito,
        variant: AppSnackbarVariant.success,
      );
    } else {
      AppSnackbar.show(
        context,
        message: failure.message ?? 'No se pudo completar la acción.',
        variant: AppSnackbarVariant.danger,
      );
    }
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
    final puedeFichar =
        esActivo &&
        (user?.hasPermission(Permission.fichajeFicharPropio) ?? false);
    final puedeVerVoluntarios =
        user?.hasPermission(Permission.fichajeVerVoluntariosEnServicio) ??
        false;

    if (!puedeFichar && !puedeVerVoluntarios) {
      return const SizedBox.shrink();
    }
    // A10: en borrador todavía no hay asistencia que consultar ni fichaje
    // posible (el servicio no se ha publicado), así que no ofrecemos el
    // atajo; solo en publicado/activo/cerrado.
    if (servicio.estado == EstadoServicio.borrador) {
      return const SizedBox.shrink();
    }

    void irAFichaje() => context.go('/servicios/${servicio.id}/fichaje');

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            // A10: para quien solo puede consultar, el bloque es "Asistencia";
            // "Fichaje" se reserva para quien efectivamente puede fichar.
            puedeFichar ? 'Fichaje' : 'Asistencia',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          // A10: la acción de fichar (primaria) usa AppPrimaryButton; la de
          // solo-consulta es secundaria, para no competir con la CTA real de
          // la ficha.
          if (puedeFichar)
            AppPrimaryButton(
              key: K.servicioFichaFichajeAccesoBtn,
              label: 'Fichar entrada / salida',
              icon: Symbols.fingerprint,
              expanded: true,
              onPressed: irAFichaje,
            )
          else
            AppSecondaryButton(
              key: K.servicioFichaFichajeAccesoBtn,
              label: 'Ver asistencia',
              icon: Symbols.list_alt,
              expanded: true,
              onPressed: irAFichaje,
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

/// A8: chip que confirma de un vistazo que el usuario está inscrito en el
/// servicio. Icono + texto (no solo color, guía 28 §WCAG 1.4.1).
class _InscritoChip extends StatelessWidget {
  const _InscritoChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: K.servicioFichaInscritoChip,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.how_to_reg,
            size: 16,
            color: theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Inscrito',
            style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
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
      title: 'Servicio',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite consultar este servicio.',
        icon: Symbols.lock,
      ),
    );
  }
}
