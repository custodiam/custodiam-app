// Page test del formulario de alta de material (US-05-01). Cubre:
//  - gate RBAC (forbidden),
//  - validación (nombre/cantidad/ubicación) sin tocar backend,
//  - snackbar de error en Fail del backend,
//  - camino feliz (UI completo + atajo viewmodel) con navegación,
//  - regresión setState-during-build al fijar ubicación en el Form+ListView
//    real (PR #63),
//  - doble submit / botón deshabilitado durante isLoading,
//  - acoplamiento alta → listado (refresh dispara repo.listMaterial).
//
// mocktail (no mockito). Se mockea el REPOSITORY y se overridean los use
// cases. El selector de ubicación necesita ubicacionesCatalogoServiceProvider
// mockeado. La page navega con context.go en éxito, así que se monta un
// GoRouter real con MaterialApp.router (NO pumpRiverpod, que monta home:).

import 'dart:async';

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/buttons/app_primary_button.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/domain/entities/material_create.dart';
import 'package:custodiam/features/inventario/domain/entities/material_item.dart';
import 'package:custodiam/features/inventario/domain/entities/materiales_page.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_material.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/create_material.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_materiales.dart';
import 'package:custodiam/features/inventario/presentation/pages/alta_material_page.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/alta_material_view_model.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/catalogo/catalogo_recurso.dart';
import 'package:custodiam/infrastructure/catalogo/ubicaciones_catalogo_service.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

// --- Dobles -------------------------------------------------------------
class _MockRepo extends Mock implements InventarioRepository {}

class _MockAuth extends Mock implements AuthService {}

class _MockUbicaciones extends Mock implements UbicacionesCatalogoService {}

class _FakeMaterialCreate extends Fake implements MaterialCreate {}

// --- Builders de datos --------------------------------------------------
MaterialItem _material({String id = 'm-1', String nombre = 'Botiquín'}) =>
    MaterialItem(
      id: id,
      nombre: nombre,
      tipo: TipoMaterial.prestable,
      estado: EstadoInventario.operativo,
      cantidad: 1,
    );

_MockAuth _authWith(List<String> roles) {
  final auth = _MockAuth();
  when(() => auth.currentUser)
      .thenReturn(CurrentUser(sub: 's', email: 'e@e', roles: roles));
  when(() => auth.authStateListenable).thenReturn(ValueNotifier(true));
  return auth;
}

