import 'package:custodiam/core/ui/inputs/app_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppPasswordField', () {
    testWidgets('renders default "Contraseña" label and lock icon',
        (tester) async {
      await pumpRiverpod(tester, const AppPasswordField());

      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('starts obscured and toggles visibility on tap',
        (tester) async {
      await pumpRiverpod(tester, const AppPasswordField());

      TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('writes through controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpRiverpod(
        tester,
        AppPasswordField(controller: controller),
      );

      await tester.enterText(find.byType(TextFormField), 'Volunt1234');
      expect(controller.text, 'Volunt1234');
    });

    testWidgets('accepts custom label', (tester) async {
      await pumpRiverpod(
        tester,
        const AppPasswordField(label: 'Nueva contraseña'),
      );

      expect(find.text('Nueva contraseña'), findsOneWidget);
    });
  });
}
