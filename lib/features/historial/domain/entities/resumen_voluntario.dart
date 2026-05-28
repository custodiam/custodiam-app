// Resumen agregado del voluntario (US-02-06 / CU-13). El backend
// calcula `horas_totales` y `segundos_totales` desde la tabla
// `fichajes` (fuente canónica), no agregando los eventos del audit
// log. `servicios_realizados` cuenta SOLO servicios en estado
// `cerrado`. `ultimoServicio` es `null` si el voluntario aún no ha
// participado en ningún servicio cerrado.

class UltimoServicioResumen {
  final String servicioId;
  final String titulo;
  final DateTime fechaInicio;

  const UltimoServicioResumen({
    required this.servicioId,
    required this.titulo,
    required this.fechaInicio,
  });
}

class ResumenVoluntario {
  final int horasTotales;
  final int segundosTotales;
  final int serviciosRealizados;
  final UltimoServicioResumen? ultimoServicio;

  const ResumenVoluntario({
    required this.horasTotales,
    required this.segundosTotales,
    required this.serviciosRealizados,
    required this.ultimoServicio,
  });
}
