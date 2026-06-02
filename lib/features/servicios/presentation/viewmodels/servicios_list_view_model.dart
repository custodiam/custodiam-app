// AsyncNotifier que mueve ServiciosListPage. State incluye página
// actual (items + total + filtros activos) + flag isLoadingMore para
// el scroll paginado. Errores propagados como Failures vía AsyncError
// para que la page los pinte con AppSnackbar.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/estado_servicio.dart';
import '../../domain/entities/servicio_summary.dart';
import '../../domain/entities/tipo_servicio.dart';
import '../../domain/usecases/list_servicios.dart';
import 'servicios_di.dart';

class ServiciosListState {
  final List<ServicioSummary> items;
  final int total;
  final String query;
  final EstadoServicio? estado;
  final TipoServicio? tipo;
  final DateTime? desde;
  final DateTime? hasta;
  final bool isLoadingMore;

  const ServiciosListState({
    this.items = const [],
    this.total = 0,
    this.query = '',
    this.estado,
    this.tipo,
    this.desde,
    this.hasta,
    this.isLoadingMore = false,
  });

  bool get hasMore => items.length < total;

  bool get tieneRangoFechas => desde != null || hasta != null;

  ServiciosListState copyWith({
    List<ServicioSummary>? items,
    int? total,
    String? query,
    EstadoServicio? estado,
    bool clearEstado = false,
    TipoServicio? tipo,
    bool clearTipo = false,
    DateTime? desde,
    DateTime? hasta,
    bool clearRango = false,
    bool? isLoadingMore,
  }) {
    return ServiciosListState(
      items: items ?? this.items,
      total: total ?? this.total,
      query: query ?? this.query,
      estado: clearEstado ? null : (estado ?? this.estado),
      tipo: clearTipo ? null : (tipo ?? this.tipo),
      desde: clearRango ? null : (desde ?? this.desde),
      hasta: clearRango ? null : (hasta ?? this.hasta),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ServiciosListViewModel extends AsyncNotifier<ServiciosListState> {
  static const int pageSize = 50;

  ListServicios get _list => ref.read(listServiciosProvider);

  @override
  Future<ServiciosListState> build() {
    return _fetchFirstPage(
      query: '',
      estado: null,
      tipo: null,
      desde: null,
      hasta: null,
    );
  }

  Future<ServiciosListState> _fetchFirstPage({
    required String query,
    required EstadoServicio? estado,
    required TipoServicio? tipo,
    required DateTime? desde,
    required DateTime? hasta,
  }) async {
    final result = await _list(
      skip: 0,
      limit: pageSize,
      query: query.isEmpty ? null : query,
      estado: estado,
      tipo: tipo,
      desde: desde,
      hasta: hasta,
    );
    return switch (result) {
      Success(:final value) => ServiciosListState(
          items: value.items,
          total: value.total,
          query: query,
          estado: estado,
          tipo: tipo,
          desde: desde,
          hasta: hasta,
        ),
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> search(String query) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(
        query: query,
        estado: current?.estado,
        tipo: current?.tipo,
        desde: current?.desde,
        hasta: current?.hasta,
      ),
    );
  }

  Future<void> filterByEstado(EstadoServicio? estado) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(
        query: current?.query ?? '',
        estado: estado,
        tipo: current?.tipo,
        desde: current?.desde,
        hasta: current?.hasta,
      ),
    );
  }

  Future<void> filterByTipo(TipoServicio? tipo) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(
        query: current?.query ?? '',
        estado: current?.estado,
        tipo: tipo,
        desde: current?.desde,
        hasta: current?.hasta,
      ),
    );
  }

  /// Aplica (o limpia, si ambos son `null`) el filtro por rango de
  /// `fecha_inicio`. Conserva el resto de filtros activos.
  Future<void> filterByDateRange({DateTime? desde, DateTime? hasta}) async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(
        query: current?.query ?? '',
        estado: current?.estado,
        tipo: current?.tipo,
        desde: desde,
        hasta: hasta,
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(
        query: current?.query ?? '',
        estado: current?.estado,
        tipo: current?.tipo,
        desde: current?.desde,
        hasta: current?.hasta,
      ),
    );
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
      desde: current.desde,
      hasta: current.hasta,
    );
    state = switch (result) {
      Success(:final value) => AsyncData(
          current.copyWith(
            items: [...current.items, ...value.items],
            total: value.total,
            isLoadingMore: false,
          ),
        ),
      Fail(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

final serviciosListViewModelProvider =
    AsyncNotifierProvider<ServiciosListViewModel, ServiciosListState>(
  ServiciosListViewModel.new,
);
