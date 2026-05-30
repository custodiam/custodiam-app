// Cross-cutting Riverpod providers that any feature can read. Per
// guide 26 §1 / §6, infrastructure services live here as global
// providers and feature-level DI files compose them into the
// per-feature DataSource -> Repository -> UseCase chain.
//
// EN-08-34 / ADR-023: this is the ONLY place where the AuthService
// implementation is selected by platform. Both concrete classes share
// the same AuthService contract; any further kIsWeb branching inside
// either implementation would be an anti-smell — write the code in the
// correct class instead. The single static lookup that legitimately
// remains is KeycloakConfig.redirectUri.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../auth/keycloak_mobile_auth_service.dart';
import '../auth/keycloak_web_auth_service.dart';
import '../auth/token_store.dart';
import '../catalogo/inventario_catalogo_service.dart';
import '../catalogo/ubicaciones_catalogo_service.dart';
import '../network/api_client.dart';
// Conditional import: on web targets we get the real
// WebSessionStorageGateway backed by package:web; on VM (unit tests)
// and mobile we get a stub that compiles but is never reached at
// runtime because the kIsWeb guard below blocks the only callsite.
import '../auth/web_session_storage_gateway_stub.dart'
    if (dart.library.js_interop) '../auth/web_session_storage_gateway.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authServiceProvider = Provider<AuthService>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  if (kIsWeb) {
    return KeycloakWebAuthService(
      tokenStore: tokenStore,
      sessionStorage: const WebSessionStorageGateway(),
    );
  }
  return KeycloakMobileAuthService(tokenStore: tokenStore);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(authService: ref.watch(authServiceProvider));
});

/// Catálogo de inventario para pickers, compartido entre features
/// (lo consume `servicios` al asignar recursos a un servicio — R1).
final inventarioCatalogoServiceProvider = Provider<InventarioCatalogoService>(
  (ref) => InventarioCatalogoService(ref.watch(apiClientProvider)),
);

/// Catálogo de ubicaciones para el picker de las altas de inventario (PR2).
final ubicacionesCatalogoServiceProvider =
    Provider<UbicacionesCatalogoService>(
  (ref) => UbicacionesCatalogoService(ref.watch(apiClientProvider)),
);
