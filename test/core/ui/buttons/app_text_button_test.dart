import 'package:custodiam/core/ui/buttons/app_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppTextButton', () {
    testWidgets('renders label and triggers onPressed', (tester) async {
      var pressed = 0;
      await pumpRiverpod(
        tester,
        AppTextButton(
          label: '¿Has olvidado la contraseña?',
          onPressed: () => pressed++,
        ),
      );

      expect(find.text('¿Has olvidado la contraseña?'), findsOneWidget);
      await tester.tap(find.byType(AppTextButton));
      expect(pressed, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpRiverpod(
        tester,
        const AppTextButton(label: 'Acción', onPressed: null),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.enabled, isFalse);
    });

    testWidgets('renders leading icon when provided', (tester) async {
      await pumpRiverpod(
        tester,
        AppTextButton(
          label: 'Ver más',
          onPressed: () {},
          icon: Icons.expand_more,
        ),
      );

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });
  });
}
