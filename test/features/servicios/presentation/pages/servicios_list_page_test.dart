import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_summary.dart';
import 'package:custodiam/features/servicios/domain/entities/servicios_page.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/list_servicios.dart';
import 'package:custodiam/features/servicios/presentation/pages/servicios_list_page.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

class _MockAuth extends Mock implements AuthService {}

ServicioSummary _s(String id, String titulo,
    {EstadoServicio estado = EstadoServicio.publicado,
    TipoServicio tipo = TipoServicio.preventivo}) {
  return ServicioSummary(
    id: id,
    titulo: titulo,
    tipo: tipo,
    estado: estado,
    fechaInicio: DateTime.utc(2026, 6, 10, 8),
    ubicacion: 'Zuera',
    inscritosCount: 0,
  );
}

_MockAuth _authWith(List<String> roles) {
  final auth = _MockAuth();
  when(() => auth.currentUser).thenReturn(
    CurrentUser(sub: 's', email: 'e@e', roles: roles),
  );
  when(() => auth.authStateListenable).thenReturn(ValueNotifier(true));
  return auth;
}

void main() {
  setUpAll(() {
    registerFallbackValue(EstadoServicio.publicado);
    registerFallbackValue(TipoServicio.preventivo);
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    List<String> roles = const ['jefe_equipo'],
  }) async {
    await pumpRiverpod(
      tester,
      const ServiciosListPage(),
      wrapInScaffold: false,
      settle: false,
      overrides: [
        listServiciosProvider.overrideWithValue(ListServicios(repo)),
        authServiceProvider.overrideWithValue(_authWith(roles)),
      ],
    );
  }

  testWidgets('shows the forbidden screen when the user has no permission',
      (tester) async {
    when(() => repo.list(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).thenAnswer((_) async => const Success(ServiciosPage(
          items: [],
          total: 0,
        )));

    await pumpPage(tester, roles: const []);
    await tester.pumpAndSettle();

    expect(find.text('Sin acceso'), findsOneWidget);
    verifyNever(() => repo.list(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        ));
  });

  testWidgets('renders each servicio with title and location',
      (tester) async {
    when(() => repo.list(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).thenAnswer((_) async => Success(ServiciosPage(
          items: [
            _s('a', 'Preventivo Feria'),
            _s('b', 'Emergencia Inundación', tipo: TipoServicio.emergencia),
          ],
          total: 2,
        )));

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Preventivo Feria'), findsOneWidget);
    expect(find.text('Emergencia Inundación'), findsOneWidget);
    expect(find.textContaining('Zuera'), findsWidgets);
    expect(find.text('Publicado'), findsWidgets);
  });

  testWidgets('shows the empty state when the listing has no items',
      (tester) async {
    when(() => repo.list(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).thenAnswer((_) async => const Success(ServiciosPage(
          items: [],
          total: 0,
        )));

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Sin servicios'), findsOneWidget);
  });

  testWidgets('shows the error state and lets the user retry',
      (tester) async {
    var first = true;
    when(() => repo.list(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).thenAnswer((_) async {
      if (first) {
        first = false;
        return const Fail(NetworkFailure.serverError(503));
      }
      return Success(ServiciosPage(items: [_s('a', 'Preventivo Feria')], total: 1));
    });

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar los servicios'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Preventivo Feria'), findsOneWidget);
  });
}
