// Widget tests de las acciones de mando de la ficha de servicio
// (ServicioFichaPage > _AdminActions): publicar, convocar y cerrar.
//
// Cada acción tiene una superficie distinta:
//   - Publicar: botón directo, sin diálogo de confirmación.
//   - Convocar: AppConfirmDialog ('Convocar voluntarios').
//   - Cerrar: AppDialog con campo Observaciones + confirmar/cancelar.
//
// Se mockea ServiciosRepository (mocktail) y se overridean los use-case
// providers de la cadena. El rol se inyecta vía currentUser de
// pumpRiverpod (no pumpWithRole) porque la page necesita además los
// overrides de los use cases, no solo el gate de auth.
//
// Nota de plumbing: al completar una acción con éxito la page dispara
// `serviciosListViewModelProvider.notifier.refresh()` (ref.listen), que
// recorre listServiciosProvider -> repo.list. Para que ese refresh no
// toque la red real se overridea también listServiciosProvider con el
// mismo repo mock y se le stubea `list` con una página vacía.

import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_inventario.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_summary.dart';
import 'package:custodiam/features/servicios/domain/entities/servicios_page.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/usecases/cerrar_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/convocar_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_inventario_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_servicio_by_id.dart';
import 'package:custodiam/features/servicios/domain/usecases/list_servicios.dart';
import 'package:custodiam/features/servicios/domain/usecases/list_voluntarios_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/publicar_servicio.dart';
import 'package:custodiam/features/servicios/presentation/pages/servicio_ficha_page.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

// jefe_equipo tiene servicios.publicar / .convocar / .cerrar (ver
// kRolePermissions en lib/infrastructure/auth/permissions.dart).
const _jefeEquipo = CurrentUser(
  sub: 's',
  email: 'jefe@e',
  roles: ['jefe_equipo'],
);

// voluntario NO tiene ninguno de los tres permisos de mando.
const _voluntario = CurrentUser(
  sub: 's',
  email: 'vol@e',
  roles: ['voluntario'],
);

const _servicioId = 'id-1';

