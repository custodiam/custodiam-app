// FamilyAsyncNotifier por servicio. Estado base = el servicio
// cargado. Las acciones (inscribirse, desapuntarse, publicar,
// convocar, cerrar) usan el repo y, en éxito, emiten AsyncData con el
// nuevo servicio que devuelve el backend; en fallo NO tumban el estado
// (devuelven la Failure y dejan la ficha intacta). La page consume el
// estado vía ref.watch para renderizar el detalle y recoge la Failure
// devuelta por cada acción para mostrar el feedback puntual. El único
// AsyncError posible es el de la carga inicial / refresh.

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

  Future<Failure?> apuntarse() => _runAction(() => _inscribirse(arg));

  Future<Failure?> desapuntarse() => _runAction(() => _desapuntarse(arg));

  Future<Failure?> publicar() => _runAction(() => _publicar(arg));

  Future<Failure?> convocarTodos() => _runAction(() => _convocar(arg));

  Future<Failure?> convocar(List<String> voluntarioIds) =>
      _runAction(() => _convocar(arg, voluntarioIds: voluntarioIds));

  Future<Failure?> cerrar({String? observaciones}) =>
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

  /// Ejecuta una acción sobre el servicio y devuelve `null` si terminó con
  /// éxito o la [Failure] si falló. En éxito actualiza el estado a `AsyncData`
  /// con el [Servicio] que devuelve el backend (los 200 de las transiciones e
  /// inscripciones traen el `ServicioResponse` actualizado). En fallo NO toca
  /// el estado: la ficha sigue cargada y la página pinta un snackbar con el
  /// mensaje de la Failure, en vez de tumbar la pantalla entera con un
  /// `AppErrorState`. Así una acción puntual fallida no destruye el detalle.
  Future<Failure?> _runAction(
    Future<Result<Servicio>> Function() action,
  ) async {
    final result = await action();
    switch (result) {
      case Success(:final value):
        // El 200 trae el ServicioResponse actualizado: reemplazamos el
        // AsyncData para que la ficha se repinte con el nuevo estado.
        state = AsyncData(value);
        return null;
      case Fail(:final failure):
        // No tocamos el estado: la ficha sigue cargada y la página muestra
        // la Failure en un snackbar, sin tumbar la pantalla.
        return failure;
    }
  }
}

final servicioFichaViewModelProvider =
    AsyncNotifierProvider.family<ServicioFichaViewModel, Servicio, String>(
  ServicioFichaViewModel.new,
);
