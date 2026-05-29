// Widget-test helper that mounts a child inside a ProviderScope with
// authServiceProvider overridden to a FakeAuthService that carries the
// requested Keycloak role(s). Use it for RBAC widget tests where the
// only difference between cases is "who is logged in".
//
// Example:
//   await pumpWithRole(
//     tester,
//     role: 'voluntario',
//     child: const VoluntariosListPage(),
//   );
//   expect(find.byKey(K.shellSomeAction), findsNothing);
//
// For richer scenarios (multiple roles, custom user fields), pass the
// `roles:` list and `email:` directly.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';

Future<void> pumpWithRole(
  WidgetTester tester, {
  required Widget child,
  String? role,
  List<String> roles = const [],
  String email = 'test@custodiam.es',
  bool settle = true,
}) async {
  final effectiveRoles = role != null ? [role, ...roles] : roles;
  final auth = _FakeAuthServiceWithRoles(roles: effectiveRoles, email: email);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWith((ref) => auth),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: Scaffold(body: child),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

class _FakeAuthServiceWithRoles implements AuthService {
  _FakeAuthServiceWithRoles({required this.roles, required this.email})
      : _notifier = ValueNotifier(roles.isNotEmpty);

  final List<String> roles;
  final String email;
  final ValueNotifier<bool> _notifier;

  @override
  Future<void> init() async {}

  @override
  bool get isAuthenticated => roles.isNotEmpty;

  @override
  String? get accessToken => isAuthenticated ? 'fake-token' : null;

  @override
  CurrentUser? get currentUser => isAuthenticated
      ? CurrentUser(sub: 'fake-sub', email: email, roles: roles)
      : null;

  @override
  Listenable get authStateListenable => _notifier;

  @override
  bool consumeExpiredFlag() => false;

  @override
  Future<Result<void>> login() async => const Success(null);

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<Result<String>> getValidAccessToken() async {
    if (!isAuthenticated) {
      return const Fail(AuthFailure.sessionExpired());
    }
    return const Success('fake-token');
  }
}