Servicio _servicio({
  EstadoServicio estado = EstadoServicio.borrador,
}) {
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
    // El refresh de la lista en caché (ref.listen tras éxito) recorre
    // repo.list; lo dejamos en una página vacía para no tocar la red.
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
  });

  Future<void> pumpFicha(
    WidgetTester tester, {
    required Servicio servicio,
    required CurrentUser user,
  }) async {
    when(() => repo.getById(servicio.id))
        .thenAnswer((_) async => Success(servicio));
    when(() => repo.getInventario(servicio.id)).thenAnswer(
      (_) async => const Success(
        ServicioInventario(
          material: <MaterialAsignadoServicio>[],
          vehiculos: <VehiculoAsignadoServicio>[],
        ),
      ),
    );
    // La sección "Personal del servicio" (A9) carga la lista de voluntarios;
    // la dejamos vacía para no tocar la red real.
    when(() => repo.listVoluntarios(servicio.id))
        .thenAnswer((_) async => const Success([]));
    await pumpRiverpod(
      tester,
      ServicioFichaPage(servicioId: servicio.id),
      wrapInScaffold: false,
      currentUser: user,
      overrides: [
        getServicioByIdProvider.overrideWithValue(GetServicioById(repo)),
        getInventarioServicioProvider
            .overrideWithValue(GetInventarioServicio(repo)),
        listVoluntariosServicioProvider
            .overrideWithValue(ListVoluntariosServicio(repo)),
        publicarServicioProvider.overrideWithValue(PublicarServicio(repo)),
        convocarServicioProvider.overrideWithValue(ConvocarServicio(repo)),
        cerrarServicioProvider.overrideWithValue(CerrarServicio(repo)),
        // Mantiene el refresh de la lista dentro del repo mock.
        listServiciosProvider.overrideWithValue(ListServicios(repo)),
      ],
    );
  }

  group('RBAC negativo (rol voluntario)', () {
    testWidgets(
        'no muestra publicar / convocar / cerrar y no llama al repo',
        (tester) async {
      // Un voluntario sobre un borrador no debe ver ninguna acción de
      // mando; sobre publicado/activo tampoco. Probamos en borrador
      // (donde un mando sí vería "Publicar") para que la ausencia sea
      // significativa.
      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.borrador),
        user: _voluntario,
      );

      expect(find.byKey(K.servicioFichaPublicarBtn), findsNothing);
      expect(find.byKey(K.servicioFichaConvocarBtn), findsNothing);
      expect(find.byKey(K.servicioFichaCerrarBtn), findsNothing);

      verifyNever(() => repo.publicar(any()));
      verifyNever(
        () => repo.convocar(any(), voluntarioIds: any(named: 'voluntarioIds')),
      );
      verifyNever(
        () => repo.cerrar(any(), observaciones: any(named: 'observaciones')),
      );
    });

    testWidgets(
        'en borrador, sin permiso de publicar, muestra el mensaje explicativo '
        'en vez de un hueco vacío',
        (tester) async {
      // Caso real: el secretario (y aquí el voluntario) crea/abre un borrador
      // pero no puede publicarlo. En vez de ocultar el botón en silencio
      // ("no sale / se queda en borrador"), la ficha explica por qué.
      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.borrador),
        user: _voluntario,
      );

      expect(find.byKey(K.servicioFichaPublicarBtn), findsNothing);
      expect(
        find.textContaining('Debe publicarlo un responsable'),
        findsOneWidget,
      );
    });

    testWidgets(
        'tampoco muestra convocar/cerrar sobre un servicio activo',
        (tester) async {
      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.activo),
        user: _voluntario,
      );

      expect(find.byKey(K.servicioFichaConvocarBtn), findsNothing);
      expect(find.byKey(K.servicioFichaCerrarBtn), findsNothing);
    });
  });

  group('Publicar (estado borrador)', () {
    testWidgets('jefe_equipo ve el botón y al pulsar llama repo.publicar',
        (tester) async {
      when(() => repo.publicar(_servicioId)).thenAnswer(
        (_) async => Success(_servicio(estado: EstadoServicio.publicado)),
      );

      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.borrador),
        user: _jefeEquipo,
      );

      final boton = find.byKey(K.servicioFichaPublicarBtn);
      expect(boton, findsOneWidget);

      await tester.tap(boton);
      await tester.pumpAndSettle();

      verify(() => repo.publicar(_servicioId)).called(1);
    });
  });

  group('Convocar (estado publicado/activo)', () {
    testWidgets(
        'abre AppConfirmDialog y al confirmar llama repo.convocar sin lista',
        (tester) async {
      when(() => repo.convocar(_servicioId, voluntarioIds: null)).thenAnswer(
        (_) async => Success(_servicio(estado: EstadoServicio.publicado)),
      );

      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.publicado),
        user: _jefeEquipo,
      );

      await tester.tap(find.byKey(K.servicioFichaConvocarBtn));
      await tester.pumpAndSettle();

      // El diálogo de confirmación está visible.
      expect(find.text('Convocar voluntarios'), findsOneWidget);

      // Confirmar: el botón confirm del AppConfirmDialog rotula 'Convocar'.
      // El botón disparador de la page rotula 'Convocar voluntarios
      // disponibles', así que 'Convocar' exacto solo matchea el del diálogo.
      await tester.tap(find.text('Convocar'));
      await tester.pumpAndSettle();

      verify(() => repo.convocar(_servicioId, voluntarioIds: null)).called(1);
    });

    testWidgets('al cancelar el diálogo no llama repo.convocar',
        (tester) async {
      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.activo),
        user: _jefeEquipo,
      );

      await tester.tap(find.byKey(K.servicioFichaConvocarBtn));
      await tester.pumpAndSettle();

      expect(find.text('Convocar voluntarios'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // El diálogo se cerró y no se convocó a nadie.
      expect(find.text('Convocar voluntarios'), findsNothing);
      verifyNever(
        () => repo.convocar(any(), voluntarioIds: any(named: 'voluntarioIds')),
      );
    });
  });

  group('Cerrar (estado activo)', () {
    testWidgets('abre el diálogo con campo Observaciones y botón confirmar',
        (tester) async {
      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.activo),
        user: _jefeEquipo,
      );

      await tester.ensureVisible(find.byKey(K.servicioFichaCerrarBtn));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.servicioFichaCerrarBtn));
      await tester.pumpAndSettle();

      expect(
        find.byKey(K.servicioFichaCerrarObservacionesField),
        findsOneWidget,
      );
      expect(find.byKey(K.servicioFichaCerrarConfirmBtn), findsOneWidget);
    });

    testWidgets(
        'con observaciones llama repo.cerrar con el texto recortado',
        (tester) async {
      when(
        () => repo.cerrar(_servicioId,
            observaciones: any(named: 'observaciones')),
      ).thenAnswer(
        (_) async => Success(_servicio(estado: EstadoServicio.cerrado)),
      );

      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.activo),
        user: _jefeEquipo,
      );

      await tester.ensureVisible(find.byKey(K.servicioFichaCerrarBtn));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.servicioFichaCerrarBtn));
      await tester.pumpAndSettle();

      // Texto con espacios alrededor: la page hace trim() antes de enviar.
      await tester.enterText(
        find.byKey(K.servicioFichaCerrarObservacionesField),
        '  Todo correcto  ',
      );
      await tester.tap(find.byKey(K.servicioFichaCerrarConfirmBtn));
      await tester.pumpAndSettle();

      final captured = verify(
        () => repo.cerrar(
          _servicioId,
          observaciones: captureAny(named: 'observaciones'),
        ),
      ).captured;
      expect(captured.single, 'Todo correcto');
    });

    testWidgets('sin observaciones envía observaciones: null', (tester) async {
      when(
        () => repo.cerrar(_servicioId,
            observaciones: any(named: 'observaciones')),
      ).thenAnswer(
        (_) async => Success(_servicio(estado: EstadoServicio.cerrado)),
      );

      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.activo),
        user: _jefeEquipo,
      );

      await tester.ensureVisible(find.byKey(K.servicioFichaCerrarBtn));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.servicioFichaCerrarBtn));
      await tester.pumpAndSettle();

      // No se escribe nada en el campo.
      await tester.tap(find.byKey(K.servicioFichaCerrarConfirmBtn));
      await tester.pumpAndSettle();

      verify(() => repo.cerrar(_servicioId, observaciones: null)).called(1);
    });

    testWidgets('al cancelar el diálogo no llama repo.cerrar', (tester) async {
      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.activo),
        user: _jefeEquipo,
      );

      await tester.ensureVisible(find.byKey(K.servicioFichaCerrarBtn));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.servicioFichaCerrarBtn));
      await tester.pumpAndSettle();

      expect(
        find.byKey(K.servicioFichaCerrarObservacionesField),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(K.servicioFichaCerrarObservacionesField),
        findsNothing,
      );
      verifyNever(
        () => repo.cerrar(any(), observaciones: any(named: 'observaciones')),
      );
    });
  });

  group('Visibilidad por estado (jefe_equipo)', () {
    testWidgets('borrador: solo Publicar', (tester) async {
      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.borrador),
        user: _jefeEquipo,
      );

      expect(find.byKey(K.servicioFichaPublicarBtn), findsOneWidget);
      expect(find.byKey(K.servicioFichaConvocarBtn), findsNothing);
      expect(find.byKey(K.servicioFichaCerrarBtn), findsNothing);
    });

    testWidgets('publicado: solo Convocar', (tester) async {
      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.publicado),
        user: _jefeEquipo,
      );

      expect(find.byKey(K.servicioFichaPublicarBtn), findsNothing);
      expect(find.byKey(K.servicioFichaConvocarBtn), findsOneWidget);
      expect(find.byKey(K.servicioFichaCerrarBtn), findsNothing);
    });

    testWidgets('activo: Convocar y Cerrar', (tester) async {
      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.activo),
        user: _jefeEquipo,
      );

      expect(find.byKey(K.servicioFichaPublicarBtn), findsNothing);
      expect(find.byKey(K.servicioFichaConvocarBtn), findsOneWidget);
      expect(find.byKey(K.servicioFichaCerrarBtn), findsOneWidget);
    });

    testWidgets('cerrado: ninguna acción de mando', (tester) async {
      await pumpFicha(
        tester,
        servicio: _servicio(estado: EstadoServicio.cerrado),
        user: _jefeEquipo,
      );

      expect(find.byKey(K.servicioFichaPublicarBtn), findsNothing);
      expect(find.byKey(K.servicioFichaConvocarBtn), findsNothing);
      expect(find.byKey(K.servicioFichaCerrarBtn), findsNothing);
    });
  });
}
