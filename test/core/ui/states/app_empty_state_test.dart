import 'package:custodiam/core/ui/buttons/app_primary_button.dart';
import 'package:custodiam/core/ui/states/app_empty_state.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

void main() {
  group('AppEmptyState', () {
    testWidgets('renders title and default empty icon', (tester) async {
      await pumpRiverpod(
        tester,
        const AppEmptyState(title: 'Sin voluntarios'),
      );

      expect(find.text('Sin voluntarios'), findsOneWidget);
      expect(find.byIcon(Symbols.inbox), findsOneWidget);
    });

    testWidgets('renders description when provided', (tester) async {
      await pumpRiverpod(
        tester,
        const AppEmptyState(
          title: 'Sin voluntarios',
          description: 'Aún no hay nadie dado de alta',
        ),
      );

      expect(find.text('Aún no hay nadie dado de alta'), findsOneWidget);
    });

    testWidgets('hides CTA unless both actionLabel and onAction are set',
        (tester) async {
      await pumpRiverpod(
        tester,
        const AppEmptyState(title: 'Sin voluntarios'),
      );
      expect(find.byType(AppPrimaryButton), findsNothing);
    });

    testWidgets('shows CTA and invokes onAction on tap', (tester) async {
      var taps = 0;
      await pumpRiverpod(
        tester,
        AppEmptyState(
          title: 'Sin voluntarios',
          actionLabel: 'Crear voluntario',
          onAction: () => taps++,
        ),
      );

      expect(find.text('Crear voluntario'), findsOneWidget);
      await tester.tap(find.byType(AppPrimaryButton));
      expect(taps, 1);
    });
  });
}
