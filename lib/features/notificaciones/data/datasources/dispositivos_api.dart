// Thin wrapper around ApiClient with the dispositivos endpoints
// (EN-06-05 backend). Stays close to the wire format; the repository
// handles Result<T> shaping.

import '../../../../infrastructure/network/api_client.dart';
import '../../domain/entities/plataforma_dispositivo.dart';

class DispositivosApi {
  final ApiClient _client;

  const DispositivosApi(this._client);

  /// POST /dispositivos — registra/refresca mi token FCM. El backend es
  /// idempotente: enviar el mismo token no duplica filas, solo reactiva
  /// la existente (o la reasigna si pertenecía a otro voluntario).
  Future<Map<String, dynamic>> registrar({
    required String fcmToken,
    required PlataformaDispositivo plataforma,
  }) {
    return _client.post('/dispositivos', {
      'fcm_token': fcmToken,
      'plataforma': plataforma.wire,
    });
  }

  /// GET /dispositivos/me — mis dispositivos activos.
  Future<ApiResponse<List<dynamic>>> listarMisDispositivos() {
    return _client.getList('/dispositivos/me');
  }

  /// DELETE /dispositivos/{id} — soft delete de un dispositivo propio.
  /// 204 No Content en caso feliz; 403 si pertenece a otro voluntario.
  Future<Map<String, dynamic>> darBaja(String dispositivoId) {
    return _client.delete('/dispositivos/$dispositivoId');
  }
}
