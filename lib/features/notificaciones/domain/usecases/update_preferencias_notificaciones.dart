// Callable use case for US-06-03 — write side.

import '../entities/preferencias_notificaciones.dart';
import '../repositories/notificaciones_repository.dart';

class UpdatePreferenciasNotificaciones {
  final NotificacionesRepository _repository;

  const UpdatePreferenciasNotificaciones(this._repository);

  Future<void> call(PreferenciasNotificaciones preferencias) {
    return _repository.setPreferencias(preferencias);
  }
}
