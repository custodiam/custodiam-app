// FamilyAsyncNotifier del inventario de un servicio (R1). Carga los recursos
// asignados y expone asignar material / vehículo. Las acciones devuelven la
// [Failure] del fallo (o `null` en éxito) SIN tocar el estado de la lista: un
// rechazo al asignar (p. ej. un recurso ya comprometido, un 409) no debe
// tumbar la sección a AsyncError —que perdería la lista ya cargada y la
// degradaría a "Reintentar"—, sino mostrarse por snackbar dejando la lista en
// pantalla. En éxito recargan la lista. El estado AsyncError queda reservado
// para el fallo de CARGA inicial de la lista (build/refresh).

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

  /// Asigna material al servicio. Devuelve `null` en éxito (y recarga la
  /// lista) o la [Failure] del rechazo, dejando la lista cargada intacta para
  /// que la sección la siga mostrando mientras el llamador surface el motivo.
  Future<Failure?> asignarMaterial({
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
        return null;
      case Fail(:final failure):
        return failure;
    }
  }

  /// Asigna un vehículo al servicio. Misma semántica que [asignarMaterial]:
  /// `null` en éxito, la [Failure] en fallo, sin tocar el estado de la lista.
  Future<Failure?> asignarVehiculo({required String vehiculoId}) async {
    final result = await _asignarVehiculo(arg, vehiculoId: vehiculoId);
    switch (result) {
      case Success():
        await refresh();
        return null;
      case Fail(:final failure):
        return failure;
    }
  }
}

final servicioInventarioViewModelProvider = AsyncNotifierProvider.family<
    ServicioInventarioViewModel, ServicioInventario, String>(
  ServicioInventarioViewModel.new,
);
