// VoluntarioFichaPage (US-02-02 + US-02-08). Admin ficha for any voluntario.
//
// Access gate: `voluntarios.ver_ficha` shows the screen read-only.
// `voluntarios.editar` unlocks the form + role mutations.
// `voluntarios.dar_baja` unlocks the destructive section at the
// bottom (soft delete + anonimización RGPD). The split keeps the
// gates aligned with the backend: `GET /voluntarios/{id}` requires
// ver_ficha; PATCH and role mutations require editar; DELETE and
// POST /anonimizar require dar_baja.
//
// Out of scope (documented as deuda):
//   - Add/remove formación and certificados — backend has no PATCH
//     endpoint for the nested catalogs yet.
//   - Historial de cambios — depends on EN-02-04 (audit log table).
//   - Aviso de material pendiente de devolución antes de dar de baja:
//     no hay endpoint específico `/voluntarios/{id}/material-asignado`
//     y filtrar el listado entero del inventario por voluntario sería
//     caro. El diálogo se limita a recordarlo en el copy.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/test_keys.dart';
import '../../../../core/ui/auth/app_permission_gate.dart';
import '../../../../core/ui/buttons/app_destructive_button.dart';
import '../../../../core/ui/buttons/app_icon_button.dart';
import '../../../../core/ui/buttons/app_primary_button.dart';
import '../../../../core/ui/buttons/app_secondary_button.dart';
import '../../../../core/ui/containers/app_page_scaffold.dart';
import '../../../../core/ui/feedback/app_confirm_dialog.dart';
import '../../../../core/ui/feedback/app_loading_indicator.dart';
import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../core/ui/inputs/app_text_field.dart';
import '../../../../core/ui/states/app_empty_state.dart';
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_radius.dart';
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
import '../viewmodels/voluntarios_list_view_model.dart';

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
        AppIconButton(
          key: K.voluntarioFichaRefreshButton,
          tooltip: 'Recargar',
          icon: Symbols.refresh,
          onPressed: () => ref.read(provider.notifier).refresh(),
        ),
      ],
      body: asyncState.when(
        loading: () => const AppLoadingIndicator.fullScreen(),
        error: (error, _) {
          if (error is VoluntarioNotFound) {
            return const AppEmptyState(
              title: 'Voluntario no encontrado',
              description: 'Es posible que haya sido eliminado.',
              icon: Symbols.person_off,
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
        const SizedBox(height: AppSpacing.xl),
        AppPermissionGate(
          permission: Permission.voluntariosDarBaja,
          child: _BajaSection(
            voluntarioId: voluntarioId,
            voluntario: state.voluntario,
            isMutating: isMutating,
          ),
        ),
      ],
    );
  }
}

/// US-02-08. Destructive section at the bottom of the ficha. Two
/// branches: soft delete (idempotent, reversible) and anonimización
/// (Art. 17 RGPD, irreversible). Both are gated by
/// `voluntarios.dar_baja` from the parent. The destructive button
/// styling separates this block from the rest of the form so it never
/// gets confused with a "Save" click.
class _BajaSection extends ConsumerWidget {
  final String voluntarioId;
  final Voluntario voluntario;
  final bool isMutating;

