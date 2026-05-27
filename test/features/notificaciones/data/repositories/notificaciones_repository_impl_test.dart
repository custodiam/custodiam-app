import 'package:custodiam/features/notificaciones/data/datasources/dispositivos_api.dart';
import 'package:custodiam/features/notificaciones/data/datasources/fcm_service.dart';
import 'package:custodiam/features/notificaciones/data/datasources/preferencias_local_data_source.dart';
import 'package:custodiam/features/notificaciones/data/repositories/notificaciones_repository_impl.dart';
import 'package:custodiam/features/notificaciones/domain/entities/dispositivo_registrado.dart';
import 'package:custodiam/features/notificaciones/domain/entities/notificacion_payload.dart';
import 'package:custodiam/features/notificaciones/domain/entities/plataforma_dispositivo.dart';
import 'package:custodiam/features/notificaciones/domain/entities/preferencias_notificaciones.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements DispositivosApi {}

class _MockFcm extends Mock implements FcmService {}

Map<String, dynamic> _dispositivoJson() => {
      'id': 'dev-1',
      'voluntario_id': 'vol-1',
      'fcm_token': 'token-abc',
      'plataforma': 'android',
      'activo': true,
      'created_at': '2026-05-28T10:00:00',
      'ultima_actualizacion': '2026-05-28T10:00:00',
    };

void main() {
  late _MockApi api;
  late _MockFcm fcm;
  late NotificacionesRepositoryImpl repo;

  setUp(() async {
    api = _MockApi();
    fcm = _MockFcm();
    SharedPreferences.setMockInitialValues(const {});
    repo = NotificacionesRepositoryImpl(
      fcm: fcm,
      api: api,
      preferencias: PreferenciasLocalDataSource(SharedPreferences.getInstance()),
    );
  });

  group('registrarMiDispositivo', () {
    test('returns Success(null) when FCM is not available', () async {
      when(() => fcm.isAvailable).thenReturn(false);

      final result = await repo.registrarMiDispositivo();

      switch (result) {
        case Success(:final value):
          expect(value, isNull);
        case Fail():
          fail('Expected Success(null)');
      }
      verifyNever(() => fcm.requestPermission());
      verifyNever(() => api.registrar(
            fcmToken: any(named: 'fcmToken'),
            plataforma: any(named: 'plataforma'),
          ));
    });

    test('returns Success(null) when the user denies the permission',
        () async {
      when(() => fcm.isAvailable).thenReturn(true);
      when(() => fcm.requestPermission()).thenAnswer((_) async => false);

      final result = await repo.registrarMiDispositivo();

      switch (result) {
        case Success(:final value):
          expect(value, isNull);
        case Fail():
          fail('Expected Success(null)');
      }
      verifyNever(() => fcm.getToken());
    });

    test('returns Success(null) when token is empty (Web sin VAPID)',
        () async {
      when(() => fcm.isAvailable).thenReturn(true);
      when(() => fcm.requestPermission()).thenAnswer((_) async => true);
      when(() => fcm.getToken()).thenAnswer((_) async => null);

      final result = await repo.registrarMiDispositivo();

      switch (result) {
        case Success(:final value):
          expect(value, isNull);
        case Fail():
          fail('Expected Success(null)');
      }
    });

    test('returns Success with the registered device on Success', () async {
      when(() => fcm.isAvailable).thenReturn(true);
      when(() => fcm.requestPermission()).thenAnswer((_) async => true);
      when(() => fcm.getToken()).thenAnswer((_) async => 'token-abc');
      when(() => fcm.plataforma).thenReturn(PlataformaDispositivo.android);
      when(() => api.registrar(
            fcmToken: 'token-abc',
            plataforma: PlataformaDispositivo.android,
          )).thenAnswer((_) async => _dispositivoJson());

      final result = await repo.registrarMiDispositivo();

      switch (result) {
        case Success(:final value):
          expect(value, isNotNull);
          expect(value!.id, 'dev-1');
          expect(value.fcmToken, 'token-abc');
        case Fail():
          fail('Expected Success');
      }
      expect(result, isA<Success<DispositivoRegistrado?>>());
    });

    test('maps 401 from POST /dispositivos to AuthFailure.sessionExpired',
        () async {
      when(() => fcm.isAvailable).thenReturn(true);
      when(() => fcm.requestPermission()).thenAnswer((_) async => true);
      when(() => fcm.getToken()).thenAnswer((_) async => 'token-abc');
      when(() => fcm.plataforma).thenReturn(PlataformaDispositivo.android);
      when(() => api.registrar(
            fcmToken: 'token-abc',
            plataforma: PlataformaDispositivo.android,
          )).thenThrow(ApiException(statusCode: 401, message: 'expired'));

      final result = await repo.registrarMiDispositivo();

      switch (result) {
        case Success():
          fail('Expected Fail');
        case Fail(:final failure):
          expect(failure, isA<SessionExpired>());
      }
    });
  });

  group('preferencias locales', () {
    test('getPreferencias devuelve defaults la primera vez', () async {
      final prefs = await repo.getPreferencias();
      expect(prefs.emergencias, isTrue);
      expect(prefs.nuevosServicios, isTrue);
      expect(prefs.recordatorios, isTrue);
    });

    test('setPreferencias persiste y devuelve los nuevos valores en load',
        () async {
      await repo.setPreferencias(const PreferenciasNotificaciones(
        nuevosServicios: false,
        recordatorios: false,
      ));

      final reloaded = await repo.getPreferencias();
      expect(reloaded.nuevosServicios, isFalse);
      expect(reloaded.recordatorios, isFalse);
      // Las emergencias quedan fijas a true por seguridad.
      expect(reloaded.emergencias, isTrue);
    });
  });

  group('streams + initial message', () {
    test('forwards onForegroundMessage from FcmService', () async {
      const payload = NotificacionPayload(
        tipo: 'emergencia',
        servicioId: 'svc-1',
        titulo: 'EMERGENCIA',
      );
      when(() => fcm.onForegroundMessage)
          .thenAnswer((_) => Stream.value(payload));

      final received = await repo.onForegroundMessage.first;

      expect(received.tipo, 'emergencia');
      expect(received.servicioId, 'svc-1');
    });

    test('forwards getInitialMessage from FcmService', () async {
      const payload = NotificacionPayload(servicioId: 'svc-9');
      when(() => fcm.getInitialMessage()).thenAnswer((_) async => payload);

      final initial = await repo.getInitialMessage();
      expect(initial?.servicioId, 'svc-9');
    });
  });
}
