// AsyncNotifier para la pestaña Ubicaciones del listado de inventario (E10).
// Lista paginada con búsqueda + borrado. Mismo patrón que
// MaterialesListViewModel; el alta/edición vive en su propia página y refresca
// esta lista al volver.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/ubicacion.dart';
import '../../domain/usecases/eliminar_ubicacion.dart';
import '../../domain/usecases/listar_ubicaciones.dart';
import 'ubicaciones_di.dart';

class UbicacionesListState {
  final List<Ubicacion> items;
  final int total;
  final String query;
  final bool isLoadingMore;

  const UbicacionesListState({
    this.items = const [],
    this.total = 0,
    this.query = '',
    this.isLoadingMore = false,
  });

  bool get hasMore => items.length < total;

  UbicacionesListState copyWith({
    List<Ubicacion>? items,
    int? total,
    String? query,
    bool? isLoadingMore,
  }) {
    return UbicacionesListState(
      items: items ?? this.items,
      total: total ?? this.total,
      query: query ?? this.query,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class UbicacionesListViewModel extends AsyncNotifier<UbicacionesListState> {
  static const int pageSize = 50;

  ListarUbicaciones get _list => ref.read(listarUbicacionesProvider);
  EliminarUbicacion get _eliminar => ref.read(eliminarUbicacionProvider);

  @override
  Future<UbicacionesListState> build() => _fetchFirstPage('');

  Future<UbicacionesListState> _fetchFirstPage(String query) async {
    final result = await _list(
      skip: 0,
      limit: pageSize,
      query: query.isEmpty ? null : query,
    );
    return switch (result) {
      Success(:final value) => UbicacionesListState(
          items: value.items,
          total: value.total,
          query: query,
        ),
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(query));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchFirstPage(current?.query ?? ''));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    final result = await _list(
      skip: current.items.length,
      limit: pageSize,
      query: current.query.isEmpty ? null : current.query,
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

  /// Borra una ubicación y refresca la lista. Devuelve el [Failure] si falla
  /// (p. ej. [UbicacionesFailure.enUso] ante el 409 de "en uso") para que la
  /// UI lo comunique, o null si tuvo éxito.
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

final ubicacionesListViewModelProvider =
    AsyncNotifierProvider<UbicacionesListViewModel, UbicacionesListState>(
  UbicacionesListViewModel.new,
);
