import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/catalogo/catalogo_recurso.dart';
import 'package:custodiam/infrastructure/catalogo/ubicaciones_catalogo_service.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/features/inventario/presentation/widgets/ubicacion_selector_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockUbicacionesService extends Mock
    implements UbicacionesCatalogoService {}

CurrentUser _user(List<String> roles) =>
    CurrentUser(sub: '1', email: 'a@b.com', roles: roles);

/// Host con estado que simula al formulario padre: refleja la selección en
/// el `value` para que el campo muestre la etiqueta elegida.
class _Host extends StatefulWidget {
  const _Host({this.formKey});
  final GlobalKey<FormState>? formKey;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  CatalogoRecurso? _value;

  @override
  Widget build(BuildContext context) {
    final field = UbicacionSelectorField(
      fieldKey: const ValueKey('sel'),
      value: _value,
      onChanged: (u) => setState(() => _value = u),
      validator: (v) => v == null ? 'Ubicación obligatoria' : null,
    );
    if (widget.formKey == null) return field;
    return Form(key: widget.formKey, child: field);
  }
}

void main() {
  late _MockUbicacionesService service;

  setUp(() {
    service = _MockUbicacionesService();
    when(() => service.buscarUbicaciones(any(), any())).thenAnswer(
      (_) async => const [
        CatalogoRecurso(id: 'u-1', label: 'Base Zuera'),
        CatalogoRecurso(id: 'u-2', label: 'Almacén'),
      ],
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    GlobalKey<FormState>? formKey,
    List<String> roles = const ['jefe_seccion'],
  }) async {
    await pumpRiverpod(
      tester,
      _Host(formKey: formKey),
      overrides: [
        ubicacionesCatalogoServiceProvider.overrideWithValue(service),
      ],
      currentUser: _user(roles),
      settle: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('al pulsar el campo abre el picker con el catálogo',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('sel')));
    await tester.pumpAndSettle();

    expect(find.text('Base Zuera'), findsOneWidget);
    expect(find.text('Almacén'), findsOneWidget);
  });

  testWidgets('seleccionar una ubicación la refleja en el campo',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('sel')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Base Zuera'));
    await tester.pumpAndSettle();

    // El picker se cerró y el campo muestra la etiqueta elegida.
    expect(find.text('Base Zuera'), findsOneWidget);
  });

  testWidgets('el validator marca error cuando no hay selección',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    await pump(tester, formKey: formKey);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Ubicación obligatoria'), findsOneWidget);
  });

  testWidgets('crear desde el footer da de alta la ubicación y la selecciona',
      (tester) async {
    when(() => service.crear(
          nombre: any(named: 'nombre'),
          descripcion: any(named: 'descripcion'),
        )).thenAnswer(
      (_) async => const CatalogoRecurso(id: 'u-9', label: 'Nave nueva'),
    );

    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('sel')));
    await tester.pumpAndSettle();
    // Footer "crear" (jefe_seccion tiene ubicaciones.crear).
    await tester.tap(find.byKey(const ValueKey('catalog_create')));
    await tester.pumpAndSettle();

    // Se abre el diálogo de alta rápida.
    expect(find.text('Nueva ubicación'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('crear_ubicacion_nombre')),
      'Nave nueva',
    );
    await tester.tap(find.byKey(const ValueKey('crear_ubicacion_submit')));
    await tester.pumpAndSettle();

    // El diálogo se cerró y la ubicación creada quedó seleccionada.
    expect(find.text('Nueva ubicación'), findsNothing);
    expect(find.text('Nave nueva'), findsOneWidget);
    verify(() => service.crear(
          nombre: 'Nave nueva',
          descripcion: any(named: 'descripcion'),
        )).called(1);
  });
}
