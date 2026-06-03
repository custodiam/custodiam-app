import 'package:custodiam/app/test_keys.dart';
import 'package:custodiam/core/ui/buttons/app_primary_button.dart';
import 'package:custodiam/core/ui/buttons/app_secondary_button.dart';
import 'package:custodiam/core/ui/maps/maps_launcher.dart';
import 'package:custodiam/features/servicios/domain/entities/estado_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_inscripcion.dart';
import 'package:custodiam/features/servicios/domain/entities/tipo_servicio.dart';
import 'package:custodiam/features/servicios/domain/entities/servicio_inventario.dart';
import 'package:custodiam/features/servicios/domain/entities/voluntario_inscrito.dart';
import 'package:custodiam/features/servicios/domain/repositories/servicios_repository.dart';
import 'package:custodiam/features/servicios/domain/entities/servicios_page.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_inventario_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/get_servicio_by_id.dart';
import 'package:custodiam/features/servicios/domain/usecases/inscribirse_servicio.dart';
import 'package:custodiam/features/servicios/domain/usecases/list_servicios.dart';
import 'package:custodiam/features/servicios/domain/usecases/list_voluntarios_servicio.dart';
import 'package:custodiam/features/servicios/presentation/pages/servicio_ficha_page.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_di.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../test_utils/test_app.dart';

class _MockRepo extends Mock implements ServiciosRepository {}

/// Captura las URLs en lugar de abrir mapas reales.
class _FakeMapsLauncher extends MapsLauncher {
  _FakeMapsLauncher(this.captured);

  final List<Uri> captured;

  @override
  Future<bool> abrir(Uri uri) async {
    captured.add(uri);
    return true;
  }
}

const _voluntario = CurrentUser(
  sub: 's',
  email: 'e@e',
  roles: ['voluntario'],
);

// Rol de solo-consulta para A10: el secretario puede ver el personal del
// servicio (fichaje.ver_voluntarios_en_servicio) pero NO puede fichar
// (no tiene fichaje.fichar_propio).
const _secretario = CurrentUser(
  sub: 's2',
  email: 'sec@e',
  roles: ['secretario'],
);

