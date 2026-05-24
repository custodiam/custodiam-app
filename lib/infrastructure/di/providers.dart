// Cross-cutting Riverpod providers that any feature can read. Per
// guide 26 §1 / §6, infrastructure services live here as global
// providers and feature-level DI files compose them into the
// per-feature DataSource -> Repository -> UseCase chain.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../auth/keycloak_auth_service.dart';
import '../auth/token_store.dart';
import '../network/api_client.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authServiceProvider = Provider<AuthService>((ref) {
  return KeycloakAuthService(tokenStore: ref.watch(tokenStoreProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(authService: ref.watch(authServiceProvider));
});
