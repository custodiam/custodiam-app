import 'package:custodiam/core/ui/buttons/app_primary_button.dart';
import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_inventario.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_inventario_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_servicio_by_id.dart';
import 'package:custodiam/features/servicios/presentation/pages/servicio_ficha_page.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

const _voluntario = CurrentUser(
  sub: 's',
  email: 'e@e',
  roles: ['voluntario'],
);

Servicio _servicio({
  String id = 'id-1',
  EstadoServicio estado = EstadoServicio.publicado,
  int? numeroVoluntarios,
  int inscritosCount = 0,
}) {
  return Servicio(
    id: id,
    titulo: 'Preventivo',
    tipo: TipoServicio.preventivo,
    estado: estado,
    fechaInicio: DateTime.utc(2026, 6, 10, 8),
    ubicacion: 'Zuera',
    numeroVoluntarios: numeroVoluntarios,
    inscritosCount: inscritosCount,
  );
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Future<void> pumpFicha(WidgetTester tester, Servicio servicio) async {
    when(() => repo.getById(servicio.id))
        .thenAnswer((_) async => Success(servicio));
    when(() => repo.getInventario(servicio.id)).thenAnswer(
      (_) async => const Success(
        ServicioInventario(
          material: <MaterialAsignadoServicio>[],
          vehiculos: <VehiculoAsignadoServicio>[],
        ),
      ),
    );
    await pumpRiverpod(
      tester,
      ServicioFichaPage(servicioId: servicio.id),
      wrapInScaffold: false,
      currentUser: _voluntario,
      overrides: [
        getServicioByIdProvider.overrideWithValue(GetServicioById(repo)),
        getInventarioServicioProvider
            .overrideWithValue(GetInventarioServicio(repo)),
      ],
    );
  }

  AppPrimaryButton apuntarseButton(WidgetTester tester) {
    return tester.widget<AppPrimaryButton>(
      find.byKey(const ValueKey('servicio_ficha_apuntarse_button')),
    );
  }

  testWidgets(
      'Apuntarme deshabilitado con Semantics Aforo completo cuando aforo lleno',
      (tester) async {
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: 5, inscritosCount: 5),
    );

    expect(apuntarseButton(tester).onPressed, isNull);
    expect(
      find.descendant(
        of: find.bySemanticsLabel('Aforo completo'),
        matching: find.byKey(
          const ValueKey('servicio_ficha_apuntarse_button'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Apuntarme deshabilitado con Semantics Aforo completo cuando hay overflow (6/5)',
      (tester) async {
    // El gate usa `>=` (no `==`) para cubrir overflow ante posibles race
    // conditions del backend: si el contador de inscritos rebasa el aforo,
    // el botón debe seguir bloqueado igual que en el caso exactamente lleno.
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: 5, inscritosCount: 6),
    );

    expect(apuntarseButton(tester).onPressed, isNull);
    expect(
      find.descendant(
        of: find.bySemanticsLabel('Aforo completo'),
        matching: find.byKey(
          const ValueKey('servicio_ficha_apuntarse_button'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Apuntarme habilitado con plazas', (tester) async {
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: 5, inscritosCount: 3),
    );

    expect(apuntarseButton(tester).onPressed, isNotNull);
  });

  testWidgets('Sin Semantics Aforo completo cuando quedan plazas',
      (tester) async {
    // Rama negativa del gate: con plazas libres el Semantics 'Aforo completo'
    // no debe existir en el árbol (hasta ahora solo se testeaba el caso lleno).
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: 5, inscritosCount: 3),
    );

    expect(find.bySemanticsLabel('Aforo completo'), findsNothing);
  });

  testWidgets('Apuntarme habilitado con aforo ilimitado', (tester) async {
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: null, inscritosCount: 99),
    );

    expect(apuntarseButton(tester).onPressed, isNotNull);
  });

  testWidgets('_InfoRow muestra Plazas X/Y', (tester) async {
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: 5, inscritosCount: 2),
    );

    expect(find.text('Plazas'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
  });
}
