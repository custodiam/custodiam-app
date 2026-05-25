// Stub WebSessionStorageGateway for non-web targets. Used by VM and
// mobile builds via the conditional import in providers.dart so the
// real implementation (which imports package:web) never reaches a
// compile target that does not support it.
//
// Every method either reports the gateway as unavailable or throws,
// because this stub should only ever be reachable from
// platform-mismatched configurations (Android/iOS/VM). On those
// platforms the providers.dart factory never wires
// KeycloakWebAuthService, so the stub is structurally unreachable
// at runtime — but it must satisfy the contract surface so the file
// compiles when conditionally imported.

import 'session_storage_gateway.dart';

class WebSessionStorageGateway implements SessionStorageGateway {
  const WebSessionStorageGateway();

  @override
  bool isAvailable() => false;

  @override
  String? read(String key) {
    throw UnsupportedError(
      'WebSessionStorageGateway is only available on Flutter Web. '
      'Reached the stub on a non-web target.',
    );
  }

  @override
  void write(String key, String value) {
    throw UnsupportedError(
      'WebSessionStorageGateway is only available on Flutter Web. '
      'Reached the stub on a non-web target.',
    );
  }

  @override
  void remove(String key) {
    // Tolerated as a no-op so cleanup paths in shared lifecycle code
    // do not throw when the stub is reached by accident.
  }
}
