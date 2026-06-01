import 'package:custodiam/features/inventario/presentation/widgets/voluntario_selector_field.dart';
import 'package:custodiam/infrastructure/catalogo/catalogo_recurso.dart';
import 'package:custodiam/infrastructure/catalogo/voluntarios_catalogo_service.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockVoluntariosService extends Mock
    implements VoluntariosCatalogoService {}

/// Host con estado que simula al diálogo padre: refleja la selección en el
/// `value` para que el campo muestre la etiqueta elegida.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  CatalogoRecurso? _value;

  @override
  Widget build(BuildContext context) {
    return VoluntarioSelectorField(
      fieldKey: const ValueKey('sel'),
      value: _value,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}

void main() {
  late _MockVoluntariosService service;

  setUp(() {
    service = _MockVoluntariosService();
    when(() => service.buscarVoluntarios(any(), any())).thenAnswer(
      (_) async => const [
        CatalogoRecurso(id: 'v-1', label: 'Ana García · 600111222'),
        CatalogoRecurso(id: 'v-2', label: 'Beatriz López · 699888777'),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) async {
    await pumpRiverpod(
      tester,
      const _Host(),
      overrides: [
        voluntariosCatalogoServiceProvider.overrideWithValue(service),
      ],
      settle: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('al pulsar el campo abre el picker con el catálogo de voluntarios',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('sel')));
    await tester.pumpAndSettle();

    expect(find.text('Ana García · 600111222'), findsOneWidget);
    expect(find.text('Beatriz López · 699888777'), findsOneWidget);
  });

  testWidgets('seleccionar un voluntario lo refleja en el campo',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('sel')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana García · 600111222'));
    await tester.pumpAndSettle();

    // El picker se cerró y el campo muestra el voluntario elegido.
    expect(find.text('Ana García · 600111222'), findsOneWidget);
  });
}
