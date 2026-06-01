// Widget tests de VehiculoFichaPage: gate RBAC + diálogos de incidencia
// (reportar avería → averiado, reportar pérdida → perdido).
//
// Se mockea InventarioRepository y se sobreescriben los use case providers
// (patrón del repo: GetVehiculo, ReportarIncidenciaVehiculo,
// ListarDotacionVehiculo y ListVehiculos). La page embebe
// DotacionVehiculoSection, que carga la dotación vía su propio
// FamilyAsyncNotifier; por eso se stubea repo.listarDotacionVehiculo('v-1').
// El ref.listen de la page refresca vehiculosListViewModelProvider tras una
// acción con éxito, así que también se stubea repo.listVehiculos(...).

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/features/inventario/domain/entities/dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/entities/estado_inventario.dart';
import 'package:custodiam/features/inventario/domain/entities/tipo_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculo_item.dart';
import 'package:custodiam/features/inventario/domain/entities/vehiculos_page.dart';
import 'package:custodiam/features/inventario/domain/repositories/inventario_repository.dart';
import 'package:custodiam/features/inventario/domain/usecases/get_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/usecases/list_vehiculos.dart';
import 'package:custodiam/features/inventario/domain/usecases/listar_dotacion_vehiculo.dart';
import 'package:custodiam/features/inventario/domain/usecases/reportar_incidencia_vehiculo.dart';
import 'package:custodiam/features/inventario/presentation/pages/vehiculo_ficha_page.dart';
import 'package:custodiam/features/inventario/presentation/viewmodels/inventario_di.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements InventarioRepository {}

VehiculoItem _vehiculo({
  EstadoInventario estado = EstadoInventario.operativo,
}) =>
    VehiculoItem(
      id: 'v-1',
      codigoInterno: 'VH-01',
      matricula: '1234ABC',
      tipo: TipoVehiculo.furgoneta,
      marcaModelo: 'Renault Trafic',
      fechaItv: DateTime(2027, 3, 1),
      ubicacionBase: 'Almacén 1',
      estado: estado,
    );

CurrentUser _user(List<String> roles) =>
    CurrentUser(sub: '1', email: 'a@b.com', roles: roles);

