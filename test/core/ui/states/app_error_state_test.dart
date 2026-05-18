import 'package:custodiam/core/ui/buttons/app_primary_button.dart';
import 'package:custodiam/core/ui/states/app_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppErrorState', () {
    testWidgets('renders default title and error icon', (tester) async {
      await pumpRiverpod(tester, const AppErrorState());

      expect(find.text('Algo ha ido mal'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders description when provided', (tester) async {
      await pumpRiverpod(
        tester,
        const AppErrorState(description: 'Sin conexión a Internet'),
      );

      expect(find.text('Sin conexión a Internet'), findsOneWidget);
    });

    testWidgets('hides retry CTA when onRetry is null', (tester) async {
      await pumpRiverpod(tester, const AppErrorState());
      expect(find.byType(AppPrimaryButton), findsNothing);
    });

    testWidgets('shows retry CTA and invokes onRetry on tap', (tester) async {
      var retries = 0;
      await pumpRiverpod(
        tester,
        AppErrorState(onRetry: () => retries++, retryLabel: 'Reintentar'),
      );

      expect(find.byType(AppPrimaryButton), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.byType(AppPrimaryButton));
      expect(retries, 1);
    });
  });
}
