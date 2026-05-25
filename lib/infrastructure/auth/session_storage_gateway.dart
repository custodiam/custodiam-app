// Seam over the browser's window.sessionStorage so KeycloakWebAuthService
// can persist the PKCE code_verifier across the _self redirect to
// Keycloak without depending on package:web directly at the call site
// (the call site stays testable in pure-Dart unit tests).
//
// Three operations are exposed: read, write, remove. Failure modes
// (sessionStorage disabled, private mode quotas, security errors) all
// surface as exceptions; callers translate them into the appropriate
// AuthFailure. Existence checks should go through readAvailable() so
// the caller can decide what to do without catching.
//
// See guide 25 v0.4.0 §6.B and §12.A, ADR-023.

import 'package:web/web.dart' as web;

/// Contract used by KeycloakWebAuthService.
abstract class SessionStorageGateway {
  /// True if sessionStorage is reachable on this browser/profile. Some
  /// privacy modes and corporate policies disable it.
  bool isAvailable();

  /// Reads the value stored under [key], or null if missing.
  String? read(String key);

  /// Persists [value] under [key]. Throws on quota / availability errors.
  void write(String key, String value);

  /// Removes the entry under [key]. No-op if missing.
  void remove(String key);
}

/// Default production implementation backed by package:web. Only safe
/// to instantiate when kIsWeb is true; on mobile builds the constructor
/// compiles but the underlying calls fail at runtime (the providers.dart
/// factory guards this).
class WebSessionStorageGateway implements SessionStorageGateway {
  const WebSessionStorageGateway();

  @override
  bool isAvailable() {
    const probeKey = '__custodiam_probe__';
    try {
      web.window.sessionStorage.setItem(probeKey, '1');
      web.window.sessionStorage.removeItem(probeKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  String? read(String key) => web.window.sessionStorage.getItem(key);

  @override
  void write(String key, String value) =>
      web.window.sessionStorage.setItem(key, value);

  @override
  void remove(String key) => web.window.sessionStorage.removeItem(key);
}

/// In-memory implementation used by tests to drive the 4 DoD scenarios
/// of EN-08-34 without booting a headless browser. Behaviour mirrors
/// the browser semantics: write throws when [available] is false; reads
/// after a remove return null.
class InMemorySessionStorageGateway implements SessionStorageGateway {
  InMemorySessionStorageGateway({bool available = true})
      : _available = available;

  final Map<String, String> _store = {};
  bool _available;

  set available(bool value) => _available = value;

  @override
  bool isAvailable() => _available;

  @override
  String? read(String key) {
    if (!_available) {
      throw StateError('sessionStorage is disabled');
    }
    return _store[key];
  }

  @override
  void write(String key, String value) {
    if (!_available) {
      throw StateError('sessionStorage is disabled');
    }
    _store[key] = value;
  }

  @override
  void remove(String key) {
    if (!_available) return;
    _store.remove(key);
  }
}
