import 'package:custodiam/core/ui/buttons/app_destructive_button.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppDestructiveButton', () {
    testWidgets('renders label and triggers onPressed', (tester) async {
      var pressed = 0;
      await pumpRiverpod(
        tester,
        AppDestructiveButton(
          label: 'Eliminar',
          onPressed: () => pressed++,
        ),
      );

      expect(find.text('Eliminar'), findsOneWidget);
      await tester.tap(find.byType(AppDestructiveButton));
      expect(pressed, 1);
    });

    testWidgets('uses colorScheme.error as background', (tester) async {
      await pumpRiverpod(
        tester,
        AppDestructiveButton(label: 'Eliminar', onPressed: () {}),
      );

      final BuildContext context = tester.element(find.byType(FilledButton));
      final expectedBg = Theme.of(context).colorScheme.error;

      final filled = tester.widget<FilledButton>(find.byType(FilledButton));
      final resolvedBg =
          filled.style!.backgroundColor!.resolve(<WidgetState>{});
      expect(resolvedBg, expectedBg);
    });

    testWidgets('uses default delete icon when none provided', (tester) async {
      await pumpRiverpod(
        tester,
        AppDestructiveButton(label: 'Eliminar', onPressed: () {}),
      );

      expect(find.byIcon(Symbols.delete), findsOneWidget);
    });

    testWidgets('renders custom icon when provided', (tester) async {
      await pumpRiverpod(
        tester,
        AppDestructiveButton(
          label: 'Cerrar sesión',
          onPressed: () {},
          icon: Symbols.logout,
        ),
      );

      expect(find.byIcon(Symbols.logout), findsOneWidget);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpRiverpod(
        tester,
        const AppDestructiveButton(label: 'Eliminar', onPressed: null),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.enabled, isFalse);
    });

    testWidgets('expanded variant stretches to parent width', (tester) async {
      await pumpRiverpod(
        tester,
        Center(
          child: SizedBox(
            width: 360,
            child: AppDestructiveButton(
              label: 'Eliminar',
              onPressed: () {},
              expanded: true,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(FilledButton));
      expect(size.width, 360);
    });
  });
}
