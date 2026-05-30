import 'package:custodiam/features/inventario/domain/entities/asignacion_actual.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_asignacion.dart';
import 'package:custodiam/features/inventario/presentation/widgets/asignacion_actual_section.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_utils/test_app.dart';

AsignacionActual _asignacion({
  required TipoAsignacion tipo,
  int cantidad = 1,
  String? servicioTitulo,
}) {
  return AsignacionActual(
    tipo: tipo,
    cantidad: cantidad,
    servicioTitulo: servicioTitulo,
    fechaAsignacion: DateTime(2026, 5, 27),
  );
}

void main() {
  group('AsignacionActualSection', () {
    testWidgets('renders nothing when there are no active assignments',
        (tester) async {
      await pumpRiverpod(
        tester,
        const AsignacionActualSection(asignaciones: []),
      );

      expect(find.text('Asignación actual'), findsNothing);
    });

    testWidgets('shows a header and one row per assignment', (tester) async {
      await pumpRiverpod(
        tester,
        AsignacionActualSection(
          asignaciones: [
            _asignacion(tipo: TipoAsignacion.personal),
            _asignacion(tipo: TipoAsignacion.dotacionVehiculo, cantidad: 4),
          ],
        ),
      );

      expect(find.text('Asignación actual'), findsOneWidget);
      expect(find.text('Equipamiento personal'), findsOneWidget);
      expect(find.text('Dotación de vehículo'), findsOneWidget);
    });

    testWidgets('uses servicio_titulo as the label for servicio assignments',
        (tester) async {
      await pumpRiverpod(
        tester,
        AsignacionActualSection(
          asignaciones: [
            _asignacion(
              tipo: TipoAsignacion.servicio,
              servicioTitulo: 'Romería 2026',
            ),
          ],
        ),
      );

      expect(find.text('Romería 2026'), findsOneWidget);
    });

    testWidgets('falls back to a generic label when servicio_titulo is null',
        (tester) async {
      await pumpRiverpod(
        tester,
        AsignacionActualSection(
          asignaciones: [_asignacion(tipo: TipoAsignacion.servicio)],
        ),
      );

      expect(find.text('Asignado a un servicio'), findsOneWidget);
    });

    testWidgets('pluralises the unit count in the detail line', (tester) async {
      await pumpRiverpod(
        tester,
        AsignacionActualSection(
          asignaciones: [
            _asignacion(tipo: TipoAsignacion.prestamo, cantidad: 3),
          ],
        ),
      );

      expect(find.textContaining('3 unidades · desde 27/05/2026'),
          findsOneWidget);
    });

    testWidgets('uses the singular unit when cantidad is 1', (tester) async {
      await pumpRiverpod(
        tester,
        AsignacionActualSection(
          asignaciones: [_asignacion(tipo: TipoAsignacion.prestamo)],
        ),
      );

      expect(find.textContaining('1 unidad · desde 27/05/2026'),
          findsOneWidget);
    });
  });
}
