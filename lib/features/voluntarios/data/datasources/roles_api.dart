// Thin wrapper around ApiClient with the /roles endpoint. The roles
// catalog has its own data source (and repository) because it is
// conceptually shared — future features (e.g. asignación de rol al
// alta) read the same catalog.

import '../../../../infrastructure/network/api_client.dart';

class RolesApi {
  final ApiClient _client;

  const RolesApi(this._client);

  /// GET /roles — full catalog of realm roles.
  Future<ApiResponse<List<dynamic>>> listCatalogo() {
    return _client.getList('/roles');
  }
}
