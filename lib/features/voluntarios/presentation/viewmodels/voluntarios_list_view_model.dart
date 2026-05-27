// AsyncNotifier that drives VoluntariosListPage. State is the union
// of the current page (items + total + active filters) plus the
// `isLoadingMore` flag used by the scroll-paginated list. Errors are
// propagated as Failures via AsyncError so the page can ref.listen
// and surface an AppSnackbar without inspecting the repository.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/estado_voluntario.dart';
import '../../domain/entities/voluntario_summary.dart';
import '../../domain/usecases/list_voluntarios.dart';
import 'voluntarios_di.dart';

class VoluntariosListState {
  final List<VoluntarioSummary> items;
  final int total;
  final String query;
  final EstadoVoluntario? estado;
  final bool isLoadingMore;

  const VoluntariosListState({
    this.items = const [],
    this.total = 0,
    this.query = '',
    this.estado,
    this.isLoadingMore = false,
  });

  bool get hasMore => items.length < total;

  VoluntariosListState copyWith({
    List<VoluntarioSummary>? items,
    int? total,
    String? query,
    EstadoVoluntario? estado,
    bool clearEstado = false,
    bool? isLoadingMore,
  }) {
    return VoluntariosListState(
      items: items ?? this.items,
      total: total ?? this.total,
      query: query ?? this.query,
      estado: clearEstado ? null : (estado ?? this.estado),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class VoluntariosListViewModel extends AsyncNotifier<VoluntariosListState> {
  static const int pageSize = 50;

  ListVoluntarios get _list => ref.read(listVoluntariosProvider);

  @override
  Future<VoluntariosListState> build() {
    return _fetchFirstPage(query: '', estado: null);
  }

  Future<VoluntariosListState> _fetchFirstPage({
    required String query,
    required EstadoVoluntario? estado,
  }) async {
    final result = await _list(
      skip: 0,
      limit: pageSize,
      query: query.isEmpty ? null : query,
      estado: estado,
    );
    return switch (result) {
      Success(:final value) => VoluntariosListState(
          items: value.items,
          total: value.total,
          query: query,
          estado: estado,
        ),
      Fail(:final failure) => throw failure,
    };
  }

  /// Re-runs the listing with [query] as the search term, replacing
  /// the current page. Resets pagination to the first slice.
  Future<void> search(String query) async {
    final estado = state.valueOrNull?.estado;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(query: query, estado: estado),
    );
  }

  /// Re-runs the listing keeping the current query but switching the
  /// estado filter. Pass `null` to clear the filter.
  Future<void> filterByEstado(EstadoVoluntario? estado) async {
    final query = state.valueOrNull?.query ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(query: query, estado: estado),
    );
  }

  /// Reloads the first page with the current filters.
  Future<void> refresh() async {
    final current = state.valueOrNull;
    final query = current?.query ?? '';
    final estado = current?.estado;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchFirstPage(query: query, estado: estado),
    );
  }

  /// Loads the next page and appends it. No-op while a previous
  /// loadMore is in flight or when the listing is already complete.
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

final voluntariosListViewModelProvider =
    AsyncNotifierProvider<VoluntariosListViewModel, VoluntariosListState>(
  VoluntariosListViewModel.new,
);
