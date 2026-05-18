// Compile-time environment configuration per ADR-015.
//
// All values are resolved via String.fromEnvironment so they can be
// injected at build time with --dart-define. Defaults point to the
// local development stack. See guide 26 §8.
//
// Builds:
//   flutter run                                 (defaults to localhost)
//   flutter build apk \
//     --dart-define=API_BASE_URL=https://api.custodiam.es/api/v1 \
//     --dart-define=KEYCLOAK_BASE_URL=https://auth.custodiam.es

class EnvConfig {
  EnvConfig._();

  /// Base URL of the FastAPI backend.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// Base URL of the Keycloak instance (without realm path).
  static const String keycloakBaseUrl = String.fromEnvironment(
    'KEYCLOAK_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
