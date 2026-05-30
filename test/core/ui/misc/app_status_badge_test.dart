import 'package:custodiam/core/ui/misc/app_status_badge.dart';
import 'package:custodiam/core/ui/theme/extensions/app_semantic_colors.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

BoxDecoration _badgeDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(AppStatusBadge),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('AppStatusBadge', () {
    testWidgets('renders its label and icon', (tester) async {
      await pumpRiverpod(
        tester,
        const AppStatusBadge(
          label: 'Operativo',
          icon: Symbols.check_circle,
          variant: AppStatusVariant.success,
        ),
      );

      expect(find.text('Operativo'), findsOneWidget);
      expect(find.byIcon(Symbols.check_circle), findsOneWidget);
    });

    testWidgets('neutral variant uses the Material surface, not a semantic '
        'colour', (tester) async {
      await pumpRiverpod(
        tester,
        const AppStatusBadge(label: 'Perdido', icon: Symbols.report),
      );

      final context = tester.element(find.byType(AppStatusBadge));
      expect(
        _badgeDecoration(tester).color,
        Theme.of(context).colorScheme.surfaceContainerHighest,
      );
    });

    for (final (variant, expected) in <(AppStatusVariant, Color Function(BuildContext))>[
      (AppStatusVariant.info, (c) => c.semanticColors.info),
      (AppStatusVariant.success, (c) => c.semanticColors.success),
      (AppStatusVariant.warning, (c) => c.semanticColors.warning),
      (AppStatusVariant.danger, (c) => c.semanticColors.danger),
    ]) {
      testWidgets('$variant maps its background to the semantic colour',
          (tester) async {
        await pumpRiverpod(
          tester,
          AppStatusBadge(
            label: 'X',
            icon: Symbols.circle,
            variant: variant,
          ),
        );

        final context = tester.element(find.byType(AppStatusBadge));
        expect(_badgeDecoration(tester).color, expected(context));
      });
    }

    Widget allVariants() => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppStatusBadge(label: 'Neutro', icon: Symbols.circle),
            AppStatusBadge(
                label: 'Info',
                icon: Symbols.info,
                variant: AppStatusVariant.info),
            AppStatusBadge(
                label: 'Éxito',
                icon: Symbols.check_circle,
                variant: AppStatusVariant.success),
            AppStatusBadge(
                label: 'Aviso',
                icon: Symbols.warning_amber,
                variant: AppStatusVariant.warning),
            AppStatusBadge(
                label: 'Error',
                icon: Symbols.error,
                variant: AppStatusVariant.danger),
          ],
        );

    testWidgets('every variant meets AA text contrast (light)',
        (tester) async {
      await pumpRiverpod(tester, allVariants(), themeMode: ThemeMode.light);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('every variant meets AA text contrast (dark)', (tester) async {
      await pumpRiverpod(tester, allVariants(), themeMode: ThemeMode.dark);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('long label degrades without overflow (Flexible)',
        (tester) async {
      await pumpRiverpod(
        tester,
        const SizedBox(
          width: 120,
          child: AppStatusBadge(
            label: 'Préstamo temporal pendiente de devolución a un voluntario',
            icon: Symbols.swap_horiz,
            variant: AppStatusVariant.info,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
