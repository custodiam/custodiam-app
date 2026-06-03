// FamilyAsyncNotifier por servicio. Estado base = el servicio
// cargado. Las acciones (inscribirse, desapuntarse, publicar,
// convocar, cerrar) usan el repo y emiten AsyncData con el nuevo
// servicio o AsyncError con la Failure correspondiente. La page
// consume el estado vía ref.listen para mostrar snackbars y vía
// ref.watch para renderizar el detalle.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/error/failure.dart';
import '../../../../infrastructure/error/result.dart';
import '../../domain/entities/servicio.dart';
import '../../domain/usecases/cerrar_servicio.dart';
import '../../domain/usecases/convocar_servicio.dart';
import '../../domain/usecases/desapuntarse_servicio.dart';
import '../../domain/usecases/eliminar_servicio.dart';
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
  EliminarServicio get _eliminar => ref.read(eliminarServicioProvider);

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

  Future<bool> apuntarse() => _runAction(() => _inscribirse(arg));

  Future<bool> desapuntarse() => _runAction(() => _desapuntarse(arg));

  Future<bool> publicar() => _runAction(() => _publicar(arg));

  Future<bool> convocarTodos() => _runAction(() => _convocar(arg));

  Future<bool> convocar(List<String> voluntarioIds) =>
      _runAction(() => _convocar(arg, voluntarioIds: voluntarioIds));

  Future<bool> cerrar({String? observaciones}) =>
      _runAction(() => _cerrar(arg, observaciones: observaciones));

  /// Borra el servicio (A7). Devuelve `null` en éxito (la page navega a la
  /// lista) o la [Failure] en error —en especial el 409
  /// `ServicioTieneActividad`, que la page muestra sin navegar. No mutamos el
  /// estado del notifier: en éxito la page abandona la ficha, así que no tiene
  /// sentido emitir un AsyncData con un servicio ya borrado.
  Future<Failure?> eliminar() async {
    final result = await _eliminar(arg);
    return switch (result) {
      Success() => null,
      Fail(:final failure) => failure,
    };
  }

  /// Ejecuta una acción sobre el servicio y devuelve `true` si terminó con
  /// éxito (estado final `AsyncData`) o `false` si falló (`AsyncError`, cuyo
  /// snackbar de error pinta el `ref.listen` de la página). El valor de
  /// retorno permite al handler mostrar el feedback de éxito sin re-escuchar
  /// el estado ni adivinar qué acción se ejecutó.
  Future<bool> _runAction(
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
    return state.hasValue;
  }
}

final servicioFichaViewModelProvider =
    AsyncNotifierProvider.family<ServicioFichaViewModel, Servicio, String>(
  ServicioFichaViewModel.new,
);
