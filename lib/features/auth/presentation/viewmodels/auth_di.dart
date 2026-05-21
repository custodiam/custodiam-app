// Auth feature DI. Re-exposes the cross-cutting authServiceProvider as
// a feature-local handle so the view model can be overridden in tests
// without touching the global infrastructure provider. See guía 26 §6
// and guía 25 v0.2.0 §10.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/auth/auth_service.dart';
import '../../../../infrastructure/di/providers.dart';

final authServiceForViewModelProvider = Provider<AuthService>((ref) {
  return ref.watch(authServiceProvider);
});
