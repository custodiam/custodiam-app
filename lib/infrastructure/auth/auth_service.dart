// Auth service contract consumed by the startup use case and any
// feature that needs to know whether there is a live session. The
// real implementation lands with EN-01-02 (OIDC client). Until then
// DummyAuthService satisfies the contract and always reports the
// user as unauthenticated so SplashPage routes to /login. See guide
// 26 §7 for the bootstrap pattern.

abstract class AuthService {
  Future<void> init();

  bool get isAuthenticated;
}
