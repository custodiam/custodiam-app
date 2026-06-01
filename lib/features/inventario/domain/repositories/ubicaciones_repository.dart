// Contrato del repositorio del catálogo de ubicaciones (E10). El catálogo es
// un submódulo de inventario: solo material y vehículos referencian una
// ubicación base, así que vive aquí (guía 26 §1, sin cruce de features).

import '../../../../infrastructure/error/result.dart';
import '../entities/ubicacion.dart';
import '../entities/ubicaciones_page.dart';

abstract class UbicacionesRepository {
  Future<Result<UbicacionesPage>> listar({
    int skip,
    int limit,
    String? query,
  });

  Future<Result<Ubicacion>> obtener(String id);

  Future<Result<Ubicacion>> crear({
    required String nombre,
    String? descripcion,
    double? lat,
    double? lng,
  });

  Future<Result<Ubicacion>> actualizar(
    String id, {
    String? nombre,
    String? descripcion,
    double? lat,
    double? lng,
  });

  Future<Result<void>> eliminar(String id);
}
