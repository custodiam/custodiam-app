import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_summary.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntarios_page.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/list_voluntarios.dart';
import 'package:custodiam/features/voluntarios/presentation/pages/voluntarios_list_page.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements VoluntariosRepository {}

class _MockAuth extends Mock implements AuthService {}

VoluntarioSummary _v(String id, String nombre, {EstadoVoluntario? estado}) {
  return VoluntarioSummary(
    id: id,
    nombre: nombre,
    telefono: '600 000 000',
    municipio: 'Zuera',
    estado: estado ?? EstadoVoluntario.activo,
    conductorHabilitado: false,
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
    registerFallbackValue(EstadoVoluntario.activo);
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
      const VoluntariosListPage(),
      wrapInScaffold: false,
      settle: false,
      overrides: [
        listVoluntariosProvider.overrideWithValue(ListVoluntarios(repo)),
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
        )).thenAnswer((_) async => const Success(VoluntariosPage(
          items: [],
          total: 0,
        )));

    await pumpPage(tester, roles: const []);
    await tester.pumpAndSettle();

    expect(find.text('Sin acceso'), findsOneWidget);
    // The list itself must NOT be reachable; the permission gate prevents
    // any data fetch from happening either.
    verifyNever(() => repo.list(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
        ));
  });

  testWidgets('renders each volunteer with name, phone and municipality',
      (tester) async {
    when(() => repo.list(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
        )).thenAnswer((_) async => Success(VoluntariosPage(
          items: [
            _v('a', 'Ana Pérez'),
            _v('b', 'Bea Soto', estado: EstadoVoluntario.baja),
          ],
          total: 2,
        )));

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Bea Soto'), findsOneWidget);
    expect(find.textContaining('600 000 000'), findsWidgets);
    expect(find.text('Activo'), findsOneWidget);
    expect(find.text('Baja'), findsOneWidget);
  });

  testWidgets('shows the empty state when the listing has no items',
      (tester) async {
    when(() => repo.list(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
        )).thenAnswer((_) async => const Success(VoluntariosPage(
          items: [],
          total: 0,
        )));

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Sin resultados'), findsOneWidget);
    expect(
      find.textContaining('Todavía no hay voluntarios dados de alta'),
      findsOneWidget,
    );
  });

  testWidgets('shows the error state and lets the user retry', (tester) async {
    var firstCall = true;
    when(() => repo.list(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
        )).thenAnswer((_) async {
      if (firstCall) {
        firstCall = false;
        return const Fail(NetworkFailure.serverError(503));
      }
      return Success(VoluntariosPage(
        items: [_v('a', 'Ana Pérez')],
        total: 1,
      ));
    });

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('No se pudieron cargar los voluntarios'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Pérez'), findsOneWidget);
  });

  testWidgets('search submission re-runs the listing with the typed query',
      (tester) async {
    var seenQuery = '';
    when(() => repo.list(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
        )).thenAnswer((invocation) async {
      seenQuery = invocation.namedArguments[#query] as String? ?? '';
      return Success(VoluntariosPage(
        items: seenQuery.isEmpty ? [_v('a', 'Ana')] : [_v('b', 'Bea')],
        total: 1,
      ));
    });

    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('voluntarios_search_field')),
      'bea',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(seenQuery, 'bea');
    expect(find.text('Bea'), findsOneWidget);
  });

  testWidgets(
    'tapping a row surfaces the "ficha pendiente" snackbar (US-02-09 deuda)',
    (tester) async {
      when(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
          )).thenAnswer((_) async => Success(VoluntariosPage(
            items: [_v('a', 'Ana Pérez')],
            total: 1,
          )));

      await pumpPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ana Pérez'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Ficha detallada pendiente'), findsOneWidget);
    },
  );
}
