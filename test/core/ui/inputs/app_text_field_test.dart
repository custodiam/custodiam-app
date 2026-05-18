import 'package:custodiam/core/ui/inputs/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppTextField', () {
    testWidgets('renders label and writes through controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpRiverpod(
        tester,
        AppTextField(label: 'Nombre', controller: controller),
      );

      expect(find.text('Nombre'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'María');
      expect(controller.text, 'María');
    });

    testWidgets('shows validation error after submit', (tester) async {
      final formKey = GlobalKey<FormState>();

      await pumpRiverpod(
        tester,
        Form(
          key: formKey,
          child: AppTextField(
            label: 'Email',
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Campo requerido' : null,
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Campo requerido'), findsOneWidget);
    });

    testWidgets('renders prefix icon when provided', (tester) async {
      await pumpRiverpod(
        tester,
        const AppTextField(label: 'Email', prefixIcon: Icons.mail_outline),
      );

      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    });

    testWidgets('obscureText forces single line and hides characters',
        (tester) async {
      final controller = TextEditingController(text: 'secret');
      addTearDown(controller.dispose);

      await pumpRiverpod(
        tester,
        AppTextField(
          label: 'Pin',
          controller: controller,
          obscureText: true,
          maxLines: 5,
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.maxLines, 1);
    });

    testWidgets('respects enabled = false', (tester) async {
      await pumpRiverpod(
        tester,
        const AppTextField(label: 'Bloqueado', enabled: false),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
    });
  });
}
