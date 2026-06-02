// Verifica el guard de transición del AuthLifecycleListener (M1): solo el
// paso autenticado → no autenticado (logout) invalida los providers
// por-usuario; montar con sesión activa o el primer build NO invalidan.
// Widget test headless, sin dispositivo.

import 'package:custodiam/app/widgets/auth_lifecycle_listener.dart';
import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/get_my_profile.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/mi_perfil_view_model.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_di.dart';
import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/auth/current_user.dart';
import 'package:custodiam/infrastructure/di/providers.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// AuthService controlable: `setAuthenticated` mueve el ValueNotifier que el
/// listener observa.
class _ControllableAuth implements AuthService {
  final ValueNotifier<bool> _notifier;
  _ControllableAuth({bool initial = true}) : _notifier = ValueNotifier(initial);

  void setAuthenticated(bool value) => _notifier.value = value;

  @override
  bool get isAuthenticated => _notifier.value;
  @override
  Listenable get authStateListenable => _notifier;
  @override
  String? get accessToken => isAuthenticated ? 'tok' : null;
  @override
  CurrentUser? get currentUser => isAuthenticated
      ? const CurrentUser(sub: 'u', email: 'e@e', roles: ['voluntario'])
      : null;
  @override
  Future<void> init() async {}
  @override
  bool consumeExpiredFlag() => false;
  @override
  Future<Result<void>> login() async => const Success(null);
  @override
  Future<Result<void>> logout() async {
    setAuthenticated(false);
    return const Success(null);
  }

  @override
  Future<Result<String>> getValidAccessToken() async => const Success('tok');
}

/// Cuenta las cargas de perfil: un incremento = el provider se ha
/// recomputado (señal de que fue invalidado).
class _CountingGetMyProfile implements GetMyProfile {
  int llamadas = 0;
  @override
  Future<Result<Voluntario>> call() async {
    llamadas++;
    return Success(
      Voluntario(
        id: 'v$llamadas',
        nombre: 'Usuario $llamadas',
        telefono: '600000000',
        municipio: 'Zuera',
        fechaNacimiento: DateTime(1990, 1, 1),
        estado: EstadoVoluntario.activo,
        fechaAlta: DateTime(2026, 1, 1),
      ),
    );
  }
}

/// Observa miPerfil para que su invalidación dispare una recarga observable.
class _Probe extends ConsumerWidget {
  const _Probe();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(miPerfilViewModelProvider);
    return const SizedBox.shrink();
  }
}

Future<void> _pump(
  WidgetTester tester,
  _ControllableAuth auth,
  _CountingGetMyProfile getMyProfile,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        getMyProfileProvider.overrideWithValue(getMyProfile),
      ],
      child: const MaterialApp(
        home: AuthLifecycleListener(child: _Probe()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('montar con sesión activa NO invalida (M1)', (tester) async {
    final auth = _ControllableAuth(initial: true);
    final getMyProfile = _CountingGetMyProfile();

    await _pump(tester, auth, getMyProfile);

    // El perfil se cargó una vez por el watch del Probe; el listener al
    // montar NO debe haber invalidado (no hay segunda carga).
    expect(getMyProfile.llamadas, 1);
  });

  testWidgets('logout (true→false) invalida los providers por-usuario',
      (tester) async {
    final auth = _ControllableAuth(initial: true);
    final getMyProfile = _CountingGetMyProfile();

    await _pump(tester, auth, getMyProfile);
    expect(getMyProfile.llamadas, 1);

    auth.setAuthenticated(false); // logout real
    await tester.pumpAndSettle();

    // El listener invalidó miPerfil → el Probe lo recarga.
    expect(getMyProfile.llamadas, 2);
  });

  testWidgets('arrancar SIN sesión y luego loguear (false→true) NO invalida',
      (tester) async {
    final auth = _ControllableAuth(initial: false);
    final getMyProfile = _CountingGetMyProfile();

    await _pump(tester, auth, getMyProfile);
    final cargasTrasArranque = getMyProfile.llamadas;

    auth.setAuthenticated(true); // login
    await tester.pumpAndSettle();

    // El login no debe disparar el reset (solo true→false lo hace): la cuenta
    // de cargas no aumenta por culpa del listener.
    expect(getMyProfile.llamadas, cargasTrasArranque);
  });
}
