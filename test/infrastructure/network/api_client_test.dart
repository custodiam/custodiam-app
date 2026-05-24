import 'dart:convert';

import 'package:custodiam/infrastructure/auth/auth_service.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:custodiam/infrastructure/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('http://example.test'));
  });

  late _MockAuthService auth;
  late _MockHttpClient http_;
  late ApiClient client;

  setUp(() {
    auth = _MockAuthService();
    http_ = _MockHttpClient();
    client = ApiClient(
      authService: auth,
      baseUrl: 'http://localhost:8000/api/v1',
      client: http_,
    );
  });

  group('GET', () {
    test('adds Authorization header when AuthService returns a token',
        () async {
      when(() => auth.getValidAccessToken())
          .thenAnswer((_) async => const Success('tok-123'));
      when(() => http_.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      final body = await client.get('/me');

      expect(body, {'ok': true});
      final captured = verify(
        () => http_.get(any(), headers: captureAny(named: 'headers')),
      ).captured.single as Map<String, String>;
      expect(captured['Authorization'], 'Bearer tok-123');
      expect(captured['Content-Type'], 'application/json');
    });

    test('omits Authorization when AuthService has no session', () async {
      when(() => auth.getValidAccessToken())
          .thenAnswer((_) async => const Fail(AuthFailure.sessionExpired()));
      when(() => http_.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{}', 200));

      await client.get('/public');

      final captured = verify(
        () => http_.get(any(), headers: captureAny(named: 'headers')),
      ).captured.single as Map<String, String>;
      expect(captured.containsKey('Authorization'), isFalse);
    });

    test('throws ApiException with status code on non-2xx', () async {
      when(() => auth.getValidAccessToken())
          .thenAnswer((_) async => const Success('tok'));
      when(() => http_.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('boom', 500));

      expect(
        () => client.get('/x'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('POST', () {
    test('serialises body as JSON and sends Bearer token', () async {
      when(() => auth.getValidAccessToken())
          .thenAnswer((_) async => const Success('tok-abc'));
      when(() => http_.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => http.Response('{}', 201));

      await client.post('/things', {'name': 'one'});

      final captured = verify(
        () => http_.post(
          any(),
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      final headers = captured[0] as Map<String, String>;
      final body = captured[1] as String;
      expect(headers['Authorization'], 'Bearer tok-abc');
      expect(jsonDecode(body), {'name': 'one'});
    });
  });
}
