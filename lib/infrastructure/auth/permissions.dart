// Catálogo de permisos RBAC y mapa rol → permisos.
//
// Espeja exactamente la sección 3 de docs/trabajo/backlog/RBAC_v0.1.0.md
// y la estructura ROLE_PERMISSIONS de custodiam-api/app/core/permissions.py.
// Cuando esa matriz cambie, este módulo cambia en el mismo PR.
//
// El backend valida los permisos sobre el JWT real (require_permission).
// El frontend los espeja para decidir qué widgets mostrar — la fuente de
// verdad sigue siendo el servidor; el cliente solo evita renderizar
// botones que no van a funcionar.

enum Permission {
  // E02 — Voluntarios
  voluntariosCrear('voluntarios.crear'),
  voluntariosEditar('voluntarios.editar'),
  voluntariosEditarPropio('voluntarios.editar_propio'),
  voluntariosDisponibilidadPropia('voluntarios.disponibilidad_propia'),
  voluntariosVerPropio('voluntarios.ver_propio'),
  voluntariosDarBaja('voluntarios.dar_baja'),
  voluntariosListar('voluntarios.listar'),
  voluntariosVerFicha('voluntarios.ver_ficha'),

  // E03 — Servicios
  serviciosCrearPreventivo('servicios.crear_preventivo'),
  serviciosCrearEmergencia('servicios.crear_emergencia'),
  serviciosPublicar('servicios.publicar'),
  serviciosConvocar('servicios.convocar'),
  serviciosVerPublicados('servicios.ver_publicados'),
  serviciosApuntarsePropio('servicios.apuntarse_propio'),
  serviciosDesapuntarsePropio('servicios.desapuntarse_propio'),
  serviciosCerrar('servicios.cerrar'),

  // E04 — Fichaje
  fichajeFicharPropio('fichaje.fichar_propio'),
  fichajeVerPropio('fichaje.ver_propio'),
  fichajeVerVoluntariosEnServicio('fichaje.ver_voluntarios_en_servicio'),

  // E05 — Inventario
  inventarioRegistrarMaterial('inventario.registrar_material'),
  inventarioRegistrarVehiculo('inventario.registrar_vehiculo'),
  inventarioAsignarEquipamientoPersonal(
      'inventario.asignar_equipamiento_personal'),
  inventarioPrestarTemporal('inventario.prestar_temporal'),
  inventarioRegistrarDevolucion('inventario.registrar_devolucion'),
  inventarioAsignarAServicio('inventario.asignar_a_servicio'),
  inventarioReportarIncidencia('inventario.reportar_incidencia'),
  inventarioVer('inventario.ver'),

  // E06 — Notificaciones
  notificacionesRecibirEmergencia('notificaciones.recibir_emergencia'),
  notificacionesRecibirNuevoServicio('notificaciones.recibir_nuevo_servicio'),
  notificacionesConfigurarPropias('notificaciones.configurar_propias'),
  notificacionesRegistrarToken('notificaciones.registrar_token'),

  // E07 — Offline
  offlineConsultarServicios('offline.consultar_servicios'),
  offlineFicharPropio('offline.fichar_propio'),
  offlineVerEstadoConexion('offline.ver_estado_conexion'),

  // Administración del sistema
  sistemaPanelAdmin('sistema.panel_admin'),
  sistemaConfiguracion('sistema.configuracion'),
  sistemaLogsAuditoria('sistema.logs_auditoria'),
  sistemaExportarRgpd('sistema.exportar_rgpd'),
  sistemaBackups('sistema.backups'),
  economicoGestionar('economico.gestionar'),
  documentalGestionar('documental.gestionar');

  const Permission(this.value);

  /// Identificador textual; coincide con el value del StrEnum del backend.
  /// Sirve para comparar contra la lista que devuelve /me/permissions
  /// y para que aparezca tal cual en logs.
  final String value;

  static Permission? fromString(String value) {
    for (final p in Permission.values) {
      if (p.value == value) return p;
    }
    return null;
  }
}

// Conjuntos base reutilizados por varios roles.

const _todosLosOperativosBase = <Permission>{
  Permission.voluntariosEditarPropio,
  Permission.voluntariosDisponibilidadPropia,
  Permission.voluntariosVerPropio,
  Permission.serviciosVerPublicados,
  Permission.serviciosApuntarsePropio,
  Permission.serviciosDesapuntarsePropio,
  Permission.fichajeFicharPropio,
  Permission.fichajeVerPropio,
  Permission.inventarioReportarIncidencia,
  Permission.notificacionesRecibirEmergencia,
  Permission.notificacionesRecibirNuevoServicio,
  Permission.notificacionesConfigurarPropias,
  Permission.notificacionesRegistrarToken,
  Permission.offlineConsultarServicios,
  Permission.offlineFicharPropio,
  Permission.offlineVerEstadoConexion,
};

