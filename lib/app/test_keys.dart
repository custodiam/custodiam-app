// Catálogo central de ValueKey estables del proyecto. ADR-028.
//
// Importado tanto por widgets de producción (lib/features/**) como por
// widget tests (test/**) y tests E2E Patrol (patrol_test/**). El símbolo
// es la única fuente del string de cada key: la page lo aplica al
// construir el widget y el test lo localiza con find.byKey.
//
// Convención de nombres: K.<scope><Element> en camelCase. Para listas
// parametrizadas, factory function (`K.servicioCard(int index)`).

import 'package:flutter/foundation.dart';

abstract final class K {
  K._();

  // ---- Shell de navegación (BottomAppBar custom) -------------------------
  static const Key shellDrawerButton = ValueKey('shell_drawer_button');
  static const Key shellHomeButton = ValueKey('shell_home_button');
  static const Key shellServiciosButton = ValueKey('shell_servicios_button');
  static const Key shellInventarioButton = ValueKey('shell_inventario_button');
  static const Key shellAvatarButton = ValueKey('shell_avatar_button');

  // ---- Drawer lateral (todas las secciones) -----------------------------
  static const Key drawerHomeTile = ValueKey('drawer_home_tile');
  static const Key drawerVoluntariosTile = ValueKey('drawer_voluntarios_tile');
  static const Key drawerServiciosTile = ValueKey('drawer_servicios_tile');
  static const Key drawerInventarioTile = ValueKey('drawer_inventario_tile');
  static const Key drawerMiPerfilTile = ValueKey('drawer_mi_perfil_tile');
  static const Key drawerNotificacionesTile = ValueKey('drawer_notificaciones_tile');
  static const Key drawerSettingsTile = ValueKey('drawer_settings_tile');
  static const Key drawerLogoutTile = ValueKey('drawer_logout_tile');

  // ---- Home (dashboard básico tras login) -------------------------------
  static const Key homeGreeting = ValueKey('home_greeting');
  static const Key homeBannerMando = ValueKey('home_banner_mando');
  static const Key homeQuickActionDisponibilidad =
      ValueKey('home_quick_action_disponibilidad');
  static const Key homeQuickActionServicios =
      ValueKey('home_quick_action_servicios');
}
