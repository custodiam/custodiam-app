// Real WebSessionStorageGateway: thin wrapper over
// window.sessionStorage via package:web. Loaded ONLY when the program
// is compiled for the web target.
//
// providers.dart selects this file via the conditional import
//
//   import 'web_session_storage_gateway_stub.dart'
//       if (dart.library.js_interop) 'web_session_storage_gateway.dart';
//
// so VM-targeted code (unit tests, Android, iOS) picks up the stub
// instead and never tries to compile package:web.

import 'package:web/web.dart' as web;

import 'session_storage_gateway.dart';

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
