// Pestaña "Ubicaciones" del listado de inventario (E10). Catálogo maestro de
// ubicaciones con búsqueda + paginación + alta/edición (página aparte con el
// AppLocationPicker) + borrado. Solo se muestra a quien tiene
// `ubicaciones.crear` — el gateo lo hace InventarioListPage al construir el
// TabBar, así que esta pestaña no se renderiza para roles sin permiso.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/feedback/app_confirm_dialog.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/ubicacion.dart';
import '../viewmodels/ubicaciones_list_view_model.dart';

class UbicacionesTab extends ConsumerStatefulWidget {
  const UbicacionesTab({super.key});

  @override
  ConsumerState<UbicacionesTab> createState() => _UbicacionesTabState();
}

class _UbicacionesTabState extends ConsumerState<UbicacionesTab> {
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
      ref.read(ubicacionesListViewModelProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _borrar(Ubicacion u) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Eliminar ubicación',
      message: '¿Eliminar "${u.nombre}"? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    final failure =
        await ref.read(ubicacionesListViewModelProvider.notifier).eliminar(u.id);
    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: failure?.message ?? 'Ubicación eliminada.',
      variant: failure != null
          ? AppSnackbarVariant.danger
          : AppSnackbarVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(ubicacionesListViewModelProvider);

    ref.listen(ubicacionesListViewModelProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message:
                  error.message ?? 'No se pudieron cargar las ubicaciones.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: AppTextField(
            key: K.ubicacionesSearch,
            label: 'Buscar por nombre',
            controller: _searchController,
            prefixIcon: Symbols.search,
            textInputAction: TextInputAction.search,
            onEditingComplete: () => ref
                .read(ubicacionesListViewModelProvider.notifier)
                .search(_searchController.text.trim()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: AppPrimaryButton(
            key: K.ubicacionesNuevaBtn,
            label: 'Nueva ubicación',
            icon: Symbols.add_location,
            expanded: true,
            onPressed: () => context.go('/inventario/ubicaciones/alta'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: asyncState.when(
            loading: () => const AppLoadingIndicator.fullScreen(),
            error: (error, _) => AppErrorState(
              title: 'No se pudieron cargar las ubicaciones',
              description: error is Failure ? error.message : null,
              onRetry: () =>
                  ref.read(ubicacionesListViewModelProvider.notifier).refresh(),
            ),
            data: (state) {
              Future<void> onRefresh() => ref
                  .read(ubicacionesListViewModelProvider.notifier)
                  .refresh();
              if (state.items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xxl),
                        child: AppEmptyState(
                          title: 'Sin ubicaciones',
                          description:
                              'Crea la primera ubicación con "Nueva ubicación".',
                          icon: Symbols.location_off,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView.separated(
                  key: K.ubicacionesListView,
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
                    final u = state.items[index];
                    return _UbicacionTile(
                      ubicacion: u,
                      onEditar: () =>
                          context.go('/inventario/ubicaciones/${u.id}/editar'),
                      onBorrar: () => _borrar(u),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UbicacionTile extends StatelessWidget {
  final Ubicacion ubicacion;
  final VoidCallback onEditar;
  final VoidCallback onBorrar;

  const _UbicacionTile({
    required this.ubicacion,
    required this.onEditar,
    required this.onBorrar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conCoords = ubicacion.tieneCoordenadas;
    return ListTile(
      key: K.ubicacionItem(ubicacion.id),
      leading: const CircleAvatar(child: Icon(Symbols.location_on)),
      title: Text(ubicacion.nombre),
      subtitle: Row(
        children: [
          Icon(
            conCoords ? Symbols.map : Symbols.location_off,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            conCoords ? 'Con coordenadas' : 'Sin coordenadas',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        key: K.ubicacionAccionesBtn(ubicacion.id),
        tooltip: 'Acciones de la ubicación',
        icon: const Icon(Symbols.more_vert),
        onSelected: (v) => v == 'editar' ? onEditar() : onBorrar(),
        itemBuilder: (_) => const [
          PopupMenuItem<String>(
            value: 'editar',
            child: ListTile(
              leading: Icon(Symbols.edit),
              title: Text('Editar'),
            ),
          ),
          PopupMenuItem<String>(
            value: 'borrar',
            child: ListTile(
              leading: Icon(Symbols.delete),
              title: Text('Eliminar'),
            ),
          ),
        ],
      ),
      onTap: onEditar,
    );
  }
}
