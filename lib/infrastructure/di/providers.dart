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
import '../network/api_client.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authServiceProvider = Provider<AuthService>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  if (kIsWeb) {
    return KeycloakWebAuthService(tokenStore: tokenStore);
  }
  return KeycloakMobileAuthService(tokenStore: tokenStore);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(authService: ref.watch(authServiceProvider));
});
