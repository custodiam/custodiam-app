// Failure hierarchy used inside Result<T>.
//
// All sealed so Dart 3 exhaustive switch is enforced at use sites.
// Subclasses are public so the presentation layer can pattern-match
// each variant and decide how to render it. Add new failure types as
// needed; never throw across layers. See guide 26 §4.

sealed class Failure {
  final String? message;
  const Failure([this.message]);
}

// ── Auth ─────────────────────────────────────────────────────────────

sealed class AuthFailure extends Failure {
  const AuthFailure([super.message]);

  const factory AuthFailure.invalidCredentials() = InvalidCredentials;
  const factory AuthFailure.sessionExpired() = SessionExpired;
  const factory AuthFailure.refreshFailed() = RefreshFailed;
  const factory AuthFailure.userCancelled() = UserCancelled;
  const factory AuthFailure.browserError() = BrowserError;
  const factory AuthFailure.networkError() = AuthNetworkError;
  const factory AuthFailure.serverError(int statusCode) = AuthServerError;
  const factory AuthFailure.sessionStorageUnavailable() =
      SessionStorageUnavailable;
}

final class InvalidCredentials extends AuthFailure {
  const InvalidCredentials() : super('Credenciales inválidas');
}

final class SessionExpired extends AuthFailure {
  const SessionExpired() : super('Sesión expirada');
}

final class RefreshFailed extends AuthFailure {
  const RefreshFailed() : super('No se pudo refrescar la sesión');
}

final class UserCancelled extends AuthFailure {
  const UserCancelled() : super('Inicio de sesión cancelado');
}

final class BrowserError extends AuthFailure {
  const BrowserError() : super('No se pudo abrir el navegador');
}

final class AuthNetworkError extends AuthFailure {
  const AuthNetworkError() : super('Error de red durante la autenticación');
}

final class AuthServerError extends AuthFailure {
  final int statusCode;
  const AuthServerError(this.statusCode) : super('Error del servidor');
}

final class SessionStorageUnavailable extends AuthFailure {
  const SessionStorageUnavailable()
      : super('El navegador tiene el almacenamiento de sesión '
            'deshabilitado. Habilítalo en la configuración del navegador '
            'para iniciar sesión.');
}

// ── Network ──────────────────────────────────────────────────────────

sealed class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);

  const factory NetworkFailure.serverError(int statusCode) = ServerError;
  const factory NetworkFailure.timeout() = Timeout;
  const factory NetworkFailure.noConnection() = NoConnection;
  const factory NetworkFailure.unknown() = UnknownNetworkError;
}

final class ServerError extends NetworkFailure {
  final int statusCode;
  const ServerError(this.statusCode) : super('Error del servidor');
}

final class Timeout extends NetworkFailure {
  const Timeout() : super('Tiempo de espera agotado');
}

final class NoConnection extends NetworkFailure {
  const NoConnection() : super('Sin conexión');
}

final class UnknownNetworkError extends NetworkFailure {
  const UnknownNetworkError() : super('Error desconocido');
}

// ── Voluntarios ──────────────────────────────────────────────────────

sealed class VoluntariosFailure extends Failure {
  const VoluntariosFailure([super.message]);

  const factory VoluntariosFailure.notFound() = VoluntarioNotFound;
  const factory VoluntariosFailure.emailDuplicado() = EmailDuplicado;
}

final class VoluntarioNotFound extends VoluntariosFailure {
  const VoluntarioNotFound()
      : super('No hay un voluntario en BD vinculado a tu usuario. '
            'Pide al administrador que te dé de alta.');
}

final class EmailDuplicado extends VoluntariosFailure {
  const EmailDuplicado()
      : super('Ese email ya está registrado para otro voluntario.');
}

// ── Validation ───────────────────────────────────────────────────────

sealed class ValidationFailure extends Failure {
  const ValidationFailure([super.message]);

  const factory ValidationFailure.invalidField(String field) = InvalidField;
  const factory ValidationFailure.missingField(String field) = MissingField;
}

final class InvalidField extends ValidationFailure {
  final String field;
  const InvalidField(this.field) : super('Campo inválido');
}

final class MissingField extends ValidationFailure {
  final String field;
  const MissingField(this.field) : super('Campo requerido');
}
