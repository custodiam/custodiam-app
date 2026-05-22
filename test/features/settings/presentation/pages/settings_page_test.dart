// Widget tests for SettingsPage. The view model talks to the use cases
// through Riverpod providers, so we override the dataSource provider
// with a mock to bypass shared_preferences entirely.

import 'package:custodiam/features/settings/data/datasources/preferences_local_datasource.dart';
import 'package:custodiam/features/settings/presentation/pages/settings_page.dart';
import 'package:custodiam/features/settings/presentation/viewmodels/settings_di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockDataSource extends Mock implements PreferencesLocalDataSource {}

void main() {
  late _MockDataSource dataSource;

  setUp(() {
    dataSource = _MockDataSource();
    when(() => dataSource.readThemeMode()).thenAnswer((_) async => null);
    when(() => dataSource.writeThemeMode(any())).thenAnswer((_) async {});
  });

  group('SettingsPage', () {
    testWidgets('renders the theme selector with all three options',
        (tester) async {
      await pumpRiverpod(
        tester,
        const SettingsPage(),
        wrapInScaffold: false,
        overrides: [
          preferencesLocalDataSourceProvider.overrideWithValue(dataSource),
        ],
      );

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Tema de la aplicación'), findsOneWidget);
      expect(find.text('Sistema (automático)'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
    });

    testWidgets(
      'reflects the persisted theme on first render',
      (tester) async {
        when(() => dataSource.readThemeMode()).thenAnswer((_) async => 'dark');

        await pumpRiverpod(
          tester,
          const SettingsPage(),
          wrapInScaffold: false,
          overrides: [
            preferencesLocalDataSourceProvider.overrideWithValue(dataSource),
          ],
        );

        final group = tester.widget<RadioGroup<ThemeMode>>(
          find.byType(RadioGroup<ThemeMode>),
        );
        expect(group.groupValue, ThemeMode.dark);
      },
    );

    testWidgets(
      'selecting Oscuro writes "dark" through the data source',
      (tester) async {
        await pumpRiverpod(
          tester,
          const SettingsPage(),
          wrapInScaffold: false,
          overrides: [
            preferencesLocalDataSourceProvider.overrideWithValue(dataSource),
          ],
        );

        await tester.tap(find.text('Oscuro'));
        await tester.pumpAndSettle();

        verify(() => dataSource.writeThemeMode('dark')).called(1);
      },
    );

    testWidgets(
      'shows a danger snackbar when the persistence fails',
      (tester) async {
        when(() => dataSource.writeThemeMode(any()))
            .thenThrow(Exception('disk full'));

        await pumpRiverpod(
          tester,
          const SettingsPage(),
          wrapInScaffold: false,
          overrides: [
            preferencesLocalDataSourceProvider.overrideWithValue(dataSource),
          ],
        );

        await tester.tap(find.text('Claro'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining('No se pudo guardar la preferencia'),
          findsOneWidget,
        );
      },
    );
  });
}
