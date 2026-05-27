// FamilyAsyncNotifier para la ficha de un vehículo. Acciones:
// reportar incidencia (US-05-08/09 para vehículos).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/estado_inventario.dart';
import '../../domain/entities/vehiculo_item.dart';
import '../../domain/usecases/get_vehiculo.dart';
import '../../domain/usecases/reportar_incidencia_vehiculo.dart';
import 'inventario_di.dart';

class VehiculoFichaViewModel
    extends FamilyAsyncNotifier<VehiculoItem, String> {
  GetVehiculo get _get => ref.read(getVehiculoProvider);
  ReportarIncidenciaVehiculo get _incidencia =>
      ref.read(reportarIncidenciaVehiculoProvider);

  @override
  Future<VehiculoItem> build(String arg) async => _fetch();

  Future<VehiculoItem> _fetch() async {
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

  Future<void> reportarIncidencia({
    required EstadoInventario nuevoEstado,
    required String descripcion,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _incidencia(
        arg,
        nuevoEstado: nuevoEstado,
        descripcion: descripcion,
      );
      return switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => throw failure,
      };
    });
  }
}

final vehiculoFichaViewModelProvider = AsyncNotifierProvider.family<
    VehiculoFichaViewModel, VehiculoItem, String>(
  VehiculoFichaViewModel.new,
);
