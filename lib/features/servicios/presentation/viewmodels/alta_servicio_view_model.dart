// AsyncNotifier que mueve AltaServicioPage (US-03-01 / US-03-02).
// Estado inicial AsyncData(null); submit() resuelve a AsyncData(creado)
// en Success o AsyncError(Failure) en Fail.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/servicio.dart';
import '../../domain/entities/servicio_create.dart';
import '../../domain/usecases/crear_servicio.dart';
import 'servicios_di.dart';

class AltaServicioViewModel extends AsyncNotifier<Servicio?> {
  CrearServicio get _crearServicio => ref.read(crearServicioProvider);

  @override
  Future<Servicio?> build() async => null;

  Future<void> submit(ServicioCreate data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _crearServicio(data);
      return switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => throw failure,
      };
    });
  }
}

final altaServicioViewModelProvider =
    AsyncNotifierProvider<AltaServicioViewModel, Servicio?>(
  AltaServicioViewModel.new,
);
