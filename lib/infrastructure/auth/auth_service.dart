// Auth service contract consumed by SplashPage's startup use case and
// any feature that needs to know whether there is a live session or
// drive login / logout. Production implementations are
// KeycloakMobileAuthService (Android + iOS) and KeycloakWebAuthService
// (PWA), selected by kIsWeb in providers.dart — see ADR-023.
//
// All operations that can fail return Result<T>; nothing throws
// cross-layer (guide 26 §4).

import 'package:flutter/foundation.dart' show Listenable;

import '../error/result.dart';
import 'current_user.dart';

abstract class AuthService {
  /// Restore persisted session and prepare listeners. Called from
  /// DecideStartupDestination on every cold start (guide 26 §7).
  Future<void> init();

  /// True if the in-memory client has non-expired credentials.
  bool get isAuthenticated;

  /// Current access token. May be expired — use [getValidAccessToken]
  /// when the caller needs a guaranteed-valid token.
  String? get accessToken;

  /// Snapshot of the authenticated user decoded from the current access
  /// token, or null if there is no session. Cheap to call: implementations
  /// memoize the parse against the active token.
  ///
  /// Consumers reading this from a widget should still wrap themselves in
  /// a ConsumerWidget that depends on a Riverpod provider observing
  /// [authStateListenable], so the UI rebuilds on login / logout.
  CurrentUser? get currentUser;

  /// Notifies when the authentication state flips between authenticated
  /// and unauthenticated (login, logout, restore, refresh failure that
  /// clears the local session). Wired as `refreshListenable` on the
  /// GoRouter so a protected route auto-redirects to `/login` when the
  /// refresh token expires mid-session.
  Listenable get authStateListenable;

  /// Single-shot flag: returns true exactly once after the most recent
  /// clearing of the session was caused by an expired refresh token
  /// (NOT by an explicit logout). LoginPage consumes it on mount to
  /// decide whether to surface a "sesión expirada" snackbar; once
  /// consumed it returns false until the next expiration. Used so the
  /// banner does not appear after a deliberate sign-out.
  bool consumeExpiredFlag();

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
