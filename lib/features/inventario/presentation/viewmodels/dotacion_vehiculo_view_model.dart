// FamilyAsyncNotifier de la dotación fija de un vehículo (PR3). Carga la
// lista de material asignado al vehículo y expone alta/baja. Las acciones
// devuelven bool y, en fallo, vuelcan AsyncError vía _surface (mismo
// patrón que MaterialFichaViewModel); en éxito recargan la lista.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/dotacion_vehiculo.dart';
import '../../domain/usecases/asignar_dotacion_vehiculo.dart';
import '../../domain/usecases/liberar_dotacion_vehiculo.dart';
import '../../domain/usecases/listar_dotacion_vehiculo.dart';
import 'inventario_di.dart';

class DotacionVehiculoViewModel
    extends FamilyAsyncNotifier<List<DotacionVehiculo>, String> {
  ListarDotacionVehiculo get _listar =>
      ref.read(listarDotacionVehiculoProvider);
  AsignarDotacionVehiculo get _asignar =>
      ref.read(asignarDotacionVehiculoProvider);
  LiberarDotacionVehiculo get _liberar =>
      ref.read(liberarDotacionVehiculoProvider);

  @override
  Future<List<DotacionVehiculo>> build(String arg) async => _fetch();

  Future<List<DotacionVehiculo>> _fetch() async {
    final result = await _listar(arg);
    return switch (result) {
      Success(:final value) => value,
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> asignar({
    required String materialId,
    int cantidad = 1,
  }) async {
    final result = await _asignar(
      arg,
      materialId: materialId,
      cantidad: cantidad,
    );
    switch (result) {
      case Success():
        await refresh();
        return true;
      case Fail(:final failure):
        return _surface(failure);
    }
  }

  Future<bool> liberar({required String asignacionId}) async {
    final result = await _liberar(arg, asignacionId: asignacionId);
    switch (result) {
      case Success():
        await refresh();
        return true;
      case Fail(:final failure):
        return _surface(failure);
    }
  }

  bool _surface(Failure failure) {
    state = AsyncError(failure, StackTrace.current);
    return false;
  }
}

final dotacionVehiculoViewModelProvider = AsyncNotifierProvider.family<
    DotacionVehiculoViewModel, List<DotacionVehiculo>, String>(
  DotacionVehiculoViewModel.new,
);
