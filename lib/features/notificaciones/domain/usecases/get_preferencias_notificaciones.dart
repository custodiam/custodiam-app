// Callable use case for US-06-03 — read side.

import '../entities/preferencias_notificaciones.dart';
import '../repositories/notificaciones_repository.dart';

class GetPreferenciasNotificaciones {
  final NotificacionesRepository _repository;

  const GetPreferenciasNotificaciones(this._repository);

  Future<PreferenciasNotificaciones> call() => _repository.getPreferencias();
}
