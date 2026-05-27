// One page of a paginated voluntarios listing. [total] is the value
// the API reports in `X-Total-Count` so the view can decide whether
// to keep loading on scroll.

import 'voluntario_summary.dart';

class VoluntariosPage {
  final List<VoluntarioSummary> items;
  final int total;

  const VoluntariosPage({required this.items, required this.total});
}
