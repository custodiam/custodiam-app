// AltaServicioPage (US-03-01 / US-03-02). Formulario para crear un
// servicio. El permiso a aplicar depende del tipo seleccionado; el
// gate de entrada acepta cualquiera de los dos (anyOf) para que el
// usuario al menos llegue, y validamos al enviar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/servicio_create.dart';
import '../../domain/entities/tipo_servicio.dart';
import '../viewmodels/alta_servicio_view_model.dart';
import '../viewmodels/servicios_list_view_model.dart';

class AltaServicioPage extends ConsumerWidget {
  const AltaServicioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate.anyOf(
      anyOf: [
        Permission.serviciosCrearPreventivo,
        Permission.serviciosCrearEmergencia,
      ],
      fallback: _ForbiddenScreen(),
      child: _AltaServicioForm(),
    );
  }
}

class _AltaServicioForm extends ConsumerStatefulWidget {
  const _AltaServicioForm();

  @override
  ConsumerState<_AltaServicioForm> createState() => _AltaServicioFormState();
}

class _AltaServicioFormState extends ConsumerState<_AltaServicioForm> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _numeroVoluntariosCtrl = TextEditingController();
  final _notasMaterialCtrl = TextEditingController();
  final _notasVehiculosCtrl = TextEditingController();
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();
  TipoServicio _tipo = TipoServicio.preventivo;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _ubicacionCtrl.dispose();
    _numeroVoluntariosCtrl.dispose();
    _notasMaterialCtrl.dispose();
    _notasVehiculosCtrl.dispose();
    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    super.dispose();
  }

  String? _normalize(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDateTime(DateTime f) {
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    final hh = f.hour.toString().padLeft(2, '0');
    final mi = f.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${f.year} $hh:$mi';
  }

  Future<DateTime?> _pickDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final base = initial ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Selecciona fecha',
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: 'Selecciona hora',
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickFechaInicio() async {
    final picked = await _pickDateTime(initial: _fechaInicio);
    if (picked == null) return;
    setState(() {
      _fechaInicio = picked;
      _fechaInicioCtrl.text = _formatDateTime(picked);
    });
  }

  Future<void> _pickFechaFin() async {
    final picked = await _pickDateTime(initial: _fechaFin ?? _fechaInicio);
    if (picked == null) return;
    setState(() {
      _fechaFin = picked;
      _fechaFinCtrl.text = _formatDateTime(picked);
    });
  }

  String? _validateRequired(String? raw, String field) {
    if (raw == null || raw.trim().isEmpty) return '$field obligatorio';
    return null;
  }

  String? _validateNumeroVoluntarios(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final n = int.tryParse(raw.trim());
    if (n == null || n < 0) return 'Número no válido';
    return null;
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fechaInicio == null) {
      AppSnackbar.show(
        context,
        message: 'Selecciona la fecha de inicio.',
        variant: AppSnackbarVariant.warning,
      );
      return;
    }
    final user = ref.read(authServiceProvider).currentUser;
    final permisoNecesario = _tipo == TipoServicio.emergencia
        ? Permission.serviciosCrearEmergencia
        : Permission.serviciosCrearPreventivo;
    if (user == null || !user.hasPermission(permisoNecesario)) {
      AppSnackbar.show(
        context,
        message: _tipo == TipoServicio.emergencia
            ? 'Tu rol no permite crear emergencias.'
            : 'Tu rol no permite crear servicios de este tipo.',
        variant: AppSnackbarVariant.danger,
      );
      return;
    }
    final numeroVoluntariosRaw = _numeroVoluntariosCtrl.text.trim();
    final data = ServicioCreate(
      titulo: _tituloCtrl.text.trim(),
      descripcion: _normalize(_descripcionCtrl.text),
      tipo: _tipo,
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin,
      ubicacion: _ubicacionCtrl.text.trim(),
      numeroVoluntarios:
          numeroVoluntariosRaw.isEmpty ? null : int.parse(numeroVoluntariosRaw),
      notasMaterial: _normalize(_notasMaterialCtrl.text),
      notasVehiculos: _normalize(_notasVehiculosCtrl.text),
    );
    ref.read(altaServicioViewModelProvider.notifier).submit(data);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubmit = ref.watch(altaServicioViewModelProvider);

    ref.listen(altaServicioViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (created) {
          if (created == null) return;
          AppSnackbar.show(
            context,
            message: 'Servicio "${created.titulo}" creado correctamente.',
            variant: AppSnackbarVariant.success,
          );
          ref.read(serviciosListViewModelProvider.notifier).refresh();
          context.go('/servicios/${created.id}');
        },
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'No se pudo crear el servicio.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
    });

    return AppPageScaffold(
      title: 'Crear servicio',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Tipo de servicio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _TipoSelector(
              selected: _tipo,
              onChanged: (t) => setState(() => _tipo = t),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Datos obligatorios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: const ValueKey('alta_servicio_titulo'),
              label: 'Título',
              controller: _tituloCtrl,
              autofocus: true,
              prefixIcon: Icons.title,
              validator: (v) => _validateRequired(v, 'Título'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_servicio_ubicacion'),
              label: 'Ubicación',
              controller: _ubicacionCtrl,
              prefixIcon: Icons.location_on_outlined,
              validator: (v) => _validateRequired(v, 'Ubicación'),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              key: const ValueKey('alta_servicio_fecha_inicio'),
              onTap: _pickFechaInicio,
              child: AbsorbPointer(
                child: AppTextField(
                  label: 'Fecha y hora de inicio',
                  controller: _fechaInicioCtrl,
                  prefixIcon: Icons.calendar_today_outlined,
                  validator: (_) =>
                      _fechaInicio == null ? 'Fecha obligatoria' : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Datos opcionales',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: const ValueKey('alta_servicio_descripcion'),
              label: 'Descripción',
              controller: _descripcionCtrl,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              key: const ValueKey('alta_servicio_fecha_fin'),
              onTap: _pickFechaFin,
              child: AbsorbPointer(
                child: AppTextField(
                  label: 'Fecha y hora de fin',
                  controller: _fechaFinCtrl,
                  prefixIcon: Icons.event_outlined,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_servicio_numero_voluntarios'),
              label: 'Número de voluntarios necesarios',
              controller: _numeroVoluntariosCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.groups_outlined,
              validator: _validateNumeroVoluntarios,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_servicio_notas_material'),
              label: 'Notas sobre material',
              controller: _notasMaterialCtrl,
              prefixIcon: Icons.inventory_2_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_servicio_notas_vehiculos'),
              label: 'Notas sobre vehículos',
              controller: _notasVehiculosCtrl,
              prefixIcon: Icons.directions_car_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              key: const ValueKey('alta_servicio_submit'),
              label: _tipo == TipoServicio.emergencia
                  ? 'Crear emergencia'
                  : 'Crear servicio',
              icon: _tipo == TipoServicio.emergencia
                  ? Icons.warning_amber_rounded
                  : Icons.event_available,
              expanded: true,
              isLoading: asyncSubmit.isLoading,
              onPressed: asyncSubmit.isLoading ? null : _onSubmit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              key: const ValueKey('alta_servicio_cancel'),
              label: 'Cancelar',
              expanded: true,
              onPressed: asyncSubmit.isLoading
                  ? null
                  : () => context.go('/servicios'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipoSelector extends StatelessWidget {
  final TipoServicio selected;
  final ValueChanged<TipoServicio> onChanged;

  const _TipoSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: TipoServicio.values.map((t) {
        return ChoiceChip(
          key: ValueKey('alta_servicio_tipo_${t.wire}'),
          label: Text(_label(t)),
          selected: selected == t,
          onSelected: (_) => onChanged(t),
        );
      }).toList(growable: false),
    );
  }

  String _label(TipoServicio t) => switch (t) {
        TipoServicio.preventivo => 'Preventivo',
        TipoServicio.emergencia => 'Emergencia',
        TipoServicio.formacion => 'Formación',
        TipoServicio.otro => 'Otro',
      };
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Crear servicio',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite crear servicios.',
        icon: Icons.lock_outline,
      ),
    );
  }
}
