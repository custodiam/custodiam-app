// Sección "Personal del servicio" de la ficha (A9). Lista los voluntarios
// inscritos y convocados del servicio, diferenciando ambos tipos con icono y
// texto (no solo color, guía 28 §WCAG 1.4.1). Muestra el teléfono únicamente
// cuando el backend lo devuelve no-nulo: a quien consulta sin ser mando se le
// oculta el teléfono del resto de operativos, así que la lista llega ya
// recortada y aquí solo decidimos pintarlo o no.
//
// La sección se monta gateada por `servicios.ver_publicados` (todos los
// operativos lo tienen) desde la page, así que aquí no repetimos el gate; nos
// limitamos a consumir el provider de personal y manejar loading/empty/error.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/buttons/app_text_button.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/tipo_inscripcion.dart';
import '../../domain/entities/voluntario_inscrito.dart';
import '../viewmodels/personal_servicio_view_model.dart';

class PersonalServicioSection extends ConsumerWidget {
  final String servicioId;

  const PersonalServicioSection({super.key, required this.servicioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final provider = personalServicioViewModelProvider(servicioId);
    final async = ref.watch(provider);

    return Column(
      key: K.servicioPersonalSection,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          header: true,
          child: Text('Personal del servicio', style: theme.textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: AppLoadingIndicator(),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error is Failure
                      ? (error.message ?? 'No se pudo cargar el personal.')
                      : 'No se pudo cargar el personal.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                AppTextButton(
                  label: 'Reintentar',
                  onPressed: () => ref.read(provider.notifier).refresh(),
                ),
              ],
            ),
          ),
          data: (voluntarios) {
            if (voluntarios.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Todavía no hay nadie inscrito ni convocado.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final v in voluntarios) _PersonalTile(voluntario: v),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PersonalTile extends StatelessWidget {
  final VoluntarioInscrito voluntario;

  const _PersonalTile({required this.voluntario});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Guía 28 §WCAG 1.4.1: el tipo se distingue por icono + texto, nunca
    // solo por color.
    final (IconData icon, String etiquetaTipo) =
        switch (voluntario.tipo) {
      TipoInscripcion.inscrito => (Symbols.how_to_reg, 'Inscrito'),
      TipoInscripcion.convocado => (Symbols.campaign, 'Convocado'),
    };
    final telefono = voluntario.telefono;
    // Solo se muestra el teléfono si el backend lo devolvió (es de un mando);
    // a los no-mandos llega null y no se renderiza esa línea.
    final detalle = (telefono != null && telefono.isNotEmpty)
        ? '$etiquetaTipo · $telefono'
        : etiquetaTipo;

    return Padding(
      key: K.servicioPersonalItem(voluntario.voluntarioId),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(voluntario.nombre, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
