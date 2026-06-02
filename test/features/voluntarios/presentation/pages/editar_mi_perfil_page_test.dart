import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/mi_perfil_update.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/repositories/voluntarios_repository.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/get_my_profile.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/update_my_profile.dart';
import 'package:custodiam/features/voluntarios/presentation/pages/editar_mi_perfil_page.dart';
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

class _FakePatch extends Fake implements MiPerfilUpdate {}

Voluntario _profile() => Voluntario(
      id: 'id-1',
      nombre: 'Ana Pérez',
      telefono: '600000000',
      municipio: 'Zuera',
      fechaNacimiento: DateTime(1990, 5, 10),
      estado: EstadoVoluntario.activo,
      fechaAlta: DateTime(2024, 1, 15),
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

/// Wraps the page in a real (in-memory) GoRouter so the post-submit
/// `context.go('/mi-perfil')` call has somewhere to land instead of
/// blowing up the test.
Future<void> pumpPage(
  WidgetTester tester,
  VoluntariosRepository repo, {
  List<String> roles = const ['voluntario'],
}) async {
  final router = GoRouter(
    initialLocation: '/mi-perfil/editar',
    routes: [
      GoRoute(
        path: '/mi-perfil',
        builder: (_, _) => const Scaffold(body: Text('mi-perfil-stub')),
      ),
      GoRoute(
        path: '/mi-perfil/editar',
        builder: (_, _) => const EditarMiPerfilPage(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        getMyProfileProvider.overrideWithValue(GetMyProfile(repo)),
        updateMyProfileProvider.overrideWithValue(UpdateMyProfile(repo)),
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
    registerFallbackValue(_FakePatch());
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  testWidgets('shows forbidden screen when the user lacks editar_propio',
      (tester) async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));

    await pumpPage(tester, repo, roles: const []);
    await tester.pumpAndSettle();

    expect(find.text('Sin acceso'), findsOneWidget);
    verifyNever(() => repo.updateMyProfile(any()));
  });

  testWidgets('prefills the form with the current profile values',
      (tester) async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('600000000'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('Zuera'), findsOneWidget);
  });

  testWidgets('submitting unchanged values shows an info snackbar and skips '
      'the network call', (tester) async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(K.editarMiPerfilSubmitButton));
    await tester.pump();

    expect(find.textContaining('No has cambiado nada'), findsOneWidget);
    verifyNever(() => repo.updateMyProfile(any()));
  });

  testWidgets('submitting a changed telefono calls the use case',
      (tester) async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));
    when(() => repo.updateMyProfile(any()))
        .thenAnswer((_) async => Success(_profile()));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(K.editarMiPerfilTelefonoField),
      '699999999',
    );
    await tester.tap(find.byKey(K.editarMiPerfilSubmitButton));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.updateMyProfile(captureAny())).captured;
    expect(captured.single, isA<MiPerfilUpdate>());
    expect((captured.single as MiPerfilUpdate).telefono, '699999999');
  });

  testWidgets('shows a danger snackbar with email-duplicado copy on 409',
      (tester) async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));
    when(() => repo.updateMyProfile(any())).thenAnswer(
      (_) async => const Fail(VoluntariosFailure.emailDuplicado()),
    );

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(K.editarMiPerfilEmailField),
      'taken@example.com',
    );
    await tester.tap(find.byKey(K.editarMiPerfilSubmitButton));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining('Ese email ya está registrado'),
      findsOneWidget,
    );
  });

  testWidgets('invalid email shows an inline validation error', (tester) async {
    when(() => repo.getMyProfile())
        .thenAnswer((_) async => Success(_profile()));

    await pumpPage(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(K.editarMiPerfilEmailField),
      'no-arroba',
    );
    await tester.tap(find.byKey(K.editarMiPerfilSubmitButton));
    await tester.pump();

    expect(find.text('Email no válido'), findsOneWidget);
    verifyNever(() => repo.updateMyProfile(any()));
  });
}
