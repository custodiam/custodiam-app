// FamilyAsyncNotifier por servicio. Estado base = el servicio
// cargado. Las acciones (inscribirse, desapuntarse, publicar,
// convocar, cerrar) usan el repo y emiten AsyncData con el nuevo
// servicio o AsyncError con la Failure correspondiente. La page
// consume el estado vía ref.listen para mostrar snackbars y vía
// ref.watch para renderizar el detalle.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/servicio.dart';
import '../../domain/usecases/cerrar_servicio.dart';
import '../../domain/usecases/convocar_servicio.dart';
import '../../domain/usecases/desapuntarse_servicio.dart';
import '../../domain/usecases/get_servicio_by_id.dart';
import '../../domain/usecases/inscribirse_servicio.dart';
import '../../domain/usecases/publicar_servicio.dart';
import 'servicios_di.dart';

class ServicioFichaViewModel extends FamilyAsyncNotifier<Servicio, String> {
  GetServicioById get _get => ref.read(getServicioByIdProvider);
  InscribirseServicio get _inscribirse =>
      ref.read(inscribirseServicioProvider);
  DesapuntarseServicio get _desapuntarse =>
      ref.read(desapuntarseServicioProvider);
  PublicarServicio get _publicar => ref.read(publicarServicioProvider);
  ConvocarServicio get _convocar => ref.read(convocarServicioProvider);
  CerrarServicio get _cerrar => ref.read(cerrarServicioProvider);

  @override
  Future<Servicio> build(String arg) async {
    return _fetch();
  }

  Future<Servicio> _fetch() async {
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

  Future<void> apuntarse() => _runAction(() => _inscribirse(arg));

  Future<void> desapuntarse() => _runAction(() => _desapuntarse(arg));

  Future<void> publicar() => _runAction(() => _publicar(arg));

  Future<void> convocarTodos() => _runAction(() => _convocar(arg));

  Future<void> convocar(List<String> voluntarioIds) =>
      _runAction(() => _convocar(arg, voluntarioIds: voluntarioIds));

  Future<void> cerrar({String? observaciones}) =>
      _runAction(() => _cerrar(arg, observaciones: observaciones));

  Future<void> _runAction(
    Future<Result<Servicio>> Function() action,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await action();
      return switch (result) {
        Success(:final value) => value,
        Fail(:final failure) => throw failure,
      };
    });
  }
}

final servicioFichaViewModelProvider =
    AsyncNotifierProvider.family<ServicioFichaViewModel, Servicio, String>(
  ServicioFichaViewModel.new,
);
