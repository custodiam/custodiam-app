// Bootstrap-time placeholder for AuthService. Always reports the
// session as missing so the app flows through SplashPage -> /login.
// Replaced by the OIDC-backed implementation in EN-01-02.

import 'auth_service.dart';

class DummyAuthService implements AuthService {
  bool _initialised = false;

  bool get isInitialised => _initialised;

  @override
  Future<void> init() async {
    _initialised = true;
  }

  @override
  bool get isAuthenticated => false;
}
