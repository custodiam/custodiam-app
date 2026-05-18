import 'package:custodiam/core/ui/buttons/app_destructive_button.dart';
import 'package:custodiam/core/ui/buttons/app_primary_button.dart';
import 'package:custodiam/core/ui/feedback/app_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppConfirmDialog', () {
    testWidgets('show returns true when confirm tapped', (tester) async {
      late BuildContext capturedContext;

      await pumpRiverpod(
        tester,
        Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        }),
      );

      final future = AppConfirmDialog.show(
        capturedContext,
        title: 'Eliminar',
        message: '¿Seguro?',
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppPrimaryButton), findsOneWidget);

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(await future, isTrue);
    });

    testWidgets('show returns false when cancel tapped', (tester) async {
      late BuildContext capturedContext;

      await pumpRiverpod(
        tester,
        Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        }),
      );

      final future = AppConfirmDialog.show(
        capturedContext,
        title: 'Eliminar',
        message: '¿Seguro?',
        cancelLabel: 'No',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(await future, isFalse);
    });

    testWidgets('show returns false when dismissed via barrier',
        (tester) async {
      late BuildContext capturedContext;

      await pumpRiverpod(
        tester,
        Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        }),
      );

      final future = AppConfirmDialog.show(
        capturedContext,
        title: 'Eliminar',
        message: '¿Seguro?',
      );
      await tester.pumpAndSettle();

      Navigator.of(capturedContext).pop();
      await tester.pumpAndSettle();

      expect(await future, isFalse);
    });

    testWidgets('isDestructive swaps confirm for AppDestructiveButton',
        (tester) async {
      late BuildContext capturedContext;

      await pumpRiverpod(
        tester,
        Builder(builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        }),
      );

      AppConfirmDialog.show(
        capturedContext,
        title: 'Eliminar voluntario',
        message: 'No se puede deshacer',
        confirmLabel: 'Eliminar',
        isDestructive: true,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppDestructiveButton), findsOneWidget);
      expect(find.byType(AppPrimaryButton), findsNothing);
    });
  });
}
