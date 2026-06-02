// FamilyAsyncNotifier del inventario de un servicio (R1). Carga los recursos
// asignados y expone asignar material / vehículo. Las acciones devuelven bool
// y, en fallo, vuelcan AsyncError vía _surface (mismo patrón que
// DotacionVehiculoViewModel); en éxito recargan la lista.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/servicio_inventario.dart';
import '../../domain/usecases/asignar_material_servicio.dart';
import '../../domain/usecases/asignar_vehiculo_servicio.dart';
import '../../domain/usecases/get_inventario_servicio.dart';
import 'servicios_di.dart';

class ServicioInventarioViewModel
    extends FamilyAsyncNotifier<ServicioInventario, String> {
  GetInventarioServicio get _get => ref.read(getInventarioServicioProvider);
  AsignarMaterialServicio get _asignarMaterial =>
      ref.read(asignarMaterialServicioProvider);
  AsignarVehiculoServicio get _asignarVehiculo =>
      ref.read(asignarVehiculoServicioProvider);

  @override
  Future<ServicioInventario> build(String arg) async => _fetch();

  Future<ServicioInventario> _fetch() async {
    final result = await _get(arg);
    return switch (result) {
      Success(:final value) => value,
      Fail(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> asignarMaterial({
    required String materialId,
    int cantidad = 1,
  }) async {
    final result = await _asignarMaterial(
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

  Future<bool> asignarVehiculo({required String vehiculoId}) async {
    final result = await _asignarVehiculo(arg, vehiculoId: vehiculoId);
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

final servicioInventarioViewModelProvider = AsyncNotifierProvider.family<
    ServicioInventarioViewModel, ServicioInventario, String>(
  ServicioInventarioViewModel.new,
);
