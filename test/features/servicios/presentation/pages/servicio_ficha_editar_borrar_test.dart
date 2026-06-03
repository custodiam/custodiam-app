// Widget tests de las acciones Editar (A5) y Borrar (A7) en la ficha de
// servicio (ServicioFichaPage).
//
// Cubren:
//  - Editar: botón visible para un rol con servicios.crear_preventivo
//    (jefe_equipo) y oculto para un voluntario; al pulsar navega a la ruta
//    /servicios/{id}/editar.
//  - Borrar: botón visible para jefe_equipo; confirmar el AppConfirmDialog
//    llama a repo.delete y navega a /servicios; un 409 (servicio con
//    actividad) muestra el mensaje del backend y NO navega.
//
// Se mockea ServiciosRepository (mocktail) y se overridean los use-case
// providers de la cadena. Para los casos que navegan se monta MaterialApp.router
// con un GoRouter de rutas stub; para los de visibilidad basta pumpRiverpod.

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_inventario.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_summary.dart';
import 'package:custodiam/features/servicios/domain/entities/servicios_page.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/eliminar_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_inventario_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_servicio_by_id.dart';
import 'package:custodiam/features/servicios/domain/usecases/list_servicios.dart';
import 'package:custodiam/features/servicios/domain/usecases/list_voluntarios_servicio.dart';
import 'package:custodiam/features/servicios/presentation/pages/servicio_ficha_page.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

// jefe_equipo tiene servicios.crear_preventivo (mismo permiso que el PATCH y el
// DELETE del backend). voluntario NO.
const _jefeEquipo = CurrentUser(sub: 's', email: 'jefe@e', roles: ['jefe_equipo']);
const _voluntario = CurrentUser(sub: 's', email: 'vol@e', roles: ['voluntario']);

const _servicioId = 'id-1';

