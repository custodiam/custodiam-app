// Verifica el manejo de mensajes FCM en PRIMER PLANO por FcmBootstrap:
// - una emergencia dispara la notificación local heads-up (el bug previo
//   era que el foreground no mostraba nada porque el SnackBar se resolvía
//   contra un context por encima del MaterialApp, sin ScaffoldMessenger);
// - cualquier mensaje muestra el SnackBar vía el messenger global;
// - un servicio normal NO dispara la notificación local de emergencia;
// - el servicio local se inicializa al montar con el callback de tap.
// Widget test headless, sin dispositivo ni platform channels.

import 'dart:async';

import 'package:custodiam/app/scaffold_messenger_provider.dart';
import 'package:custodiam/core/ui/theme/app_theme.dart';
import 'package:custodiam/features/notificaciones/data/datasources/local_notifications_service.dart';
import 'package:custodiam/features/notificaciones/domain/entities/notificacion_payload.dart';
import 'package:custodiam/features/notificaciones/domain/repositories/notificaciones_repository.dart';
import 'package:custodiam/features/notificaciones/presentation/viewmodels/notificaciones_di.dart';
import 'package:custodiam/features/notificaciones/presentation/widgets/fcm_bootstrap.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements NotificacionesRepository {}

/// Fake en memoria del servicio de notificaciones locales: registra las
/// emergencias pintadas y captura el callback de tap pasado a `init`.
class _FakeLocalNotifications implements LocalNotificationsService {
  int initCalls = 0;
  void Function(String? servicioId)? capturedOnTap;
  final List<({String titulo, String cuerpo, String? servicioId})> emergencias =
      [];

  @override
  Future<void> init({
    required void Function(String? servicioId) onTapServicio,
  }) async {
    initCalls++;
    capturedOnTap = onTapServicio;
  }

  @override
  Future<void> mostrarEmergencia({
    required String titulo,
    required String cuerpo,
    String? servicioId,
  }) async {
    emergencias.add((titulo: titulo, cuerpo: cuerpo, servicioId: servicioId));
  }
}

/// AuthService no autenticado: evita que el bootstrap dispare el registro
/// de dispositivo, que no es objeto de este test.
class _UnauthAuth implements AuthService {
  final ValueNotifier<bool> _n = ValueNotifier(false);

  @override
  bool get isAuthenticated => false;
  @override
  Listenable get authStateListenable => _n;
  @override
  String? get accessToken => null;
  @override
  CurrentUser? get currentUser => null;
  @override
  Future<void> init() async {}
  @override
  bool consumeExpiredFlag() => false;
  @override
  Future<Result<void>> login() async => const Success(null);
  @override
  Future<Result<void>> logout() async => const Success(null);
  @override
  Future<Result<String>> getValidAccessToken() async => const Success('');
}

void main() {
  late StreamController<NotificacionPayload> foreground;
  late _MockRepo repo;
  late _FakeLocalNotifications local;

  setUp(() {
    foreground = StreamController<NotificacionPayload>.broadcast();
    repo = _MockRepo();
    local = _FakeLocalNotifications();
    when(() => repo.onForegroundMessage).thenAnswer((_) => foreground.stream);
    when(() => repo.onMessageOpenedApp)
        .thenAnswer((_) => const Stream<NotificacionPayload>.empty());
    when(() => repo.getInitialMessage()).thenAnswer((_) async => null);
  });

  tearDown(() => foreground.close());

  Future<void> pump(WidgetTester tester) async {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificacionesRepositoryProvider.overrideWithValue(repo),
          localNotificationsServiceProvider.overrideWithValue(local),
          scaffoldMessengerKeyProvider.overrideWithValue(messengerKey),
          authServiceProvider.overrideWithValue(_UnauthAuth()),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: messengerKey,
          theme: AppTheme.light(),
          home: const FcmBootstrap(child: Scaffold(body: SizedBox.shrink())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('emergencia en foreground pinta notificación local y SnackBar',
      (tester) async {
    await pump(tester);

    foreground.add(
      const NotificacionPayload(
        tipo: 'emergencia',
        servicioId: 's1',
        titulo: 'EMERGENCIA',
        cuerpo: 'Activación',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(local.emergencias, hasLength(1));
    expect(local.emergencias.single.titulo, 'EMERGENCIA');
    expect(local.emergencias.single.servicioId, 's1');
    expect(find.text('EMERGENCIA · Activación'), findsOneWidget);
  });

  testWidgets('servicio normal en foreground solo muestra SnackBar',
      (tester) async {
    await pump(tester);

    foreground.add(
      const NotificacionPayload(
        tipo: 'servicio',
        servicioId: 's2',
        titulo: 'Nuevo servicio',
        cuerpo: 'Mañana 10:00',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(local.emergencias, isEmpty);
    expect(find.text('Nuevo servicio · Mañana 10:00'), findsOneWidget);
  });

  testWidgets('inicializa el servicio local con el callback de tap al montar',
      (tester) async {
    await pump(tester);

    expect(local.initCalls, 1);
    expect(local.capturedOnTap, isNotNull);
  });
}
