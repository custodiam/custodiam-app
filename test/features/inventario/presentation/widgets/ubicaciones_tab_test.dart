// Widget tests de UbicacionesTab (E10). pumpRiverpod inyecta un jefe_seccion
// (rol con ubicaciones.crear) y overridea los providers de use case sobre un
// repo mock para no tocar la red. Verifica:
//  - render de los items con el chip de coordenadas según tieneCoordenadas,
//  - presencia del botón "Nueva ubicación",
//  - flujo de borrado: PopupMenu -> 'Eliminar' -> AppConfirmDialog ->
//    confirmar llama a repo.eliminar y muestra el snackbar de éxito,
//  - cancelar el diálogo no llama al repo,
//  - un 409 enUso muestra el snackbar de error con su mensaje.
//
// NO se pulsan "Nueva"/"editar": navegan con context.go y este test no monta
// un GoRouter (la navegación se cubre en otros niveles). settle:false porque
// el AsyncNotifier arranca en AsyncLoading; cada caso hace su pumpAndSettle.

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/features/inventario/domain/entities/ubicacion.dart';
import 'package:custodiam/features/inventario/domain/entities/ubicaciones_page.dart';
import 'package:custodiam/features/inventario/domain/repositories/ubicaciones_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/eliminar_ubicacion.dart';
import 'package:custodiam/features/inventario/domain/usecases/listar_ubicaciones.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/ubicaciones_di.dart';
import 'package:custodiam/features/inventario/presentation/widgets/ubicaciones_tab.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements UbicacionesRepository {}

const _jefeSeccion = CurrentUser(
  sub: 's',
  email: 'jefe@e',
  roles: ['jefe_seccion'],
);

Ubicacion _conCoords() => const Ubicacion(
      id: 'u-1',
      nombre: 'Base Zuera',
      lat: 41.86,
      lng: -0.78,
    );

Ubicacion _sinCoords() => const Ubicacion(id: 'u-2', nombre: 'Almacén');

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Future<void> pump(WidgetTester tester) async {
    await pumpRiverpod(
      tester,
      const UbicacionesTab(),
      currentUser: _jefeSeccion,
      overrides: [
        listarUbicacionesProvider.overrideWithValue(ListarUbicaciones(repo)),
        eliminarUbicacionProvider.overrideWithValue(EliminarUbicacion(repo)),
      ],
      settle: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los items con el chip de coordenadas correcto',
      (tester) async {
    when(() => repo.listar(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
        )).thenAnswer((_) async => Success(
          UbicacionesPage(items: [_conCoords(), _sinCoords()], total: 2),
        ));

    await pump(tester);

    expect(find.text('Base Zuera'), findsOneWidget);
    expect(find.text('Almacén'), findsOneWidget);
    expect(find.text('Con coordenadas'), findsOneWidget);
    expect(find.text('Sin coordenadas'), findsOneWidget);
    expect(find.byKey(K.ubicacionesNuevaBtn), findsOneWidget);
    expect(find.byKey(K.ubicacionItem('u-1')), findsOneWidget);
  });

  testWidgets('borrado: PopupMenu -> Eliminar -> confirmar llama al repo y '
      'muestra snackbar de éxito', (tester) async {
    when(() => repo.listar(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
        )).thenAnswer((_) async => Success(
          UbicacionesPage(items: [_conCoords()], total: 1),
        ));
    when(() => repo.eliminar('u-1'))
        .thenAnswer((_) async => const Success<void>(null));

    await pump(tester);

    await tester.tap(find.byKey(K.ubicacionAccionesBtn('u-1')));
    await tester.pumpAndSettle();

    // El item 'Eliminar' del PopupMenu.
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    // AppConfirmDialog (título + botón destructivo 'Eliminar').
    expect(find.text('Eliminar ubicación'), findsOneWidget);

    // Confirmar: el botón del diálogo rotula 'Eliminar'. Al estar abierto el
    // diálogo (con título distinto) el único 'Eliminar' visible es el confirm.
    await tester.tap(find.text('Eliminar'));
    // Borrado -> refresh -> segundo listar -> snackbar. Bombeamos sin esperar
    // el auto-dismiss de 4 s del SnackBar (pumpAndSettle colgaría en él).
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => repo.eliminar('u-1')).called(1);
    expect(find.text('Ubicación eliminada.'), findsOneWidget);
  });

  testWidgets('cancelar el diálogo de borrado no llama al repo', (tester) async {
    when(() => repo.listar(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
        )).thenAnswer((_) async => Success(
          UbicacionesPage(items: [_conCoords()], total: 1),
        ));

    await pump(tester);

    await tester.tap(find.byKey(K.ubicacionAccionesBtn('u-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar ubicación'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar ubicación'), findsNothing);
    verifyNever(() => repo.eliminar(any()));
  });

  testWidgets('borrado con 409 enUso muestra el snackbar de error',
      (tester) async {
    when(() => repo.listar(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
        )).thenAnswer((_) async => Success(
          UbicacionesPage(items: [_conCoords()], total: 1),
        ));
    when(() => repo.eliminar('u-1')).thenAnswer(
      (_) async => const Fail(UbicacionesFailure.enUso()),
    );

    await pump(tester);

    await tester.tap(find.byKey(K.ubicacionAccionesBtn('u-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    // Confirmar.
    await tester.tap(find.text('Eliminar'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    verify(() => repo.eliminar('u-1')).called(1);
    // El snackbar muestra el message del Failure (UbicacionEnUso).
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('La ubicación está en uso'), findsOneWidget);
  });
}