Servicio _servicio({EstadoServicio estado = EstadoServicio.borrador}) {
  return Servicio(
    id: _servicioId,
    titulo: 'Preventivo',
    tipo: TipoServicio.preventivo,
    estado: estado,
    fechaInicio: DateTime.utc(2026, 6, 10, 8),
    ubicacion: 'Zuera',
    inscritosCount: 0,
  );
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(
      () => repo.list(
        skip: any(named: 'skip'),
        limit: any(named: 'limit'),
        query: any(named: 'query'),
        estado: any(named: 'estado'),
        tipo: any(named: 'tipo'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success(ServiciosPage(items: <ServicioSummary>[], total: 0)),
    );
    when(() => repo.getById(_servicioId))
        .thenAnswer((_) async => Success(_servicio()));
    when(() => repo.getInventario(_servicioId)).thenAnswer(
      (_) async => const Success(
        ServicioInventario(
          material: <MaterialAsignadoServicio>[],
          vehiculos: <VehiculoAsignadoServicio>[],
        ),
      ),
    );
    // Personal del servicio (A9): lista vacía, sin tocar la red real.
    when(() => repo.listVoluntarios(_servicioId))
        .thenAnswer((_) async => const Success([]));
  });

  List<Override> buildOverrides() => [
        getServicioByIdProvider.overrideWithValue(GetServicioById(repo)),
        getInventarioServicioProvider
            .overrideWithValue(GetInventarioServicio(repo)),
        listVoluntariosServicioProvider
            .overrideWithValue(ListVoluntariosServicio(repo)),
        eliminarServicioProvider.overrideWithValue(EliminarServicio(repo)),
        listServiciosProvider.overrideWithValue(ListServicios(repo)),
      ];

  // Mount sin router: suficiente para las pruebas de visibilidad.
  Future<void> pumpFicha(WidgetTester tester, {required CurrentUser user}) async {
    await pumpRiverpod(
      tester,
      const ServicioFichaPage(servicioId: _servicioId),
      wrapInScaffold: false,
      currentUser: user,
      overrides: buildOverrides(),
    );
  }

  // Mount con router: para los casos que navegan (editar / borrar con éxito).
  Future<void> pumpFichaConRouter(
    WidgetTester tester, {
    required CurrentUser user,
    required void Function(String location) onNavegar,
  }) async {
    // Rutas planas (hermanas) en lugar de anidadas: así montar la ficha en
    // /servicios/{id} no construye en cascada el builder de la lista, y las
    // navegaciones a /servicios y /servicios/{id}/editar quedan aisladas y
    // comprobables sin falsos positivos.
    final router = GoRouter(
      initialLocation: '/servicios/$_servicioId',
      routes: [
        GoRoute(
          path: '/servicios',
          builder: (_, _) {
            onNavegar('/servicios');
            return const Scaffold(body: Text('LISTA SERVICIOS'));
          },
        ),
        GoRoute(
          path: '/servicios/:id',
          builder: (_, state) => ServicioFichaPage(
            servicioId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/servicios/:id/editar',
          builder: (_, state) {
            onNavegar(state.uri.toString());
            return const Scaffold(body: Text('EDITAR SERVICIO'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(_FakeAuth(user)),
          ...buildOverrides(),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('A5 Editar', () {
    testWidgets('jefe_equipo ve el botón Editar', (tester) async {
      await pumpFicha(tester, user: _jefeEquipo);
      expect(find.byKey(K.servicioFichaEditarBtn), findsOneWidget);
    });

    testWidgets('voluntario NO ve el botón Editar', (tester) async {
      await pumpFicha(tester, user: _voluntario);
      expect(find.byKey(K.servicioFichaEditarBtn), findsNothing);
    });

    testWidgets('al pulsar Editar navega a /servicios/{id}/editar',
        (tester) async {
      final navegado = <String>[];
      await pumpFichaConRouter(
        tester,
        user: _jefeEquipo,
        onNavegar: navegado.add,
      );

      await tester.tap(find.byKey(K.servicioFichaEditarBtn));
      await tester.pumpAndSettle();

      expect(navegado, contains('/servicios/$_servicioId/editar'));
      expect(find.text('EDITAR SERVICIO'), findsOneWidget);
    });
  });

  group('A7 Borrar', () {
    testWidgets('jefe_equipo ve el botón Borrar', (tester) async {
      await pumpFicha(tester, user: _jefeEquipo);
      expect(find.byKey(K.servicioFichaBorrarBtn), findsOneWidget);
    });

    testWidgets('voluntario NO ve el botón Borrar', (tester) async {
      await pumpFicha(tester, user: _voluntario);
      expect(find.byKey(K.servicioFichaBorrarBtn), findsNothing);
    });

    testWidgets(
        'confirmar el diálogo llama a repo.delete y navega a /servicios',
        (tester) async {
      when(() => repo.delete(_servicioId))
          .thenAnswer((_) async => const Success<void>(null));

      final navegado = <String>[];
      await pumpFichaConRouter(
        tester,
        user: _jefeEquipo,
        onNavegar: navegado.add,
      );

      await tester.ensureVisible(find.byKey(K.servicioFichaBorrarBtn));
      await tester.tap(find.byKey(K.servicioFichaBorrarBtn));
      await tester.pumpAndSettle();

      // AppConfirmDialog destructivo: botón confirm rotula 'Borrar'.
      expect(find.text('Borrar servicio'), findsWidgets);
      await tester.tap(find.text('Borrar'));
      await tester.pumpAndSettle();

      verify(() => repo.delete(_servicioId)).called(1);
      expect(navegado, contains('/servicios'));
      expect(find.text('LISTA SERVICIOS'), findsOneWidget);
    });

    testWidgets('cancelar el diálogo no llama a repo.delete', (tester) async {
      await pumpFicha(tester, user: _jefeEquipo);

      await tester.ensureVisible(find.byKey(K.servicioFichaBorrarBtn));
      await tester.tap(find.byKey(K.servicioFichaBorrarBtn));
      await tester.pumpAndSettle();

      expect(find.text('Borrar servicio'), findsWidgets);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.delete(any()));
    });

    testWidgets(
        '409 (servicio con actividad) muestra el mensaje y NO navega',
        (tester) async {
      const mensaje = 'El servicio tiene actividad; ciérralo en lugar de borrarlo.';
      when(() => repo.delete(_servicioId)).thenAnswer(
        (_) async => const Fail(ServiciosFailure.tieneActividad(mensaje)),
      );

      final navegado = <String>[];
      await pumpFichaConRouter(
        tester,
        user: _jefeEquipo,
        onNavegar: navegado.add,
      );

      await tester.ensureVisible(find.byKey(K.servicioFichaBorrarBtn));
      await tester.tap(find.byKey(K.servicioFichaBorrarBtn));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Borrar'));
      // Borrado fallido -> snackbar. Sin pumpAndSettle (el SnackBar tiene
      // auto-dismiss y colgaría).
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => repo.delete(_servicioId)).called(1);
      // No navegó: seguimos en la ficha, sin la pantalla de lista.
      expect(navegado, isNot(contains('/servicios')));
      expect(find.text('LISTA SERVICIOS'), findsNothing);
      expect(find.text(mensaje), findsOneWidget);
    });
  });
}

/// AuthService falso para los tests con router (el de pumpRiverpod es privado).
class _FakeAuth implements AuthService {
  _FakeAuth(this._user) : _notifier = ValueNotifier(true);

  final CurrentUser _user;
  final ValueNotifier<bool> _notifier;

  @override
  Future<void> init() async {}

  @override
  bool get isAuthenticated => true;

  @override
  String? get accessToken => 'fake-token';

  @override
  CurrentUser? get currentUser => _user;

  @override
  Listenable get authStateListenable => _notifier;

  @override
  bool consumeExpiredFlag() => false;

  @override
  Future<Result<void>> login() async => const Success(null);

  @override
  Future<Result<void>> logout() async => const Success(null);

  @override
  Future<Result<String>> getValidAccessToken() async =>
      const Success('fake-token');
}
