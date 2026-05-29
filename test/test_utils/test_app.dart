// Shared widget-test helper that wraps a child in ProviderScope and
// MaterialApp with the app theme. Use it in every widget test that
// touches Riverpod providers. See guide 22 §5.
//
// Example:
//   await pumpRiverpod(tester, const LoginPage(), overrides: [
//     authViewModelProvider.overrideWith((ref) => FakeAuthViewModel()),
//   ]);
//
// Pass [currentUser] to simulate an authenticated user (e.g. a
// voluntario) without wiring a full fake AuthService by hand. It is
// injected as an override of [authServiceProvider] so widgets that read
// the live session — like AppPermissionGate — behave as if that user is
// logged in. When [currentUser] is null no auth override is added and
// the default unauthenticated AuthService stands, unless the caller
// supplies its own override in [overrides].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/result.dart';

Future<void> pumpRiverpod(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  bool settle = true,
  bool wrapInScaffold = true,
  CurrentUser? currentUser,
}) async {
  final effectiveOverrides = <Override>[
    if (currentUser != null)
      authServiceProvider
          .overrideWithValue(_FakeAuthServiceWithUser(currentUser)),
    ...overrides,
  ];
  final Widget host = wrapInScaffold ? Scaffold(body: child) : child;
  await tester.pumpWidget(
    ProviderScope(
      overrides: effectiveOverrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: host,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

class _FakeAuthServiceWithUser implements AuthService {
  _FakeAuthServiceWithUser(this._user)
      : _notifier = ValueNotifier(true);

  final CurrentUser _user;
  final ValueNotifier<bool> _notifier;

  @override
  Future<void> init() async {}

  @override
  bool get isAuthenticated => true;

  @override
  String? get accessToken => 'fake-token';

  @override
  CurrentUser? get currentUser => _user;

  @override
  Listenable get authStateListenable => _notifier;

  @override
  bool consumeExpiredFlag() => false;

  @override
  Future<Result<void>> login() async => const Success(null);

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<Result<String>> getValidAccessToken() async =>
      const Success('fake-token');
}
