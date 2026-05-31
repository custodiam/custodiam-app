// ServiciosListPage (US-03-07).
//
// Listado paginado de servicios. Quien tenga permiso de creación ve
// además un botón de alta en la AppBar (US-03-01 / US-03-02 entry).
// Filtros: búsqueda libre + ChoiceChip por estado. Tap sobre un
// servicio → ficha detalle.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_icon_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_date_range_picker.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_breakpoints.dart';
import '../../../../core/ui/tokens/app_radius.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/estado_servicio.dart';
import '../../domain/entities/servicio_summary.dart';
import '../../domain/entities/tipo_servicio.dart';
import '../viewmodels/servicios_list_view_model.dart';

class ServiciosListPage extends ConsumerWidget {
  const ServiciosListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.serviciosVerPublicados,
      fallback: _ForbiddenScreen(),
      child: _ServiciosListPageBody(),
    );
  }
}

class _ServiciosListPageBody extends ConsumerStatefulWidget {
  const _ServiciosListPageBody();

  @override
  ConsumerState<_ServiciosListPageBody> createState() =>
      _ServiciosListPageBodyState();
}

class _ServiciosListPageBodyState
    extends ConsumerState<_ServiciosListPageBody> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const double _loadMoreThreshold = 200;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(serviciosListViewModelProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    ref
        .read(serviciosListViewModelProvider.notifier)
        .search(_searchController.text.trim());
  }

  Future<void> _abrirDateRangePicker(ServiciosListState? estado) async {
    final hoy = DateTime.now();
    final inicial = estado?.desde != null && estado?.hasta != null
        ? DateTimeRange(start: estado!.desde!, end: estado.hasta!)
        : null;
    // Los servicios se planifican a futuro, así que el rango admite
    // tanto pasado como porvenir: ±5 años en torno a hoy cubre con
    // holgura cualquier servicio histórico o programado del piloto.
    final range = await showAppDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year - 5, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 5, hoy.month, hoy.day),
      initialDateRange: inicial,
    );
    if (range == null) return;
    if (!mounted) return;
    await ref
        .read(serviciosListViewModelProvider.notifier)
        .filterByDateRange(desde: range.start, hasta: range.end);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(serviciosListViewModelProvider);

    ref.listen<AsyncValue<ServiciosListState>>(
      serviciosListViewModelProvider,
      (prev, next) {
        next.whenOrNull(
          error: (error, _) {
            if (error is Failure) {
              AppSnackbar.show(
                context,
                message: error.message ?? 'No se pudieron cargar los servicios.',
                variant: AppSnackbarVariant.danger,
              );
            }
          },
        );
      },
    );

    return AppPageScaffold(
      maxContentWidth: AppBreakpoints.listMaxWidth,
      title: 'Servicios',
      actions: [
        const AppPermissionGate.anyOf(
          anyOf: [
            Permission.serviciosCrearPreventivo,
            Permission.serviciosCrearEmergencia,
          ],
          child: _AltaServicioButton(),
        ),
        AppIconButton(
          key: K.serviciosListFiltroFechasBtn,
          tooltip: 'Filtrar por fechas',
          icon: Symbols.date_range,
          onPressed: asyncState.valueOrNull == null
              ? null
              : () => _abrirDateRangePicker(asyncState.valueOrNull),
        ),
        AppIconButton(
          key: K.serviciosListRefreshBtn,
          tooltip: 'Recargar',
          icon: Symbols.refresh,
          onPressed: () =>
              ref.read(serviciosListViewModelProvider.notifier).refresh(),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: AppTextField(
              key: K.serviciosListSearchField,
              label: 'Buscar por título o ubicación',
              controller: _searchController,
              prefixIcon: Symbols.search,
              textInputAction: TextInputAction.search,
              onEditingComplete: _submitSearch,
            ),
          ),
          _EstadoFilterRow(
            selected: asyncState.valueOrNull?.estado,
            onChanged: (estado) => ref
                .read(serviciosListViewModelProvider.notifier)
                .filterByEstado(estado),
          ),
          if (asyncState.valueOrNull?.tieneRangoFechas ?? false)
            _RangoActivoChip(
              desde: asyncState.valueOrNull!.desde,
              hasta: asyncState.valueOrNull!.hasta,
              onLimpiar: () => ref
                  .read(serviciosListViewModelProvider.notifier)
                  .filterByDateRange(),
            ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildBody(asyncState)),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncValue<ServiciosListState> asyncState) {
    return asyncState.when(
      loading: () => const AppLoadingIndicator.fullScreen(),
      error: (error, _) {
        final message = error is Failure
            ? error.message
            : 'No se pudieron cargar los servicios.';
        return AppErrorState(
          title: 'No se pudieron cargar los servicios',
          description: message,
          onRetry: () =>
              ref.read(serviciosListViewModelProvider.notifier).refresh(),
        );
      },
      data: (state) {
        Future<void> onRefresh() =>
            ref.read(serviciosListViewModelProvider.notifier).refresh();
        if (state.items.isEmpty) {
          final hayFiltros = state.query.isNotEmpty ||
              state.estado != null ||
              state.tieneRangoFechas;
          // ListView scrollable (no un widget estático) para que el gesto
          // de deslizar-para-refrescar funcione también sin resultados.
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxl),
                  child: AppEmptyState(
                    title: 'Sin servicios',
                    description: hayFiltros
                        ? 'Prueba a cambiar la búsqueda o el filtro.'
                        : 'Aún no hay servicios disponibles.',
                    icon: Symbols.event,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            key: K.serviciosListView,
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: AppLoadingIndicator.fullScreen(),
                );
              }
              final s = state.items[index];
              return _ServicioTile(servicio: s);
            },
          ),
        );
      },
    );
  }
}

