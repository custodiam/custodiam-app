// Persistencia local de preferencias de notificaciones con
// shared_preferences. Sin endpoint backend en MVP — vive solo en el
// cliente, lo que es coherente con el alcance de US-06-03.

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/preferencias_notificaciones.dart';

class PreferenciasLocalDataSource {
  static const _keyNuevosServicios = 'notificaciones.nuevos_servicios';
  static const _keyRecordatorios = 'notificaciones.recordatorios';

  final Future<SharedPreferences> _prefs;

  /// Inyecta el future para que los tests puedan pasar un `mock`
  /// pre-configurado con `SharedPreferences.setMockInitialValues`.
  const PreferenciasLocalDataSource(this._prefs);

  Future<PreferenciasNotificaciones> load() async {
    final prefs = await _prefs;
    return PreferenciasNotificaciones(
      // Las emergencias quedan fijas a true en el dominio. Aquí ignoramos
      // cualquier valor persistido para que un downgrade accidental no
      // deje al usuario sin alarma.
      emergencias: true,
      nuevosServicios: prefs.getBool(_keyNuevosServicios) ?? true,
      recordatorios: prefs.getBool(_keyRecordatorios) ?? true,
    );
  }

  Future<void> save(PreferenciasNotificaciones p) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyNuevosServicios, p.nuevosServicios);
    await prefs.setBool(_keyRecordatorios, p.recordatorios);
  }
}
