// Centralised HTTP client for the FastAPI backend.
//
// Reads its base URL from EnvConfig so it can be parameterised at
// build time with --dart-define. The token getter/setter is kept
// minimal for the bootstrap; the token-refresh integration with
// AuthService lands in EN-01-02 (see guide 25 §5).
//
// See guide 26 §2 (Data layer) and §8 (EnvConfig).

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/env_config.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _accessToken;

  ApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? EnvConfig.apiBaseUrl,
        _client = client ?? http.Client();

  void setToken(String token) {
    _accessToken = token;
  }

  void clearToken() {
    _accessToken = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
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
