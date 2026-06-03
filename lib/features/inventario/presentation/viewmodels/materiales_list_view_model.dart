// AsyncNotifier para la pestaña Material del listado de inventario.
// Paginado con búsqueda + filtros estado/tipo. Mismo patrón que
// ServiciosListViewModel.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/material_summary.dart';
import '../../domain/entities/tipo_material.dart';
import '../../domain/usecases/eliminar_material.dart';
import '../../domain/usecases/list_materiales.dart';
import 'inventario_di.dart';

class MaterialesListState {
  final List<MaterialSummary> items;
  final int total;
  final String query;
  final EstadoInventario? estado;
  final TipoMaterial? tipo;
  final bool isLoadingMore;

  const MaterialesListState({
    this.items = const [],
    this.total = 0,
    this.query = '',
    this.estado,
    this.tipo,
    this.isLoadingMore = false,
  });

  bool get hasMore => items.length < total;

  MaterialesListState copyWith({
    List<MaterialSummary>? items,
    int? total,
    String? query,
    EstadoInventario? estado,
    bool clearEstado = false,
    TipoMaterial? tipo,
    bool clearTipo = false,
    bool? isLoadingMore,
  }) {
    return MaterialesListState(
      items: items ?? this.items,
      total: total ?? this.total,
      query: query ?? this.query,
      estado: clearEstado ? null : (estado ?? this.estado),
      tipo: clearTipo ? null : (tipo ?? this.tipo),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class MaterialesListViewModel extends AsyncNotifier<MaterialesListState> {
  static const int pageSize = 50;

  ListMateriales get _list => ref.read(listMaterialesProvider);
  EliminarMaterial get _eliminar => ref.read(eliminarMaterialProvider);

  @override
  Future<MaterialesListState> build() {
    return _fetchFirstPage(query: '', estado: null, tipo: null);
  }

  Future<MaterialesListState> _fetchFirstPage({
    required String query,
    required EstadoInventario? estado,
    required TipoMaterial? tipo,
  }) async {
    final result = await _list(
      skip: 0,
      limit: pageSize,
      query: query.isEmpty ? null : query,
      estado: estado,
      tipo: tipo,
    );
    return switch (result) {
      Success(:final value) => MaterialesListState(
          items: value.items,
          total: value.total,
          query: query,
          estado: estado,
          tipo: tipo,
        ),
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> search(String query) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(
          query: query,
          estado: current?.estado,
          tipo: current?.tipo,
        ));
  }

  Future<void> filterByEstado(EstadoInventario? estado) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(
          query: current?.query ?? '',
          estado: estado,
          tipo: current?.tipo,
        ));
  }

  Future<void> filterByTipo(TipoMaterial? tipo) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(
          query: current?.query ?? '',
          estado: current?.estado,
          tipo: tipo,
        ));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(
          query: current?.query ?? '',
          estado: current?.estado,
          tipo: current?.tipo,
        ));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    final result = await _list(
      skip: current.items.length,
      limit: pageSize,
      query: current.query.isEmpty ? null : current.query,
      estado: current.estado,
      tipo: current.tipo,
    );
    state = switch (result) {
      Success(:final value) => AsyncData(current.copyWith(
          items: [...current.items, ...value.items],
          total: value.total,
          isLoadingMore: false,
        )),
      Fail(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }

  /// Borra un material y refresca la lista. Devuelve el [Failure] si falla
  /// (p. ej. [InventarioFailure.enUso] ante el 409 de "tiene asignaciones")
  /// para que la UI lo comunique, o null si tuvo éxito.
  Future<Failure?> eliminar(String id) async {
    final result = await _eliminar(id);
    switch (result) {
      case Success():
        await refresh();
        return null;
      case Fail(:final failure):
        return failure;
    }
  }
}

final materialesListViewModelProvider =
    AsyncNotifierProvider<MaterialesListViewModel, MaterialesListState>(
  MaterialesListViewModel.new,
);
