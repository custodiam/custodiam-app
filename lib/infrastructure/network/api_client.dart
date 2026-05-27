// Centralised HTTP client for the FastAPI backend.
//
// Reads its base URL from EnvConfig and asks AuthService for a valid
// access token before every request (refreshing automatically when
// needed). Errors stay as ApiException at this layer; data-layer
// repositories convert them to Failure when crossing into domain
// (guide 26 §2).

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/env_config.dart';
import '../auth/auth_service.dart';
import '../error/result.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final AuthService _authService;

  ApiClient({
    required AuthService authService,
    String? baseUrl,
    http.Client? client,
  })  : _authService = authService,
        baseUrl = baseUrl ?? EnvConfig.apiBaseUrl,
        _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final result = await _authService.getValidAccessToken();
    if (result case Success(:final value)) {
      headers['Authorization'] = 'Bearer $value';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParams == null || queryParams.isEmpty) return uri;
    return uri.replace(queryParameters: <String, String>{
      ...uri.queryParameters,
      ...queryParams,
    });
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _client.get(
      _uri(path),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  /// GET returning a JSON array body plus the raw response headers so
  /// callers can read paging hints (e.g. `X-Total-Count`) without an
  /// extra HEAD request. Throws [ApiException] on non-2xx responses.
  Future<ApiResponse<List<dynamic>>> getList(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final response = await _client.get(
      _uri(path, queryParams),
      headers: await _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Expected JSON array, got ${decoded.runtimeType}',
      );
    }
    return ApiResponse(body: decoded, headers: response.headers);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: response.body,
    );
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Envelope used by [ApiClient.getList] to expose response headers along
/// with the decoded body. Generic on the body type so future helpers
/// (e.g. a typed `getRaw<T>`) can reuse it.
class ApiResponse<T> {
  final T body;
  final Map<String, String> headers;

  const ApiResponse({required this.body, required this.headers});
}
