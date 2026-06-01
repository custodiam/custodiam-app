// Widget tests de MaterialFichaPage: gate RBAC + diálogos de asignación,
// préstamo, devolución e incidencia (avería / pérdida).
//
// Patrón: pumpRiverpod (test_app.dart) inyecta el CurrentUser que dispara
// el AppPermissionGate; los use cases se overridean con instancias reales
// envolviendo un repo mock (mocktail). Cada caso abre el diálogo desde su
// botón gateado por K.*, rellena los AppTextField y confirma, verificando
// la llamada al repo o la validación que la bloquea.

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/features/inventario/domain/entities/asignacion_actual.dart';
import 'package:custodiam/features/inventario/domain/entities/asignacion_material.dart';
import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/domain/entities/material_item.dart';
import 'package:custodiam/features/inventario/domain/entities/materiales_page.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_asignacion.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_material.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/asignar_material_a_voluntario.dart';
import 'package:custodiam/features/inventario/domain/usecases/devolver_material.dart';
import 'package:custodiam/features/inventario/domain/usecases/get_material.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_materiales.dart';
import 'package:custodiam/features/inventario/domain/usecases/reportar_incidencia_material.dart';
import 'package:custodiam/features/inventario/presentation/pages/material_ficha_page.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements InventarioRepository {}

const _materialId = 'm-1';

MaterialItem _material({
  TipoMaterial tipo = TipoMaterial.prestable,
  EstadoInventario estado = EstadoInventario.operativo,
}) {
  return MaterialItem(
    id: _materialId,
    nombre: 'Casco de intervención',
    tipo: tipo,
    estado: estado,
    cantidad: 5,
    asignacionesActivas: const <AsignacionActual>[],
  );
}

AsignacionMaterial _asignacion() => AsignacionMaterial(
      id: 'a-1',
      materialId: _materialId,
      tipo: TipoAsignacion.prestamo,
      cantidad: 1,
      fechaAsignacion: DateTime(2026, 5, 31),
      activa: true,
    );

CurrentUser _user(List<String> roles) =>
    CurrentUser(sub: '1', email: 'a@b.com', roles: roles);

