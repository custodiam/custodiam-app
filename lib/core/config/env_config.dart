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

  /// Keycloak realm.
  static const String keycloakRealm = String.fromEnvironment(
    'KEYCLOAK_REALM',
    defaultValue: 'custodiam',
  );

  /// Keycloak client ID (Flutter public client with PKCE S256).
  static const String keycloakClientId = String.fromEnvironment(
    'KEYCLOAK_CLIENT_ID',
    defaultValue: 'custodiam-app',
  );

  /// Web Push VAPID key emitted by Firebase Cloud Messaging (EN-06-02).
  /// Only meaningful on web targets: `FcmServiceFirebase.getToken` forwards
  /// it to `FirebaseMessaging.getToken(vapidKey: ...)`. When empty, the
  /// Web client stays in degraded mode (`FcmServiceUnavailable`) and the
  /// login flow keeps working without push.
  static const String fcmVapidKey = String.fromEnvironment(
    'FCM_VAPID_KEY',
    defaultValue: '',
  );
}
