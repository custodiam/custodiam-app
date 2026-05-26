import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:custodiam/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // EN-08-34 capa 3: Flutter Web usa HashUrlStrategy por defecto, lo que
  // hace que GoRouter no matchee `/callback` cuando Keycloak redirige a
  // http://host/callback?code=...  — la app arranca limpia en `/` y el
  // `_CallbackHandler` nunca se ejecuta. Forzar PathUrlStrategy alinea
  // el redirect URI registrado en Keycloak con la ruta real del router.
  // La llamada es no-op en plataformas no-web (documentado en Flutter).
  usePathUrlStrategy();
  runApp(
    const ProviderScope(
      child: CustodiamApp(),
    ),
  );
}
