// VoluntarioFichaPage (US-02-02). Admin ficha for any voluntario.
//
// Access gate: `voluntarios.ver_ficha` shows the screen read-only.
// `voluntarios.editar` unlocks the form + role mutations. The split
// keeps the gate aligned with the backend: `GET /voluntarios/{id}`
// is permitted for any rol with ver_ficha; PATCH / role mutations
// require `voluntarios.editar`.
//
// Out of scope (documented as deuda):
//   - Add/remove formación and certificados — backend has no PATCH
//     endpoint for the nested catalogs yet.
//   - Historial de cambios — depends on EN-02-04 (audit log table).
//
// Soft delete (DELETE /voluntarios/{id}) and anonimización
// (POST /{id}/anonimizar) live in the lista admin, not here, because
// they apply to a voluntario "from outside" the ficha — a future
// iteration can move them here behind a destructive menu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/di/providers.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/estado_voluntario.dart';
import '../../domain/entities/rol.dart';
import '../../domain/entities/voluntario.dart';
import '../../domain/entities/voluntario_rol_asignacion.dart';
import '../../domain/entities/voluntario_update_admin.dart';
import '../viewmodels/voluntario_ficha_view_model.dart';

class VoluntarioFichaPage extends ConsumerWidget {
  final String voluntarioId;

  const VoluntarioFichaPage({super.key, required this.voluntarioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppPermissionGate(
      permission: Permission.voluntariosVerFicha,
      fallback: const _ForbiddenScreen(),
      child: _VoluntarioFichaBody(voluntarioId: voluntarioId),
    );
  }
}

class _VoluntarioFichaBody extends ConsumerWidget {
  final String voluntarioId;

  const _VoluntarioFichaBody({required this.voluntarioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = voluntarioFichaViewModelProvider(voluntarioId);
    final asyncState = ref.watch(provider);
    final canEdit = ref
            .watch(authServiceProvider)
            .currentUser
            ?.hasPermission(Permission.voluntariosEditar) ??
        false;

    ref.listen(provider, (prev, next) {
      next.whenOrNull(error: (error, _) => _showFailure(context, error));
    });

    return AppPageScaffold(
      title: 'Ficha de voluntario',
      actions: [
        IconButton(
          key: const ValueKey('voluntario_ficha_refresh'),
          tooltip: 'Recargar',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(provider.notifier).refresh(),
        ),
      ],
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          if (error is VoluntarioNotFound) {
            return const AppEmptyState(
              title: 'Voluntario no encontrado',
              description: 'Es posible que haya sido eliminado.',
              icon: Icons.person_off_outlined,
            );
          }
          return AppErrorState(
            title: 'No se pudo cargar la ficha',
            description: error is Failure ? error.message : null,
            onRetry: () => ref.read(provider.notifier).refresh(),
          );
        },
        data: (state) => _FichaContent(
          voluntarioId: voluntarioId,
          state: state,
          canEdit: canEdit,
          isMutating: state.isMutating,
        ),
      ),
    );
  }

  void _showFailure(BuildContext context, Object error) {
    if (error is! Failure) return;
    AppSnackbar.show(
      context,
      message: error.message ?? 'Ha ocurrido un error.',
      variant: AppSnackbarVariant.danger,
    );
  }
}

class _FichaContent extends StatelessWidget {
  final String voluntarioId;
  final VoluntarioFichaState state;
  final bool canEdit;
  final bool isMutating;

  const _FichaContent({
    required this.voluntarioId,
    required this.state,
    required this.canEdit,
    required this.isMutating,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _AdminForm(
          voluntarioId: voluntarioId,
          initial: state.voluntario,
          canEdit: canEdit,
          isMutating: isMutating,
        ),
        const SizedBox(height: AppSpacing.xl),
        _RolesSection(
          voluntarioId: voluntarioId,
          asignaciones: state.rolesAsignados,
          catalogo: state.catalogoRoles,
          canEdit: canEdit,
          isMutating: isMutating,
        ),
      ],
    );
  }
}

class _AdminForm extends ConsumerStatefulWidget {
  final String voluntarioId;
  final Voluntario initial;
  final bool canEdit;
  final bool isMutating;

  const _AdminForm({
    required this.voluntarioId,
    required this.initial,
    required this.canEdit,
    required this.isMutating,
  });

  @override
  ConsumerState<_AdminForm> createState() => _AdminFormState();
}

