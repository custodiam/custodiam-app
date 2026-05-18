// Bootstrap-time placeholder for AuthService. Always reports the
// session as missing so SplashPage routes to /login. Stays in the
// tree only until EN-01-02 swaps the provider to KeycloakAuthService;
// the swap commit deletes this file along with its test.

import '../error/failure.dart';
import '../error/result.dart';
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

  @override
  String? get accessToken => null;

  @override
  Future<Result<void>> login() async =>
      const Fail(AuthFailure.sessionExpired());

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<Result<String>> getValidAccessToken() async =>
      const Fail(AuthFailure.sessionExpired());
}
