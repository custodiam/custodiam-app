// InventarioListPage (US-05-10). DefaultTabController interno entre
// Material y Vehículos. Cada pestaña tiene su propia AsyncNotifier
// y comparte el patrón de búsqueda + filtros + scroll paginado.

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
import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/material_summary.dart';
import '../../domain/entities/tipo_material.dart';
import '../../domain/entities/tipo_vehiculo.dart';
import '../../domain/entities/vehiculo_summary.dart';
import '../viewmodels/materiales_list_view_model.dart';
import '../viewmodels/vehiculos_list_view_model.dart';

class InventarioListPage extends ConsumerWidget {
  const InventarioListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.inventarioVer,
      fallback: _ForbiddenScreen(),
      child: _InventarioListBody(),
    );
  }
}

class _InventarioListBody extends ConsumerWidget {
  const _InventarioListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventario'),
          centerTitle: true,
          actions: const [
            _AltaMenuButton(),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Material'),
              Tab(
                icon: Icon(Icons.directions_car_outlined),
                text: 'Vehículos',
              ),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              _MaterialesTab(),
              _VehiculosTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AltaMenuButton extends StatelessWidget {
  const _AltaMenuButton();

  @override
  Widget build(BuildContext context) {
    return AppPermissionGate.anyOf(
      anyOf: const [
        Permission.inventarioRegistrarMaterial,
        Permission.inventarioRegistrarVehiculo,
      ],
      child: PopupMenuButton<String>(
        key: const ValueKey('inventario_alta_menu'),
        tooltip: 'Registrar nuevo',
        icon: const Icon(Icons.add),
        onSelected: (target) => context.go('/inventario/$target'),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'material/alta',
            child: ListTile(
              leading: Icon(Icons.inventory_2_outlined),
              title: Text('Nuevo material'),
            ),
          ),
          const PopupMenuItem(
            value: 'vehiculos/alta',
            child: ListTile(
              leading: Icon(Icons.directions_car_outlined),
              title: Text('Nuevo vehículo'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Materiales tab ───────────────────────────────────────────────────

class _MaterialesTab extends ConsumerStatefulWidget {
  const _MaterialesTab();

  @override
  ConsumerState<_MaterialesTab> createState() => _MaterialesTabState();
}

class _MaterialesTabState extends ConsumerState<_MaterialesTab> {
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
      ref.read(materialesListViewModelProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(materialesListViewModelProvider);

    ref.listen(materialesListViewModelProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'No se pudo cargar el material.',
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
            key: const ValueKey('inventario_material_search'),
            label: 'Buscar por nombre o código',
            controller: _searchController,
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onEditingComplete: () => ref
                .read(materialesListViewModelProvider.notifier)
                .search(_searchController.text.trim()),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _Chip(
                label: 'Todos',
                selected: asyncState.valueOrNull?.estado == null,
                onSelected: () => ref
                    .read(materialesListViewModelProvider.notifier)
                    .filterByEstado(null),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Chip(
                label: 'Operativo',
                selected:
                    asyncState.valueOrNull?.estado == EstadoInventario.operativo,
                onSelected: () => ref
                    .read(materialesListViewModelProvider.notifier)
                    .filterByEstado(EstadoInventario.operativo),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Chip(
                label: 'Averiado',
                selected:
                    asyncState.valueOrNull?.estado == EstadoInventario.averiado,
                onSelected: () => ref
                    .read(materialesListViewModelProvider.notifier)
                    .filterByEstado(EstadoInventario.averiado),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Chip(
                label: 'Perdido',
                selected:
                    asyncState.valueOrNull?.estado == EstadoInventario.perdido,
                onSelected: () => ref
                    .read(materialesListViewModelProvider.notifier)
                    .filterByEstado(EstadoInventario.perdido),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Chip(
                label: 'En uso',
                selected:
                    asyncState.valueOrNull?.estado == EstadoInventario.enUso,
                onSelected: () => ref
                    .read(materialesListViewModelProvider.notifier)
                    .filterByEstado(EstadoInventario.enUso),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: asyncState.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, _) => AppErrorState(
              title: 'No se pudo cargar el material',
              description: error is Failure ? error.message : null,
              onRetry: () => ref
                  .read(materialesListViewModelProvider.notifier)
                  .refresh(),
            ),
            data: (state) {
              if (state.items.isEmpty) {
                return const AppEmptyState(
                  title: 'Sin material',
                  description: 'No hay resultados para los filtros aplicados.',
                  icon: Icons.inventory_2_outlined,
                );
              }
              return ListView.separated(
                key: const ValueKey('inventario_material_list_view'),
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                itemCount: state.items.length + (state.hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _MaterialTile(material: state.items[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final MaterialSummary material;
  const _MaterialTile({required this.material});

  String _tipoLabel(TipoMaterial t) => switch (t) {
        TipoMaterial.personal => 'Personal',
        TipoMaterial.prestable => 'Prestable',
        TipoMaterial.servicio => 'Servicio',
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('inventario_material_item_${material.id}'),
      leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
      title: Text(material.nombre),
      subtitle: Text(
        '${_tipoLabel(material.tipo)} · ${material.ubicacionBase}'
        '${material.codigo != null ? " · ${material.codigo}" : ""}',
      ),
      trailing: _EstadoBadge(estado: material.estado),
      onTap: () => context.go('/inventario/material/${material.id}'),
    );
  }
}

// ── Vehículos tab ────────────────────────────────────────────────────

class _VehiculosTab extends ConsumerStatefulWidget {
  const _VehiculosTab();

  @override
  ConsumerState<_VehiculosTab> createState() => _VehiculosTabState();
}

class _VehiculosTabState extends ConsumerState<_VehiculosTab> {
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
      ref.read(vehiculosListViewModelProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(vehiculosListViewModelProvider);

    ref.listen(vehiculosListViewModelProvider, (prev, next) {
      next.whenOrNull(
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message:
                  error.message ?? 'No se pudieron cargar los vehículos.',
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
            key: const ValueKey('inventario_vehiculo_search'),
            label: 'Buscar por código o matrícula',
            controller: _searchController,
            prefixIcon: Icons.search,
            textInputAction: TextInputAction.search,
            onEditingComplete: () => ref
                .read(vehiculosListViewModelProvider.notifier)
                .search(_searchController.text.trim()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: asyncState.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, _) => AppErrorState(
              title: 'No se pudieron cargar los vehículos',
              description: error is Failure ? error.message : null,
              onRetry: () => ref
                  .read(vehiculosListViewModelProvider.notifier)
                  .refresh(),
            ),
            data: (state) {
              if (state.items.isEmpty) {
                return const AppEmptyState(
                  title: 'Sin vehículos',
                  description:
                      'No hay vehículos registrados con esos filtros.',
                  icon: Icons.directions_car_outlined,
                );
              }
              return ListView.separated(
                key: const ValueKey('inventario_vehiculo_list_view'),
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                itemCount: state.items.length + (state.hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _VehiculoTile(vehiculo: state.items[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VehiculoTile extends StatelessWidget {
  final VehiculoSummary vehiculo;
  const _VehiculoTile({required this.vehiculo});

  String _tipoLabel(TipoVehiculo t) => switch (t) {
        TipoVehiculo.furgoneta => 'Furgoneta',
        TipoVehiculo.pickUp => 'Pick-up',
        TipoVehiculo.ambulancia => 'Ambulancia',
        TipoVehiculo.remolque => 'Remolque',
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('inventario_vehiculo_item_${vehiculo.id}'),
      leading: const CircleAvatar(child: Icon(Icons.directions_car_outlined)),
      title: Text('${vehiculo.codigoInterno} · ${vehiculo.matricula}'),
      subtitle: Text('${_tipoLabel(vehiculo.tipo)} · ${vehiculo.ubicacionBase}'),
      trailing: _EstadoBadge(estado: vehiculo.estado),
      onTap: () => context.go('/inventario/vehiculos/${vehiculo.id}'),
    );
  }
}

// ── Shared chip + badge ──────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoInventario estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color bg, Color fg, String label) = switch (estado) {
      EstadoInventario.operativo => (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
          'Operativo',
        ),
      EstadoInventario.averiado => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
          'Averiado',
        ),
      EstadoInventario.perdido => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          'Perdido',
        ),
      EstadoInventario.enUso => (
          theme.colorScheme.tertiaryContainer,
          theme.colorScheme.onTertiaryContainer,
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
      title: 'Inventario',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite consultar el inventario.',
        icon: Icons.lock_outline,
      ),
    );
  }
}
