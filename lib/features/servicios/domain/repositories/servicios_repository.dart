// Repository contract for the servicios feature. Implementations
// never throw cross-layer (guide 26 §4); always return Result<T>.

import '../../../../infrastructure/error/result.dart';
import '../entities/estado_servicio.dart';
import '../entities/servicio.dart';
import '../entities/servicio_create.dart';
import '../entities/servicio_inventario.dart';
import '../entities/servicios_page.dart';
import '../entities/tipo_servicio.dart';
import '../entities/voluntario_inscrito.dart';

abstract class ServiciosRepository {
  /// GET /servicios — paginated listing (US-03-07). Backend caps
  /// limit at 200. `desde`/`hasta` acotan por `fecha_inicio` (rango
  /// inclusivo de día completo en ambos extremos).
  Future<Result<ServiciosPage>> list({
    int skip,
    int limit,
    String? query,
    EstadoServicio? estado,
    TipoServicio? tipo,
    DateTime? desde,
    DateTime? hasta,
  });

  /// GET /servicios/{id} — full detail.
  Future<Result<Servicio>> getById(String id);

  /// POST /servicios — create new (US-03-01 / US-03-02). The backend
  /// picks the initial estado from the tipo: preventivo/formacion/otro
  /// → borrador, emergencia → activo.
  Future<Result<Servicio>> create(ServicioCreate data);

  /// POST /servicios/{id}/publicar (US-03-03). 409 maps to
  /// ServiciosFailure.transicionInvalida.
  Future<Result<Servicio>> publicar(String id);

  /// POST /servicios/{id}/convocar (US-03-04 / US-03-05 / US-03-06).
  /// If `voluntarioIds` is empty/null the backend convoca a todos los
  /// activos disponibles. 409 → ServiciosFailure.transicionInvalida.
  Future<Result<Servicio>> convocar(
    String id, {
    List<String>? voluntarioIds,
  });

  /// POST /servicios/{id}/cerrar (US-03-10). 409 → transicionInvalida.
  Future<Result<Servicio>> cerrar(String id, {String? observaciones});

  /// POST /servicios/{id}/inscribirse (US-03-08). 409 may be
  /// "ya inscrito" or "estado no admite inscripciones".
  Future<Result<Servicio>> inscribirse(String id);

  /// DELETE /servicios/{id}/inscribirse (US-03-09). 404 → noInscrito.
  Future<Result<Servicio>> desapuntarse(String id);

  /// GET /servicios/{id}/voluntarios — list of inscritos/convocados.
  Future<Result<List<VoluntarioInscrito>>> listVoluntarios(String id);

  /// GET /servicios/{id}/inventario — recursos asignados al servicio (R1).
  Future<Result<ServicioInventario>> getInventario(String id);

  /// POST /servicios/{id}/inventario/material (CU-22 / US-05-06). El 409 de
  /// solape temporal → InventarioFailure.recursoSolapado.
  Future<Result<void>> asignarMaterial(
    String id, {
    required String materialId,
    int cantidad,
  });

  /// POST /servicios/{id}/inventario/vehiculo (CU-22 / US-05-07). El 409 de
  /// solape temporal → InventarioFailure.recursoSolapado.
  Future<Result<void>> asignarVehiculo(String id, {required String vehiculoId});
}
