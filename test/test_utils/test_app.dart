// Shared widget-test helper that wraps a child in ProviderScope and
// MaterialApp with the app theme. Use it in every widget test that
// touches Riverpod providers. See guide 22 §5.
//
// Example:
//   await pumpRiverpod(tester, const LoginPage(), overrides: [
//     authViewModelProvider.overrideWith((ref) => FakeAuthViewModel()),
//   ]);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:custodiam/core/ui/theme/app_theme.dart';

Future<void> pumpRiverpod(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  bool settle = true,
  bool wrapInScaffold = true,
}) async {
  final Widget host = wrapInScaffold ? Scaffold(body: child) : child;
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
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
