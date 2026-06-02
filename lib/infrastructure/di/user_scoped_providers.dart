// Registro central de los providers cuyo estado pertenece al usuario con
// sesión iniciada. Al cerrar sesión hay que invalidarlos para que la cuenta
// siguiente no vea datos cacheados de la anterior (el escenario "salgo de una
// cuenta y entro en otra y veo lo del usuario previo").
//
// Patrón (idiomático Riverpod): el estado de un provider keep-alive solo se
// purga si se recomputa o se invalida explícitamente. Las fichas .family
// por-id además son `.autoDispose` (se liberan al salir de la pantalla), y se
// incluyen aquí como red de seguridad redundante: `invalidate(familia)`
// invalida todas sus instancias de golpe.
//
// REGLA DE MANTENIMIENTO (ver custodiam-app/CLAUDE.md §Riverpod): todo
// AsyncNotifierProvider/Notifier nuevo que cachee datos por-usuario debe
// añadirse a esta lista en el mismo commit. El test guardián de
// `user_scoped_providers_test.dart` cubre los conocidos, pero no caza un
// provider futuro olvidado: es responsabilidad de la revisión.
//
// NO incluir aquí: preferencias de dispositivo (tema, ajustes locales en
// SharedPreferences), infraestructura de sesión (authService, apiClient,
// tokenStore) ni formularios efímeros (alta_/editar_), que parten de null.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/disponibilidad/presentation/viewmodels/mi_disponibilidad_view_model.dart';
import '../../features/fichaje/presentation/viewmodels/fichaje_en_servicio_view_model.dart';
import '../../features/fichaje/presentation/viewmodels/mis_horas_view_model.dart';
import '../../features/fichaje/presentation/viewmodels/voluntarios_fichados_view_model.dart';
import '../../features/historial/presentation/viewmodels/mi_historial_view_model.dart';
import '../../features/historial/presentation/viewmodels/mi_resumen_view_model.dart';
import '../../features/inventario/presentation/viewmodels/dotacion_vehiculo_view_model.dart';
import '../../features/inventario/presentation/viewmodels/materiales_list_view_model.dart';
import '../../features/inventario/presentation/viewmodels/material_ficha_view_model.dart';
import '../../features/inventario/presentation/viewmodels/ubicaciones_list_view_model.dart';
import '../../features/inventario/presentation/viewmodels/vehiculos_list_view_model.dart';
import '../../features/inventario/presentation/viewmodels/vehiculo_ficha_view_model.dart';
import '../../features/inventario/presentation/viewmodels/ubicaciones_di.dart';
import '../../features/notificaciones/presentation/viewmodels/notificaciones_ajustes_view_model.dart';
import '../../features/servicios/presentation/viewmodels/servicio_ficha_view_model.dart';
import '../../features/servicios/presentation/viewmodels/servicio_inventario_view_model.dart';
import '../../features/servicios/presentation/viewmodels/servicios_list_view_model.dart';
import '../../features/voluntarios/presentation/viewmodels/mi_perfil_view_model.dart';
import '../../features/voluntarios/presentation/viewmodels/voluntario_ficha_view_model.dart';
import '../../features/voluntarios/presentation/viewmodels/voluntarios_list_view_model.dart';

/// Providers con estado propiedad del usuario en sesión. Se invalidan en el
/// logout (transición autenticado → no autenticado) vía
/// [resetUserScopedProviders].
final List<ProviderOrFamily> userScopedProviders = [
  // Perfil y datos del propio voluntario.
  miPerfilViewModelProvider,
  miDisponibilidadViewModelProvider,
  misHorasViewModelProvider,
  miResumenViewModelProvider,
  miHistorialViewModelProvider,
  notificacionesAjustesViewModelProvider,
  // Listados por-usuario (paginados / filtrables).
  voluntariosListViewModelProvider,
  serviciosListViewModelProvider,
  materialesListViewModelProvider,
  vehiculosListViewModelProvider,
  ubicacionesListViewModelProvider,
  // Fichas .family por-id (además `.autoDispose`; aquí, defensa redundante:
  // invalidar la familia purga cualquier instancia que siguiera viva).
  voluntarioFichaViewModelProvider,
  servicioFichaViewModelProvider,
  servicioInventarioViewModelProvider,
  materialFichaViewModelProvider,
  vehiculoFichaViewModelProvider,
  dotacionVehiculoViewModelProvider,
  voluntariosFichadosViewModelProvider,
  fichajeEnServicioViewModelProvider,
  ubicacionPorIdProvider,
];

/// Invalida todos los [userScopedProviders]. El llamador aporta el mecanismo
/// de invalidación (`ref.invalidate` desde un widget, o
/// `container.invalidate` en tests), de modo que esta función no depende de
/// tener un `WidgetRef` ni un `ProviderContainer` concretos.
void resetUserScopedProviders(
  void Function(ProviderOrFamily provider) invalidate,
) {
  for (final provider in userScopedProviders) {
    invalidate(provider);
  }
}
