// Bootstrap compartido para los tests E2E móviles de Patrol (guía 36).
//
// Replica la parte de lib/main.dart que NO depende de plataforma y que las
// pantallas necesitan para pintar: la estrategia de URL y los símbolos de
// locale de `intl`. Sin `initializeDateFormatting('es_ES', null)`, cualquier
// pantalla que use `DateFormat(..., 'es_ES')` lanza `LocaleDataException`, así
// que todo flujo E2E que aterrice más allá del login debe llamar a esto antes
// de bombear el árbol. Firebase NO se inicializa aquí: en los tests el
// `fcmServiceProvider` se sobreescribe con `FcmServiceUnavailable`.

import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Prepara el entorno no-dependiente-de-plataforma que `lib/main.dart` deja
/// listo antes de `runApp`. Idempotente y seguro de llamar al inicio de cada
/// `patrolTest`.
Future<void> bootstrapPatrolApp() async {
  // No-op en plataformas no-web; se mantiene por fidelidad con main.dart.
  usePathUrlStrategy();
  await initializeDateFormatting('es_ES', null);
}
