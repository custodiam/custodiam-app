// Auth view model. Orchestrates AuthService.login()/logout() through
// the AsyncNotifier lifecycle so the LoginPage can ref.listen for
// success / failure and ref.watch for the loading flag. See guía 25
// v0.2.0 §10.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/auth/auth_service.dart';
import '../../../../infrastructure/error/result.dart';
import 'auth_di.dart';

class AuthViewModel extends AsyncNotifier<void> {
  AuthService get _auth => ref.read(authServiceForViewModelProvider);

  @override
  FutureOr<void> build() {}

  Future<void> login() async {
    state = const AsyncLoading();
    final result = await _auth.login();
    state = switch (result) {
      Success() => const AsyncData(null),
      Fail(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    final result = await _auth.logout();
    state = switch (result) {
      Success() => const AsyncData(null),
      Fail(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, void>(AuthViewModel.new);
