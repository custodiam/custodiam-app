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
  const factory VoluntariosFailure.dniOrEmailDuplicado() =
      DniOrEmailDuplicado;
  const factory VoluntariosFailure.keycloakSyncFailed() = KeycloakSyncFailed;
  const factory VoluntariosFailure.rolYaAsignado() = RolYaAsignado;
  const factory VoluntariosFailure.rolOAsignacionNoEncontrado() =
      RolOAsignacionNoEncontrado;
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

final class DniOrEmailDuplicado extends VoluntariosFailure {
  const DniOrEmailDuplicado()
      : super('Ya existe un voluntario con ese DNI o email.');
}

final class KeycloakSyncFailed extends VoluntariosFailure {
  const KeycloakSyncFailed()
      : super('No se pudo crear la cuenta en Keycloak. '
            'Inténtalo de nuevo o avisa a un administrador.');
}

final class RolYaAsignado extends VoluntariosFailure {
  const RolYaAsignado()
      : super('Ese rol ya está asignado al voluntario.');
}

final class RolOAsignacionNoEncontrado extends VoluntariosFailure {
  const RolOAsignacionNoEncontrado()
      : super('El rol o la asignación ya no existen.');
}

// ── Servicios ────────────────────────────────────────────────────────

sealed class ServiciosFailure extends Failure {
  const ServiciosFailure([super.message]);

  const factory ServiciosFailure.notFound() = ServicioNotFound;
  const factory ServiciosFailure.transicionInvalida(String detalle) =
      TransicionInvalida;
  const factory ServiciosFailure.yaInscrito() = YaInscrito;
  const factory ServiciosFailure.inscripcionNoPermitida() =
      InscripcionNoPermitida;
  const factory ServiciosFailure.noInscrito() = NoInscrito;
}

final class ServicioNotFound extends ServiciosFailure {
  const ServicioNotFound() : super('El servicio ya no existe.');
}

final class TransicionInvalida extends ServiciosFailure {
  final String detalle;
  const TransicionInvalida(this.detalle) : super('Transición no permitida');
}

final class YaInscrito extends ServiciosFailure {
  const YaInscrito() : super('Ya estás apuntado a este servicio.');
}

final class InscripcionNoPermitida extends ServiciosFailure {
  const InscripcionNoPermitida()
      : super('El servicio no admite inscripciones en su estado actual.');
}

final class NoInscrito extends ServiciosFailure {
  const NoInscrito() : super('No estás apuntado a este servicio.');
}

// ── Fichaje ──────────────────────────────────────────────────────────

sealed class FichajeFailure extends Failure {
  const FichajeFailure([super.message]);

  const factory FichajeFailure.servicioNoActivo() = ServicioNoActivoParaFichar;
  const factory FichajeFailure.voluntarioNoInscrito() =
      VoluntarioNoInscritoParaFichar;
  const factory FichajeFailure.yaFichado() = YaFichado;
  const factory FichajeFailure.sinFichajeAbierto() = SinFichajeAbierto;
  const factory FichajeFailure.notFound() = FichajeNotFound;
}

final class ServicioNoActivoParaFichar extends FichajeFailure {
  const ServicioNoActivoParaFichar()
      : super('El servicio no admite fichajes en su estado actual.');
}

final class VoluntarioNoInscritoParaFichar extends FichajeFailure {
  const VoluntarioNoInscritoParaFichar()
      : super('No estás inscrito ni convocado a este servicio.');
}

final class YaFichado extends FichajeFailure {
  const YaFichado()
      : super('Ya tienes una entrada fichada en este servicio.');
}

final class SinFichajeAbierto extends FichajeFailure {
  const SinFichajeAbierto()
      : super('No tienes ninguna entrada fichada para cerrar.');
}

final class FichajeNotFound extends FichajeFailure {
  const FichajeNotFound() : super('Fichaje no encontrado.');
}

// ── Inventario ───────────────────────────────────────────────────────

sealed class InventarioFailure extends Failure {
  const InventarioFailure([super.message]);

  const factory InventarioFailure.notFound() = InventarioNotFound;
  const factory InventarioFailure.estadoFinal() = EstadoFinal;
  const factory InventarioFailure.materialNoOperativo() = MaterialNoOperativo;
  const factory InventarioFailure.tipoIncompatible() = TipoIncompatible;
  const factory InventarioFailure.yaAsignado() = YaAsignado;
  const factory InventarioFailure.cantidadInsuficiente() =
      CantidadInsuficiente;
  const factory InventarioFailure.vehiculoNoOperativo() = VehiculoNoOperativo;
  const factory InventarioFailure.estadoIncidenciaInvalido() =
      EstadoIncidenciaInvalido;
  const factory InventarioFailure.asignacionNoEncontrada() =
      AsignacionNoEncontrada;
}

final class InventarioNotFound extends InventarioFailure {
  const InventarioNotFound() : super('Recurso de inventario no encontrado.');
}

final class EstadoFinal extends InventarioFailure {
  const EstadoFinal()
      : super('El recurso está en un estado final y no admite cambios.');
}

final class MaterialNoOperativo extends InventarioFailure {
  const MaterialNoOperativo()
      : super('El material no está operativo: no se puede asignar.');
}

final class TipoIncompatible extends InventarioFailure {
  const TipoIncompatible()
      : super('El tipo de asignación no es compatible con el material.');
}

final class YaAsignado extends InventarioFailure {
  const YaAsignado() : super('El recurso ya está asignado.');
}

final class CantidadInsuficiente extends InventarioFailure {
  const CantidadInsuficiente()
      : super('No hay cantidad suficiente disponible para esta operación.');
}

final class VehiculoNoOperativo extends InventarioFailure {
  const VehiculoNoOperativo()
      : super('El vehículo no está operativo: no se puede asignar.');
}

final class EstadoIncidenciaInvalido extends InventarioFailure {
  const EstadoIncidenciaInvalido()
      : super('El estado solicitado no es válido para una incidencia.');
}

final class AsignacionNoEncontrada extends InventarioFailure {
  const AsignacionNoEncontrada()
      : super('No hay una asignación activa para devolver.');
}

// ── Disponibilidad ───────────────────────────────────────────────────

sealed class DisponibilidadFailure extends Failure {
  const DisponibilidadFailure([super.message]);

  const factory DisponibilidadFailure.fechaPasada() = FechaPasada;
  const factory DisponibilidadFailure.mesInvalido() = MesInvalido;
}

final class FechaPasada extends DisponibilidadFailure {
  const FechaPasada()
      : super('No puedes modificar la disponibilidad de un día pasado.');
}

final class MesInvalido extends DisponibilidadFailure {
  const MesInvalido()
      : super('El mes solicitado no es válido. Año entre 2000 y 2100, '
            'mes entre 1 y 12.');
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
