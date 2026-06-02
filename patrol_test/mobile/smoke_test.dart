// Smoke E2E móvil (guía 36 / ADR-024).
//
// Valida que el pipeline Patrol nativo arranca la app REAL en el
// dispositivo Android y llega a la pantalla de login. Deliberadamente NO
// toca el backend: fuerza una sesión inexistente (authServiceProvider
// sobreescrito) para aislar el arranque del runner nativo (PatrolJUnitRunner
// + MainActivityTest) de cualquier dependencia de red. Es el primer test que
// debe pasar tras el bootstrap; los flujos de negocio (login real, crear
// servicio/material) corren contra el backend en los demás ficheros de
// patrol_test/mobile/.

import 'package:custodiam/app/app.dart';
import 'package:custodiam/features/notificaciones/data/datasources/fcm_service_unavailable.dart';
import 'package:custodiam/features/notificaciones/presentation/viewmodels/notificaciones_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol/patrol.dart';

import '../support/patrol_bootstrap.dart';

class _UnauthenticatedAuthService extends Mock implements AuthService {}

void main() {
  patrolTest('the app boots on device and lands on the login screen',
      ($) async {
    // Mismo bootstrap no-dependiente-de-plataforma que lib/main.dart, para que
    // los flujos que sigan a este smoke pinten pantallas con DateFormat(..,
    // 'es_ES') sin LocaleDataException.
    await bootstrapPatrolApp();

    final auth = _UnauthenticatedAuthService();
    when(() => auth.init()).thenAnswer((_) async {});
    when(() => auth.isAuthenticated).thenReturn(false);
    when(() => auth.accessToken).thenReturn(null);
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.authStateListenable).thenReturn(ValueNotifier(false));
    when(() => auth.consumeExpiredFlag()).thenReturn(false);

    await $.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          // Aislamiento explícito de FCM: sin Firebase inicializado el
          // FcmBootstrap caería igualmente al fallback, pero lo fijamos para
          // no depender de ese comportamiento de runtime (ni de que
          // FirebaseMessaging.instance lance sin init en cada device/imagen).
          fcmServiceProvider.overrideWithValue(const FcmServiceUnavailable()),
        ],
        child: const CustodiamApp(),
      ),
    );
    await $.pumpAndSettle();

    // AppStartupUseCase, al no haber sesión, enruta a /login.
    expect($('Iniciar sesión'), findsOneWidget);
  });
}
