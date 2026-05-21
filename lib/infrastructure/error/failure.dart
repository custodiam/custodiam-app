// Failure hierarchy used inside Result<T>.
//
// All sealed so Dart 3 exhaustive switch is enforced at use sites.
// Add new failure types as needed; never throw across layers.
// See guide 26 §4.

sealed class Failure {
  final String? message;
  const Failure([this.message]);
}

// ── Auth ─────────────────────────────────────────────────────────────

sealed class AuthFailure extends Failure {
  const AuthFailure([super.message]);

  const factory AuthFailure.invalidCredentials() = _InvalidCredentials;
  const factory AuthFailure.sessionExpired() = _SessionExpired;
  const factory AuthFailure.refreshFailed() = _RefreshFailed;
  const factory AuthFailure.userCancelled() = _UserCancelled;
  const factory AuthFailure.browserError() = _BrowserError;
  const factory AuthFailure.networkError() = _AuthNetworkError;
}

final class _InvalidCredentials extends AuthFailure {
  const _InvalidCredentials() : super('Credenciales inválidas');
}

final class _SessionExpired extends AuthFailure {
  const _SessionExpired() : super('Sesión expirada');
}

final class _RefreshFailed extends AuthFailure {
  const _RefreshFailed() : super('No se pudo refrescar la sesión');
}

final class _UserCancelled extends AuthFailure {
  const _UserCancelled() : super('Inicio de sesión cancelado');
}

final class _BrowserError extends AuthFailure {
  const _BrowserError() : super('No se pudo abrir el navegador');
}

final class _AuthNetworkError extends AuthFailure {
  const _AuthNetworkError() : super('Error de red durante la autenticación');
}

// ── Network ──────────────────────────────────────────────────────────

sealed class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);

  const factory NetworkFailure.serverError(int statusCode) = _ServerError;
  const factory NetworkFailure.timeout() = _Timeout;
  const factory NetworkFailure.noConnection() = _NoConnection;
  const factory NetworkFailure.unknown() = _Unknown;
}

final class _ServerError extends NetworkFailure {
  final int statusCode;
  const _ServerError(this.statusCode) : super('Error del servidor');
}

final class _Timeout extends NetworkFailure {
  const _Timeout() : super('Tiempo de espera agotado');
}

final class _NoConnection extends NetworkFailure {
  const _NoConnection() : super('Sin conexión');
}

final class _Unknown extends NetworkFailure {
  const _Unknown() : super('Error desconocido');
}

// ── Validation ───────────────────────────────────────────────────────

sealed class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);

  const factory ValidationFailure.invalidField(String field) = _InvalidField;
  const factory ValidationFailure.missingField(String field) = _MissingField;
}

final class _InvalidField extends ValidationFailure {
  final String field;
  const _InvalidField(this.field) : super('Campo inválido');
}

final class _MissingField extends ValidationFailure {
  final String field;
  const _MissingField(this.field) : super('Campo requerido');
}
