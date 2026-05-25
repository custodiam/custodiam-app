import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:custodiam/app/app.dart';
import 'package:custodiam/features/splash/presentation/pages/splash_page.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';

import '../test_utils/test_app.dart';

class _InMemoryAuthService implements AuthService {
  final ValueNotifier<bool> _authNotifier = ValueNotifier(false);

  @override
  Future<void> init() async {}

  @override
  bool get isAuthenticated => false;

  @override
  String? get accessToken => null;

  @override
  CurrentUser? get currentUser => null;

  @override
  Listenable get authStateListenable => _authNotifier;

  @override
  bool consumeExpiredFlag() => false;

  @override
  Future<Result<void>> login() async => const Success(null);

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<Result<String>> getValidAccessToken() async =>
      const Fail(AuthFailure.sessionExpired());
}

void main() {
  testWidgets('App boots without exceptions and leaves splash behind',
      (tester) async {
    // CustodiamApp is mounted with its real router (MaterialApp.router).
    // authServiceProvider is overridden with an in-memory fake so the
    // smoke test does not depend on FlutterSecureStorage platform
    // channels (those are covered by integration_test/). The startup
    // use case resolves to /login and SplashPage navigates away.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_InMemoryAuthService()),
        ],
        child: const CustodiamApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SplashPage), findsNothing);
  });

  testWidgets('pumpRiverpod helper renders a trivial child', (tester) async {
    // Smoke test for the shared helper. It wraps the child in
    // Scaffold(body: ...) automatically, so a bare Text is enough.
    await pumpRiverpod(tester, const Text('ok'));
    expect(find.text('ok'), findsOneWidget);
  });
}
