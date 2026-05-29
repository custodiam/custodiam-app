import 'package:custodiam/core/ui/buttons/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppPrimaryButton', () {
    testWidgets('renders label and triggers onPressed', (tester) async {
      var pressed = 0;
      await pumpRiverpod(
        tester,
        AppPrimaryButton(
          label: 'Guardar',
          onPressed: () => pressed++,
        ),
      );

      expect(find.text('Guardar'), findsOneWidget);
      await tester.tap(find.byType(AppPrimaryButton));
      expect(pressed, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpRiverpod(
        tester,
        const AppPrimaryButton(label: 'Guardar', onPressed: null),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.enabled, isFalse);
    });

    testWidgets('shows spinner and ignores taps when isLoading', (tester) async {
      var pressed = 0;
      await pumpRiverpod(
        tester,
        AppPrimaryButton(
          label: 'Guardar',
          onPressed: () => pressed++,
          isLoading: true,
        ),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final filled = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filled.enabled, isFalse);
      expect(pressed, 0);
    });

    testWidgets('renders provided leading icon', (tester) async {
      await pumpRiverpod(
        tester,
        AppPrimaryButton(
          label: 'Guardar',
          onPressed: () {},
          icon: Symbols.save,
        ),
      );

      expect(find.byIcon(Symbols.save), findsOneWidget);
    });

    testWidgets('expanded variant stretches to parent width', (tester) async {
      await pumpRiverpod(
        tester,
        Center(
          child: SizedBox(
            width: 400,
            child: AppPrimaryButton(
              label: 'Guardar',
              onPressed: () {},
              expanded: true,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(FilledButton));
      expect(size.width, 400);
    });
  });
}
