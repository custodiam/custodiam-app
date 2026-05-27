// Idéntico a MaterialesListViewModel pero para la pestaña Vehículos.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/tipo_vehiculo.dart';
import '../../domain/entities/vehiculo_summary.dart';
import '../../domain/usecases/list_vehiculos.dart';
import 'inventario_di.dart';

class VehiculosListState {
  final List<VehiculoSummary> items;
  final int total;
  final String query;
  final EstadoInventario? estado;
  final TipoVehiculo? tipo;
  final bool isLoadingMore;

  const VehiculosListState({
    this.items = const [],
    this.total = 0,
    this.query = '',
    this.estado,
    this.tipo,
    this.isLoadingMore = false,
  });

  bool get hasMore => items.length < total;

  VehiculosListState copyWith({
    List<VehiculoSummary>? items,
    int? total,
    String? query,
    EstadoInventario? estado,
    bool clearEstado = false,
    TipoVehiculo? tipo,
    bool clearTipo = false,
    bool? isLoadingMore,
  }) {
    return VehiculosListState(
      items: items ?? this.items,
      total: total ?? this.total,
      query: query ?? this.query,
      estado: clearEstado ? null : (estado ?? this.estado),
      tipo: clearTipo ? null : (tipo ?? this.tipo),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class VehiculosListViewModel extends AsyncNotifier<VehiculosListState> {
  static const int pageSize = 50;

  ListVehiculos get _list => ref.read(listVehiculosProvider);

  @override
  Future<VehiculosListState> build() {
    return _fetchFirstPage(query: '', estado: null, tipo: null);
  }

  Future<VehiculosListState> _fetchFirstPage({
    required String query,
    required EstadoInventario? estado,
    required TipoVehiculo? tipo,
  }) async {
    final result = await _list(
      skip: 0,
      limit: pageSize,
      query: query.isEmpty ? null : query,
      estado: estado,
      tipo: tipo,
    );
    return switch (result) {
      Success(:final value) => VehiculosListState(
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
}

final vehiculosListViewModelProvider =
    AsyncNotifierProvider<VehiculosListViewModel, VehiculosListState>(
  VehiculosListViewModel.new,
);
