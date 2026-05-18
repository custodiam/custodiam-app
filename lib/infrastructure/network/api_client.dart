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

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
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