void main() {
  setUpAll(() {
    registerFallbackValue(EstadoInventario.averiado);
  });

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    // La dotación embebida no aporta a estos tests: lista vacía.
    when(() => repo.listarDotacionVehiculo('v-1'))
        .thenAnswer((_) async => const Success(<DotacionVehiculo>[]));
    // El ref.listen de la page refresca el listado tras una acción con
    // éxito; el listado necesita una página resoluble.
    when(() => repo.listVehiculos(
          skip: any(named: 'skip'),
          limit: any(named: 'limit'),
          query: any(named: 'query'),
          estado: any(named: 'estado'),
          tipo: any(named: 'tipo'),
        )).thenAnswer(
      (_) async => const Success(VehiculosPage(items: [], total: 0)),
    );
  });

  Future<void> pump(
    WidgetTester tester,
    CurrentUser user, {
    EstadoInventario estado = EstadoInventario.operativo,
  }) async {
    when(() => repo.getVehiculo('v-1'))
        .thenAnswer((_) async => Success(_vehiculo(estado: estado)));
    await pumpRiverpod(
      tester,
      const VehiculoFichaPage(vehiculoId: 'v-1'),
      currentUser: user,
      wrapInScaffold: false,
      settle: false,
      overrides: [
        getVehiculoProvider.overrideWithValue(GetVehiculo(repo)),
        reportarIncidenciaVehiculoProvider
            .overrideWithValue(ReportarIncidenciaVehiculo(repo)),
        listarDotacionVehiculoProvider
            .overrideWithValue(ListarDotacionVehiculo(repo)),
        listVehiculosProvider.overrideWithValue(ListVehiculos(repo)),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('gate RBAC', () {
    testWidgets('un voluntario (sin inventario.ver) ve la pantalla "Sin acceso"',
        (tester) async {
      await pump(tester, _user(['voluntario']));

      expect(find.text('Sin acceso'), findsOneWidget);
      // No debe ni siquiera cargar el vehículo: el gate corta antes.
      verifyNever(() => repo.getVehiculo(any()));
      expect(find.byKey(K.vehiculoFichaAveria), findsNothing);
      expect(find.byKey(K.vehiculoFichaPerdida), findsNothing);
    });
  });

  group('vehículo operativo + permiso de incidencia', () {
    testWidgets(
        'jefe_seccion ve los botones de avería y pérdida',
        (tester) async {
      await pump(tester, _user(['jefe_seccion']));

      expect(find.byKey(K.vehiculoFichaAveria), findsOneWidget);
      expect(find.byKey(K.vehiculoFichaPerdida), findsOneWidget);
    });

    testWidgets(
        'secretario también ve los botones de incidencia',
        (tester) async {
      await pump(tester, _user(['secretario']));

      expect(find.byKey(K.vehiculoFichaAveria), findsOneWidget);
      expect(find.byKey(K.vehiculoFichaPerdida), findsOneWidget);
    });
  });

  group('diálogo de avería', () {
    testWidgets('al pulsar "Reportar avería" se abre el diálogo',
        (tester) async {
      await pump(tester, _user(['jefe_seccion']));

      await tester.tap(find.byKey(K.vehiculoFichaAveria));
      await tester.pumpAndSettle();

      expect(find.byKey(K.vehiculoIncidenciaDescripcion), findsOneWidget);
      expect(find.byKey(K.vehiculoIncidenciaConfirm), findsOneWidget);
    });

    testWidgets(
        'descripción vacía + confirmar: no llama al repo y avisa por SnackBar',
        (tester) async {
      await pump(tester, _user(['jefe_seccion']));

      await tester.tap(find.byKey(K.vehiculoFichaAveria));
      await tester.pumpAndSettle();

      // Se confirma sin escribir nada en la descripción.
      await tester.tap(find.byKey(K.vehiculoIncidenciaConfirm));
      await tester.pumpAndSettle();

      expect(find.text('La descripción es obligatoria.'), findsOneWidget);
      verifyNever(
        () => repo.reportarIncidenciaVehiculo(
          any(),
          nuevoEstado: any(named: 'nuevoEstado'),
          descripcion: any(named: 'descripcion'),
        ),
      );
    });

    testWidgets('al cancelar el diálogo no llama al repo', (tester) async {
      await pump(tester, _user(['jefe_seccion']));

      await tester.tap(find.byKey(K.vehiculoFichaAveria));
      await tester.pumpAndSettle();

      // Cerrar por "Cancelar" reconstruye el campo durante la animación de
      // cierre — el camino del use-after-dispose. No debe tocar el repo.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byKey(K.vehiculoIncidenciaConfirm), findsNothing);
      verifyNever(
        () => repo.reportarIncidenciaVehiculo(
          any(),
          nuevoEstado: any(named: 'nuevoEstado'),
          descripcion: any(named: 'descripcion'),
        ),
      );
    });

    testWidgets(
        'éxito: rellenar descripción y confirmar llama al repo con averiado',
        (tester) async {
      when(() => repo.reportarIncidenciaVehiculo(
            'v-1',
            nuevoEstado: any(named: 'nuevoEstado'),
            descripcion: any(named: 'descripcion'),
          )).thenAnswer(
        (_) async => Success(_vehiculo(estado: EstadoInventario.averiado)),
      );

      await pump(tester, _user(['jefe_seccion']));

      await tester.tap(find.byKey(K.vehiculoFichaAveria));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(K.vehiculoIncidenciaDescripcion),
        'Motor de arranque defectuoso',
      );
      await tester.tap(find.byKey(K.vehiculoIncidenciaConfirm));
      await tester.pumpAndSettle();

      verify(
        () => repo.reportarIncidenciaVehiculo(
          'v-1',
          nuevoEstado: EstadoInventario.averiado,
          descripcion: 'Motor de arranque defectuoso',
        ),
      ).called(1);
    });
  });

  group('diálogo de pérdida', () {
    testWidgets(
        'éxito: rellenar descripción y confirmar llama al repo con perdido',
        (tester) async {
      when(() => repo.reportarIncidenciaVehiculo(
            'v-1',
            nuevoEstado: any(named: 'nuevoEstado'),
            descripcion: any(named: 'descripcion'),
          )).thenAnswer(
        (_) async => Success(_vehiculo(estado: EstadoInventario.perdido)),
      );

      await pump(tester, _user(['jefe_seccion']));

      await tester.tap(find.byKey(K.vehiculoFichaPerdida));
      await tester.pumpAndSettle();

      expect(find.byKey(K.vehiculoIncidenciaDescripcion), findsOneWidget);

      await tester.enterText(
        find.byKey(K.vehiculoIncidenciaDescripcion),
        'Sustraído en intervención',
      );
      await tester.tap(find.byKey(K.vehiculoIncidenciaConfirm));
      await tester.pumpAndSettle();

      verify(
        () => repo.reportarIncidenciaVehiculo(
          'v-1',
          nuevoEstado: EstadoInventario.perdido,
          descripcion: 'Sustraído en intervención',
        ),
      ).called(1);
    });
  });

  group('estado no operativo', () {
    testWidgets(
        'con estado averiado los botones de incidencia no se muestran',
        (tester) async {
      await pump(
        tester,
        _user(['jefe_seccion']),
        estado: EstadoInventario.averiado,
      );

      expect(find.byKey(K.vehiculoFichaAveria), findsNothing);
      expect(find.byKey(K.vehiculoFichaPerdida), findsNothing);
    });

    testWidgets(
        'con estado perdido los botones de incidencia no se muestran',
        (tester) async {
      await pump(
        tester,
        _user(['jefe_seccion']),
        estado: EstadoInventario.perdido,
      );

      expect(find.byKey(K.vehiculoFichaAveria), findsNothing);
      expect(find.byKey(K.vehiculoFichaPerdida), findsNothing);
    });
  });
}
