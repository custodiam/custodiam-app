import 'package:custodiam/core/ui/misc/app_status_badge.dart';
import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/presentation/widgets/inventario_estado_badge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_utils/test_app.dart';

void main() {
  group('InventarioEstadoBadge', () {
    for (final (estado, variant, label) in const <(
      EstadoInventario,
      AppStatusVariant,
      String
    )>[
      (EstadoInventario.operativo, AppStatusVariant.success, 'Operativo'),
      (EstadoInventario.enUso, AppStatusVariant.info, 'En uso'),
      (EstadoInventario.averiado, AppStatusVariant.danger, 'Averiado'),
      (EstadoInventario.perdido, AppStatusVariant.neutral, 'Perdido'),
    ]) {
      testWidgets('$estado maps to $variant with label "$label"',
          (tester) async {
        await pumpRiverpod(tester, InventarioEstadoBadge(estado: estado));

        final badge =
            tester.widget<AppStatusBadge>(find.byType(AppStatusBadge));
        expect(badge.variant, variant);
        expect(badge.label, label);
        expect(find.text(label), findsOneWidget);
      });
    }
  });
}