  const _BajaSection({
    required this.voluntarioId,
    required this.voluntario,
    required this.isMutating,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final yaDeBaja = voluntario.estado == EstadoVoluntario.baja;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zona destructiva', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Acciones administrativas sobre la cuenta del voluntario. '
          'Si el voluntario tiene material asignado, gestiona la '
          'devolución desde el módulo de inventario antes de continuar.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (!yaDeBaja)
          AppDestructiveButton(
            key: K.voluntarioFichaDarBajaButton,
            label: 'Dar de baja',
            icon: Symbols.person_off,
            expanded: true,
            onPressed: isMutating
                ? null
                : () => _onDarDeBaja(context, ref),
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.info,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'El voluntario ya está dado de baja.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        AppDestructiveButton(
          key: K.voluntarioFichaAnonimizarButton,
          label: 'Anonimizar (RGPD, irreversible)',
          icon: Symbols.privacy_tip,
          expanded: true,
          onPressed: isMutating ? null : () => _onAnonimizar(context, ref),
        ),
      ],
    );
  }

  Future<void> _onDarDeBaja(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Dar de baja a ${voluntario.nombre}',
      message:
          'El voluntario pasará a estado "baja" y su cuenta de Keycloak se '
          'deshabilitará. La operación es reversible cambiando el estado '
          'desde la propia ficha. ¿Continuar?',
      confirmLabel: 'Dar de baja',
      isDestructive: true,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    final ok = await ref
        .read(voluntarioFichaViewModelProvider(voluntarioId).notifier)
        .darDeBaja();
    if (!context.mounted) return;
    if (ok) {
      AppSnackbar.show(
        context,
        message: '${voluntario.nombre} dado de baja.',
        variant: AppSnackbarVariant.success,
      );
      ref.read(voluntariosListViewModelProvider.notifier).refresh();
      context.go('/voluntarios');
    }
  }

  Future<void> _onAnonimizar(BuildContext context, WidgetRef ref) async {
    // Doble confirmación por la naturaleza irreversible de la operación.
    final firstOk = await AppConfirmDialog.show(
      context,
      title: 'Anonimizar a ${voluntario.nombre}',
      message:
          'Esta operación elimina los datos personales (nombre, DNI, '
          'email, teléfono, dirección) sustituyéndolos por valores '
          'anonimizados y borra la cuenta de Keycloak. Es IRREVERSIBLE y '
          'cumple el Art. 17 del RGPD. ¿Continuar?',
      confirmLabel: 'Continuar',
      isDestructive: true,
    );
    if (!firstOk) return;
    if (!context.mounted) return;
    final secondOk = await AppConfirmDialog.show(
      context,
      title: 'Confirmación final',
      message:
          'Vas a borrar definitivamente los datos personales de '
          '${voluntario.nombre}. No se puede deshacer. ¿Estás absolutamente '
          'seguro?',
      confirmLabel: 'Anonimizar definitivamente',
      isDestructive: true,
    );
    if (!secondOk) return;
    if (!context.mounted) return;
    final ok = await ref
        .read(voluntarioFichaViewModelProvider(voluntarioId).notifier)
        .anonimizar();
    if (!context.mounted) return;
    if (ok) {
      AppSnackbar.show(
        context,
        message: 'Voluntario anonimizado correctamente.',
        variant: AppSnackbarVariant.success,
      );
      ref.read(voluntariosListViewModelProvider.notifier).refresh();
      context.go('/voluntarios');
    }
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
            key: K.voluntarioFichaNombreField,
            label: 'Nombre completo',
            controller: _nombreCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            prefixIcon: Symbols.person,
            validator: (v) => _validateRequired(v, 'Nombre'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: K.voluntarioFichaTelefonoField,
            label: 'Teléfono',
            controller: _telefonoCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            keyboardType: TextInputType.phone,
            prefixIcon: Symbols.phone,
            validator: (v) => _validateRequired(v, 'Teléfono'),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: K.voluntarioFichaMunicipioField,
            label: 'Municipio',
            controller: _municipioCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            prefixIcon: Symbols.location_city,
            validator: (v) => _validateRequired(v, 'Municipio'),
          ),
          const SizedBox(height: AppSpacing.md),
          // Guía 28 §WCAG 4.1.2: el GestureDetector envuelve un campo
          // que el screen reader leería como TextField editable, pero
          // su rol real es "botón que abre un date picker".
          // `Semantics(button: true, label: ...)` fuerza la
          // interpretación correcta.
          Semantics(
            label: 'Fecha de nacimiento',
            button: true,
            enabled: widget.canEdit && !widget.isMutating,
            child: GestureDetector(
              key: K.voluntarioFichaFechaNacimientoField,
              onTap: widget.canEdit && !widget.isMutating ? _pickDate : null,
              child: AbsorbPointer(
                child: AppTextField(
                  label: 'Fecha de nacimiento',
                  controller: _fechaCtrl,
                  enabled: widget.canEdit && !widget.isMutating,
                  prefixIcon: Symbols.calendar_today,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: K.voluntarioFichaDniField,
            label: 'DNI',
            controller: _dniCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            prefixIcon: Symbols.badge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: K.voluntarioFichaEmailField,
            label: 'Email',
            controller: _emailCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Symbols.email,
            validator: _validateEmail,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: K.voluntarioFichaDireccionField,
            label: 'Dirección',
            controller: _direccionCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            prefixIcon: Symbols.home,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: K.voluntarioFichaFotoField,
            label: 'URL de foto',
            controller: _fotoCtrl,
            enabled: widget.canEdit && !widget.isMutating,
            keyboardType: TextInputType.url,
            prefixIcon: Symbols.image,
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            key: K.voluntarioFichaConductorSwitch,
            title: const Text('Conductor habilitado'),
            value: _conductorHabilitado,
            onChanged: widget.canEdit && !widget.isMutating
                ? (v) => setState(() => _conductorHabilitado = v)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<EstadoVoluntario>(
            key: K.voluntarioFichaEstadoDropdown,
            initialValue: _estado,
            decoration: const InputDecoration(
              labelText: 'Estado',
              prefixIcon: Icon(Symbols.flag),
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
              key: K.voluntarioFichaSaveButton,
              label: 'Guardar cambios',
              icon: Symbols.save,
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
                  key: K.voluntarioFichaRolChip(a.rolId),
                  label: Text(a.rolNombre),
                  onDeleted: widget.canEdit && !widget.isMutating ? () => _onQuitar(a.rolId) : null,
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        if (widget.canEdit && !widget.isMutating && disponibles.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            key: K.voluntarioFichaRolSelectorDropdown,
            initialValue: _seleccionado,
            decoration: const InputDecoration(
              labelText: 'Asignar nuevo rol',
              prefixIcon: Icon(Symbols.add_moderator),
            ),
            items: [
              for (final r in disponibles)
                DropdownMenuItem(value: r.id, child: Text(r.nombre)),
            ],
            onChanged: (v) => setState(() => _seleccionado = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            key: K.voluntarioFichaRolAsignarButton,
            label: 'Asignar rol',
            icon: Symbols.add,
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
        icon: Symbols.lock,
      ),
    );
  }
}
