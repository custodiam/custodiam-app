import 'package:flutter_test/flutter_test.dart';
import 'package:custodiam/core/config/env_config.dart';

// Note: String.fromEnvironment is compile-time; these tests verify the
// default values that ship when no --dart-define is passed. Runtime
// override testing would require a separate build configuration.

void main() {
  group('EnvConfig defaults', () {
    test('apiBaseUrl defaults to local FastAPI', () {
      expect(EnvConfig.apiBaseUrl, 'http://localhost:8000/api/v1');
    });

    test('keycloakBaseUrl defaults to local Keycloak', () {
      expect(EnvConfig.keycloakBaseUrl, 'http://localhost:8080');
    });

    test('keycloakRealm defaults to "custodiam"', () {
      expect(EnvConfig.keycloakRealm, 'custodiam');
    });

    test('keycloakClientId defaults to "custodiam-app"', () {
      expect(EnvConfig.keycloakClientId, 'custodiam-app');
    });

    test('defaults are non-empty and use http scheme', () {
      expect(EnvConfig.apiBaseUrl, isNotEmpty);
      expect(EnvConfig.keycloakBaseUrl, isNotEmpty);
      expect(EnvConfig.keycloakRealm, isNotEmpty);
      expect(EnvConfig.keycloakClientId, isNotEmpty);
      expect(EnvConfig.apiBaseUrl, startsWith('http'));
      expect(EnvConfig.keycloakBaseUrl, startsWith('http'));
    });
  });
}
