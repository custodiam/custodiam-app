// Page test del formulario de alta de servicio (US-03-01 / US-03-02).
//
// Cubre:
//  - gate RBAC (forbidden) y el matiz `secretario` (entra pero no ve el
//    chip de emergencia, hallazgo RBAC A4),
//  - validacion del Form (titulo/ubicacion/fecha) sin tocar el backend,
//  - camino feliz: submit -> snackbar success + refresh de la lista
//    (acoplamiento alta->listado) + navegacion context.go a la ficha,
//  - Fail del backend (snackbar danger, sin navegacion),
//  - doble submit / boton deshabilitado durante isLoading,
//  - invariante "ambas o ninguna" de las coordenadas.
//
// mocktail (no mockito). Se mockea el REPOSITORY de dominio y se overridean
// los use cases reales (CrearServicio / ListServicios) sobre ese mock.
//
// El date picker (showDatePicker/showTimePicker) y el picker de mapa
// (showAppLocationPicker) NO son inyectables por UI; el camino feliz y los
// escenarios de submit disparan el viewmodel directo con el DTO, ejercitando
// igualmente todo el wiring ref.listen -> snackbar/refresh/navegacion.

import 'dart:async';

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/buttons/app_primary_button.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_create.dart';
import 'package:custodiam/features/servicios/domain/entities/servicios_page.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/crear_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/list_servicios.dart';
import 'package:custodiam/features/servicios/presentation/pages/alta_servicio_page.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/alta_servicio_view_model.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
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

// --- Dobles -------------------------------------------------------------
class _MockRepo extends Mock implements ServiciosRepository {}

class _MockAuth extends Mock implements AuthService {}

class _FakeServicioCreate extends Fake implements ServicioCreate {}

// --- Builders -----------------------------------------------------------
Servicio _servicio({String id = 'new-1', String titulo = 'Preventivo Feria'}) =>
    Servicio(
      id: id,
      titulo: titulo,
      tipo: TipoServicio.preventivo,
      estado: EstadoServicio.borrador,
      fechaInicio: DateTime.utc(2026, 6, 10, 8),
      ubicacion: 'Zuera',
      inscritosCount: 0,
    );

ServicioCreate _create({TipoServicio tipo = TipoServicio.preventivo}) =>
    ServicioCreate(
      titulo: 'Preventivo Feria',
      tipo: tipo,
      fechaInicio: DateTime.utc(2026, 6, 10, 8),
      ubicacion: 'Zuera',
    );

_MockAuth _authWith(List<String> roles) {
  final auth = _MockAuth();
  when(() => auth.currentUser)
      .thenReturn(CurrentUser(sub: 's', email: 'e@e', roles: roles));
  when(() => auth.authStateListenable).thenReturn(ValueNotifier(true));
  return auth;
}

// Stub de repo.list para que el refresh() del ref.listen (camino feliz) no
// truene: tras crear, la page refresca la lista de servicios. ES la prueba
// del acoplamiento alta->listado (riesgo alto de la spec).
void _stubList(_MockRepo repo) {
  when(() => repo.list(
        skip: any(named: 'skip'),
        limit: any(named: 'limit'),
        query: any(named: 'query'),
        estado: any(named: 'estado'),
        tipo: any(named: 'tipo'),
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      )).thenAnswer(
    (_) async => const Success(ServiciosPage(items: [], total: 0)),
  );
}

