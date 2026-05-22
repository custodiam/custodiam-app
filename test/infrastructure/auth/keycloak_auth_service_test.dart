// Pure-Dart tests for KeycloakAuthService.
//
// Surface that requires platform channels (launchUrl, app_links
// uriLinkStream) lives outside this file and is exercised by
// integration_test/. Here we cover the JSON restore path,
// token-availability getters and dispose safety using a mocktail
// TokenStore + a fake AppLinks.

import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:custodiam/infrastructure/auth/keycloak_auth_service.dart';
import 'package:custodiam/infrastructure/auth/token_store.dart';
import 'package:custodiam/infrastructure/error/failure.dart';
import 'package:custodiam/infrastructure/error/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockTokenStore extends Mock implements TokenStore {}

class _MockHttpClient extends Mock implements http.Client {}

class _FakeUri extends Fake implements Uri {}

class _FakeAppLinks implements AppLinks {
  final _controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get uriLinkStream => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

String _credentialsJson({
  required Duration expiresIn,
  String accessToken = 'access-token',
  String? refreshToken,
  List<String> scopes = const ['openid'],
}) {
  final expiration = DateTime.now().add(expiresIn).millisecondsSinceEpoch;
  final tokens = <String, dynamic>{
    'accessToken': accessToken,
    'tokenEndpoint':
        'http://localhost:8080/realms/custodiam/protocol/openid-connect/token',
    'scopes': scopes,
    'expiration': expiration,
  };
  if (refreshToken != null) {
    tokens['refreshToken'] = refreshToken;
  }
  return jsonEncode(tokens);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockTokenStore tokenStore;
  late _MockHttpClient httpClient;
  late KeycloakAuthService service;

  setUp(() {
    tokenStore = _MockTokenStore();
    httpClient = _MockHttpClient();
    service = KeycloakAuthService(
      tokenStore: tokenStore,
      appLinks: _FakeAppLinks(),
      httpClient: httpClient,
    );

    when(() => tokenStore.read()).thenAnswer((_) async => null);
    when(() => tokenStore.save(any())).thenAnswer((_) async {});
    when(() => tokenStore.clear()).thenAnswer((_) async {});
  });

  group('default state', () {
    test('isAuthenticated is false before init', () {
      expect(service.isAuthenticated, isFalse);
    });

    test('accessToken is null before init', () {
      expect(service.accessToken, isNull);
    });
  });

  group('init', () {
    test('does nothing when storage is empty', () async {
      await service.init();

      expect(service.isAuthenticated, isFalse);
      expect(service.accessToken, isNull);
      verifyNever(() => tokenStore.clear());
    });

    test('restores a non-expired session into memory', () async {
      when(() => tokenStore.read()).thenAnswer((_) async => _credentialsJson(
            expiresIn: const Duration(hours: 1),
            accessToken: 'fresh',
            refreshToken: 'refresh-1',
          ));

      await service.init();

      expect(service.isAuthenticated, isTrue);
      expect(service.accessToken, 'fresh');
    });

    test('clears storage when stored JSON is corrupt', () async {
      when(() => tokenStore.read())
          .thenAnswer((_) async => 'not really a json');

      await service.init();

      expect(service.isAuthenticated, isFalse);
      verify(() => tokenStore.clear()).called(1);
    });

    test('clears storage when credentials are expired without refresh',
        () async {
      when(() => tokenStore.read()).thenAnswer((_) async => _credentialsJson(
            expiresIn: const Duration(hours: -2),
          ));

      await service.init();

      expect(service.isAuthenticated, isFalse);
      verify(() => tokenStore.clear()).called(1);
    });
  });

  group('getValidAccessToken', () {
    test('returns Fail.sessionExpired when no session', () async {
      final result = await service.getValidAccessToken();
      expect(result, isA<Fail<String>>());
      result as Fail<String>;
      expect(result.failure, isA<AuthFailure>());
    });

    test('returns Success(token) when credentials are still valid',
        () async {
      when(() => tokenStore.read()).thenAnswer((_) async => _credentialsJson(
            expiresIn: const Duration(hours: 1),
            accessToken: 'fresh',
            refreshToken: 'refresh-1',
          ));
      await service.init();

      final result = await service.getValidAccessToken();
      expect(result, isA<Success<String>>());
      result as Success<String>;
      expect(result.value, 'fresh');
    });
  });

  group('logout', () {
    Future<void> primeWithSession({
      String refreshToken = 'refresh-1',
    }) async {
      when(() => tokenStore.read()).thenAnswer((_) async => _credentialsJson(
            expiresIn: const Duration(hours: 1),
            accessToken: 'fresh',
            refreshToken: refreshToken,
          ));
      await service.init();
    }

    test('returns Success without POST when no session is active',
        () async {
      final result = await service.logout();

      expect(result, isA<Success<void>>());
      verifyNever(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      );
      verify(() => tokenStore.clear()).called(1);
    });

    test('POSTs to endSessionEndpoint with refresh_token and clears '
        'local state on 204', () async {
      await primeWithSession(refreshToken: 'refresh-1');
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('', 204));

      final result = await service.logout();

      expect(result, isA<Success<void>>());
      final captured = verify(
        () => httpClient.post(
          captureAny(),
          headers: captureAny(named: 'headers'),
          body: captureAny(named: 'body'),
        ),
      ).captured;
      expect(captured[0].toString(), contains('/protocol/openid-connect/logout'));
      expect(
        captured[1] as Map<String, String>,
        containsPair('Content-Type', 'application/x-www-form-urlencoded'),
      );
      expect(
        captured[2] as Map<String, String>,
        containsPair('refresh_token', 'refresh-1'),
      );
      expect(service.isAuthenticated, isFalse);
      verify(() => tokenStore.clear()).called(1);
    });

    test('returns AuthFailure.networkError when POST throws', () async {
      await primeWithSession();
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('connection refused'));

      final result = await service.logout();

      expect(result, isA<Fail<void>>());
      result as Fail<void>;
      expect(result.failure, isA<AuthNetworkError>());
      // Local state is wiped even on network errors so the user is not
      // left half-authenticated.
      expect(service.isAuthenticated, isFalse);
      verify(() => tokenStore.clear()).called(1);
    });

    test('returns AuthFailure.serverError carrying the status code on 4xx',
        () async {
      await primeWithSession();
      when(
        () => httpClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Bad Request', 400));

      final result = await service.logout();

      expect(result, isA<Fail<void>>());
      result as Fail<void>;
      expect(result.failure, isA<AuthServerError>());
      expect((result.failure as AuthServerError).statusCode, 400);
      expect(service.isAuthenticated, isFalse);
    });
  });

  group('dispose', () {
    test('can be called even when never initialised', () {
      expect(service.dispose, returnsNormally);
    });
  });
}
