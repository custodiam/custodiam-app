import 'package:custodiam/core/ui/pages/app_coming_soon_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppComingSoonPage', () {
    testWidgets('renders the title, the coming-soon copy and the phase',
        (tester) async {
      await pumpRiverpod(
        tester,
        const AppComingSoonPage(
          title: 'Administración',
          phase: 'Fase 3',
          icon: Icons.admin_panel_settings_outlined,
        ),
        // The page builds its own AppPageScaffold (a Scaffold); avoid
        // nesting it inside the helper's default Scaffold.
        wrapInScaffold: false,
      );

      // Title appears in the AppBar.
      expect(find.text('Administración'), findsOneWidget);
      // Empty-state title.
      expect(find.text('Próximamente'), findsOneWidget);
      // Description mentions the phase.
      expect(
        find.textContaining('Fase 3'),
        findsOneWidget,
      );
    });

    testWidgets('renders the provided decorative icon', (tester) async {
      await pumpRiverpod(
        tester,
        const AppComingSoonPage(
          title: 'Gestión documental',
          phase: 'Fase 2',
          icon: Icons.folder_outlined,
        ),
        wrapInScaffold: false,
      );

      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    });

    testWidgets('exposes a Semantics container labelled "<title> — Próximamente"',
        (tester) async {
      await pumpRiverpod(
        tester,
        const AppComingSoonPage(
          title: 'Gestión económica',
          phase: 'Fase 2',
          icon: Icons.payments_outlined,
        ),
        wrapInScaffold: false,
      );

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('Gestión económica — Próximamente'),
      );
      expect(semantics, isNotNull);
    });
  });
}