const _baseVoluntario = <Permission>{
  ..._todosLosOperativosBase,
  Permission.voluntariosListar,
};

const _baseJefeEquipo = <Permission>{
  ..._baseVoluntario,
  Permission.voluntariosVerFicha,
  Permission.serviciosCrearPreventivo,
  Permission.serviciosCrearEmergencia,
  Permission.serviciosPublicar,
  Permission.serviciosConvocar,
  Permission.serviciosCerrar,
  Permission.fichajeVerVoluntariosEnServicio,
  Permission.inventarioRegistrarMaterial,
  Permission.inventarioPrestarTemporal,
  Permission.inventarioRegistrarDevolucion,
  Permission.inventarioAsignarAServicio,
  Permission.inventarioVer,
};

const _baseJefeSeccion = <Permission>{
  ..._baseJefeEquipo,
  Permission.inventarioAsignarEquipamientoPersonal,
};

const _baseJefeUnidad = <Permission>{
  ..._baseJefeSeccion,
  Permission.inventarioRegistrarVehiculo,
};

const _baseSubjefe = <Permission>{
  ..._baseJefeUnidad,
  Permission.voluntariosCrear,
  Permission.voluntariosEditar,
  Permission.voluntariosDarBaja,
};

const _baseJefeAgrupacion = <Permission>{
  ..._baseSubjefe,
  Permission.sistemaLogsAuditoria,
  Permission.sistemaExportarRgpd,
  Permission.economicoGestionar,
  Permission.documentalGestionar,
};

// Coordinador equivale a jefe_agrupacion (decisión 2 del documento RBAC).
const _baseCoordinador = _baseJefeAgrupacion;

const _baseSecretario = <Permission>{
  Permission.voluntariosCrear,
  Permission.voluntariosEditar,
  Permission.voluntariosEditarPropio,
  Permission.voluntariosVerPropio,
  Permission.voluntariosDarBaja,
  Permission.voluntariosListar,
  Permission.voluntariosVerFicha,
  Permission.serviciosCrearPreventivo,
  Permission.serviciosVerPublicados,
  Permission.fichajeVerVoluntariosEnServicio,
  Permission.inventarioRegistrarMaterial,
  Permission.inventarioRegistrarVehiculo,
  Permission.inventarioRegistrarDevolucion,
  Permission.inventarioReportarIncidencia,
  Permission.inventarioVer,
  Permission.notificacionesRecibirEmergencia,
  Permission.notificacionesRecibirNuevoServicio,
  Permission.notificacionesConfigurarPropias,
  Permission.notificacionesRegistrarToken,
  Permission.offlineVerEstadoConexion,
  Permission.sistemaExportarRgpd,
  Permission.documentalGestionar,
};

const _baseTesorero = <Permission>{
  Permission.voluntariosEditarPropio,
  Permission.voluntariosVerPropio,
  Permission.voluntariosListar,
  Permission.voluntariosVerFicha,
  Permission.serviciosVerPublicados,
  Permission.inventarioReportarIncidencia,
  Permission.inventarioVer,
  Permission.notificacionesRecibirEmergencia,
  Permission.notificacionesRecibirNuevoServicio,
  Permission.notificacionesConfigurarPropias,
  Permission.notificacionesRegistrarToken,
  Permission.offlineVerEstadoConexion,
  Permission.economicoGestionar,
};

const _baseAdmin = <Permission>{
  Permission.notificacionesConfigurarPropias,
  Permission.notificacionesRegistrarToken,
  Permission.offlineVerEstadoConexion,
  Permission.sistemaPanelAdmin,
  Permission.sistemaConfiguracion,
  Permission.sistemaLogsAuditoria,
  Permission.sistemaExportarRgpd,
  Permission.sistemaBackups,
};

/// Mapa rol Keycloak → conjunto de permisos. Lockstep con
/// ``ROLE_PERMISSIONS`` del backend.
const Map<String, Set<Permission>> kRolePermissions = {
  'voluntario_practicas': _todosLosOperativosBase,
  'voluntario': _baseVoluntario,
  'jefe_equipo': _baseJefeEquipo,
  'jefe_grupo': _baseJefeEquipo,
  'jefe_seccion': _baseJefeSeccion,
  'jefe_unidad': _baseJefeUnidad,
  'subjefe_agrupacion': _baseSubjefe,
  'jefe_agrupacion': _baseJefeAgrupacion,
  'coordinador': _baseCoordinador,
  'secretario': _baseSecretario,
  'tesorero': _baseTesorero,
  'admin': _baseAdmin,
};

/// Unión de permisos de todos los roles de un usuario. Roles que no
/// aparecen en el mapa se ignoran silenciosamente.
Set<Permission> permissionsForRoles(List<String> roles) {
  final result = <Permission>{};
  for (final role in roles) {
    final perms = kRolePermissions[role];
    if (perms != null) result.addAll(perms);
  }
  return result;
}
