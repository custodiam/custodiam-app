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
  static const Key drawerAdministracionTile =
      ValueKey('drawer_administracion_tile');
  static const Key drawerRgpdTile = ValueKey('drawer_rgpd_tile');
  static const Key drawerDocumentalTile = ValueKey('drawer_documental_tile');
  static const Key drawerEconomicoTile = ValueKey('drawer_economico_tile');

  // ---- Home (dashboard básico tras login) -------------------------------
  static const Key homeGreeting = ValueKey('home_greeting');
  static const Key homeBannerMando = ValueKey('home_banner_mando');
  static const Key homeQuickActionDisponibilidad =
      ValueKey('home_quick_action_disponibilidad');
  static const Key homeQuickActionServicios =
      ValueKey('home_quick_action_servicios');
  static const Key homeQuickActionEmergencia =
      ValueKey('home_quick_action_emergencia');
  static const Key homeTitle = ValueKey('home_title');

  // ---- Inventario — Alta material ---------------------------------------
  static const Key altaMaterialNombre = ValueKey('alta_material_nombre');
  static const Key altaMaterialCantidad = ValueKey('alta_material_cantidad');
  static const Key altaMaterialUbicacion = ValueKey('alta_material_ubicacion');
  static const Key altaMaterialDescripcion =
      ValueKey('alta_material_descripcion');
  static const Key altaMaterialCodigo = ValueKey('alta_material_codigo');
  static const Key altaMaterialNumeroSerie =
      ValueKey('alta_material_numero_serie');
  static const Key altaMaterialCategoria = ValueKey('alta_material_categoria');
  static const Key altaMaterialSubmit = ValueKey('alta_material_submit');
  static const Key altaMaterialCancel = ValueKey('alta_material_cancel');
  static Key altaMaterialTipoChip(String wire) =>
      ValueKey('alta_material_tipo_$wire');

  // ---- Inventario — Alta vehículo ---------------------------------------
  static const Key altaVehiculoCodigo = ValueKey('alta_vehiculo_codigo');
  static const Key altaVehiculoMatricula = ValueKey('alta_vehiculo_matricula');
  static const Key altaVehiculoUbicacion = ValueKey('alta_vehiculo_ubicacion');
  static const Key altaVehiculoMarcaModelo =
      ValueKey('alta_vehiculo_marca_modelo');
  static const Key altaVehiculoItv = ValueKey('alta_vehiculo_itv');
  static const Key altaVehiculoObservaciones =
      ValueKey('alta_vehiculo_observaciones');
  static const Key altaVehiculoSubmit = ValueKey('alta_vehiculo_submit');
  static const Key altaVehiculoCancel = ValueKey('alta_vehiculo_cancel');
  static Key altaVehiculoTipoChip(String wire) =>
      ValueKey('alta_vehiculo_tipo_$wire');

  // ---- Inventario — Ficha material --------------------------------------
  static const Key materialFichaRefresh = ValueKey('material_ficha_refresh');
  static const Key materialFichaAbrirMapaBtn =
      ValueKey('material_ficha_abrir_mapa');
  static const Key materialFichaAsignarPersonal =
      ValueKey('material_ficha_asignar_personal');
  static const Key materialFichaPrestar = ValueKey('material_ficha_prestar');
  static const Key materialFichaDevolver = ValueKey('material_ficha_devolver');
  static const Key materialFichaAveria = ValueKey('material_ficha_averia');
  static const Key materialFichaPerdida = ValueKey('material_ficha_perdida');

  // ---- Inventario — Ficha material (diálogo asignar) --------------------
  static const Key materialAsignarVoluntarioSelector =
      ValueKey('material_asignar_voluntario_selector');
  static const Key materialAsignarCantidad =
      ValueKey('material_asignar_cantidad');
  static const Key materialAsignarConfirm =
      ValueKey('material_asignar_confirm');

  // ---- Inventario — Ficha material (diálogo devolver) ------------------
  static const Key materialDevolverVoluntarioSelector =
      ValueKey('material_devolver_voluntario_selector');
  static const Key materialDevolverObservaciones =
      ValueKey('material_devolver_observaciones');
  static const Key materialDevolverConfirm =
      ValueKey('material_devolver_confirm');

  // ---- Inventario — Ficha material (diálogo incidencia) ----------------
  static const Key materialIncidenciaDescripcion =
      ValueKey('material_incidencia_descripcion');
  static const Key materialIncidenciaConfirm =
      ValueKey('material_incidencia_confirm');

  // ---- Inventario — Ficha vehículo --------------------------------------
  static const Key vehiculoFichaRefresh = ValueKey('vehiculo_ficha_refresh');
  static const Key vehiculoFichaAbrirMapaBtn =
      ValueKey('vehiculo_ficha_abrir_mapa');
  static const Key vehiculoFichaAveria = ValueKey('vehiculo_ficha_averia');
  static const Key vehiculoFichaPerdida = ValueKey('vehiculo_ficha_perdida');

  // ---- Inventario — Ficha vehículo (diálogo incidencia) ----------------
  static const Key vehiculoIncidenciaDescripcion =
      ValueKey('vehiculo_incidencia_descripcion');
  static const Key vehiculoIncidenciaConfirm =
      ValueKey('vehiculo_incidencia_confirm');

  // ---- Inventario — Listado ---------------------------------------------
  static const Key inventarioAltaMenu = ValueKey('inventario_alta_menu');
  static const Key inventarioMaterialSearch =
      ValueKey('inventario_material_search');
  static const Key inventarioMaterialListView =
      ValueKey('inventario_material_list_view');
  static Key inventarioMaterialItem(String materialId) =>
      ValueKey('inventario_material_item_$materialId');
  static const Key inventarioVehiculoSearch =
      ValueKey('inventario_vehiculo_search');
  static const Key inventarioVehiculoListView =
      ValueKey('inventario_vehiculo_list_view');
  static Key inventarioVehiculoItem(String vehiculoId) =>
      ValueKey('inventario_vehiculo_item_$vehiculoId');
  static Key inventarioMaterialAccionesBtn(String materialId) =>
      ValueKey('inventario_material_acciones_$materialId');
  static Key inventarioVehiculoAccionesBtn(String vehiculoId) =>
      ValueKey('inventario_vehiculo_acciones_$vehiculoId');
  static const Key inventarioMaterialEditarItem =
      ValueKey('inventario_material_editar_item');
  static const Key inventarioMaterialBorrarItem =
      ValueKey('inventario_material_borrar_item');
  static const Key inventarioVehiculoEditarItem =
      ValueKey('inventario_vehiculo_editar_item');
  static const Key inventarioVehiculoBorrarItem =
      ValueKey('inventario_vehiculo_borrar_item');

  // ---- Inventario — Crear ubicación (diálogo) ---------------------------
  static const Key crearUbicacionNombre = ValueKey('crear_ubicacion_nombre');
  static const Key crearUbicacionDescripcion =
      ValueKey('crear_ubicacion_descripcion');
  static const Key crearUbicacionSubmit = ValueKey('crear_ubicacion_submit');
  static const Key crearUbicacionCancel = ValueKey('crear_ubicacion_cancel');

  // ---- Inventario — Gestión de ubicaciones (E10) ------------------------
  static const Key ubicacionesSearch = ValueKey('ubicaciones_search');
  static const Key ubicacionesListView = ValueKey('ubicaciones_list_view');
  static const Key ubicacionesNuevaBtn = ValueKey('ubicaciones_nueva');
  static Key ubicacionItem(String id) => ValueKey('ubicacion_item_$id');
  static Key ubicacionAccionesBtn(String id) =>
      ValueKey('ubicacion_acciones_$id');
  static const Key ubicacionFormNombre = ValueKey('ubicacion_form_nombre');
  static const Key ubicacionFormDescripcion =
      ValueKey('ubicacion_form_descripcion');
  static const Key ubicacionFormMapaBtn = ValueKey('ubicacion_form_mapa');
  static const Key ubicacionFormSubmit = ValueKey('ubicacion_form_submit');

  // ---- Inventario — Dotación vehículo -----------------------------------
  static const Key dotacionAnadir = ValueKey('dotacion_anadir');
  static const Key dotacionMaterialId = ValueKey('dotacion_material_id');
  static const Key dotacionCantidad = ValueKey('dotacion_cantidad');
  static const Key dotacionAnadirConfirm =
      ValueKey('dotacion_anadir_confirm');
  static const Key dotacionQuitarConfirm =
      ValueKey('dotacion_quitar_confirm');

  // ---- Servicios — Alta servicio ----------------------------------------
  static const Key altaServicioTitulo = ValueKey('alta_servicio_titulo');
  static const Key altaServicioUbicacion =
      ValueKey('alta_servicio_ubicacion');
  static const Key altaServicioUbicacionMapaBtn =
      ValueKey('alta_servicio_ubicacion_mapa');
  static const Key altaServicioQuitarCoordsBtn =
      ValueKey('alta_servicio_quitar_coords');
  static const Key altaServicioFechaInicioBtn =
      ValueKey('alta_servicio_fecha_inicio');
  static const Key altaServicioDescripcion =
      ValueKey('alta_servicio_descripcion');
  static const Key altaServicioFechaFinBtn =
      ValueKey('alta_servicio_fecha_fin');
  static const Key altaServicioNumeroVoluntarios =
      ValueKey('alta_servicio_numero_voluntarios');
  static const Key altaServicioNotasMaterial =
      ValueKey('alta_servicio_notas_material');
  static const Key altaServicioNotasVehiculos =
      ValueKey('alta_servicio_notas_vehiculos');
  static const Key altaServicioSubmitBtn = ValueKey('alta_servicio_submit');
  static const Key altaServicioCancelBtn = ValueKey('alta_servicio_cancel');
  static Key altaServicioTipoChip(String wire) =>
      ValueKey('alta_servicio_tipo_$wire');

  // ---- Servicios — Listado ----------------------------------------------
  static const Key serviciosListFiltroFechasBtn =
      ValueKey('servicios_filtro_fechas_button');
  static const Key serviciosListRefreshBtn =
      ValueKey('servicios_refresh_button');
  static const Key serviciosListSearchField =
      ValueKey('servicios_search_field');
  static const Key serviciosListView = ValueKey('servicios_list_view');
  static const Key serviciosListAltaBtn = ValueKey('servicios_alta_button');
  static const Key serviciosListFilterTodosChip =
      ValueKey('servicios_filter_todos');
  static const Key serviciosListFilterPublicadoChip =
      ValueKey('servicios_filter_publicado');
  static const Key serviciosListFilterActivoChip =
      ValueKey('servicios_filter_activo');
  static const Key serviciosListFilterBorradorChip =
      ValueKey('servicios_filter_borrador');
  static const Key serviciosListFilterCerradoChip =
      ValueKey('servicios_filter_cerrado');
  static const Key serviciosListRangoActivoChip =
      ValueKey('servicios_chip_rango_activo');
  static Key serviciosListItem(String servicioId) =>
      ValueKey('servicios_item_$servicioId');

  // ---- Servicios — Ficha detalle ----------------------------------------
  static const Key servicioFichaRefreshBtn =
      ValueKey('servicio_ficha_refresh');
  static const Key servicioFichaAbrirMapaBtn =
      ValueKey('servicio_ficha_abrir_mapa');
  static const Key servicioFichaApuntarseBtn =
      ValueKey('servicio_ficha_apuntarse_button');
  static const Key servicioFichaDesapuntarseBtn =
      ValueKey('servicio_ficha_desapuntarse_button');
  static const Key servicioFichaPublicarBtn =
      ValueKey('servicio_ficha_publicar_button');
  static const Key servicioFichaConvocarBtn =
      ValueKey('servicio_ficha_convocar_button');
  static const Key servicioFichaCerrarBtn =
      ValueKey('servicio_ficha_cerrar_button');
  static const Key servicioFichaCerrarObservacionesField =
      ValueKey('servicio_ficha_cerrar_observaciones');
  static const Key servicioFichaCerrarConfirmBtn =
      ValueKey('servicio_ficha_cerrar_confirm');
  static const Key servicioFichaFichajeAccesoBtn =
      ValueKey('servicio_ficha_fichaje_acceso');
  static const Key servicioFichaEditarBtn =
      ValueKey('servicio_ficha_editar');
  static const Key servicioFichaBorrarBtn =
      ValueKey('servicio_ficha_borrar');
  static const Key servicioFichaInscritoChip =
      ValueKey('servicio_ficha_inscrito_chip');

  // ---- Servicios — Personal del servicio (A9) ---------------------------
  static const Key servicioPersonalSection =
      ValueKey('servicio_personal_section');
  static Key servicioPersonalItem(String voluntarioId) =>
      ValueKey('servicio_personal_item_$voluntarioId');

  // ---- Servicios — Recursos asignados -----------------------------------
  static const Key servicioRecursosAnadirBtn = ValueKey('recursos_anadir');
  static const Key servicioRecursosTipoMaterialBtn =
      ValueKey('recursos_tipo_material');
  static const Key servicioRecursosTipoVehiculoBtn =
      ValueKey('recursos_tipo_vehiculo');
  static const Key servicioRecursosCantidadField =
      ValueKey('recursos_cantidad');
  static const Key servicioRecursosCantidadConfirmBtn =
      ValueKey('recursos_cantidad_confirm');

  // ---- Voluntarios — Ficha admin ----------------------------------------
  static const Key voluntarioFichaRefreshButton =
      ValueKey('voluntario_ficha_refresh');
  static const Key voluntarioFichaDarBajaButton = ValueKey('ficha_dar_baja');
  static const Key voluntarioFichaAnonimizarButton =
      ValueKey('ficha_anonimizar');
  static const Key voluntarioFichaNombreField = ValueKey('ficha_nombre');
  static const Key voluntarioFichaTelefonoField = ValueKey('ficha_telefono');
  static const Key voluntarioFichaMunicipioField = ValueKey('ficha_municipio');
  static const Key voluntarioFichaFechaNacimientoField =
      ValueKey('ficha_fecha_nacimiento');
  static const Key voluntarioFichaDniField = ValueKey('ficha_dni');
  static const Key voluntarioFichaEmailField = ValueKey('ficha_email');
  static const Key voluntarioFichaDireccionField = ValueKey('ficha_direccion');
  static const Key voluntarioFichaFotoField = ValueKey('ficha_foto');
  static const Key voluntarioFichaConductorSwitch =
      ValueKey('ficha_conductor');
  static const Key voluntarioFichaEstadoDropdown = ValueKey('ficha_estado');
  static const Key voluntarioFichaSaveButton = ValueKey('ficha_save');
  static const Key voluntarioFichaRolSelectorDropdown =
      ValueKey('ficha_rol_selector');
  static const Key voluntarioFichaRolAsignarButton =
      ValueKey('ficha_rol_asignar');
  static Key voluntarioFichaRolChip(String rolId) =>
      ValueKey('ficha_rol_chip_$rolId');

  // ---- Voluntarios — Listado --------------------------------------------
  static const Key voluntariosListAltaButton =
      ValueKey('voluntarios_alta_button');
  static const Key voluntariosListRefreshButton =
      ValueKey('voluntarios_refresh_button');
  static const Key voluntariosListSearchField =
      ValueKey('voluntarios_search_field');
  static const Key voluntariosListListView =
      ValueKey('voluntarios_list_view');
  static const Key voluntariosListFilterTodosChip =
      ValueKey('voluntarios_filter_todos');
  static const Key voluntariosListFilterActivosChip =
      ValueKey('voluntarios_filter_activos');
  static const Key voluntariosListFilterBajaChip =
      ValueKey('voluntarios_filter_baja');
  static const Key voluntariosListFilterSuspendidosChip =
      ValueKey('voluntarios_filter_suspendidos');
  static Key voluntariosListItem(String voluntarioId) =>
      ValueKey('voluntarios_item_$voluntarioId');

  // ---- Voluntarios — Mi perfil ------------------------------------------
  static const Key miPerfilRefreshButton =
      ValueKey('mi_perfil_refresh_button');
  static const Key miPerfilTileHoras = ValueKey('mi_perfil_tile_horas');
  static const Key miPerfilTileDisponibilidad =
      ValueKey('mi_perfil_tile_disponibilidad');
  static const Key miPerfilTileHistorial =
      ValueKey('mi_perfil_tile_historial');
  static const Key miPerfilEditButton = ValueKey('mi_perfil_edit_button');

  // ---- Voluntarios — Editar mi perfil -----------------------------------
  static const Key editarMiPerfilTelefonoField =
      ValueKey('editar_perfil_telefono');
  static const Key editarMiPerfilEmailField = ValueKey('editar_perfil_email');
  static const Key editarMiPerfilMunicipioField =
      ValueKey('editar_perfil_municipio');
  static const Key editarMiPerfilDireccionField =
      ValueKey('editar_perfil_direccion');
  static const Key editarMiPerfilFotoField = ValueKey('editar_perfil_foto');
  static const Key editarMiPerfilSubmitButton =
      ValueKey('editar_perfil_submit');
  static const Key editarMiPerfilCancelButton =
      ValueKey('editar_perfil_cancel');

  // ---- Voluntarios — Alta -----------------------------------------------
  static const Key altaVoluntarioNombreField = ValueKey('alta_nombre');
  static const Key altaVoluntarioTelefonoField = ValueKey('alta_telefono');
  static const Key altaVoluntarioMunicipioField = ValueKey('alta_municipio');
  static const Key altaVoluntarioFechaNacimientoField =
      ValueKey('alta_fecha_nacimiento');
  static const Key altaVoluntarioDniField = ValueKey('alta_dni');
  static const Key altaVoluntarioEmailField = ValueKey('alta_email');
  static const Key altaVoluntarioDireccionField = ValueKey('alta_direccion');
  static const Key altaVoluntarioFotoField = ValueKey('alta_foto');
  static const Key altaVoluntarioConductorSwitch = ValueKey('alta_conductor');
  static const Key altaVoluntarioSubmitButton = ValueKey('alta_submit');
  static const Key altaVoluntarioCancelButton = ValueKey('alta_cancel');

  // ---- Core UI — Location picker (mapas) --------------------------------
  static const Key locationPickerConfirmarAppBarBtn =
      ValueKey('location_picker_confirmar');
  static const Key locationPickerDireccionField =
      ValueKey('location_picker_direccion');
  static const Key locationPickerRecargarBtn =
      ValueKey('location_picker_recargar');
  static const Key locationPickerConfirmarBtn =
      ValueKey('location_picker_confirmar_btn');
  static const Key locationPickerMantenerBtn =
      ValueKey('location_picker_mantener');
  static const Key locationPickerUsarSugerenciaBtn =
      ValueKey('location_picker_usar_sugerencia');

  // ---- Core UI — Catalog search picker (inputs) -------------------------
  static const Key catalogSearchField = ValueKey('catalog_search_field');
  static const Key catalogCreateBtn = ValueKey('catalog_create');

  // ---- Fichaje — Mis horas ----------------------------------------------
  static const Key misHorasRefresh = ValueKey('mis_horas_refresh');

  // ---- Fichaje — En servicio --------------------------------------------
  static const Key fichajeEnServicioSalidaButton =
      ValueKey('fichaje_salida_button');
  static const Key fichajeEnServicioEntradaButton =
      ValueKey('fichaje_entrada_button');
  static const Key fichajeEnServicioVoluntariosRefresh =
      ValueKey('voluntarios_fichados_refresh');
  static Key fichajeEnServicioVoluntarioItem(String fichajeId) =>
      ValueKey('voluntarios_fichados_item_$fichajeId');

  // ---- Disponibilidad — Mi disponibilidad -------------------------------
  static const Key miDisponibilidadRefresh =
      ValueKey('mi_disponibilidad_refresh');
  static const Key miDisponibilidadPrevMonth =
      ValueKey('mi_disponibilidad_prev_month');
  static const Key miDisponibilidadNextMonth =
      ValueKey('mi_disponibilidad_next_month');
  static Key miDisponibilidadDia(int dia) =>
      ValueKey('mi_disponibilidad_dia_$dia');

  // ---- Historial — Mi historial -----------------------------------------
  static const Key miHistorialFiltroFechas =
      ValueKey('mi_historial_filtro_fechas');
  static const Key miHistorialRefresh = ValueKey('mi_historial_refresh');
  static const Key miHistorialChipRangoActivo =
      ValueKey('mi_historial_chip_rango_activo');
  static const Key miHistorialFiltroTodos =
      ValueKey('mi_historial_filtro_todos');
  static Key miHistorialFiltroTipo(String wire) =>
      ValueKey('mi_historial_filtro_$wire');

  // ---- Notificaciones — Ajustes -----------------------------------------
  static const Key notifAjustesEmergencias =
      ValueKey('notif_ajustes_emergencias');
  static const Key notifAjustesNuevosServicios =
      ValueKey('notif_ajustes_nuevos_servicios');
  static const Key notifAjustesRecordatorios =
      ValueKey('notif_ajustes_recordatorios');
}
