import 'package:custodiam/core/ui/buttons/app_secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppSecondaryButton', () {
    testWidgets('renders label and triggers onPressed', (tester) async {
      var pressed = 0;
      await pumpRiverpod(
        tester,
        AppSecondaryButton(
          label: 'Cancelar',
          onPressed: () => pressed++,
        ),
      );

      expect(find.text('Cancelar'), findsOneWidget);
      await tester.tap(find.byType(AppSecondaryButton));
      expect(pressed, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpRiverpod(
        tester,
        const AppSecondaryButton(label: 'Cancelar', onPressed: null),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(button.enabled, isFalse);
    });

    testWidgets('renders leading icon when provided', (tester) async {
      await pumpRiverpod(
        tester,
        AppSecondaryButton(
          label: 'Cancelar',
          onPressed: () {},
          icon: Symbols.close,
        ),
      );

      expect(find.byIcon(Symbols.close), findsOneWidget);
    });

    testWidgets('expanded variant stretches to parent width', (tester) async {
      await pumpRiverpod(
        tester,
        Center(
          child: SizedBox(
            width: 320,
            child: AppSecondaryButton(
              label: 'Cancelar',
              onPressed: () {},
              expanded: true,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(OutlinedButton));
      expect(size.width, 320);
    });
  });
}
