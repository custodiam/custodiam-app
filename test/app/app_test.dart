import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:custodiam/app/app.dart';

import '../test_utils/test_app.dart';

void main() {
  // CustodiamApp uses MaterialApp.router internally, so we mount it
  // through pumpRiverpod which only provides ProviderScope. The router
  // takes care of the rest.
  testWidgets('App renders without errors', (tester) async {
    await tester.pumpWidget(const CustodiamApp());
    await tester.pumpAndSettle();

    expect(find.text('Custodiam'), findsWidgets);
  });

  testWidgets('pumpRiverpod helper renders a trivial child', (tester) async {
    // Smoke test for the shared helper. It now wraps the child in
    // Scaffold(body: ...) automatically, so a bare Text is enough.
    await pumpRiverpod(tester, const Text('ok'));
    expect(find.text('ok'), findsOneWidget);
  });
}
