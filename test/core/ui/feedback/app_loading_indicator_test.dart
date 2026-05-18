import 'package:custodiam/core/ui/feedback/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppLoadingIndicator', () {
    testWidgets('renders spinner without message', (tester) async {
      await pumpRiverpod(
        tester,
        const AppLoadingIndicator(),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders message when provided', (tester) async {
      await pumpRiverpod(
        tester,
        const AppLoadingIndicator(message: 'Cargando voluntarios...'),
        settle: false,
      );

      expect(find.text('Cargando voluntarios...'), findsOneWidget);
    });

    testWidgets('fullScreen variant centres content', (tester) async {
      await pumpRiverpod(
        tester,
        const AppLoadingIndicator.fullScreen(message: 'Cargando...'),
        settle: false,
      );

      expect(
        find.descendant(
          of: find.byType(AppLoadingIndicator),
          matching: find.byType(Center),
        ),
        findsWidgets,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando...'), findsOneWidget);
    });
  });
}
