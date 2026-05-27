// Catalog of realm roles. The catalog is read-only from the client
// (creation/edition of roles is a Keycloak admin task, not exposed
// through the API for now). Used by the ficha admin form to populate
// the "asignar rol" dropdown.

import '../../../../infrastructure/error/result.dart';
import '../entities/rol.dart';

abstract class RolesRepository {
  /// GET /roles — full catalog ordered by nivel ascendente.
  Future<Result<List<Rol>>> listCatalogo();
}
