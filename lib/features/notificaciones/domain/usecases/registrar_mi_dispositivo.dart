// Callable use case for US-06-04.

import '../../../../infrastructure/error/result.dart';
import '../entities/dispositivo_registrado.dart';
import '../repositories/notificaciones_repository.dart';

class RegistrarMiDispositivo {
  final NotificacionesRepository _repository;

  const RegistrarMiDispositivo(this._repository);

  Future<Result<DispositivoRegistrado?>> call() =>
      _repository.registrarMiDispositivo();
}