// --- pumpPage: GoRouter REAL (la page navega con context.go en exito) ----
Future<void> pumpPage(
  WidgetTester tester,
  ServiciosRepository repo, {
  List<String> roles = const ['jefe_equipo'],
  TipoServicio? tipoInicial,
}) async {
  final router = GoRouter(
    initialLocation: '/servicios/alta',
    routes: [
      GoRoute(
        path: '/servicios',
        builder: (_, _) => const Scaffold(body: Text('servicios-list-stub')),
      ),
      GoRoute(
        path: '/servicios/alta',
        builder: (_, _) => AltaServicioPage(tipoInicial: tipoInicial),
      ),
      GoRoute(
        path: '/servicios/:id',
        builder: (_, _) =>
            const Scaffold(body: Text('servicios-detalle-stub')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        crearServicioProvider.overrideWithValue(CrearServicio(repo)),
        listServiciosProvider.overrideWithValue(ListServicios(repo)),
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

// Obtiene el notifier del VM desde el arbol montado para disparar el flujo
// sin pelear con el date picker (no inyectable por UI).
AltaServicioViewModel _vm(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AltaServicioPage)),
  );
  return container.read(altaServicioViewModelProvider.notifier);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeServicioCreate());
  });

  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  group('gate RBAC', () {
    testWidgets('forbidden cuando el rol no puede crear servicios',
        (tester) async {
      await pumpPage(tester, repo, roles: const ['voluntario']);
      await tester.pumpAndSettle();

      expect(find.text('Sin acceso'), findsOneWidget);
      expect(find.byKey(K.altaServicioSubmitBtn), findsNothing);
      verifyNever(() => repo.create(any()));
    });

    testWidgets('secretario entra pero NO ve el chip de emergencia',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpPage(tester, repo, roles: const ['secretario']);
      await tester.pumpAndSettle();

      // El gate anyOf deja entrar (tiene serviciosCrearPreventivo)...
      expect(find.byKey(K.altaServicioSubmitBtn), findsOneWidget);
      expect(
        find.byKey(K.altaServicioTipoChip(TipoServicio.preventivo.wire)),
        findsOneWidget,
      );
      // ...pero el chip de emergencia no se ofrece (hallazgo RBAC A4).
      expect(
        find.byKey(K.altaServicioTipoChip(TipoServicio.emergencia.wire)),
        findsNothing,
      );
    });
  });

  group('validacion (no llega al backend)', () {
    testWidgets('campos vacios: muestra errores inline y no envia',
        (tester) async {
      // Superficie alta: el form completo (campos arriba + boton abajo) se
      // dispone sin scroll para poder tocar el submit y leer los errores.
      await tester.binding.setSurfaceSize(const Size(600, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpPage(tester, repo);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(K.altaServicioSubmitBtn));
      await tester.pump();

      expect(find.text('Título obligatorio'), findsOneWidget);
      expect(find.text('Ubicación obligatorio'), findsOneWidget);
      expect(find.text('Fecha obligatoria'), findsOneWidget);
      verifyNever(() => repo.create(any()));
    });

    testWidgets('titulo+ubicacion ok pero sin fecha bloquea el submit',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpPage(tester, repo);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(K.altaServicioTitulo), 'Feria');
      await tester.enterText(find.byKey(K.altaServicioUbicacion), 'Zuera');
      await tester.tap(find.byKey(K.altaServicioSubmitBtn));
      await tester.pump();

      // El validator del field marca la fecha que falta; no se envia.
      expect(find.text('Fecha obligatoria'), findsOneWidget);
      verifyNever(() => repo.create(any()));
    });

    testWidgets('numero de voluntarios negativo bloquea el submit',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpPage(tester, repo);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(K.altaServicioNumeroVoluntarios), '-3');
      await tester.tap(find.byKey(K.altaServicioSubmitBtn));
      await tester.pump();

      expect(find.text('Número no válido'), findsOneWidget);
      verifyNever(() => repo.create(any()));
    });
  });

  group('boton submit (estado de carga)', () {
    testWidgets('label es "Crear emergencia" con tipoInicial emergencia',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpPage(tester, repo,
          roles: const ['jefe_equipo'], tipoInicial: TipoServicio.emergencia);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AppPrimaryButton, 'Crear emergencia'),
        findsOneWidget,
      );
    });

    testWidgets(
        'doble submit / boton deshabilitado mientras el create esta en curso',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      _stubList(repo);
      // El create no resuelve hasta que liberamos el completer: el VM queda
      // en AsyncLoading y el boton debe quedar deshabilitado (onPressed null).
      final completer = Completer<Result<Servicio>>();
      when(() => repo.create(any())).thenAnswer((_) => completer.future);

      await pumpPage(tester, repo);
      await tester.pumpAndSettle();

      // Primer submit (sin await: queremos observar el estado in-flight).
      // ignore: unawaited_futures
      _vm(tester).submit(_create());
      await tester.pump(); // aplica AsyncLoading

      final btn = tester.widget<AppPrimaryButton>(
        find.byKey(K.altaServicioSubmitBtn),
      );
      expect(btn.isLoading, isTrue);
      expect(btn.onPressed, isNull); // deshabilitado durante loading

      completer.complete(Success(_servicio()));
      await tester.pumpAndSettle();

      // Un unico create salio adelante.
      verify(() => repo.create(any())).called(1);
    });
  });

  group('submit -> backend', () {
    testWidgets(
        'exito: snackbar success + refresh de la lista + navega al detalle',
        (tester) async {
      _stubList(repo); // refresh() del ref.listen lo necesita
      when(() => repo.create(any()))
          .thenAnswer((_) async => Success(_servicio(titulo: 'Feria')));

      await pumpPage(tester, repo);
      await tester.pumpAndSettle();

      // Atajo: dispara el VM directo (el date picker no es inyectable por UI).
      await _vm(tester).submit(_create());
      await tester.pump(); // 1 frame: inserta el SnackBar success

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('creado correctamente'), findsOneWidget);

      await tester.pumpAndSettle(); // completa la navegacion context.go

      expect(find.text('servicios-detalle-stub'), findsOneWidget);
      verify(() => repo.create(any())).called(1);
      // El acoplamiento alta->listado disparó el refresh sobre repo.list (el
      // provider del listado se construye y refresh() lo recarga, así que
      // lista más de una vez: basta verificar que ocurrió).
      verify(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
            desde: any(named: 'desde'),
            hasta: any(named: 'hasta'),
          ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('captura el DTO correcto en el create', (tester) async {
      _stubList(repo);
      when(() => repo.create(any()))
          .thenAnswer((_) async => Success(_servicio()));

      await pumpPage(tester, repo);
      await tester.pumpAndSettle();

      await _vm(tester).submit(_create());
      await tester.pumpAndSettle();

      final captured = verify(() => repo.create(captureAny()))
          .captured
          .single as ServicioCreate;
      expect(captured.titulo, 'Preventivo Feria');
      expect(captured.tipo, TipoServicio.preventivo);
      expect(captured.ubicacion, 'Zuera');
      expect(captured.fechaInicio, DateTime.utc(2026, 6, 10, 8));
    });

    testWidgets('Fail backend: snackbar danger y NO navega', (tester) async {
      when(() => repo.create(any())).thenAnswer(
        (_) async => const Fail(NetworkFailure.serverError(500)),
      );

      await pumpPage(tester, repo);
      await tester.pumpAndSettle();

      await _vm(tester).submit(_create());
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      // Permanece en la pantalla de alta (no navego al detalle).
      expect(find.text('servicios-detalle-stub'), findsNothing);
      expect(find.byType(AltaServicioPage), findsOneWidget);
      // En error no se refresca la lista.
      verifyNever(() => repo.list(
            skip: any(named: 'skip'),
            limit: any(named: 'limit'),
            query: any(named: 'query'),
            estado: any(named: 'estado'),
            tipo: any(named: 'tipo'),
            desde: any(named: 'desde'),
            hasta: any(named: 'hasta'),
          ));
    });
  });

  group('coords lat/lng (invariante "ambas o ninguna")', () {
    testWidgets('toJson incluye ambas coordenadas o ninguna', (tester) async {
      _stubList(repo);
      when(() => repo.create(any()))
          .thenAnswer((_) async => Success(_servicio()));

      await pumpPage(tester, repo);
      await tester.pumpAndSettle();

      await _vm(tester).submit(ServicioCreate(
        titulo: 'Con coords',
        tipo: TipoServicio.preventivo,
        fechaInicio: DateTime.utc(2026, 6, 10, 8),
        ubicacion: 'Zuera',
        ubicacionLat: 41.86,
        ubicacionLng: -0.79,
      ));
      await tester.pumpAndSettle();

      final captured = verify(() => repo.create(captureAny()))
          .captured
          .single as ServicioCreate;
      expect(captured.ubicacionLat, isNotNull);
      expect(captured.ubicacionLng, isNotNull);
      // toJson manda lat y lng juntas (mismo presence en el mapa).
      final json = captured.toJson();
      expect(
        json.containsKey('ubicacion_lat'),
        equals(json.containsKey('ubicacion_lng')),
      );
    });

    testWidgets('una sola coordenada se descarta en toJson (ambas o ninguna)',
        (tester) async {
      _stubList(repo);
      when(() => repo.create(any()))
          .thenAnswer((_) async => Success(_servicio()));

      await pumpPage(tester, repo);
      await tester.pumpAndSettle();

      await _vm(tester).submit(ServicioCreate(
        titulo: 'Coord a medias',
        tipo: TipoServicio.preventivo,
        fechaInicio: DateTime.utc(2026, 6, 10, 8),
        ubicacion: 'Zuera',
        ubicacionLat: 41.86,
        // ubicacionLng deliberadamente null.
      ));
      await tester.pumpAndSettle();

      final captured = verify(() => repo.create(captureAny()))
          .captured
          .single as ServicioCreate;
      final json = captured.toJson();
      expect(json.containsKey('ubicacion_lat'), isFalse);
      expect(json.containsKey('ubicacion_lng'), isFalse);
    });
  });
}
