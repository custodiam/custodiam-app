// Restores the session through AuthService.init() and decides where
// SplashPage should send the user. Pure Dart, no Flutter / Riverpod
// imports — per guide 26 §2.

import '../../../../infrastructure/auth/auth_service.dart';

enum StartupDestination { home, login }

class DecideStartupDestination {
  final AuthService _authService;

  const DecideStartupDestination(this._authService);

  Future<StartupDestination> call() async {
    await _authService.init();
    return _authService.isAuthenticated
        ? StartupDestination.home
        : StartupDestination.login;
  }
}
