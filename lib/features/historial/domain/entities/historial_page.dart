// Envoltorio paginado para la respuesta del historial. Combina la
// lista de eventos con el `X-Total-Count` que el backend devuelve en
// las cabeceras, para que el ViewModel pueda decidir si quedan más
// páginas sin tener que hacer una segunda llamada de count.

import 'evento_voluntario.dart';

class HistorialPage {
  final List<EventoVoluntario> eventos;
  final int total;
  final int skip;
  final int limit;

  const HistorialPage({
    required this.eventos,
    required this.total,
    required this.skip,
    required this.limit,
  });

  bool get hayMas => skip + eventos.length < total;
}
