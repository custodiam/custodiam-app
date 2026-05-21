// OIDC endpoints derived from EnvConfig.
//
// Per guide 25 §4 the URLs are not hardcoded — every value flows from
// EnvConfig so builds can override realm / base URL / client ID via
// --dart-define without touching the source.

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/config/env_config.dart';

class KeycloakConfig {
  KeycloakConfig._();

  static String get realmBase =>
      '${EnvConfig.keycloakBaseUrl}/realms/${EnvConfig.keycloakRealm}';

  static String get _oidcBase => '$realmBase/protocol/openid-connect';

  static Uri get authorizationEndpoint => Uri.parse('$_oidcBase/auth');
  static Uri get tokenEndpoint => Uri.parse('$_oidcBase/token');
  static Uri get endSessionEndpoint => Uri.parse('$_oidcBase/logout');

  /// OIDC scopes requested at login. Roles come via the
  /// `custodiam-roles` client scope mapper configured in EN-01-01;
  /// they are not a separate scope.
  static const List<String> scopes = ['openid', 'profile', 'email'];

  /// Redirect URI used for the OAuth callback.
  /// - Mobile: deep-link custom scheme registered in
  ///   AndroidManifest.xml and Info.plist
  /// - Web: the current origin + `/callback` so the same build works
  ///   in dev (localhost) and prod (app.custodiam.es) without
  ///   recompilation. The origin must be registered as a redirect URI
  ///   on the Keycloak `custodiam-app` client.
  static Uri get redirectUri {
    if (kIsWeb) {
      return Uri.parse('${Uri.base.origin}/callback');
    }
    return Uri.parse('es.custodiam://callback');
  }

  static Uri get postLogoutRedirectUri {
    if (kIsWeb) {
      return Uri.parse(Uri.base.origin);
    }
    return Uri.parse('es.custodiam://logout');
  }
}
