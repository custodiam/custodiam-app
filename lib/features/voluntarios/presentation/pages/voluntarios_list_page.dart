// VoluntariosListPage (US-02-09).
//
// Paginated listing with text search and estado filter. Wraps the
// whole page in AppPermissionGate(voluntarios.listar): users without
// the permission see a friendly "no access" placeholder instead of a
// SizedBox.shrink — they should not have hit this page (the gate at
// the home entry already hides the icon button), but a direct URL
// bypass deserves a clear message.
//
// CA from the user story not implemented in this iteration (deferred
// as documented deuda):
//   - Filter by rol: backend exposes ?rol_id=<uuid> but there is no
//     endpoint to list roles yet — UI would need an empty dropdown.
//   - Filter by disponibilidad: requires the calendario endpoint
//     (EN-02-04, Sprint 5).
// The "ficha detallada" CA leads to a snackbar until the detail page
// lands in a follow-up story; the tap is wired so plugging the
// navigation later is a one-line change.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_breakpoints.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/estado_voluntario.dart';
import '../../domain/entities/voluntario_summary.dart';
import '../viewmodels/voluntarios_list_view_model.dart';

class VoluntariosListPage extends ConsumerWidget {
  const VoluntariosListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.voluntariosListar,
      fallback: _ForbiddenScreen(),
      child: _VoluntariosListPageBody(),
    );
  }
}

class _VoluntariosListPageBody extends ConsumerStatefulWidget {
  const _VoluntariosListPageBody();

  @override
  ConsumerState<_VoluntariosListPageBody> createState() =>
      _VoluntariosListPageBodyState();
}

class _VoluntariosListPageBodyState
    extends ConsumerState<_VoluntariosListPageBody> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// How far from the bottom (in pixels) we start prefetching the
  /// next page. 200 keeps the spinner unobtrusive on a 50-row page.
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
      ref.read(voluntariosListViewModelProvider.notifier).loadMore();
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
        .read(voluntariosListViewModelProvider.notifier)
        .search(_searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(voluntariosListViewModelProvider);
    // Voluntarios sin permission.voluntariosVerFicha ven la lista pero
    // sus filas deben quedar no-tap. La auditoría RBAC (29-may, hallazgo
    // A1) lo formaliza: el rol `voluntario` tiene `voluntariosListar` pero
    // no `voluntariosVerFicha`; sin este gate, el tap aterrizaba en el
    // `_ForbiddenScreen` de la ficha.
    final canViewFicha = ref
            .watch(authServiceProvider)
            .currentUser
            ?.hasPermission(Permission.voluntariosVerFicha) ??
        false;

    ref.listen<AsyncValue<VoluntariosListState>>(
      voluntariosListViewModelProvider,
      (prev, next) {
        next.whenOrNull(
          error: (error, _) {
            if (error is Failure) {
              AppSnackbar.show(
                context,
                message: error.message ?? 'No se pudo cargar la lista.',
                variant: AppSnackbarVariant.danger,
              );
            }
          },
        );
      },
    );

    return AppPageScaffold(
      maxContentWidth: AppBreakpoints.listMaxWidth,
      title: 'Voluntarios',
      actions: [
        AppPermissionGate(
          permission: Permission.voluntariosCrear,
          child: IconButton(
            key: const ValueKey('voluntarios_alta_button'),
            tooltip: 'Alta de voluntario',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => context.go('/voluntarios/alta'),
          ),
        ),
        IconButton(
          key: const ValueKey('voluntarios_refresh_button'),
          tooltip: 'Recargar',
          icon: const Icon(Icons.refresh),
          onPressed: () =>
              ref.read(voluntariosListViewModelProvider.notifier).refresh(),
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
              key: const ValueKey('voluntarios_search_field'),
              label: 'Buscar por nombre, DNI o email',
              controller: _searchController,
              prefixIcon: Icons.search,
              textInputAction: TextInputAction.search,
              onEditingComplete: _submitSearch,
            ),
          ),
          _EstadoFilterRow(
            selected: asyncState.valueOrNull?.estado,
            onChanged: (estado) => ref
                .read(voluntariosListViewModelProvider.notifier)
                .filterByEstado(estado),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildBody(asyncState, canViewFicha: canViewFicha)),
        ],
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<VoluntariosListState> asyncState, {
    required bool canViewFicha,
  }) {
    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        final message =
            error is Failure ? error.message : 'No se pudo cargar la lista.';
        return AppErrorState(
          title: 'No se pudieron cargar los voluntarios',
          description: message,
          onRetry: () =>
              ref.read(voluntariosListViewModelProvider.notifier).refresh(),
        );
      },
      data: (state) {
        if (state.items.isEmpty) {
          return AppEmptyState(
            title: 'Sin resultados',
            description: state.query.isNotEmpty || state.estado != null
                ? 'Prueba a cambiar la búsqueda o el filtro.'
                : 'Todavía no hay voluntarios dados de alta.',
            icon: Icons.people_outline,
          );
        }
        return ListView.separated(
          key: const ValueKey('voluntarios_list_view'),
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
            final v = state.items[index];
            return _VoluntarioTile(voluntario: v, canViewFicha: canViewFicha);
          },
        );
      },
    );
  }
}

class _EstadoFilterRow extends StatelessWidget {
  final EstadoVoluntario? selected;
  final ValueChanged<EstadoVoluntario?> onChanged;

  const _EstadoFilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          ChoiceChip(
            key: const ValueKey('voluntarios_filter_todos'),
            label: const Text('Todos'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: const ValueKey('voluntarios_filter_activos'),
            label: const Text('Activos'),
            selected: selected == EstadoVoluntario.activo,
            onSelected: (_) => onChanged(EstadoVoluntario.activo),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: const ValueKey('voluntarios_filter_baja'),
            label: const Text('Bajas'),
            selected: selected == EstadoVoluntario.baja,
            onSelected: (_) => onChanged(EstadoVoluntario.baja),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            key: const ValueKey('voluntarios_filter_suspendidos'),
            label: const Text('Suspendidos'),
            selected: selected == EstadoVoluntario.suspendido,
            onSelected: (_) => onChanged(EstadoVoluntario.suspendido),
          ),
        ],
      ),
    );
  }
}

class _VoluntarioTile extends StatelessWidget {
  final VoluntarioSummary voluntario;
  final bool canViewFicha;

  const _VoluntarioTile({
    required this.voluntario,
    required this.canViewFicha,
  });

  String get _initials {
    final parts = voluntario.nombre.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0]
        : '';
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('voluntarios_item_${voluntario.id}'),
      leading: CircleAvatar(child: Text(_initials)),
      title: Text(voluntario.nombre),
      subtitle: Text('${voluntario.telefono} · ${voluntario.municipio}'),
      trailing: _EstadoBadge(estado: voluntario.estado),
      onTap: canViewFicha
          ? () => context.go('/voluntarios/${voluntario.id}')
          : null,
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoVoluntario estado;

  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color bg, Color fg, String label) = switch (estado) {
      EstadoVoluntario.activo => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
          'Activo',
        ),
      EstadoVoluntario.baja => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          'Baja',
        ),
      EstadoVoluntario.suspendido => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
          'Suspendido',
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
      title: 'Voluntarios',
      body: AppEmptyState(
        title: 'Sin acceso',
        description:
            'Tu rol no permite consultar la lista de voluntarios. '
            'Si crees que es un error, contacta con un responsable.',
        icon: Icons.lock_outline,
      ),
    );
  }
}
