// AltaVehiculoPage (US-05-02).

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/test_keys.dart';
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
import '../../../../infrastructure/catalogo/catalogo_recurso.dart';
import '../../../../infrastructure/error/failure.dart';
import '../../domain/entities/tipo_vehiculo.dart';
import '../../domain/entities/vehiculo_create.dart';
import '../viewmodels/alta_vehiculo_view_model.dart';
import '../viewmodels/vehiculos_list_view_model.dart';
import '../widgets/ubicacion_selector_field.dart';

class AltaVehiculoPage extends ConsumerWidget {
  const AltaVehiculoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppPermissionGate(
      permission: Permission.inventarioRegistrarVehiculo,
      fallback: _ForbiddenScreen(),
      child: _AltaVehiculoForm(),
    );
  }
}

class _AltaVehiculoForm extends ConsumerStatefulWidget {
  const _AltaVehiculoForm();

  @override
  ConsumerState<_AltaVehiculoForm> createState() =>
      _AltaVehiculoFormState();
}

class _AltaVehiculoFormState extends ConsumerState<_AltaVehiculoForm> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _marcaModeloCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  final _itvCtrl = TextEditingController();
  TipoVehiculo _tipo = TipoVehiculo.furgoneta;
  DateTime? _fechaItv;
  CatalogoRecurso? _ubicacion;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _matriculaCtrl.dispose();
    _marcaModeloCtrl.dispose();
    _observacionesCtrl.dispose();
    _itvCtrl.dispose();
    super.dispose();
  }

  String? _normalize(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _validateRequired(String? raw, String field) {
    if (raw == null || raw.trim().isEmpty) return '$field obligatorio';
    return null;
  }

  Future<void> _pickItv() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaItv ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'Fecha próxima ITV',
    );
    if (picked == null) return;
    setState(() {
      _fechaItv = picked;
      final dd = picked.day.toString().padLeft(2, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      _itvCtrl.text = '$dd/$mm/${picked.year}';
    });
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final data = VehiculoCreate(
      codigoInterno: _codigoCtrl.text.trim(),
      matricula: _matriculaCtrl.text.trim(),
      tipo: _tipo,
      ubicacionBase: _ubicacion?.label,
      ubicacionBaseId: _ubicacion?.id,
      marcaModelo: _normalize(_marcaModeloCtrl.text),
      fechaItv: _fechaItv,
      observaciones: _normalize(_observacionesCtrl.text),
    );
    ref.read(altaVehiculoViewModelProvider.notifier).submit(data);
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubmit = ref.watch(altaVehiculoViewModelProvider);

    ref.listen(altaVehiculoViewModelProvider, (prev, next) {
      next.whenOrNull(
        data: (created) {
          if (created == null) return;
          AppSnackbar.show(
            context,
            message: 'Vehículo ${created.codigoInterno} registrado.',
            variant: AppSnackbarVariant.success,
          );
          ref.read(vehiculosListViewModelProvider.notifier).refresh();
          context.go('/inventario/vehiculos/${created.id}');
        },
        error: (error, _) {
          if (error is Failure) {
            AppSnackbar.show(
              context,
              message: error.message ?? 'No se pudo registrar el vehículo.',
              variant: AppSnackbarVariant.danger,
            );
          }
        },
      );
    });

    return AppPageScaffold(
      maxContentWidth: AppBreakpoints.formMaxWidth,
      title: 'Nuevo vehículo',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              'Tipo de vehículo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: TipoVehiculo.values.map((t) {
                final label = switch (t) {
                  TipoVehiculo.furgoneta => 'Furgoneta',
                  TipoVehiculo.pickUp => 'Pick-up',
                  TipoVehiculo.ambulancia => 'Ambulancia',
                  TipoVehiculo.remolque => 'Remolque',
                };
                return ChoiceChip(
                  key: K.altaVehiculoTipoChip(t.wire),
                  label: Text(label),
                  selected: _tipo == t,
                  onSelected: (_) => setState(() => _tipo = t),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Datos obligatorios',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: K.altaVehiculoCodigo,
              label: 'Código interno',
              controller: _codigoCtrl,
              autofocus: true,
              prefixIcon: Symbols.qr_code_2,
              validator: (v) => _validateRequired(v, 'Código'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.altaVehiculoMatricula,
              label: 'Matrícula',
              controller: _matriculaCtrl,
              prefixIcon: Symbols.directions_car,
              validator: (v) => _validateRequired(v, 'Matrícula'),
            ),
            const SizedBox(height: AppSpacing.md),
            UbicacionSelectorField(
              fieldKey: K.altaVehiculoUbicacion,
              value: _ubicacion,
              onChanged: (u) => setState(() => _ubicacion = u),
              validator: (v) => v == null ? 'Ubicación obligatoria' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Datos opcionales',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              key: K.altaVehiculoMarcaModelo,
              label: 'Marca y modelo',
              controller: _marcaModeloCtrl,
              prefixIcon: Symbols.commute,
            ),
            const SizedBox(height: AppSpacing.md),
            // Guía 28 §WCAG 4.1.2: rol real = botón que abre date
            // picker, no TextField. Semantics fuerza la interpretación
            // para el screen reader.
            Semantics(
              label: 'Próxima ITV',
              button: true,
              child: GestureDetector(
                key: K.altaVehiculoItv,
                onTap: _pickItv,
                child: AbsorbPointer(
                  child: AppTextField(
                    label: 'Próxima ITV',
                    controller: _itvCtrl,
                    prefixIcon: Symbols.event,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: K.altaVehiculoObservaciones,
              label: 'Observaciones',
              controller: _observacionesCtrl,
              prefixIcon: Symbols.notes,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              key: K.altaVehiculoSubmit,
              label: 'Registrar vehículo',
              icon: Symbols.directions_car_filled,
              expanded: true,
              isLoading: asyncSubmit.isLoading,
              onPressed: asyncSubmit.isLoading ? null : _onSubmit,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              key: K.altaVehiculoCancel,
              label: 'Cancelar',
              expanded: true,
              onPressed: asyncSubmit.isLoading
                  ? null
                  : () => context.go('/inventario'),
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
      title: 'Nuevo vehículo',
      body: AppEmptyState(
        title: 'Sin acceso',
        description: 'Tu rol no permite registrar vehículos.',
        icon: Symbols.lock,
      ),
    );
  }
}
