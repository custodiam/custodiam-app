// Page test del formulario de alta de ubicación (E10). Cubre:
//  - gate RBAC (voluntario -> 'Sin acceso', no toca el repo),
//  - nombre vacío + submit: validación 'El nombre es obligatorio', no crea,
//  - nombre relleno + submit: llama crearUbicacionProvider con ese nombre
//    y navega a /inventario,
//  - 409 -> snackbar 'Ya existe una ubicación con ese nombre.' sin navegar.
//
// La page navega con context.go('/inventario') en éxito (no hay nada que
// pop al no venir de un push), así que se monta un GoRouter real con
// MaterialApp.router y una ruta stub de /inventario (mismo patrón que
// alta_material_page_test). NO se pulsa "Fijar en el mapa": abre el
// AppLocationPicker real, no mockeable a este nivel.
//
// El refresh de la lista en éxito recorre ubicacionesListViewModelProvider,
// que pega contra listarUbicacionesProvider; se overridea con el repo mock
// para que ese refresh no toque la red.

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/inventario/domain/entities/ubicacion.dart';
import 'package:custodiam/features/inventario/domain/entities/ubicaciones_page.dart';
import 'package:custodiam/features/inventario/domain/repositories/ubicaciones_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/crear_ubicacion.dart';
import 'package:custodiam/features/inventario/domain/usecases/listar_ubicaciones.dart';
import 'package:custodiam/features/inventario/presentation/pages/ubicacion_form_page.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/ubicaciones_di.dart';
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

class _MockRepo extends Mock implements UbicacionesRepository {}

class _MockAuth extends Mock implements AuthService {}

_MockAuth _authWith(List<String> roles) {
  final auth = _MockAuth();
  when(() => auth.currentUser)
      .thenReturn(CurrentUser(sub: 's', email: 'e@e', roles: roles));
  when(() => auth.authStateListenable).thenReturn(ValueNotifier(true));
  return auth;
}

Ubicacion _u() => const Ubicacion(id: 'u-1', nombre: 'Base Zuera');

Future<void> pumpPage(
  WidgetTester tester,
  UbicacionesRepository repo, {
  List<String> roles = const ['jefe_seccion'],
}) async {
  final router = GoRouter(
    initialLocation: '/inventario/ubicaciones/alta',
    routes: [
      GoRoute(
        path: '/inventario',
        builder: (_, _) => const Scaffold(body: Text('inventario-stub')),
      ),
      GoRoute(
        path: '/inventario/ubicaciones/alta',
        builder: (_, _) => const UbicacionFormPage(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        crearUbicacionProvider.overrideWithValue(CrearUbicacion(repo)),
        listarUbicacionesProvider.overrideWithValue(ListarUbicaciones(repo)),
        authServiceProvider.overrideWithValue(_authWith(roles)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    // El refresh de la lista tras un alta con éxito recorre listar; lo
    // dejamos en una página vacía para no tocar la red real.
    when(() => repo.listar(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
        )).thenAnswer(
      (_) async => const Success(UbicacionesPage(items: [], total: 0)),
    );
  });

  testWidgets('gate RBAC: un voluntario ve "Sin acceso" y no se crea nada',
      (tester) async {
    await pumpPage(tester, repo, roles: const ['voluntario']);

    expect(find.text('Sin acceso'), findsOneWidget);
    expect(find.byKey(K.ubicacionFormSubmit), findsNothing);
    verifyNever(() => repo.crear(
          nombre: any(named: 'nombre'),
          descripcion: any(named: 'descripcion'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ));
  });

  testWidgets('nombre vacío + submit: muestra validación y no llama crear',
      (tester) async {
    await pumpPage(tester, repo);

    // No se rellena el nombre.
    await tester.tap(find.byKey(K.ubicacionFormSubmit));
    await tester.pump();

    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    verifyNever(() => repo.crear(
          nombre: any(named: 'nombre'),
          descripcion: any(named: 'descripcion'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ));
  });

  testWidgets('nombre relleno + submit: llama crear con ese nombre y navega',
      (tester) async {
    when(() => repo.crear(
          nombre: any(named: 'nombre'),
          descripcion: any(named: 'descripcion'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        )).thenAnswer((_) async => Success(_u()));

    await pumpPage(tester, repo);

    await tester.enterText(find.byKey(K.ubicacionFormNombre), 'Base Zuera');
    await tester.tap(find.byKey(K.ubicacionFormSubmit));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.crear(
          nombre: captureAny(named: 'nombre'),
          descripcion: any(named: 'descripcion'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        )).captured;
    expect(captured.single, 'Base Zuera');
    // Sin coordenadas fijadas, lat/lng van null.
    expect(find.text('inventario-stub'), findsOneWidget);
  });

  testWidgets('409: snackbar de nombre duplicado, sin navegar', (tester) async {
    when(() => repo.crear(
          nombre: any(named: 'nombre'),
          descripcion: any(named: 'descripcion'),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        )).thenAnswer(
      (_) async => const Fail(UbicacionesFailure.nombreDuplicado()),
    );

    await pumpPage(tester, repo);

    await tester.enterText(find.byKey(K.ubicacionFormNombre), 'Base Zuera');
    await tester.tap(find.byKey(K.ubicacionFormSubmit));
    // pumpAndSettle (no un único pump): si la rama de error navegara por error,
    // GoRouter montaría la ruta destino y la aserción de "no navega" lo
    // detectaría. Con un solo pump la ruta no se monta y el guard sería falso.
    await tester.pumpAndSettle();

    expect(
      find.text('Ya existe una ubicación con ese nombre.'),
      findsOneWidget,
    );
    // No navega en error: la page sigue montada.
    expect(find.text('inventario-stub'), findsNothing);
    expect(find.byKey(K.ubicacionFormSubmit), findsOneWidget);
  });
}