void main() {
  setUpAll(() {
    // Necesario para los matchers `any(named:)` sobre enums en mocktail.
    registerFallbackValue(TipoAsignacion.prestamo);
    registerFallbackValue(EstadoInventario.averiado);
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  // Monta la ficha con el material indicado y todos los use cases de la
  // página apuntando al repo mock. `listMaterialesProvider` también se
  // overridea: el `ref.listen` de la página refresca el listado tras una
  // acción con éxito, y sin override esa recarga golpearía la red real.
  Future<void> pump(
    WidgetTester tester,
    CurrentUser user, {
    TipoMaterial tipo = TipoMaterial.prestable,
    EstadoInventario estado = EstadoInventario.operativo,
  }) async {
    // Superficie alta para que toda la columna de acciones del ListView
    // quede dispuesta sin scroll — los tests tocan botones que de otro
    // modo caerían bajo el fold con la superficie por defecto (800x600).
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => repo.getMaterial(_materialId)).thenAnswer(
      (_) async => Success(_material(tipo: tipo, estado: estado)),
    );
    when(() => repo.listMaterial(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
          categoria: any(named: 'categoria'),
        )).thenAnswer(
      (_) async => const Success(MaterialesPage(items: [], total: 0)),
    );

    await pumpRiverpod(
      tester,
      const MaterialFichaPage(materialId: _materialId),
      currentUser: user,
      overrides: [
        getMaterialProvider.overrideWithValue(GetMaterial(repo)),
        reportarIncidenciaMaterialProvider
            .overrideWithValue(ReportarIncidenciaMaterial(repo)),
        asignarMaterialAVoluntarioProvider
            .overrideWithValue(AsignarMaterialAVoluntario(repo)),
        devolverMaterialProvider.overrideWithValue(DevolverMaterial(repo)),
        listMaterialesProvider.overrideWithValue(ListMateriales(repo)),
      ],
      settle: false,
    );
    await tester.pumpAndSettle();
  }

  group('Gate RBAC inventario.ver', () {
    testWidgets('a voluntario without inventario.ver sees the forbidden screen',
        (tester) async {
      await pump(tester, _user(['voluntario']));

      expect(find.text('Sin acceso'), findsOneWidget);
      // El AppPermissionGate corta antes del cuerpo: ni siquiera se carga
      // el material.
      verifyNever(() => repo.getMaterial(any()));
    });
  });

  group('Visibilidad de acciones según tipo/rol', () {
    testWidgets(
        'personal + operativo: jefe_seccion ve "asignar personal"',
        (tester) async {
      await pump(
        tester,
        _user(['jefe_seccion']),
        tipo: TipoMaterial.personal,
      );

      expect(find.byKey(K.materialFichaAsignarPersonal), findsOneWidget);
    });

    testWidgets(
        'personal + operativo: jefe_equipo NO ve "asignar personal"',
        (tester) async {
      await pump(
        tester,
        _user(['jefe_equipo']),
        tipo: TipoMaterial.personal,
      );

      // jefe_equipo carece de inventario.asignar_equipamiento_personal.
      expect(find.byKey(K.materialFichaAsignarPersonal), findsNothing);
    });

    testWidgets(
        'prestable + operativo: jefe_equipo ve "prestar"',
        (tester) async {
      await pump(tester, _user(['jefe_equipo']));

      expect(find.byKey(K.materialFichaPrestar), findsOneWidget);
    });

    testWidgets(
        'estado averiado: los botones de incidencia quedan ocultos',
        (tester) async {
      await pump(
        tester,
        _user(['jefe_equipo']),
        estado: EstadoInventario.averiado,
      );

      expect(find.byKey(K.materialFichaAveria), findsNothing);
      expect(find.byKey(K.materialFichaPerdida), findsNothing);
    });

    testWidgets(
        'estado perdido: los botones de incidencia quedan ocultos',
        (tester) async {
      await pump(
        tester,
        _user(['jefe_equipo']),
        estado: EstadoInventario.perdido,
      );

      expect(find.byKey(K.materialFichaAveria), findsNothing);
      expect(find.byKey(K.materialFichaPerdida), findsNothing);
    });
  });

  group('Diálogo prestar / asignar', () {
    testWidgets('tapping prestar opens the dialog with its fields',
        (tester) async {
      await pump(tester, _user(['jefe_equipo']));

      await tester.tap(find.byKey(K.materialFichaPrestar));
      await tester.pumpAndSettle();

      expect(find.byKey(K.materialAsignarVoluntarioId), findsOneWidget);
      expect(find.byKey(K.materialAsignarCantidad), findsOneWidget);
      expect(find.byKey(K.materialAsignarConfirm), findsOneWidget);
    });

    testWidgets(
        'empty voluntarioId: warning snackbar, no repo call',
        (tester) async {
      await pump(tester, _user(['jefe_equipo']));

      await tester.tap(find.byKey(K.materialFichaPrestar));
      await tester.pumpAndSettle();

      // No rellenamos el ID. Confirmar.
      await tester.tap(find.byKey(K.materialAsignarConfirm));
      await tester.pump();

      expect(find.text('Indica el ID del voluntario.'), findsOneWidget);
      verifyNever(() => repo.asignarMaterialAVoluntario(
            any(),
            voluntarioId: any(named: 'voluntarioId'),
            tipo: any(named: 'tipo'),
            cantidad: any(named: 'cantidad'),
          ));
    });

    testWidgets(
        'success: calls repo.asignarMaterialAVoluntario + success snackbar',
        (tester) async {
      when(() => repo.asignarMaterialAVoluntario(
            any(),
            voluntarioId: any(named: 'voluntarioId'),
            tipo: any(named: 'tipo'),
            cantidad: any(named: 'cantidad'),
          )).thenAnswer((_) async => Success(_asignacion()));

      await pump(tester, _user(['jefe_equipo']));

      await tester.tap(find.byKey(K.materialFichaPrestar));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(K.materialAsignarVoluntarioId),
        'vol-99',
      );
      await tester.enterText(
        find.byKey(K.materialAsignarCantidad),
        '2',
      );
      await tester.tap(find.byKey(K.materialAsignarConfirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => repo.asignarMaterialAVoluntario(
            _materialId,
            voluntarioId: 'vol-99',
            tipo: TipoAsignacion.prestamo,
            cantidad: 2,
          )).called(1);
      expect(find.text('Asignación registrada.'), findsOneWidget);
    });
  });

  group('Diálogo devolver', () {
    testWidgets('tapping devolver opens the dialog with its fields',
        (tester) async {
      // secretario tiene inventario.registrar_devolucion y inventario.ver.
      await pump(tester, _user(['secretario']));

      await tester.tap(find.byKey(K.materialFichaDevolver));
      await tester.pumpAndSettle();

      expect(find.byKey(K.materialDevolverVoluntarioId), findsOneWidget);
      expect(find.byKey(K.materialDevolverObservaciones), findsOneWidget);
      expect(find.byKey(K.materialDevolverConfirm), findsOneWidget);
    });

    testWidgets(
        'empty voluntarioId: warning snackbar, no repo call',
        (tester) async {
      await pump(tester, _user(['jefe_equipo']));

      await tester.tap(find.byKey(K.materialFichaDevolver));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(K.materialDevolverConfirm));
      await tester.pump();

      expect(find.text('Indica el ID del voluntario.'), findsOneWidget);
      verifyNever(() => repo.devolverMaterial(
            any(),
            voluntarioId: any(named: 'voluntarioId'),
            observaciones: any(named: 'observaciones'),
          ));
    });

    testWidgets('success: calls repo.devolverMaterial + success snackbar',
        (tester) async {
      when(() => repo.devolverMaterial(
            any(),
            voluntarioId: any(named: 'voluntarioId'),
            observaciones: any(named: 'observaciones'),
          )).thenAnswer((_) async => Success(_asignacion()));

      await pump(tester, _user(['jefe_equipo']));

      await tester.tap(find.byKey(K.materialFichaDevolver));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(K.materialDevolverVoluntarioId),
        'vol-7',
      );
      await tester.tap(find.byKey(K.materialDevolverConfirm));
      await tester.pump();

      verify(() => repo.devolverMaterial(
            _materialId,
            voluntarioId: 'vol-7',
            observaciones: any(named: 'observaciones'),
          )).called(1);
      expect(find.text('Devolución registrada.'), findsOneWidget);
    });
  });

  group('Diálogo incidencia — avería', () {
    testWidgets(
        'empty descripción: warning snackbar, no repo call',
        (tester) async {
      await pump(tester, _user(['jefe_equipo']));

      await tester.tap(find.byKey(K.materialFichaAveria));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(K.materialIncidenciaConfirm));
      await tester.pump();

      expect(find.text('La descripción es obligatoria.'), findsOneWidget);
      verifyNever(() => repo.reportarIncidenciaMaterial(
            any(),
            nuevoEstado: any(named: 'nuevoEstado'),
            descripcion: any(named: 'descripcion'),
          ));
    });

    testWidgets(
        'success: calls reportarIncidenciaMaterial with estado averiado',
        (tester) async {
      when(() => repo.reportarIncidenciaMaterial(
            any(),
            nuevoEstado: any(named: 'nuevoEstado'),
            descripcion: any(named: 'descripcion'),
          )).thenAnswer(
        (_) async => Success(_material(estado: EstadoInventario.averiado)),
      );

      await pump(tester, _user(['jefe_equipo']));

      await tester.tap(find.byKey(K.materialFichaAveria));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(K.materialIncidenciaDescripcion),
        'Correa rota',
      );
      await tester.tap(find.byKey(K.materialIncidenciaConfirm));
      await tester.pumpAndSettle();

      verify(() => repo.reportarIncidenciaMaterial(
            _materialId,
            nuevoEstado: EstadoInventario.averiado,
            descripcion: 'Correa rota',
          )).called(1);
    });
  });

  group('Diálogo incidencia — pérdida', () {
    testWidgets(
        'empty descripción: warning snackbar, no repo call',
        (tester) async {
      await pump(tester, _user(['jefe_equipo']));

      await tester.tap(find.byKey(K.materialFichaPerdida));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(K.materialIncidenciaConfirm));
      await tester.pump();

      expect(find.text('La descripción es obligatoria.'), findsOneWidget);
      verifyNever(() => repo.reportarIncidenciaMaterial(
            any(),
            nuevoEstado: any(named: 'nuevoEstado'),
            descripcion: any(named: 'descripcion'),
          ));
    });

    testWidgets(
        'success: calls reportarIncidenciaMaterial with estado perdido',
        (tester) async {
      when(() => repo.reportarIncidenciaMaterial(
            any(),
            nuevoEstado: any(named: 'nuevoEstado'),
            descripcion: any(named: 'descripcion'),
          )).thenAnswer(
        (_) async => Success(_material(estado: EstadoInventario.perdido)),
      );

      await pump(tester, _user(['jefe_equipo']));

      await tester.tap(find.byKey(K.materialFichaPerdida));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(K.materialIncidenciaDescripcion),
        'Extraviado en intervención',
      );
      await tester.tap(find.byKey(K.materialIncidenciaConfirm));
      await tester.pumpAndSettle();

      verify(() => repo.reportarIncidenciaMaterial(
            _materialId,
            nuevoEstado: EstadoInventario.perdido,
            descripcion: 'Extraviado en intervención',
          )).called(1);
    });
  });
}