// --- pumpPage (GoRouter real: la page navega con context.go en éxito) ----
Future<void> pumpPage(
  WidgetTester tester,
  InventarioRepository repo,
  UbicacionesCatalogoService ubic, {
  List<String> roles = const ['jefe_seccion'],
}) async {
  final router = GoRouter(
    initialLocation: '/inventario/material/alta',
    routes: [
      GoRoute(
        path: '/inventario',
        builder: (_, _) => const Scaffold(body: Text('inventario-stub')),
      ),
      GoRoute(
        path: '/inventario/material/alta',
        builder: (_, _) => const AltaMaterialPage(),
      ),
      GoRoute(
        path: '/inventario/material/:id',
        builder: (_, _) => const Scaffold(body: Text('material-detalle-stub')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        createMaterialProvider.overrideWithValue(CreateMaterial(repo)),
        listMaterialesProvider.overrideWithValue(ListMateriales(repo)),
        ubicacionesCatalogoServiceProvider.overrideWithValue(ubic),
        authServiceProvider.overrideWithValue(_authWith(roles)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(); // NO settle: build() del viewmodel resuelve async.
}

Future<void> _seleccionarUbicacion(WidgetTester tester) async {
  await tester.tap(find.byKey(K.altaMaterialUbicacion));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Base Zuera').last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeMaterialCreate());
  });

  late _MockRepo repo;
  late _MockUbicaciones ubic;

  setUp(() {
    repo = _MockRepo();
    ubic = _MockUbicaciones();

    // Catálogo del picker: dos ubicaciones fijas. buscarUbicaciones es
    // posicional (query, page) y devuelve la lista directa (no Result).
    when(() => ubic.buscarUbicaciones(any(), any())).thenAnswer(
      (_) async => const [
        CatalogoRecurso(id: 'u-1', label: 'Base Zuera'),
        CatalogoRecurso(id: 'u-2', label: 'Almacén'),
      ],
    );

    // El refresh de la lista en éxito pega contra listMaterial. Sin este
    // stub, materialesListViewModelProvider.refresh() lanzaría desde el
    // mismo callback que navega: es la prueba del acoplamiento alta→listado.
    when(
      () => repo.listMaterial(
        skip: any(named: 'skip'),
        limit: any(named: 'limit'),
        query: any(named: 'query'),
        estado: any(named: 'estado'),
        tipo: any(named: 'tipo'),
        categoria: any(named: 'categoria'),
      ),
    ).thenAnswer(
      (_) async => const Success(MaterialesPage(items: [], total: 0)),
    );
  });

  testWidgets('forbidden cuando el rol no tiene inventario.registrar_material',
      (tester) async {
    await pumpPage(tester, repo, ubic, roles: const ['voluntario']);
    await tester.pumpAndSettle();

    expect(find.text('Sin acceso'), findsOneWidget);
    verifyNever(() => repo.createMaterial(any()));
  });

  testWidgets('bloquea submit y muestra errores de validación al estar vacío',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(tester, repo, ubic);
    await tester.pumpAndSettle();

    // Nombre vacío, cantidad default '1', sin ubicación seleccionada.
    await tester.tap(find.byKey(K.altaMaterialSubmit));
    await tester.pump();

    expect(find.text('Nombre obligatorio'), findsOneWidget);
    expect(find.text('Ubicación obligatoria'), findsOneWidget);
    verifyNever(() => repo.createMaterial(any()));
  });

  testWidgets('cantidad vacía bloquea el submit', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(tester, repo, ubic);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(K.altaMaterialNombre), 'Botiquín');
    await tester.enterText(find.byKey(K.altaMaterialCantidad), '');
    await tester.tap(find.byKey(K.altaMaterialSubmit));
    await tester.pump();

    expect(find.text('Cantidad obligatoria'), findsOneWidget);
    verifyNever(() => repo.createMaterial(any()));
  });

  testWidgets('cantidad no entera bloquea el submit', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(tester, repo, ubic);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(K.altaMaterialNombre), 'Botiquín');
    await tester.enterText(find.byKey(K.altaMaterialCantidad), '1.5');
    await tester.tap(find.byKey(K.altaMaterialSubmit));
    await tester.pump();

    expect(find.text('Cantidad no válida'), findsOneWidget);
    verifyNever(() => repo.createMaterial(any()));
  });

  testWidgets('snackbar danger en Fail del backend', (tester) async {
    when(() => repo.createMaterial(any())).thenAnswer(
      (_) async => const Fail(InventarioFailure.cantidadInsuficiente()),
    );

    await pumpPage(tester, repo, ubic);
    await tester.pumpAndSettle();

    // Atajo: disparar el viewmodel directo (evita rellenar el picker). El
    // wiring de ref.listen → AppSnackbar se ejercita igualmente.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AltaMaterialPage)),
    );
    await container.read(altaMaterialViewModelProvider.notifier).submit(
          const MaterialCreate(
            nombre: 'Botiquín',
            tipo: TipoMaterial.prestable,
            cantidad: 1,
            ubicacionBaseId: 'u-1',
            ubicacionBase: 'Base Zuera',
          ),
        );
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('No hay cantidad suficiente'), findsOneWidget);
    // No navega en error.
    expect(find.text('material-detalle-stub'), findsNothing);
  });

  testWidgets('éxito (atajo viewmodel): snackbar + navegación a la ficha',
      (tester) async {
    when(() => repo.createMaterial(any()))
        .thenAnswer((_) async => Success(_material()));

    await pumpPage(tester, repo, ubic);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AltaMaterialPage)),
    );
    await container.read(altaMaterialViewModelProvider.notifier).submit(
          const MaterialCreate(
            nombre: 'Botiquín',
            tipo: TipoMaterial.prestable,
            cantidad: 1,
            ubicacionBaseId: 'u-1',
            ubicacionBase: 'Base Zuera',
          ),
        );
    await tester.pumpAndSettle();

    expect(find.text('material-detalle-stub'), findsOneWidget);
    verify(() => repo.createMaterial(any())).called(1);
    // El refresh de la lista se disparó como parte del callback de éxito (sin
    // el stub de listMaterial esto habría ensuciado el árbol). En el test el
    // provider del listado se construye y luego refresh() lo recarga, así que
    // lista más de una vez: basta verificar que ocurrió.
    verify(
      () => repo.listMaterial(
        skip: any(named: 'skip'),
        limit: any(named: 'limit'),
        query: any(named: 'query'),
        estado: any(named: 'estado'),
        tipo: any(named: 'tipo'),
        categoria: any(named: 'categoria'),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'éxito (UI completo): rellenar form + picker + submit construye el '
      'DTO correcto y navega', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => repo.createMaterial(any()))
        .thenAnswer((_) async => Success(_material()));

    await pumpPage(tester, repo, ubic);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(K.altaMaterialNombre), 'Botiquín');
    // cantidad ya trae '1' por defecto; tipo ya es prestable por defecto.
    await _seleccionarUbicacion(tester);

    // Cazaría el crash setState-during-build conocido de este form
    // (UbicacionSelectorField dentro de Form+ListView, PR #63).
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(K.altaMaterialSubmit));
    await tester.pumpAndSettle();

    expect(find.text('material-detalle-stub'), findsOneWidget);

    final captured = verify(() => repo.createMaterial(captureAny()))
        .captured
        .single as MaterialCreate;
    expect(captured.nombre, 'Botiquín');
    expect(captured.tipo, TipoMaterial.prestable);
    expect(captured.cantidad, 1);
    expect(captured.ubicacionBaseId, 'u-1');
    expect(captured.ubicacionBase, 'Base Zuera');
    // Campos sin presencia en la UI deben ir null.
    expect(captured.fechaAdquisicion, isNull);
    expect(captured.fechaProximaRevision, isNull);
    expect(captured.descripcion, isNull);
    expect(captured.codigo, isNull);
  });

  testWidgets(
      'seleccionar tipo distinto del default se refleja en el DTO',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => repo.createMaterial(any()))
        .thenAnswer((_) async => Success(_material()));

    await pumpPage(tester, repo, ubic);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(K.altaMaterialNombre), 'Casco');
    await tester
        .tap(find.byKey(K.altaMaterialTipoChip(TipoMaterial.personal.wire)));
    await tester.pump();
    await _seleccionarUbicacion(tester);

    await tester.tap(find.byKey(K.altaMaterialSubmit));
    await tester.pumpAndSettle();

    final captured = verify(() => repo.createMaterial(captureAny()))
        .captured
        .single as MaterialCreate;
    expect(captured.tipo, TipoMaterial.personal);
  });

  testWidgets(
      'seleccionar ubicación en el Form+ListView real no lanza '
      'setState-during-build (regresión PR #63)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(tester, repo, ubic);
    await tester.pumpAndSettle();

    await _seleccionarUbicacion(tester);

    // El setState del padre reconstruye el Form; didUpdateWidget del selector
    // copia el label al controller. Si el diferido con addPostFrameCallback
    // se revierte, esto vuelve a lanzar "setState() called during build".
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tras seleccionar ubicación el re-submit valida y crea '
      '(la selección cuenta para el Form)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => repo.createMaterial(any()))
        .thenAnswer((_) async => Success(_material()));

    await pumpPage(tester, repo, ubic);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(K.altaMaterialNombre), 'Botiquín');
    await tester.tap(find.byKey(K.altaMaterialSubmit));
    await tester.pump();
    // Primer submit sin ubicación: error de validación, no se envía.
    expect(find.text('Ubicación obligatoria'), findsOneWidget);
    verifyNever(() => repo.createMaterial(any()));

    await _seleccionarUbicacion(tester);

    // NOTA DE UX: el form valida al enviar (autovalidateMode por defecto),
    // igual que el resto de campos; el mensaje de error no se limpia hasta el
    // siguiente submit. Lo que importa es que la selección SÍ cuenta: al
    // reenviar, la validación pasa y el material se crea.
    await tester.tap(find.byKey(K.altaMaterialSubmit));
    await tester.pumpAndSettle();

    expect(find.text('material-detalle-stub'), findsOneWidget);
    final captured = verify(() => repo.createMaterial(captureAny()))
        .captured
        .single as MaterialCreate;
    expect(captured.ubicacionBaseId, 'u-1');
  });

  testWidgets(
      'botón submit deshabilitado mientras el create está en curso '
      '(anti doble-submit)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final completer = Completer<Result<MaterialItem>>();
    when(() => repo.createMaterial(any()))
        .thenAnswer((_) => completer.future);

    await pumpPage(tester, repo, ubic);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AltaMaterialPage)),
    );
    // Dispara el envío sin esperar: el create queda pendiente (Completer).
    // ignore: unawaited_futures
    container.read(altaMaterialViewModelProvider.notifier).submit(
          const MaterialCreate(
            nombre: 'Botiquín',
            tipo: TipoMaterial.prestable,
            cantidad: 1,
            ubicacionBaseId: 'u-1',
            ubicacionBase: 'Base Zuera',
          ),
        );
    await tester.pump(); // AsyncLoading aplicado.

    // Durante isLoading el primario queda deshabilitado (onPressed == null).
    final boton = tester.widget<AppPrimaryButton>(
      find.byKey(K.altaMaterialSubmit),
    );
    expect(boton.onPressed, isNull);

    // Un intento de tap mientras está deshabilitado no debe disparar otro
    // create: liberamos el completer y comprobamos una sola llamada.
    completer.complete(Success(_material()));
    await tester.pumpAndSettle();

    verify(() => repo.createMaterial(any())).called(1);
  });
}
