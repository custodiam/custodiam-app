import 'package:custodiam/core/ui/containers/app_page_scaffold.dart';
import 'package:custodiam/core/ui/tokens/app_breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppPageScaffold', () {
    testWidgets('renders body inside SafeArea and ConstrainedBox',
        (tester) async {
      await pumpRiverpod(
        tester,
        const AppPageScaffold(
          body: Text('contenido'),
        ),
      );

      expect(find.text('contenido'), findsOneWidget);
      expect(find.byType(SafeArea), findsWidgets);
      expect(find.byType(ConstrainedBox), findsWidgets);
    });

    testWidgets('renders AppBar with title and actions when provided',
        (tester) async {
      await pumpRiverpod(
        tester,
        AppPageScaffold(
          title: 'Voluntarios',
          actions: [
            IconButton(
              tooltip: 'Buscar',
              onPressed: () {},
              icon: const Icon(Symbols.search),
            ),
          ],
          body: const Text('contenido'),
        ),
      );

      expect(find.text('Voluntarios'), findsOneWidget);
      expect(find.byIcon(Symbols.search), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('does not render AppBar when title is null', (tester) async {
      await pumpRiverpod(
        tester,
        const AppPageScaffold(body: Text('contenido')),
      );

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('applies default contentMaxWidth from tokens', (tester) async {
      await pumpRiverpod(
        tester,
        const AppPageScaffold(body: SizedBox.expand()),
      );

      final scaffold = tester.widget<AppPageScaffold>(
        find.byType(AppPageScaffold),
      );
      expect(scaffold.maxContentWidth, AppBreakpoints.contentMaxWidth);
    });

    testWidgets('renders bottomNavigationBar and FAB when provided',
        (tester) async {
      await pumpRiverpod(
        tester,
        AppPageScaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: const BottomAppBar(child: SizedBox(height: 48)),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Symbols.add),
          ),
        ),
      );

      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
