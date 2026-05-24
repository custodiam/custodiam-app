import 'package:custodiam/core/config/env_config.dart';
import 'package:custodiam/infrastructure/auth/keycloak_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KeycloakConfig endpoints (default EnvConfig)', () {
    test('realmBase composes baseUrl and realm', () {
      expect(
        KeycloakConfig.realmBase,
        '${EnvConfig.keycloakBaseUrl}/realms/${EnvConfig.keycloakRealm}',
      );
    });

    test('authorizationEndpoint ends with /protocol/openid-connect/auth',
        () {
      expect(
        KeycloakConfig.authorizationEndpoint.toString(),
        endsWith('/realms/custodiam/protocol/openid-connect/auth'),
      );
    });

    test('tokenEndpoint ends with /protocol/openid-connect/token', () {
      expect(
        KeycloakConfig.tokenEndpoint.toString(),
        endsWith('/realms/custodiam/protocol/openid-connect/token'),
      );
    });

    test('endSessionEndpoint ends with /protocol/openid-connect/logout',
        () {
      expect(
        KeycloakConfig.endSessionEndpoint.toString(),
        endsWith('/realms/custodiam/protocol/openid-connect/logout'),
      );
    });

    test('scopes are openid, profile, email', () {
      expect(KeycloakConfig.scopes, ['openid', 'profile', 'email']);
    });

    test('redirectUri uses mobile custom scheme outside web', () {
      // flutter_test runs with kIsWeb == false, so this exercises the
      // mobile branch. The web branch is verified by hand against the
      // dev/prod origin lists in Keycloak.
      expect(KeycloakConfig.redirectUri.toString(), 'es.custodiam://callback');
    });

    test('postLogoutRedirectUri uses mobile custom scheme outside web', () {
      expect(
        KeycloakConfig.postLogoutRedirectUri.toString(),
        'es.custodiam://logout',
      );
    });
  });
}
