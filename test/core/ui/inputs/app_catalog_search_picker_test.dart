import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/inputs/app_catalog_search_picker.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/auth/permissions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_utils/test_app.dart';

AppCatalogSearchPicker<String> _picker({
  required Future<List<String>> Function(String, int) onLoadPage,
  ValueChanged<String>? onSelected,
  Permission? createPermission,
  String? createLabel,
  VoidCallback? onCreate,
}) {
  return AppCatalogSearchPicker<String>(
    title: 'Elegir material',
    onLoadPage: onLoadPage,
    labelOf: (s) => s,
    onSelected: onSelected ?? (_) {},
    createPermission: createPermission,
    createLabel: createLabel,
    onCreate: onCreate,
  );
}

CurrentUser _user(List<String> roles) =>
    CurrentUser(sub: '1', email: 'a@b.com', roles: roles);

void main() {
  group('AppCatalogSearchPicker', () {
    testWidgets('renders title, search field and the loaded items',
        (tester) async {
      await pumpRiverpod(
        tester,
        _picker(onLoadPage: (q, p) async => p == 0 ? ['Casco', 'Botas'] : []),
        settle: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Elegir material'), findsOneWidget);
      expect(find.byKey(K.catalogSearchField), findsOneWidget);
      expect(find.text('Casco'), findsOneWidget);
      expect(find.text('Botas'), findsOneWidget);
    });

    testWidgets('tapping an item calls onSelected with that item',
        (tester) async {
      String? selected;
      await pumpRiverpod(
        tester,
        _picker(
          onLoadPage: (q, p) async => p == 0 ? ['Casco'] : [],
          onSelected: (s) => selected = s,
        ),
        settle: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Casco'));
      await tester.pump();

      expect(selected, 'Casco');
    });

    testWidgets('shows the empty state when there are no results',
        (tester) async {
      await pumpRiverpod(
        tester,
        _picker(onLoadPage: (q, p) async => <String>[]),
        settle: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin resultados.'), findsOneWidget);
    });

    testWidgets('typing reloads the catalog with the debounced query',
        (tester) async {
      final queries = <String>[];
      await pumpRiverpod(
        tester,
        _picker(
          onLoadPage: (q, p) async {
            queries.add(q);
            return p == 0 ? ['X'] : [];
          },
        ),
        settle: false,
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(K.catalogSearchField),
        'cas',
      );
      await tester.pump(const Duration(milliseconds: 350)); // pasa el debounce
      await tester.pumpAndSettle();

      expect(queries, contains('cas'));
    });

    testWidgets('shows the create footer for a user with the permission',
        (tester) async {
      await pumpRiverpod(
        tester,
        _picker(
          onLoadPage: (q, p) async => <String>[],
          createPermission: Permission.voluntariosCrear,
          createLabel: 'Crear material',
          onCreate: () {},
        ),
        currentUser: _user(['subjefe_agrupacion']), // tiene voluntarios.crear
        settle: false,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(K.catalogCreateBtn), findsOneWidget);
    });

    testWidgets('hides the create footer for a user without the permission',
        (tester) async {
      await pumpRiverpod(
        tester,
        _picker(
          onLoadPage: (q, p) async => <String>[],
          createPermission: Permission.voluntariosCrear,
          createLabel: 'Crear material',
          onCreate: () {},
        ),
        currentUser: _user(['voluntario']), // NO tiene voluntarios.crear
        settle: false,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(K.catalogCreateBtn), findsNothing);
    });

    testWidgets('item tap targets meet the minimum size guideline',
        (tester) async {
      await pumpRiverpod(
        tester,
        _picker(onLoadPage: (q, p) async => p == 0 ? ['Casco', 'Botas'] : []),
        settle: false,
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    // Regresión del camino real show() → showModalBottomSheet, que antes no
    // tenía cobertura: el resto de tests montan el picker directamente en un
    // Scaffold (altura acotada) y por eso no detectaron el colapso de altura
    // de la hoja modal. Aquí se abre por el flujo de producción y se verifica
    // que la lista se puebla y un item es seleccionable, devolviendo su valor.
    testWidgets('show() opens the modal sheet with interactive items',
        (tester) async {
      String? selected;
      await pumpRiverpod(
        tester,
        Builder(
          builder: (context) => Center(
            child: GestureDetector(
              onTap: () async {
                selected = await AppCatalogSearchPicker.show<String>(
                  context,
                  title: 'Elegir material',
                  onLoadPage: (q, p) async => p == 0 ? ['Casco', 'Botas'] : [],
                  labelOf: (s) => s,
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
        settle: false,
      );
      await tester.pump();

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Casco'), findsOneWidget);
      expect(find.text('Botas'), findsOneWidget);

      await tester.tap(find.text('Botas'));
      await tester.pumpAndSettle();

      expect(selected, 'Botas');
    });
  });
}