class _AdminFormState extends ConsumerState<_AdminForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _municipioCtrl;
  late final TextEditingController _fechaCtrl;
  late final TextEditingController _dniCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _fotoCtrl;
  late DateTime _fechaNacimiento;
  late bool _conductorHabilitado;
  late EstadoVoluntario _estado;

  @override
  void initState() {
    super.initState();
    _resetFrom(widget.initial);
  }

  @override
  void didUpdateWidget(_AdminForm old) {
    super.didUpdateWidget(old);
    // El padre rebuilds con el voluntario actualizado tras un save.
    // No reseteamos los controllers si el usuario está editando (lo
    // detectamos comparando id), pero sí actualizamos los toggles
    // que no llevan controller.
    if (old.initial.id != widget.initial.id) {
      _resetFrom(widget.initial);
    } else {
      _conductorHabilitado = widget.initial.conductorHabilitado;
      _estado = widget.initial.estado;
    }
  }

  void _resetFrom(Voluntario v) {
    _nombreCtrl = TextEditingController(text: v.nombre);
    _telefonoCtrl = TextEditingController(text: v.telefono);
    _municipioCtrl = TextEditingController(text: v.municipio);
    _fechaCtrl = TextEditingController(text: _formatDate(v.fechaNacimiento));
    _dniCtrl = TextEditingController(text: v.dni ?? '');
    _emailCtrl = TextEditingController(text: v.email ?? '');
    _direccionCtrl = TextEditingController(text: v.direccion ?? '');
    _fotoCtrl = TextEditingController(text: v.fotoUrl ?? '');
    _fechaNacimiento = v.fechaNacimiento;
    _conductorHabilitado = v.conductorHabilitado;
    _estado = v.estado;
  }

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

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Fecha de nacimiento',
    );
    if (picked == null) return;
    setState(() {
      _fechaNacimiento = picked;
      _fechaCtrl.text = _formatDate(picked);
    });
  }

  String? _normalize(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
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

  VoluntarioUpdateAdmin _buildPatch() {
    final initial = widget.initial;
    final nombre = _normalize(_nombreCtrl.text);
    final telefono = _normalize(_telefonoCtrl.text);
    final municipio = _normalize(_municipioCtrl.text);
    final dni = _normalize(_dniCtrl.text);
    final email = _normalize(_emailCtrl.text);
    final direccion = _normalize(_direccionCtrl.text);
    final foto = _normalize(_fotoCtrl.text);
    return VoluntarioUpdateAdmin(
      nombre: nombre != initial.nombre ? nombre : null,
      telefono: telefono != initial.telefono ? telefono : null,
      municipio: municipio != initial.municipio ? municipio : null,
      fechaNacimiento: _fechaNacimiento != initial.fechaNacimiento
          ? _fechaNacimiento
          : null,
      dni: dni != initial.dni ? dni : null,
      email: email != initial.email ? email : null,
      direccion: direccion != initial.direccion ? direccion : null,
      fotoUrl: foto != initial.fotoUrl ? foto : null,
      conductorHabilitado: _conductorHabilitado != initial.conductorHabilitado
          ? _conductorHabilitado
          : null,
      estado: _estado != initial.estado ? _estado : null,
    );
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final patch = _buildPatch();
    if (patch.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'No has cambiado nada.',
        variant: AppSnackbarVariant.info,
      );
      return;
    }
    ref
        .read(voluntarioFichaViewModelProvider(widget.voluntarioId).notifier)
        .saveAdmin(patch)
        .then((_) {
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: 'Datos guardados.',
        variant: AppSnackbarVariant.success,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datos del voluntario', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            key: const ValueKey('ficha_nombre'),
            label: 'Nombre completo',
            controller: _nombreCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            prefixIcon: Icons.person_outline,
            validator: (v) => _validateRequired(v, 'Nombre'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('ficha_telefono'),
            label: 'Teléfono',
            controller: _telefonoCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: (v) => _validateRequired(v, 'Teléfono'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('ficha_municipio'),
            label: 'Municipio',
            controller: _municipioCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            prefixIcon: Icons.location_city_outlined,
            validator: (v) => _validateRequired(v, 'Municipio'),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            key: const ValueKey('ficha_fecha_nacimiento'),
            onTap: widget.canEdit && !widget.isMutating ? _pickDate : null,
            child: AbsorbPointer(
              child: AppTextField(
                label: 'Fecha de nacimiento',
                controller: _fechaCtrl,
                enabled: widget.canEdit && !widget.isMutating,
                prefixIcon: Icons.calendar_today_outlined,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('ficha_dni'),
            label: 'DNI',
            controller: _dniCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('ficha_email'),
            label: 'Email',
            controller: _emailCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: _validateEmail,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('ficha_direccion'),
            label: 'Dirección',
            controller: _direccionCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            prefixIcon: Icons.home_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('ficha_foto'),
            label: 'URL de foto',
            controller: _fotoCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            keyboardType: TextInputType.url,
            prefixIcon: Icons.image_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            key: const ValueKey('ficha_conductor'),
            title: const Text('Conductor habilitado'),
            value: _conductorHabilitado,
            onChanged: widget.canEdit && !widget.isMutating
                ? (v) => setState(() => _conductorHabilitado = v)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<EstadoVoluntario>(
            key: const ValueKey('ficha_estado'),
            initialValue: _estado,
            decoration: const InputDecoration(
              labelText: 'Estado',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: EstadoVoluntario.activo,
                child: Text('Activo'),
              ),
              DropdownMenuItem(
                value: EstadoVoluntario.baja,
                child: Text('Baja'),
              ),
              DropdownMenuItem(
                value: EstadoVoluntario.suspendido,
                child: Text('Suspendido'),
              ),
            ],
            onChanged: widget.canEdit && !widget.isMutating
                ? (v) {
                    if (v != null) setState(() => _estado = v);
                  }
                : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (widget.canEdit)
            AppPrimaryButton(
              key: const ValueKey('ficha_save'),
              label: 'Guardar cambios',
              icon: Icons.save_outlined,
              expanded: true,
              isLoading: widget.isMutating,
              onPressed: widget.isMutating ? null : _onSave,
            ),
        ],
      ),
    );
  }
}

class _RolesSection extends ConsumerStatefulWidget {
  final String voluntarioId;
  final List<VoluntarioRolAsignacion> asignaciones;
  final List<Rol> catalogo;
  final bool canEdit;
  final bool isMutating;

  const _RolesSection({
    required this.voluntarioId,
    required this.asignaciones,
    required this.catalogo,
    required this.canEdit,
    required this.isMutating,
  });

  @override
  ConsumerState<_RolesSection> createState() => _RolesSectionState();
}

class _RolesSectionState extends ConsumerState<_RolesSection> {
  String? _seleccionado;

  Iterable<Rol> get _disponibles {
    final asignados = widget.asignaciones.map((a) => a.rolId).toSet();
    return widget.catalogo.where((r) => !asignados.contains(r.id));
  }

  void _onAsignar() {
    final rolId = _seleccionado;
    if (rolId == null) return;
    ref
        .read(voluntarioFichaViewModelProvider(widget.voluntarioId).notifier)
        .asignarRol(rolId);
    setState(() => _seleccionado = null);
  }

  void _onQuitar(String rolId) {
    ref
        .read(voluntarioFichaViewModelProvider(widget.voluntarioId).notifier)
        .quitarRol(rolId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disponibles = _disponibles.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Roles', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (widget.asignaciones.isEmpty)
          Text(
            'Sin roles asignados.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final a in widget.asignaciones)
                InputChip(
                  key: ValueKey('ficha_rol_chip_${a.rolId}'),
                  label: Text(a.rolNombre),
                  onDeleted: widget.canEdit && !widget.isMutating ? () => _onQuitar(a.rolId) : null,
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        if (widget.canEdit && !widget.isMutating && disponibles.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            key: const ValueKey('ficha_rol_selector'),
            initialValue: _seleccionado,
            decoration: const InputDecoration(
              labelText: 'Asignar nuevo rol',
              prefixIcon: Icon(Icons.add_moderator_outlined),
            ),
            items: [
              for (final r in disponibles)
                DropdownMenuItem(value: r.id, child: Text(r.nombre)),
            ],
            onChanged: (v) => setState(() => _seleccionado = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            key: const ValueKey('ficha_rol_asignar'),
            label: 'Asignar rol',
            icon: Icons.add,
            expanded: true,
            onPressed: _seleccionado == null ? null : _onAsignar,
          ),
        ] else if (widget.canEdit && !widget.isMutating && disponibles.isEmpty)
          Text(
            'Este voluntario ya tiene todos los roles del catálogo.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Ficha de voluntario',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite consultar la ficha de otros voluntarios.',
        icon: Icons.lock_outline,
      ),
    );
  }
}
