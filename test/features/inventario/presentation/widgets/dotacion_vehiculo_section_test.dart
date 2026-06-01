import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/features/inventario/domain/entities/dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/asignar_dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/usecases/liberar_dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/usecases/listar_dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/features/inventario/presentation/widgets/dotacion_vehiculo_section.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements InventarioRepository {}

DotacionVehiculo _dotacion() => DotacionVehiculo(
      id: 'a-1',
      materialId: 'm-1',
      materialNombre: 'Casco',
      cantidad: 2,
      fechaAsignacion: DateTime(2026, 5, 27),
    );

CurrentUser _user(List<String> roles) =>
    CurrentUser(sub: '1', email: 'a@b.com', roles: roles);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  // El ViewModel real construye la lista desde el use case listar; lo
  // sobreescribimos con un repo mock para no tocar la red. El gate RBAC
  // se ejercita a través del CurrentUser inyectado por pumpRiverpod.
  //
  // También sobreescribimos los use cases de alta y baja para verificar
  // las llamadas al repo desde los flujos de diálogo. Se pasa `settle:
  // false` porque el FamilyAsyncNotifier arranca en AsyncLoading (que
  // renderiza un SizedBox.shrink) y resuelve a AsyncData en el siguiente
  // microtask; cada test hace su propio pumpAndSettle tras el pump.
  Future<void> pump(WidgetTester tester, CurrentUser user) async {
    await pumpRiverpod(
      tester,
      const DotacionVehiculoSection(vehiculoId: 'v-1'),
      currentUser: user,
      overrides: [
        listarDotacionVehiculoProvider
            .overrideWithValue(ListarDotacionVehiculo(repo)),
        asignarDotacionVehiculoProvider
            .overrideWithValue(AsignarDotacionVehiculo(repo)),
        liberarDotacionVehiculoProvider
            .overrideWithValue(LiberarDotacionVehiculo(repo)),
      ],
      settle: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a manager (jefe_seccion) sees the add and remove actions',
      (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));

    await pump(tester, _user(['jefe_seccion']));

    expect(find.text('Casco'), findsOneWidget);
    expect(find.byKey(K.dotacionAnadir), findsOneWidget);
    expect(find.byTooltip('Quitar de la dotación'), findsOneWidget);
  });

  testWidgets('a viewer without the permission sees the list read-only',
      (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));

    await pump(tester, _user(['voluntario']));

    expect(find.text('Casco'), findsOneWidget);
    expect(find.byKey(K.dotacionAnadir), findsNothing);
    expect(find.byTooltip('Quitar de la dotación'), findsNothing);
  });

  testWidgets('a viewer sees nothing at all when the dotación is empty',
      (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => const Success(<DotacionVehiculo>[]));

    await pump(tester, _user(['voluntario']));

    expect(find.text('Material asignado al vehículo'), findsNothing);
    expect(find.byKey(K.dotacionAnadir), findsNothing);
  });

  // -- Flujo "Añadir material a la dotación" --------------------------------

  testWidgets('tapping add opens the dialog with its fields and confirm action',
      (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));

    await pump(tester, _user(['jefe_seccion']));

    await tester.tap(find.byKey(K.dotacionAnadir));
    await tester.pumpAndSettle();

    expect(find.text('Añadir material a la dotación'), findsOneWidget);
    expect(find.byKey(K.dotacionMaterialId), findsOneWidget);
    expect(find.byKey(K.dotacionCantidad), findsOneWidget);
    expect(find.byKey(K.dotacionAnadirConfirm), findsOneWidget);
  });

  testWidgets(
      'confirming the add dialog with an empty material id warns and does '
      'not call the repo', (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));

    await pump(tester, _user(['jefe_seccion']));

    await tester.tap(find.byKey(K.dotacionAnadir));
    await tester.pumpAndSettle();

    // Confirmar sin rellenar el ID del material (el campo arranca vacío).
    await tester.tap(find.byKey(K.dotacionAnadirConfirm));
    // El diálogo se cierra y se muestra el SnackBar de aviso de forma
    // síncrona (no hay llamada al repo). Bombeamos sin pumpAndSettle para
    // no colgar en el auto-dismiss de 4 s del SnackBar.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Indica el ID del material.'), findsOneWidget);
    verifyNever(
      () => repo.asignarDotacionVehiculo(
        any(),
        materialId: any(named: 'materialId'),
        cantidad: any(named: 'cantidad'),
      ),
    );
  });

  testWidgets(
      'filling the add dialog and confirming calls the repo and shows success',
      (tester) async {
    // Primer fetch (build inicial) y segundo fetch (refresh tras éxito).
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));
    when(
      () => repo.asignarDotacionVehiculo(
        'v-1',
        materialId: 'm-2',
        cantidad: 3,
      ),
    ).thenAnswer((_) async => Success(_dotacion()));

    await pump(tester, _user(['jefe_seccion']));

    await tester.tap(find.byKey(K.dotacionAnadir));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(K.dotacionMaterialId), 'm-2');
    await tester.enterText(find.byKey(K.dotacionCantidad), '3');
    await tester.tap(find.byKey(K.dotacionAnadirConfirm));
    // El confirm cierra el diálogo y dispara la cadena async (asignar →
    // refresh → segundo listar → SnackBar). Un único pump no flushea toda
    // la cadena; bombeamos hasta que el SnackBar aparece sin esperar su
    // auto-dismiss de 4 s (pumpAndSettle colgaría en ese timer).
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(
      () => repo.asignarDotacionVehiculo(
        'v-1',
        materialId: 'm-2',
        cantidad: 3,
      ),
    ).called(1);
    expect(find.text('Material añadido a la dotación.'), findsOneWidget);
  });

  testWidgets('al cancelar el alta no llama al repo', (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));

    await pump(tester, _user(['jefe_seccion']));

    await tester.tap(find.byKey(K.dotacionAnadir));
    await tester.pumpAndSettle();

    // Cerrar por "Cancelar" desmonta el diálogo durante la animación de
    // cierre (el camino del use-after-dispose); no debe llamar al repo.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byKey(K.dotacionAnadirConfirm), findsNothing);
    verifyNever(
      () => repo.asignarDotacionVehiculo(
        any(),
        materialId: any(named: 'materialId'),
        cantidad: any(named: 'cantidad'),
      ),
    );
  });

  testWidgets(
      'cantidad no numérica cae al fallback de 1 unidad', (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));
    when(
      () => repo.asignarDotacionVehiculo('v-1', materialId: 'm-2', cantidad: 1),
    ).thenAnswer((_) async => Success(_dotacion()));

    await pump(tester, _user(['jefe_seccion']));

    await tester.tap(find.byKey(K.dotacionAnadir));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(K.dotacionMaterialId), 'm-2');
    // 'abc' no parsea → int.tryParse(...) ?? 1.
    await tester.enterText(find.byKey(K.dotacionCantidad), 'abc');
    await tester.tap(find.byKey(K.dotacionAnadirConfirm));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(
      () => repo.asignarDotacionVehiculo('v-1', materialId: 'm-2', cantidad: 1),
    ).called(1);
  });

  // -- Flujo "Quitar de la dotación" ----------------------------------------

  testWidgets('tapping remove opens the confirmation dialog', (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));

    await pump(tester, _user(['jefe_seccion']));

    await tester.tap(find.byTooltip('Quitar de la dotación'));
    await tester.pumpAndSettle();

    expect(find.byKey(K.dotacionQuitarConfirm), findsOneWidget);
  });

  testWidgets('confirming the remove dialog calls the repo and shows success',
      (tester) async {
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => Success([_dotacion()]));
    when(
      () => repo.liberarDotacionVehiculo('v-1', asignacionId: 'a-1'),
    ).thenAnswer((_) async => const Success(null));

    await pump(tester, _user(['jefe_seccion']));

    await tester.tap(find.byTooltip('Quitar de la dotación'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(K.dotacionQuitarConfirm));
    // Misma cadena async que en el alta: liberar → refresh → segundo
    // listar → SnackBar. Bombeamos sin esperar el auto-dismiss del SnackBar.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(
      () => repo.liberarDotacionVehiculo('v-1', asignacionId: 'a-1'),
    ).called(1);
    expect(find.text('Material retirado de la dotación.'), findsOneWidget);
  });
}
