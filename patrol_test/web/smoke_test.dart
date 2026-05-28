// Diagnostic smoke test for issue #40 (patrol-web hang).
//
// Minimum-possible patrol web test: mounts an empty MaterialApp and
// asserts nothing more than the SizedBox being present. NO ProviderScope,
// NO CustodiamApp, NO FcmBootstrap, NO GoRouter, NO Riverpod, NO Firebase
// surface — none of the moving parts that the OAuth tests exercise.
//
// Run requirements:
//   patrol test --target patrol_test/web/smoke_test.dart \
//               --device chrome --web-headless=true \
//               --web-locale=es-ES --web-timezone=Europe/Madrid --verbose
//
// Interpretation:
//   - If this smoke also hangs ~12 minutes → the bug is in the patrol_cli
//     + Playwright + Flutter Web headless teardown plumbing, independent
//     of anything we mount. Upstream bug, ready to report with minimal
//     repro.
//   - If this smoke passes green stably (≥2 runs to overcome flakiness)
//     → something inside `CustodiamApp`'s mounting triggers the hang
//     (FcmBootstrap's FirebaseMessaging.instance side-effect, GoRouter's
//     refreshListenable, SharedPreferences IndexedDB handle, etc.). The
//     bisect then narrows down within our wiring.
//
// Wrapper choice: `patrolTest` (from `package:patrol`, NOT
// `patrolWidgetTest` from `package:patrol_finders`). Under `patrol test`
// the CLI only counts `patrolTest` as executable; using `patrolWidgetTest`
// would silently report `Total: 0` and exit 1 in ~1 second — a different
// failure mode and not what we want to probe. See memory note
// `patrol-test-vs-patrolwidgettest` for the historical mistake.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'smoke: trivial MaterialApp mounts and unmounts cleanly',
    ($) async {
      await $.pumpWidget(
        const MaterialApp(home: SizedBox.shrink()),
      );
      await $.pumpAndSettle();
      expect(find.byType(SizedBox), findsOneWidget);
    },
  );
}
