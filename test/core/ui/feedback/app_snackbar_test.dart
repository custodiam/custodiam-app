import 'package:custodiam/core/ui/feedback/app_snackbar.dart';
import 'package:custodiam/core/ui/theme/extensions/app_semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

Future<void> _showFromButton(
  WidgetTester tester, {
  required AppSnackbarVariant variant,
  required String message,
}) async {
  await pumpRiverpod(
    tester,
    Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () => AppSnackbar.show(
            context,
            message: message,
            variant: variant,
          ),
          child: const Text('mostrar'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('mostrar'));
  await tester.pump();
}

void main() {
  group('AppSnackbar', () {
    testWidgets('info variant renders message and info icon', (tester) async {
      await _showFromButton(
        tester,
        variant: AppSnackbarVariant.info,
        message: 'Cambios guardados',
      );

      expect(find.text('Cambios guardados'), findsOneWidget);
      expect(find.byIcon(Symbols.info), findsOneWidget);
    });

    testWidgets('success variant uses semantic success colour',
        (tester) async {
      await _showFromButton(
        tester,
        variant: AppSnackbarVariant.success,
        message: 'OK',
      );

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final BuildContext snackContext =
          tester.element(find.text('OK'));
      expect(
        snackBar.backgroundColor,
        snackContext.semanticColors.success,
      );
      expect(find.byIcon(Symbols.check_circle), findsOneWidget);
    });

    testWidgets('warning variant uses warning icon', (tester) async {
      await _showFromButton(
        tester,
        variant: AppSnackbarVariant.warning,
        message: '¡Cuidado!',
      );

      expect(find.byIcon(Symbols.warning_amber), findsOneWidget);
    });

    testWidgets('danger variant uses error icon', (tester) async {
      await _showFromButton(
        tester,
        variant: AppSnackbarVariant.danger,
        message: 'No se pudo guardar',
      );

      expect(find.byIcon(Symbols.error), findsOneWidget);
    });
  });
}
