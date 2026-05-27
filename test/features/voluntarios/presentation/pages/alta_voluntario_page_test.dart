import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario_create.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/create_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/list_voluntarios.dart';
import 'package:custodiam/features/voluntarios/presentation/pages/alta_voluntario_page.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/alta_voluntario_view_model.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements VoluntariosRepository {}

class _MockAuth extends Mock implements AuthService {}

class _FakeCreate extends Fake implements VoluntarioCreate {}

Voluntario _profile() => Voluntario(
      id: 'new-id',
      nombre: 'Carlos López',
      telefono: '600111222',
      municipio: 'Villanueva',
      fechaNacimiento: DateTime(1995, 6, 20),
      estado: EstadoVoluntario.activo,
      fechaAlta: DateTime(2026, 5, 27),
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
  List<String> roles = const ['subjefe_agrupacion'],
}) async {
  final router = GoRouter(
    initialLocation: '/voluntarios/alta',
    routes: [
      GoRoute(
        path: '/voluntarios',
        builder: (_, _) => const Scaffold(body: Text('voluntarios-list-stub')),
      ),
      GoRoute(
        path: '/voluntarios/alta',
        builder: (_, _) => const AltaVoluntarioPage(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        createVoluntarioProvider.overrideWithValue(CreateVoluntario(repo)),
        listVoluntariosProvider.overrideWithValue(ListVoluntarios(repo)),
        authServiceProvider.overrideWithValue(_authWith(roles)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCreate());
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  testWidgets('forbidden screen when the user lacks voluntarios.crear',
      (tester) async {
    await pumpPage(tester, repo, roles: const ['voluntario']);
    await tester.pumpAndSettle();

    expect(find.text('Sin acceso'), findsOneWidget);
    verifyNever(() => repo.create(any()));
  });

  testWidgets('blocks submission and surfaces a warning when fecha is unset',
      (tester) async {
    // Tall surface so the whole form (and its validation messages) is
    // laid out without scrolling — the test asserts on a field above
    // and a button below the fold.
    await tester.binding.setSurfaceSize(const Size(600, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('alta_nombre')), 'Carlos');
    await tester.enterText(
        find.byKey(const ValueKey('alta_telefono')), '600');
    await tester.enterText(
        find.byKey(const ValueKey('alta_municipio')), 'Villanueva');

    await tester.tap(find.byKey(const ValueKey('alta_submit')));
    await tester.pump();

    expect(find.text('Fecha obligatoria'), findsOneWidget);
    verifyNever(() => repo.create(any()));
  });

  testWidgets('blocks submission on inline email validation', (tester) async {
    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('alta_email')), 'no-arroba');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('alta_submit')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('alta_submit')));
    await tester.pump();

    expect(find.text('Email no válido'), findsOneWidget);
    verifyNever(() => repo.create(any()));
  });

  testWidgets('shows a danger snackbar on DniOrEmailDuplicado',
      (tester) async {
    when(() => repo.create(any())).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.dniOrEmailDuplicado()),
    );

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    // The form will not submit without a date — skip that path by going
    // straight to the view model. The widget test still exercises the
    // listener wiring (ref.listen → AppSnackbar) via the page being
    // built and observing the provider.
    final element = tester.element(find.byType(AltaVoluntarioPage));
    final container = ProviderScope.containerOf(element);
    await container
        .read(altaVoluntarioViewModelProvider.notifier)
        .submit(VoluntarioCreate(
          nombre: 'Carlos',
          telefono: '600',
          municipio: 'Villanueva',
          fechaNacimiento: DateTime(1995, 6, 20),
        ));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining('Ya existe un voluntario con ese DNI o email'),
      findsOneWidget,
    );
  });

  testWidgets('Success path: success snackbar + navigation to /voluntarios',
      (tester) async {
    when(() => repo.create(any()))
        .thenAnswer((_) async => Success(_profile()));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(AltaVoluntarioPage));
    final container = ProviderScope.containerOf(element);
    await container
        .read(altaVoluntarioViewModelProvider.notifier)
        .submit(VoluntarioCreate(
          nombre: 'Carlos López',
          telefono: '600111222',
          municipio: 'Villanueva',
          fechaNacimiento: DateTime(1995, 6, 20),
        ));
    await tester.pumpAndSettle();

    expect(find.text('voluntarios-list-stub'), findsOneWidget);
  });
}
