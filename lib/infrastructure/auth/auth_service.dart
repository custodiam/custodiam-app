// Auth service contract consumed by SplashPage's startup use case and
// any feature that needs to know whether there is a live session or
// drive login / logout. Implementations live alongside this file:
//
//   - DummyAuthService:  bootstrap-time placeholder, always reports
//                        the session as missing
//   - KeycloakAuthService: real OIDC client wired to Keycloak
//
// All operations that can fail return Result<T>; nothing throws
// cross-layer (guide 26 §4).

import '../error/result.dart';

abstract class AuthService {
  /// Restore persisted session and prepare listeners. Called from
  /// DecideStartupDestination on every cold start (guide 26 §7).
  Future<void> init();

  /// True if the in-memory client has non-expired credentials.
  bool get isAuthenticated;

  /// Current access token. May be expired — use [getValidAccessToken]
  /// when the caller needs a guaranteed-valid token.
  String? get accessToken;

  /// Kick off the Authorization Code + PKCE flow. Resolves with
  /// Success once the session is established; Fail carries the
  /// concrete AuthFailure (cancellation, browser error, network).
  Future<Result<void>> login();

  /// Clear local credentials and invalidate the SSO session on
  /// Keycloak.
  Future<Result<void>> logout();

  /// Return a valid access token, refreshing automatically when the
  /// current one is expired. Fail if there is no session or refresh
  /// itself fails.
  Future<Result<String>> getValidAccessToken();
}
