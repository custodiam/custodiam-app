// AltaVoluntarioPage (US-02-01). Admin-only form that POSTs to
// /voluntarios; the backend creates the user in Keycloak and the
// row in BD atomically (EN-02-03). The credentials and welcome
// email are handled by the backend.
//
// Out of scope here (will land in follow-up stories):
//   - Initial-role selector (needs the EN-02-05 roles endpoint).
//   - Formación / talla / contacto de emergencia (managed through
//     dedicated endpoints in later iterations).

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
import '../../../../core/ui/tokens/app_breakpoints.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/voluntario_create.dart';
import '../viewmodels/alta_voluntario_view_model.dart';
import '../viewmodels/voluntarios_list_view_model.dart';

class AltaVoluntarioPage extends ConsumerWidget {
  const AltaVoluntarioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.voluntariosCrear,
      fallback: _ForbiddenScreen(),
      child: _AltaVoluntarioForm(),
    );
  }
}

class _AltaVoluntarioForm extends ConsumerStatefulWidget {
  const _AltaVoluntarioForm();

  @override
  ConsumerState<_AltaVoluntarioForm> createState() =>
      _AltaVoluntarioFormState();
}

class _AltaVoluntarioFormState extends ConsumerState<_AltaVoluntarioForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _municipioCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _fotoCtrl = TextEditingController();
  bool _conductorHabilitado = false;
  DateTime? _fechaNacimiento;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _municipioCtrl.dispose();
    _fechaCtrl.dispose();
    _dniCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    _fotoCtrl.dispose();
    super.dispose();
  }

  String? _normalize(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked == null) return;
    setState(() {
      _fechaNacimiento = picked;
      _fechaCtrl.text = _formatDate(picked);
    });
  }

  String? _validateRequired(String? raw, String field) {
    if (raw == null || raw.trim().isEmpty) return '$field obligatorio';
    return null;
  }

  String? _validateEmail(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'Email no válido';
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fechaNacimiento == null) {
      AppSnackbar.show(
        context,
        message: 'Selecciona una fecha de nacimiento.',
        variant: AppSnackbarVariant.warning,
      );
      return;
    }
    final data = VoluntarioCreate(
      nombre: _nombreCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      municipio: _municipioCtrl.text.trim(),
      fechaNacimiento: _fechaNacimiento!,
      dni: _normalize(_dniCtrl.text),
      email: _normalize(_emailCtrl.text),
      direccion: _normalize(_direccionCtrl.text),
      fotoUrl: _normalize(_fotoCtrl.text),
      conductorHabilitado: _conductorHabilitado,
    );
    ref.read(altaVoluntarioViewModelProvider.notifier).submit(data);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubmit = ref.watch(altaVoluntarioViewModelProvider);

    ref.listen(altaVoluntarioViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (created) {
          if (created == null) return;
          AppSnackbar.show(
            context,
            message: 'Voluntario "${created.nombre}" creado correctamente.',
            variant: AppSnackbarVariant.success,
          );
          // Refresh the list so the new row shows up on return.
          ref
              .read(voluntariosListViewModelProvider.notifier)
              .refresh();
          context.go('/voluntarios');
        },
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'No se pudo crear el voluntario.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
    });

    return AppPageScaffold(
      maxContentWidth: AppBreakpoints.formMaxWidth,
      title: 'Alta de voluntario',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Datos obligatorios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: const ValueKey('alta_nombre'),
              label: 'Nombre completo',
              controller: _nombreCtrl,
              autofocus: true,
              prefixIcon: Icons.person_outline,
              validator: (v) => _validateRequired(v, 'Nombre'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_telefono'),
              label: 'Teléfono',
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) => _validateRequired(v, 'Teléfono'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_municipio'),
              label: 'Municipio',
              controller: _municipioCtrl,
              prefixIcon: Icons.location_city_outlined,
              validator: (v) => _validateRequired(v, 'Municipio'),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              key: const ValueKey('alta_fecha_nacimiento'),
              onTap: _pickDate,
              child: AbsorbPointer(
                child: AppTextField(
                  label: 'Fecha de nacimiento',
                  controller: _fechaCtrl,
                  prefixIcon: Icons.calendar_today_outlined,
                  validator: (_) => _fechaNacimiento == null
                      ? 'Fecha obligatoria'
                      : null,
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
              key: const ValueKey('alta_dni'),
              label: 'DNI',
              controller: _dniCtrl,
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_email'),
              label: 'Email',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: _validateEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_direccion'),
              label: 'Dirección',
              controller: _direccionCtrl,
              prefixIcon: Icons.home_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('alta_foto'),
              label: 'URL de foto',
              controller: _fotoCtrl,
              keyboardType: TextInputType.url,
              prefixIcon: Icons.image_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              key: const ValueKey('alta_conductor'),
              title: const Text('Conductor habilitado'),
              subtitle: const Text(
                'Marca si tiene permiso para conducir vehículos del servicio.',
              ),
              value: _conductorHabilitado,
              onChanged: (v) => setState(() => _conductorHabilitado = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              key: const ValueKey('alta_submit'),
              label: 'Crear voluntario',
              icon: Icons.person_add_alt_1,
              expanded: true,
              isLoading: asyncSubmit.isLoading,
              onPressed: asyncSubmit.isLoading ? null : _onSubmit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              key: const ValueKey('alta_cancel'),
              label: 'Cancelar',
              expanded: true,
              onPressed: asyncSubmit.isLoading
                  ? null
                  : () => context.go('/voluntarios'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Alta de voluntario',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite dar de alta voluntarios.',
        icon: Icons.lock_outline,
      ),
    );
  }
}
