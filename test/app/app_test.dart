import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:custodiam/app/app.dart';
import 'package:custodiam/features/splash/presentation/pages/splash_page.dart';

import '../test_utils/test_app.dart';

void main() {
  testWidgets('App boots without exceptions and leaves splash behind',
      (tester) async {
    // CustodiamApp is mounted with its real router (MaterialApp.router).
    // With the bootstrap DummyAuthService the startup use case resolves
    // to /login and SplashPage navigates away.
    await tester.pumpWidget(const ProviderScope(child: CustodiamApp()));
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