Servicio _servicio({
  String id = 'id-1',
  EstadoServicio estado = EstadoServicio.publicado,
  int? numeroVoluntarios,
  int inscritosCount = 0,
  double? ubicacionLat,
  double? ubicacionLng,
  bool estoyInscrito = false,
  TipoInscripcion? miTipoInscripcion,
}) {
  return Servicio(
    id: id,
    titulo: 'Preventivo',
    tipo: TipoServicio.preventivo,
    estado: estado,
    fechaInicio: DateTime.utc(2026, 6, 10, 8),
    ubicacion: 'Zuera',
    ubicacionLat: ubicacionLat,
    ubicacionLng: ubicacionLng,
    numeroVoluntarios: numeroVoluntarios,
    inscritosCount: inscritosCount,
    estoyInscrito: estoyInscrito,
    miTipoInscripcion: miTipoInscripcion,
  );
}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  Future<void> pumpFicha(
    WidgetTester tester,
    Servicio servicio, {
    List<Override> extraOverrides = const [],
    CurrentUser currentUser = _voluntario,
    List<VoluntarioInscrito> voluntarios = const [],
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
    when(() => repo.listVoluntarios(servicio.id))
        .thenAnswer((_) async => Success(voluntarios));
    await pumpRiverpod(
      tester,
      ServicioFichaPage(servicioId: servicio.id),
      wrapInScaffold: false,
      currentUser: currentUser,
      overrides: [
        getServicioByIdProvider.overrideWithValue(GetServicioById(repo)),
        getInventarioServicioProvider
            .overrideWithValue(GetInventarioServicio(repo)),
        listVoluntariosServicioProvider
            .overrideWithValue(ListVoluntariosServicio(repo)),
        ...extraOverrides,
      ],
    );
  }

  AppPrimaryButton apuntarseButton(WidgetTester tester) {
    return tester.widget<AppPrimaryButton>(
      find.byKey(K.servicioFichaApuntarseBtn),
    );
  }

  testWidgets(
      'Apuntarme deshabilitado con Semantics Aforo completo cuando aforo lleno',
      (tester) async {
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: 5, inscritosCount: 5),
    );

    expect(apuntarseButton(tester).onPressed, isNull);
    expect(
      find.descendant(
        of: find.bySemanticsLabel('Aforo completo'),
        matching: find.byKey(
          K.servicioFichaApuntarseBtn,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'sin coordenadas, el botón de mapa enruta por la dirección textual',
      (tester) async {
    // Opción 3: un servicio sin coords pero con dirección de texto SÍ ofrece
    // el botón; la ruta la resuelve la app de mapas buscando ese texto.
    final capturadas = <Uri>[];
    await pumpFicha(
      tester,
      _servicio(), // ubicacion 'Zuera', sin lat/lng
      extraOverrides: [
        mapsLauncherProvider.overrideWithValue(_FakeMapsLauncher(capturadas)),
      ],
    );

    final boton = find.byKey(K.servicioFichaAbrirMapaBtn);
    expect(boton, findsOneWidget);

    await tester.tap(boton);
    await tester.pumpAndSettle();

    expect(capturadas, hasLength(1));
    expect(capturadas.single, mapsDirectionsUriTexto('Zuera'));
  });

  testWidgets('"Cómo llegar" abre el deeplink de direcciones en móvil',
      (tester) async {
    // El test corre en la VM (kIsWeb == false) → ruta navegable.
    final capturadas = <Uri>[];
    await pumpFicha(
      tester,
      _servicio(ubicacionLat: 41.8708, ubicacionLng: -0.7895),
      extraOverrides: [
        mapsLauncherProvider.overrideWithValue(_FakeMapsLauncher(capturadas)),
      ],
    );

    final boton = find.byKey(K.servicioFichaAbrirMapaBtn);
    expect(boton, findsOneWidget);
    expect(find.text('Cómo llegar'), findsOneWidget);

    await tester.tap(boton);
    await tester.pumpAndSettle();

    expect(capturadas, hasLength(1));
    expect(capturadas.single, mapsDirectionsUri(41.8708, -0.7895));
  });

  testWidgets(
      'Apuntarme deshabilitado con Semantics Aforo completo cuando hay overflow (6/5)',
      (tester) async {
    // El gate usa `>=` (no `==`) para cubrir overflow ante posibles race
    // conditions del backend: si el contador de inscritos rebasa el aforo,
    // el botón debe seguir bloqueado igual que en el caso exactamente lleno.
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: 5, inscritosCount: 6),
    );

    expect(apuntarseButton(tester).onPressed, isNull);
    expect(
      find.descendant(
        of: find.bySemanticsLabel('Aforo completo'),
        matching: find.byKey(
          K.servicioFichaApuntarseBtn,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Apuntarme habilitado con plazas', (tester) async {
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: 5, inscritosCount: 3),
    );

    expect(apuntarseButton(tester).onPressed, isNotNull);
  });

  testWidgets('al apuntarse con éxito muestra un snackbar de confirmación',
      (tester) async {
    final servicio = _servicio(numeroVoluntarios: 5, inscritosCount: 2);
    when(() => repo.inscribirse(servicio.id))
        .thenAnswer((_) async => Success(servicio));
    // El ref.listen recarga la lista en silencio tras la acción.
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

    await pumpFicha(
      tester,
      servicio,
      extraOverrides: [
        inscribirseServicioProvider
            .overrideWithValue(InscribirseServicio(repo)),
        listServiciosProvider.overrideWithValue(ListServicios(repo)),
      ],
    );

    await tester.tap(find.byKey(K.servicioFichaApuntarseBtn));
    await tester.pumpAndSettle();

    expect(find.text('Te has apuntado al servicio.'), findsOneWidget);
  });

  testWidgets(
      'BUG A: una acción fallida muestra snackbar y la ficha SIGUE visible '
      '(no AppErrorState)', (tester) async {
    final servicio = _servicio(numeroVoluntarios: 5, inscritosCount: 2);
    // El backend rechaza la inscripción; el repo conserva el detalle real.
    when(() => repo.inscribirse(servicio.id)).thenAnswer(
      (_) async => const Fail(
        ServiciosFailure.tieneActividad('El servicio ya no admite plazas.'),
      ),
    );

    await pumpFicha(
      tester,
      servicio,
      extraOverrides: [
        inscribirseServicioProvider
            .overrideWithValue(InscribirseServicio(repo)),
      ],
    );

    await tester.tap(find.byKey(K.servicioFichaApuntarseBtn));
    // Sin pumpAndSettle: el SnackBar tiene auto-dismiss y colgaría.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // El mensaje real del backend se muestra en el snackbar.
    expect(find.text('El servicio ya no admite plazas.'), findsOneWidget);
    // La ficha sigue cargada: NO aparece el AppErrorState de carga.
    expect(find.text('No se pudo cargar el servicio'), findsNothing);
    // Los elementos del detalle siguen presentes (la ficha no se tumbó).
    expect(find.text('Plazas'), findsOneWidget);
    expect(find.byKey(K.servicioFichaApuntarseBtn), findsOneWidget);
  });

  testWidgets('Sin Semantics Aforo completo cuando quedan plazas',
      (tester) async {
    // Rama negativa del gate: con plazas libres el Semantics 'Aforo completo'
    // no debe existir en el árbol (hasta ahora solo se testeaba el caso lleno).
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: 5, inscritosCount: 3),
    );

    expect(find.bySemanticsLabel('Aforo completo'), findsNothing);
  });

  testWidgets('Apuntarme habilitado con aforo ilimitado', (tester) async {
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: null, inscritosCount: 99),
    );

    expect(apuntarseButton(tester).onPressed, isNotNull);
  });

  testWidgets('_InfoRow muestra Plazas X/Y', (tester) async {
    await pumpFicha(
      tester,
      _servicio(numeroVoluntarios: 5, inscritosCount: 2),
    );

    expect(find.text('Plazas'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
  });

  // ── A8: inscripción propia ──────────────────────────────────────────────
  group('A8 inscripción propia', () {
    testWidgets(
        'inscrito muestra chip "Inscrito" y oculta el botón "Apuntarme"',
        (tester) async {
      await pumpFicha(
        tester,
        _servicio(
          numeroVoluntarios: 5,
          inscritosCount: 3,
          estoyInscrito: true,
          miTipoInscripcion: TipoInscripcion.inscrito,
        ),
      );

      expect(find.byKey(K.servicioFichaInscritoChip), findsOneWidget);
      expect(find.text('Inscrito'), findsWidgets);
      expect(find.byKey(K.servicioFichaApuntarseBtn), findsNothing);
      // El botón de baja sí aparece para quien ya está inscrito.
      expect(find.byKey(K.servicioFichaDesapuntarseBtn), findsOneWidget);
    });

    testWidgets(
        'no inscrito muestra "Apuntarme" y oculta el chip y "Darme de baja"',
        (tester) async {
      await pumpFicha(
        tester,
        _servicio(numeroVoluntarios: 5, inscritosCount: 3),
      );

      expect(find.byKey(K.servicioFichaApuntarseBtn), findsOneWidget);
      expect(find.byKey(K.servicioFichaInscritoChip), findsNothing);
      expect(find.byKey(K.servicioFichaDesapuntarseBtn), findsNothing);
    });
  });

  // ── A9: personal del servicio ───────────────────────────────────────────
  group('A9 personal del servicio', () {
    testWidgets(
        'pinta los nombres y muestra el teléfono solo cuando viene no-nulo',
        (tester) async {
      await pumpFicha(
        tester,
        _servicio(),
        voluntarios: [
          VoluntarioInscrito(
            voluntarioId: 'v-1',
            nombre: 'Ana Mando',
            telefono: '600111222',
            tipo: TipoInscripcion.convocado,
            fecha: DateTime.utc(2026, 6, 10, 7),
          ),
          VoluntarioInscrito(
            voluntarioId: 'v-2',
            nombre: 'Bea Operativa',
            telefono: null,
            tipo: TipoInscripcion.inscrito,
            fecha: DateTime.utc(2026, 6, 10, 8),
          ),
        ],
      );

      expect(find.byKey(K.servicioPersonalSection), findsOneWidget);
      expect(find.text('Ana Mando'), findsOneWidget);
      expect(find.text('Bea Operativa'), findsOneWidget);
      // El teléfono del mando se muestra; el del operativo sin teléfono no.
      expect(find.textContaining('600111222'), findsOneWidget);
      expect(find.textContaining('601'), findsNothing);
      expect(find.byKey(K.servicioPersonalItem('v-1')), findsOneWidget);
      expect(find.byKey(K.servicioPersonalItem('v-2')), findsOneWidget);
    });

    testWidgets('sin inscritos muestra el mensaje de lista vacía',
        (tester) async {
      await pumpFicha(tester, _servicio());

      expect(find.byKey(K.servicioPersonalSection), findsOneWidget);
      expect(
        find.text('Todavía no hay nadie inscrito ni convocado.'),
        findsOneWidget,
      );
    });
  });

  // ── A10: atajo de fichaje / asistencia ──────────────────────────────────
  group('A10 atajo fichaje/asistencia', () {
    testWidgets(
        'rol de solo-consulta ve "Asistencia" y un botón secundario '
        '"Ver asistencia"', (tester) async {
      await pumpFicha(
        tester,
        _servicio(estado: EstadoServicio.activo),
        currentUser: _secretario,
      );

      // Encabezado del bloque y label del botón.
      expect(find.text('Asistencia'), findsOneWidget);
      expect(find.text('Fichaje'), findsNothing);
      final boton = find.byKey(K.servicioFichaFichajeAccesoBtn);
      expect(boton, findsOneWidget);
      // La variante de solo-consulta usa un botón secundario, no el primario.
      expect(
        tester.widget(boton),
        isA<AppSecondaryButton>(),
      );
      expect(find.text('Ver asistencia'), findsOneWidget);
    });

    testWidgets('rol que sí puede fichar conserva "Fichaje" y botón primario',
        (tester) async {
      // jefe_equipo puede fichar (hereda fichaje.fichar_propio) en activo.
      const jefeEquipo = CurrentUser(
        sub: 'j',
        email: 'j@e',
        roles: ['jefe_equipo'],
      );
      await pumpFicha(
        tester,
        _servicio(estado: EstadoServicio.activo),
        currentUser: jefeEquipo,
      );

      // La ficha de un mando es más larga (acciones de convocar/cerrar), así
      // que el atajo de fichaje queda al final del ListView (lazy): hay que
      // desplazarse hasta él antes de comprobarlo.
      final boton = find.byKey(K.servicioFichaFichajeAccesoBtn);
      await tester.scrollUntilVisible(
        boton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Fichaje'), findsOneWidget);
      expect(tester.widget(boton), isA<AppPrimaryButton>());
      expect(find.text('Fichar entrada / salida'), findsOneWidget);
    });

    testWidgets('el atajo no se muestra en servicios en borrador',
        (tester) async {
      await pumpFicha(
        tester,
        _servicio(estado: EstadoServicio.borrador),
        currentUser: _secretario,
      );

      expect(find.byKey(K.servicioFichaFichajeAccesoBtn), findsNothing);
      expect(find.text('Asistencia'), findsNothing);
    });
  });
}
