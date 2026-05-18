// Secure wrapper around FlutterSecureStorage for the oauth2.Credentials
// JSON blob. The blob contains access token, refresh token, expiry and
// scopes (produced by Credentials.toJson(), rehydrated with
// Credentials.fromJson()). See guide 25 §5.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  static const _credentialsKey = 'custodiam_credentials';

  final FlutterSecureStorage _storage;

  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> save(String credentialsJson) =>
      _storage.write(key: _credentialsKey, value: credentialsJson);

  Future<String?> read() => _storage.read(key: _credentialsKey);

  Future<void> clear() => _storage.delete(key: _credentialsKey);
}