class _AltaServicioButton extends StatelessWidget {
  const _AltaServicioButton();

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      key: K.serviciosListAltaBtn,
      tooltip: 'Crear servicio',
      icon: Symbols.add,
      onPressed: () => context.go('/servicios/alta'),
    );
  }
}

class _EstadoFilterRow extends StatelessWidget {
  final EstadoServicio? selected;
  final ValueChanged<EstadoServicio?> onChanged;

  const _EstadoFilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          ChoiceChip(
            key: K.serviciosListFilterTodosChip,
            label: const Text('Todos'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: K.serviciosListFilterPublicadoChip,
            label: const Text('Publicados'),
            selected: selected == EstadoServicio.publicado,
            onSelected: (_) => onChanged(EstadoServicio.publicado),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: K.serviciosListFilterActivoChip,
            label: const Text('Activos'),
            selected: selected == EstadoServicio.activo,
            onSelected: (_) => onChanged(EstadoServicio.activo),
          ),
          // Auditoría RBAC (29-may, hallazgo A3): el filtro `borrador`
          // se ofrecía a cualquier rol con `serviciosVerPublicados` pero
          // el backend no expone borradores ajenos, así que voluntarios
          // /tesorero/secretario/etc filtraban a vacío siempre. Se
          // gatea por los dos permisos de creación de servicio.
          AppPermissionGate.anyOf(
            anyOf: const [
              Permission.serviciosCrearPreventivo,
              Permission.serviciosCrearEmergencia,
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  key: K.serviciosListFilterBorradorChip,
                  label: const Text('Borradores'),
                  selected: selected == EstadoServicio.borrador,
                  onSelected: (_) => onChanged(EstadoServicio.borrador),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: K.serviciosListFilterCerradoChip,
            label: const Text('Cerrados'),
            selected: selected == EstadoServicio.cerrado,
            onSelected: (_) => onChanged(EstadoServicio.cerrado),
          ),
        ],
      ),
    );
  }
}

class _RangoActivoChip extends StatelessWidget {
  final DateTime? desde;
  final DateTime? hasta;
  final VoidCallback onLimpiar;

  const _RangoActivoChip({
    required this.desde,
    required this.hasta,
    required this.onLimpiar,
  });

  String _fmt(DateTime f) => DateFormat('dd/MM/yyyy', 'es_ES').format(f);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = desde != null && hasta != null
        ? 'Del ${_fmt(desde!)} al ${_fmt(hasta!)}'
        : desde != null
            ? 'Desde ${_fmt(desde!)}'
            : 'Hasta ${_fmt(hasta!)}';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          key: K.serviciosListRangoActivoChip,
          avatar: Icon(
            Symbols.date_range,
            size: 18,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          label: Text(label),
          backgroundColor: theme.colorScheme.secondaryContainer,
          deleteIcon: const Icon(Symbols.close, size: 18),
          deleteButtonTooltipMessage: 'Quitar filtro de fechas',
          onDeleted: onLimpiar,
        ),
      ),
    );
  }
}

class _ServicioTile extends StatelessWidget {
  final ServicioSummary servicio;

  const _ServicioTile({required this.servicio});

  String _formatFecha(DateTime f) {
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    final hh = f.hour.toString().padLeft(2, '0');
    final mi = f.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${f.year} · $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: K.serviciosListItem(servicio.id),
      leading: _TipoIcon(tipo: servicio.tipo),
      title: Text(
        servicio.titulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_formatFecha(servicio.fechaInicio)} · ${servicio.ubicacion}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _EstadoBadge(estado: servicio.estado),
      onTap: () => context.go('/servicios/${servicio.id}'),
    );
  }
}

class _TipoIcon extends StatelessWidget {
  final TipoServicio tipo;
  const _TipoIcon({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, Color color) = switch (tipo) {
      TipoServicio.emergencia => (
          Symbols.warning_amber,
          theme.colorScheme.error,
        ),
      TipoServicio.preventivo => (
          Symbols.event,
          theme.colorScheme.primary,
        ),
      TipoServicio.formacion => (
          Symbols.school,
          theme.colorScheme.tertiary,
        ),
      TipoServicio.otro => (
          Symbols.bookmark,
          theme.colorScheme.secondary,
        ),
    };
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      foregroundColor: color,
      child: Icon(icon),
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
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
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
      title: 'Servicios',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite consultar los servicios. '
            'Si crees que es un error, contacta con un responsable.',
        icon: Symbols.lock,
      ),
    );
  }
}
