import 'package:custodiam/core/ui/buttons/app_text_button.dart';
import 'package:custodiam/core/ui/feedback/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppDialog', () {
    testWidgets('renders title, content and actions', (tester) async {
      await pumpRiverpod(
        tester,
        AppDialog(
          title: 'Aviso',
          content: const Text('Hay un problema'),
          actions: [
            AppTextButton(label: 'OK', onPressed: () {}),
          ],
        ),
      );

      expect(find.text('Aviso'), findsOneWidget);
      expect(find.text('Hay un problema'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('static show returns value popped from dialog',
        (tester) async {
      late BuildContext capturedContext;

      await pumpRiverpod(
        tester,
        Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        }),
      );

      final future = AppDialog.show<String>(
        capturedContext,
        title: 'Elige',
        content: const Text('¿Qué opción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(capturedContext).pop('uno'),
            child: const Text('Uno'),
          ),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Uno'));
      await tester.pumpAndSettle();

      expect(await future, 'uno');
    });
  });
}
