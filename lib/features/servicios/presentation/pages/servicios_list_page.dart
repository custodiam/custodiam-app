// ServiciosListPage (US-03-07).
//
// Listado paginado de servicios. Quien tenga permiso de creación ve
// además un botón de alta en la AppBar (US-03-01 / US-03-02 entry).
// Filtros: búsqueda libre + ChoiceChip por estado. Tap sobre un
// servicio → ficha detalle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
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
      title: 'Servicios',
      actions: [
        const AppPermissionGate.anyOf(
          anyOf: [
            Permission.serviciosCrearPreventivo,
            Permission.serviciosCrearEmergencia,
          ],
          child: _AltaServicioButton(),
        ),
        IconButton(
          key: const ValueKey('servicios_refresh_button'),
          tooltip: 'Recargar',
          icon: const Icon(Icons.refresh),
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
              key: const ValueKey('servicios_search_field'),
              label: 'Buscar por título o ubicación',
              controller: _searchController,
              prefixIcon: Icons.search,
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
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildBody(asyncState)),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncValue<ServiciosListState> asyncState) {
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
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
        if (state.items.isEmpty) {
          return AppEmptyState(
            title: 'Sin servicios',
            description: state.query.isNotEmpty || state.estado != null
                ? 'Prueba a cambiar la búsqueda o el filtro.'
                : 'Aún no hay servicios disponibles.',
            icon: Icons.event_outlined,
          );
        }
        return ListView.separated(
          key: const ValueKey('servicios_list_view'),
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          itemCount: state.items.length + (state.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final s = state.items[index];
            return _ServicioTile(servicio: s);
          },
        );
      },
    );
  }
}

class _AltaServicioButton extends StatelessWidget {
  const _AltaServicioButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('servicios_alta_button'),
      tooltip: 'Crear servicio',
      icon: const Icon(Icons.add),
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
            key: const ValueKey('servicios_filter_todos'),
            label: const Text('Todos'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: const ValueKey('servicios_filter_publicado'),
            label: const Text('Publicados'),
            selected: selected == EstadoServicio.publicado,
            onSelected: (_) => onChanged(EstadoServicio.publicado),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: const ValueKey('servicios_filter_activo'),
            label: const Text('Activos'),
            selected: selected == EstadoServicio.activo,
            onSelected: (_) => onChanged(EstadoServicio.activo),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: const ValueKey('servicios_filter_borrador'),
            label: const Text('Borradores'),
            selected: selected == EstadoServicio.borrador,
            onSelected: (_) => onChanged(EstadoServicio.borrador),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: const ValueKey('servicios_filter_cerrado'),
            label: const Text('Cerrados'),
            selected: selected == EstadoServicio.cerrado,
            onSelected: (_) => onChanged(EstadoServicio.cerrado),
          ),
        ],
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
      key: ValueKey('servicios_item_${servicio.id}'),
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
          Icons.warning_amber_rounded,
          theme.colorScheme.error,
        ),
      TipoServicio.preventivo => (
          Icons.event,
          theme.colorScheme.primary,
        ),
      TipoServicio.formacion => (
          Icons.school_outlined,
          theme.colorScheme.tertiary,
        ),
      TipoServicio.otro => (
          Icons.bookmark_border,
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
    final (Color bg, Color fg, String label) = switch (estado) {
      EstadoServicio.borrador => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          'Borrador',
        ),
      EstadoServicio.publicado => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
          'Publicado',
        ),
      EstadoServicio.activo => (
          theme.colorScheme.tertiaryContainer,
          theme.colorScheme.onTertiaryContainer,
          'Activo',
        ),
      EstadoServicio.cerrado => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12)),
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
        icon: Icons.lock_outline,
      ),
    );
  }
}
