// Map every AuthFailure variant to the snackbar variant + message that
// best matches its semantics. Cancellation is info (not an error), a
// rejected credentials response or a server failure are danger,
// session-side issues are warning.
//
// Shared by LoginPage and the home placeholder so the user sees
// consistent wording regardless of which screen raised the failure.

import 'package:flutter/material.dart';

import '../../../../core/ui/feedback/app_snackbar.dart';
import '../../../../infrastructure/error/failure.dart';

void showAuthFailure(BuildContext context, AuthFailure failure) {
  final (variant, message) = _authFailureFeedback(failure);
  AppSnackbar.show(context, message: message, variant: variant);
}

(AppSnackbarVariant, String) _authFailureFeedback(AuthFailure failure) {
  return switch (failure) {
    UserCancelled() => (
        AppSnackbarVariant.info,
        'Has cancelado el inicio de sesión.',
      ),
    BrowserError() => (
        AppSnackbarVariant.danger,
        'No se pudo abrir el navegador para autenticarte. '
            'Verifica que tienes uno instalado y vuelve a intentarlo.',
      ),
    AuthNetworkError() => (
        AppSnackbarVariant.danger,
        'Error de red durante la autenticación. '
            'Comprueba tu conexión e inténtalo de nuevo.',
      ),
    InvalidCredentials() => (
        AppSnackbarVariant.danger,
        'Credenciales inválidas. Revisa el usuario y la contraseña.',
      ),
    SessionExpired() => (
        AppSnackbarVariant.warning,
        'Tu sesión ha expirado. Vuelve a iniciar sesión para continuar.',
      ),
    RefreshFailed() => (
        AppSnackbarVariant.warning,
        'No se pudo refrescar la sesión. Vuelve a iniciar sesión.',
      ),
    AuthServerError(:final statusCode) => (
        AppSnackbarVariant.danger,
        'El servidor de autenticación devolvió un error ($statusCode). '
            'Inténtalo de nuevo en unos minutos.',
      ),
    SessionStorageUnavailable() => (
        AppSnackbarVariant.warning,
        'Tu navegador tiene el almacenamiento de sesión deshabilitado. '
            'Habilítalo en la configuración del navegador para iniciar sesión.',
      ),
  };
}
