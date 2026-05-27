// Repository contract for the fichaje feature. Returns Result<T>;
// implementations never throw cross-layer (guide 26 §4).

import '../../../../infrastructure/error/result.dart';
import '../entities/fichaje.dart';
import '../entities/fichaje_en_servicio.dart';
import '../entities/horas_acumuladas.dart';

abstract class FichajeRepository {
  /// POST /servicios/{id}/fichaje/entrada — US-04-01.
  /// 409 may be: servicio no activo, voluntario no inscrito ni
  /// convocado, o ya tiene una entrada abierta. El backend devuelve
  /// el mismo status para los 3; los repartimos por mensaje.
  Future<Result<Fichaje>> ficharEntrada(String servicioId);

  /// POST /servicios/{id}/fichaje/salida — US-04-02. 404 si no hay
  /// fichaje abierto.
  Future<Result<Fichaje>> ficharSalida(String servicioId);

  /// GET /servicios/{id}/fichaje — US-04-04, jefe+.
  Future<Result<List<FichajeEnServicio>>> listFichadosServicio(
    String servicioId,
  );

  /// GET /fichajes/me — US-04-03 (historial).
  Future<Result<List<Fichaje>>> misFichajes();

  /// GET /fichajes/me/horas — US-04-03 (resumen).
  Future<Result<HorasAcumuladas>> misHoras();
}
