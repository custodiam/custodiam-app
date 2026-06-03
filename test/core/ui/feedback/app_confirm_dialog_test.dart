import 'package:custodiam/core/ui/buttons/app_destructive_button.dart';
import 'package:custodiam/core/ui/buttons/app_primary_button.dart';
import 'package:custodiam/core/ui/buttons/app_text_button.dart';
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

    testWidgets('title is centered', (tester) async {
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
        title: 'Eliminar',
        message: '¿Seguro?',
      );
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text('Eliminar')).textAlign,
          TextAlign.center);
    });

    testWidgets('actions split the dialog width 50/50', (tester) async {
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
        title: 'Eliminar',
        message: '¿Seguro?',
      );
      await tester.pumpAndSettle();

      final cancelWidth = tester.getSize(find.byType(AppTextButton)).width;
      final confirmWidth = tester.getSize(find.byType(AppPrimaryButton)).width;
      // Ambos botones ocupan la misma mitad del ancho del diálogo.
      expect((cancelWidth - confirmWidth).abs(), lessThan(1.0));
      // Y son anchos de verdad, no apelmazados a la derecha.
      expect(cancelWidth, greaterThan(80));
    });
  });
}
