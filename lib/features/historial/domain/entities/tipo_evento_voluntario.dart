// Enum cerrado que espeja `app.models.voluntario_evento.TipoEventoVoluntario`
// del backend (EN-02-04). Los 11 valores cubren el alcance del MVP y
// ampliarlo requiere una decisión arquitectónica explícita: no se
// admite `OTRO`.

enum TipoEventoVoluntario {
  alta('alta'),
  baja('baja'),
  anonimizacion('anonimizacion'),
  cambioRolAsignado('cambio_rol_asignado'),
  cambioRolRevocado('cambio_rol_revocado'),
  fichajeEntrada('fichaje_entrada'),
  fichajeSalida('fichaje_salida'),
  inscripcionServicio('inscripcion_servicio'),
  bajaInscripcion('baja_inscripcion'),
  asignacionMaterial('asignacion_material'),
  devolucionMaterial('devolucion_material');

  const TipoEventoVoluntario(this.wire);

  /// Valor textual idéntico al StrEnum del backend.
  final String wire;

  static TipoEventoVoluntario? fromWire(String value) {
    for (final tipo in TipoEventoVoluntario.values) {
      if (tipo.wire == value) return tipo;
    }
    return null;
  }

  /// Etiqueta legible para mostrar al usuario.
  String get etiqueta {
    switch (this) {
      case TipoEventoVoluntario.alta:
        return 'Alta como voluntario';
      case TipoEventoVoluntario.baja:
        return 'Baja como voluntario';
      case TipoEventoVoluntario.anonimizacion:
        return 'Anonimización RGPD';
      case TipoEventoVoluntario.cambioRolAsignado:
        return 'Rol asignado';
      case TipoEventoVoluntario.cambioRolRevocado:
        return 'Rol revocado';
      case TipoEventoVoluntario.fichajeEntrada:
        return 'Entrada de fichaje';
      case TipoEventoVoluntario.fichajeSalida:
        return 'Salida de fichaje';
      case TipoEventoVoluntario.inscripcionServicio:
        return 'Inscripción a servicio';
      case TipoEventoVoluntario.bajaInscripcion:
        return 'Baja de inscripción';
      case TipoEventoVoluntario.asignacionMaterial:
        return 'Material asignado';
      case TipoEventoVoluntario.devolucionMaterial:
        return 'Material devuelto';
    }
  }
}
