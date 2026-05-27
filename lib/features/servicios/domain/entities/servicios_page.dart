// One page of a paginated servicios listing (US-03-07). [total] is
// the value the API reports in `X-Total-Count`.

import 'servicio_summary.dart';

class ServiciosPage {
  final List<ServicioSummary> items;
  final int total;

  const ServiciosPage({required this.items, required this.total});
}
