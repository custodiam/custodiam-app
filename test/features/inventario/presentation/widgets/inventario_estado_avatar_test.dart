// Widget tests de InventarioEstadoAvatar: el avatar de los listados que
// sustituye al badge de texto. Verifica los dos comportamientos según estado:
//   - operativo / en uso → avatar base, sin insignia de estado.
//   - averiado / perdido → insignia con el icono del estado (segundo canal no
//     cromático, WCAG 1.4.1).
// Y que el estado se anuncia SIEMPRE por Semantics (lo que antes leía el badge
// de texto retirado de la fila).

import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/presentation/widgets/inventario_estado_avatar.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_utils/test_app.dart';

void main() {
  Future<void> pumpAvatar(WidgetTester tester, EstadoInventario estado) {
    return pumpRiverpod(
      tester,
      InventarioEstadoAvatar(tipoIcon: Symbols.inventory_2, estado: estado),
    );
  }

  testWidgets('operativo: avatar base, sin insignia de estado', (tester) async {
    await pumpAvatar(tester, EstadoInventario.operativo);

    expect(find.byIcon(Symbols.inventory_2), findsOneWidget);
    expect(find.byIcon(Symbols.build), findsNothing);
    expect(find.byIcon(Symbols.report), findsNothing);
    expect(find.bySemanticsLabel('Estado: Operativo'), findsOneWidget);
  });

  testWidgets('en uso: avatar base, sin insignia de estado', (tester) async {
    await pumpAvatar(tester, EstadoInventario.enUso);

    expect(find.byIcon(Symbols.inventory_2), findsOneWidget);
    expect(find.byIcon(Symbols.build), findsNothing);
    expect(find.byIcon(Symbols.report), findsNothing);
    expect(find.bySemanticsLabel('Estado: En uso'), findsOneWidget);
  });

  testWidgets('averiado: insignia con icono build + estado en Semantics',
      (tester) async {
    await pumpAvatar(tester, EstadoInventario.averiado);

    // El icono del tipo permanece en el centro; la insignia añade el de estado.
    expect(find.byIcon(Symbols.inventory_2), findsOneWidget);
    expect(find.byIcon(Symbols.build), findsOneWidget);
    expect(find.bySemanticsLabel('Estado: Averiado'), findsOneWidget);
  });

  testWidgets('perdido: insignia con icono report + estado en Semantics',
      (tester) async {
    await pumpAvatar(tester, EstadoInventario.perdido);

    expect(find.byIcon(Symbols.inventory_2), findsOneWidget);
    expect(find.byIcon(Symbols.report), findsOneWidget);
    expect(find.bySemanticsLabel('Estado: Perdido'), findsOneWidget);
  });
}
