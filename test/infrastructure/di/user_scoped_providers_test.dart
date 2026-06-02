// Regresión del bug "tras logout/login con otra cuenta se ven datos del
// usuario anterior". Demuestra empíricamente que (1) los providers
// por-usuario son keep-alive y cachean el estado del usuario previo, y
// (2) resetUserScopedProviders lo purga para que la siguiente lectura
// re-pida los datos del nuevo usuario. Headless (ProviderContainer), sin
// dispositivo.

import 'package:custodiam/features/voluntarios/domain/entities/estado_voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/entities/voluntario.dart';
import 'package:custodiam/features/voluntarios/domain/usecases/get_my_profile.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/mi_perfil_view_model.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_di.dart';
import 'package:custodiam/features/voluntarios/presentation/viewmodels/voluntarios_list_view_model.dart';
import 'package:custodiam/features/servicios/presentation/viewmodels/servicios_list_view_model.dart';
import 'package:custodiam/infrastructure/di/user_scoped_providers.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Use case falso que devuelve un voluntario distinto en cada llamada y
/// cuenta cuántas veces se le pide el perfil (proxy de "se ha vuelto a
/// cargar contra el backend con la sesión actual").
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

void main() {
  group('userScopedProviders / resetUserScopedProviders', () {
    test(
        'reproduce el bug: sin reset, miPerfil queda cacheado del usuario anterior',
        () async {
      final getMyProfile = _CountingGetMyProfile();
      final container = ProviderContainer(
        overrides: [getMyProfileProvider.overrideWithValue(getMyProfile)],
      );
      addTearDown(container.dispose);

      final primero = await container.read(miPerfilViewModelProvider.future);
      expect(primero.nombre, 'Usuario 1');
      expect(getMyProfile.llamadas, 1);

      // Segunda lectura SIN reset: el provider keep-alive devuelve el estado
      // cacheado y NO vuelve a pedir el perfil → quedaría el del usuario
      // anterior tras un cambio de cuenta. Esto ES el bug.
      final segundo = await container.read(miPerfilViewModelProvider.future);
      expect(segundo.nombre, 'Usuario 1');
      expect(getMyProfile.llamadas, 1);
    });

    test(
        'resetUserScopedProviders purga el estado: la siguiente lectura re-pide',
        () async {
      final getMyProfile = _CountingGetMyProfile();
      final container = ProviderContainer(
        overrides: [getMyProfileProvider.overrideWithValue(getMyProfile)],
      );
      addTearDown(container.dispose);

      final primero = await container.read(miPerfilViewModelProvider.future);
      expect(primero.nombre, 'Usuario 1');

      // Simula el logout: invalidar los providers por-usuario.
      resetUserScopedProviders(container.invalidate);

      final segundo = await container.read(miPerfilViewModelProvider.future);
      expect(segundo.nombre, 'Usuario 2'); // datos frescos del nuevo usuario
      expect(getMyProfile.llamadas, 2);
    });

    test('la lista incluye los providers por-usuario conocidos (anti-drift)',
        () {
      expect(userScopedProviders, contains(miPerfilViewModelProvider));
      expect(userScopedProviders, contains(voluntariosListViewModelProvider));
      expect(userScopedProviders, contains(serviciosListViewModelProvider));
      // Si alguien borra providers de la lista, este umbral lo delata.
      expect(userScopedProviders.length, greaterThanOrEqualTo(11));
    });
  });
}
