// Widget-test helper that mounts a child inside ProviderScope and
// MaterialApp.router with a custom GoRouter. Use it when the test needs
// to exercise navigation (branches, push, pop, back stack) — that is
// the bit `pumpRiverpod` cannot do because it builds a plain
// MaterialApp without a router.
//
// Example:
//   await pumpWithRouter(
//     tester,
//     router: GoRouter(
//       initialLocation: '/home',
//       routes: [
//         StatefulShellRoute.indexedStack(
//           builder: (_, __, shell) => CustodiamShell(navigationShell: shell),
//           branches: [...],
//         ),
//       ],
//     ),
//     overrides: [
//       authServiceProvider.overrideWithValue(_FakeAuth(...)),
//     ],
//   );

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:custodiam/core/ui/theme/app_theme.dart';

Future<void> pumpWithRouter(
  WidgetTester tester, {
  required GoRouter router,
  List<Override> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: router,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
