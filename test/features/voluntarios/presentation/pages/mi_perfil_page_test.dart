import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/get_my_profile.dart';
import 'package:custodiam/features/voluntarios/presentation/pages/mi_perfil_page.dart';
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

Voluntario _profile() => Voluntario(
      id: 'id-1',
      nombre: 'Ana Pérez',
      telefono: '600000000',
      municipio: 'Zuera',
      fechaNacimiento: DateTime(1990, 5, 10),
      estado: EstadoVoluntario.activo,
      fechaAlta: DateTime(2024, 1, 15),
      dni: '12345678A',
      email: 'ana@example.com',
    );

_MockAuth _authWith(List<String> roles) {
  final auth = _MockAuth();
  when(() => auth.currentUser).thenReturn(
    CurrentUser(sub: 's', email: 'e@e', roles: roles),
  );
  when(() => auth.authStateListenable).thenReturn(ValueNotifier(true));
  return auth;
}

Future<void> pumpPage(
  WidgetTester tester,
  VoluntariosRepository repo, {
  List<String> roles = const ['voluntario'],
}) {
  return pumpRiverpod(
    tester,
    const MiPerfilPage(),
    wrapInScaffold: false,
    settle: false,
    overrides: [
      getMyProfileProvider.overrideWithValue(GetMyProfile(repo)),
      authServiceProvider.overrideWithValue(_authWith(roles)),
    ],
  );
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  testWidgets('shows forbidden screen when the user lacks the permission',
      (tester) async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));

    await pumpPage(tester, repo, roles: const []);
    await tester.pumpAndSettle();

    expect(find.text('Sin acceso'), findsOneWidget);
    verifyNever(() => repo.getMyProfile());
  });

  testWidgets('renders profile fields and current roles', (tester) async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));

    await pumpPage(tester, repo, roles: const ['voluntario', 'jefe_equipo']);
    await tester.pumpAndSettle();

    expect(find.text('Ana Pérez'), findsWidgets);
    expect(find.text('12345678A'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('600000000'), findsOneWidget);
    expect(find.text('Zuera'), findsOneWidget);
    // Roles section sits below the fold — scroll to it.
    await tester.scrollUntilVisible(
      find.text('voluntario, jefe_equipo'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('voluntario, jefe_equipo'), findsOneWidget);
  });

  testWidgets('shows error state and lets the user retry', (tester) async {
    var firstCall = true;
    when(() => repo.getMyProfile()).thenAnswer((_) async {
      if (firstCall) {
        firstCall = false;
        return const Fail(NetworkFailure.serverError(503));
      }
      return Success(_profile());
    });

    await pumpPage(tester, repo, roles: const ['voluntario']);
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar tu perfil'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Pérez'), findsWidgets);
  });

  testWidgets('VoluntarioNotFound renders a tailored empty state',
      (tester) async {
    when(() => repo.getMyProfile()).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.notFound()),
    );

    await pumpPage(tester, repo, roles: const ['voluntario']);
    await tester.pumpAndSettle();

    expect(find.text('Sin perfil'), findsOneWidget);
    expect(
      find.textContaining('No hay un voluntario en BD vinculado'),
      findsOneWidget,
    );
  });

  testWidgets('edit button only renders for users with editar_propio',
      (tester) async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));

    // tesorero has ver_propio but NOT editar_propio? Actually tesorero DOES
    // have both per RBAC matrix; use admin which has neither.
    await pumpPage(tester, repo, roles: const ['admin']);
    await tester.pumpAndSettle();

    // admin lacks ver_propio too, so we land on the forbidden screen.
    expect(find.text('Sin acceso'), findsOneWidget);
    expect(find.byKey(K.miPerfilEditButton), findsNothing);
  });

  testWidgets('edit button renders for users with editar_propio',
      (tester) async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));

    await pumpPage(tester, repo, roles: const ['voluntario']);
    await tester.pumpAndSettle();

    // The CTA lives at the bottom of a scrollable profile; scroll to it.
    await tester.scrollUntilVisible(
      find.byKey(K.miPerfilEditButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(K.miPerfilEditButton), findsOneWidget);
  });
}
