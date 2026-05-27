import 'dart:developer' as dev;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:custodiam/app/app.dart';
import 'package:custodiam/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // EN-08-34 capa 3: Flutter Web usa HashUrlStrategy por defecto, lo que
  // hace que GoRouter no matchee `/callback` cuando Keycloak redirige a
  // http://host/callback?code=...  — la app arranca limpia en `/` y el
  // `_CallbackHandler` nunca se ejecuta. Forzar PathUrlStrategy alinea
  // el redirect URI registrado en Keycloak con la ruta real del router.
  // La llamada es no-op en plataformas no-web (documentado en Flutter).
  usePathUrlStrategy();
  // EN-06-02: arranca Firebase antes de runApp para que FCM tenga
  // contexto de plataforma listo cuando se pida el token tras login.
  // Envuelto en try/catch porque `flutter test` ejecuta `main()` contra
  // una VM sin platform channels — Firebase rompe en VM y el smoke test
  // del bootstrap abortaría sin esta guarda. La inicialización real
  // solo ocurre en device/web; en VM la app sigue arrancando pero el
  // FcmService queda en modo deshabilitado y `RegistrarMiDispositivo`
  // se autosalta sin contactar al backend.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    dev.log(
      'Firebase.initializeApp falló (esperado en VM tests): $e',
      name: 'App',
      error: e,
      stackTrace: stack,
    );
  }
  runApp(
    const ProviderScope(
      child: CustodiamApp(),
    ),
  );
}
