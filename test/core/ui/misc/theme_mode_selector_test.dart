import 'package:custodiam/core/ui/misc/theme_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('ThemeModeSelector', () {
    testWidgets('renders all three modes', (tester) async {
      await pumpRiverpod(
        tester,
        ThemeModeSelector(
          selected: ThemeMode.system,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Sistema (automático)'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.byType(RadioListTile<ThemeMode>), findsNWidgets(3));
    });

    testWidgets('invokes onChanged with selected ThemeMode', (tester) async {
      ThemeMode? captured;

      await pumpRiverpod(
        tester,
        ThemeModeSelector(
          selected: ThemeMode.system,
          onChanged: (mode) => captured = mode,
        ),
      );

      await tester.tap(find.text('Oscuro'));
      expect(captured, ThemeMode.dark);

      await tester.tap(find.text('Claro'));
      expect(captured, ThemeMode.light);
    });

    testWidgets('reflects currently selected mode', (tester) async {
      await pumpRiverpod(
        tester,
        ThemeModeSelector(
          selected: ThemeMode.dark,
          onChanged: (_) {},
        ),
      );

      final tiles = tester
          .widgetList<RadioListTile<ThemeMode>>(
            find.byType(RadioListTile<ThemeMode>),
          )
          .toList();
      expect(tiles.every((t) => t.groupValue == ThemeMode.dark), isTrue);
    });
  });
}
