// EditarMiPerfilPage (US-02-03).
//
// 5-field self-edit form: teléfono, email, municipio, dirección,
// foto_url — exactly the set VoluntarioUpdateSelf accepts. Nombre,
// DNI, rol, formación stay out per CU-11 A.
//
// On Success: feeds the new profile back into MiPerfilViewModel and
// navigates to /mi-perfil; on 409 (email collision) shows a typed
// AppSnackbar so the user understands why the change was rejected.

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
import '../../../../core/ui/states/app_error_state.dart';
import '../../../../core/ui/tokens/app_breakpoints.dart';
import '../../../../core/ui/tokens/app_spacing.dart';
import '../../../../infrastructure/auth/permissions.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/mi_perfil_update.dart';
import '../../domain/entities/voluntario.dart';
import '../viewmodels/editar_mi_perfil_view_model.dart';
import '../viewmodels/mi_perfil_view_model.dart';

class EditarMiPerfilPage extends ConsumerWidget {
  const EditarMiPerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.voluntariosEditarPropio,
      fallback: _ForbiddenScreen(),
      child: _EditarMiPerfilPageBody(),
    );
  }
}

class _EditarMiPerfilPageBody extends ConsumerWidget {
  const _EditarMiPerfilPageBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(miPerfilViewModelProvider);

    return AppPageScaffold(
      maxContentWidth: AppBreakpoints.formMaxWidth,
      title: 'Editar mis datos',
      body: asyncProfile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          title: 'No se pudo cargar tu perfil',
          description: error is Failure ? error.message : null,
          onRetry: () =>
              ref.read(miPerfilViewModelProvider.notifier).refresh(),
        ),
        data: (v) => _Form(initial: v),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  final Voluntario initial;

  const _Form({required this.initial});

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _municipioCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _fotoCtrl;

  @override
  void initState() {
    super.initState();
    _telefonoCtrl = TextEditingController(text: widget.initial.telefono);
    _emailCtrl = TextEditingController(text: widget.initial.email ?? '');
    _municipioCtrl = TextEditingController(text: widget.initial.municipio);
    _direccionCtrl = TextEditingController(text: widget.initial.direccion ?? '');
    _fotoCtrl = TextEditingController(text: widget.initial.fotoUrl ?? '');
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _municipioCtrl.dispose();
    _direccionCtrl.dispose();
    _fotoCtrl.dispose();
    super.dispose();
  }

  String? _normalize(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  MiPerfilUpdate _buildPatch() {
    final telefono = _normalize(_telefonoCtrl.text);
    final email = _normalize(_emailCtrl.text);
    final municipio = _normalize(_municipioCtrl.text);
    final direccion = _normalize(_direccionCtrl.text);
    final foto = _normalize(_fotoCtrl.text);
    final initial = widget.initial;
    return MiPerfilUpdate(
      telefono: telefono != initial.telefono ? telefono : null,
      email: email != initial.email ? email : null,
      municipio: municipio != initial.municipio ? municipio : null,
      direccion: direccion != initial.direccion ? direccion : null,
      fotoUrl: foto != initial.fotoUrl ? foto : null,
    );
  }

  String? _validateEmail(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'Email no válido';
  }

  String? _validateTelefono(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Teléfono obligatorio';
    return null;
  }

  String? _validateMunicipio(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Municipio obligatorio';
    return null;
  }

  void _onSubmit() {
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
    ref.read(editarMiPerfilViewModelProvider.notifier).submit(patch);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubmit = ref.watch(editarMiPerfilViewModelProvider);

    ref.listen(editarMiPerfilViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (updated) {
          if (updated == null) return;
          ref.read(miPerfilViewModelProvider.notifier).setProfile(updated);
          AppSnackbar.show(
            context,
            message: 'Datos guardados.',
            variant: AppSnackbarVariant.success,
          );
          context.go('/mi-perfil');
        },
        error: (error, _) {
          if (error is EmailDuplicado) {
            AppSnackbar.show(
              context,
              message: error.message ??
                  'Ese email ya está registrado para otro voluntario.',
              variant: AppSnackbarVariant.danger,
            );
          } else if (error is Failure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'No se pudo guardar los cambios.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
    });

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppTextField(
            key: const ValueKey('editar_perfil_telefono'),
            label: 'Teléfono',
            controller: _telefonoCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: _validateTelefono,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('editar_perfil_email'),
            label: 'Email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: _validateEmail,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('editar_perfil_municipio'),
            label: 'Municipio',
            controller: _municipioCtrl,
            prefixIcon: Icons.location_city_outlined,
            validator: _validateMunicipio,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('editar_perfil_direccion'),
            label: 'Dirección',
            controller: _direccionCtrl,
            prefixIcon: Icons.home_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            key: const ValueKey('editar_perfil_foto'),
            label: 'URL de foto',
            controller: _fotoCtrl,
            keyboardType: TextInputType.url,
            prefixIcon: Icons.image_outlined,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            key: const ValueKey('editar_perfil_submit'),
            label: 'Guardar',
            icon: Icons.save_outlined,
            expanded: true,
            isLoading: asyncSubmit.isLoading,
            onPressed: asyncSubmit.isLoading ? null : _onSubmit,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            key: const ValueKey('editar_perfil_cancel'),
            label: 'Cancelar',
            expanded: true,
            onPressed: asyncSubmit.isLoading
                ? null
                : () => context.go('/mi-perfil'),
          ),
        ],
      ),
    );
  }
}

class _ForbiddenScreen extends StatelessWidget {
  const _ForbiddenScreen();

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      title: 'Editar mis datos',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite editar tus propios datos.',
        icon: Icons.lock_outline,
      ),
    );
  }
}
