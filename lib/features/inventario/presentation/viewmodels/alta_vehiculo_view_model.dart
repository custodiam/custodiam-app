// AsyncNotifier para US-05-02.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/vehiculo_create.dart';
import '../../domain/entities/vehiculo_item.dart';
import '../../domain/usecases/create_vehiculo.dart';
import 'inventario_di.dart';

class AltaVehiculoViewModel extends AsyncNotifier<VehiculoItem?> {
  CreateVehiculo get _create => ref.read(createVehiculoProvider);

  @override
  Future<VehiculoItem?> build() async => null;

  Future<void> submit(VehiculoCreate data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _create(data);
      return switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => throw failure,
      };
    });
  }
}

final altaVehiculoViewModelProvider =
    AsyncNotifierProvider<AltaVehiculoViewModel, VehiculoItem?>(
  AltaVehiculoViewModel.new,
);
