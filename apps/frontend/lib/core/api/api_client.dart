import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required String baseUrl, http.Client? client})
    : _baseUri = Uri.parse(baseUrl),
      _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  Future<Object?> getJson(
    String path, {
    required ApiCredential credential,
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client.get(
      uri(path, queryParameters),
      headers: credential.headers,
    );
    return decodeJsonResponse(response);
  }

  Future<Object?> postJson(
    String path, {
    required ApiCredential credential,
    Object? body,
  }) async {
    final response = await _client.post(
      uri(path),
      headers: credential.jsonHeaders,
      body: body == null ? null : jsonEncode(body),
    );
    return decodeJsonResponse(response);
  }

  Future<Object?> putJson(
    String path, {
    required ApiCredential credential,
    Object? body,
  }) async {
    final response = await _client.put(
      uri(path),
      headers: credential.jsonHeaders,
      body: body == null ? null : jsonEncode(body),
    );
    return decodeJsonResponse(response);
  }

  Future<Object?> deleteJson(
    String path, {
    required ApiCredential credential,
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client.delete(
      uri(path, queryParameters),
      headers: credential.headers,
    );
    return decodeJsonResponse(response);
  }

  Uri uri(String path, [Map<String, String>? queryParameters]) {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    return _baseUri.replace(
      path: '$basePath$path',
      queryParameters: queryParameters,
    );
  }
}

class ApiCredential {
  const ApiCredential._(this.headers);

  factory ApiCredential.devUser(String userId) {
    return ApiCredential._({'X-Dev-User-Id': userId});
  }

  factory ApiCredential.bearerToken(String token) {
    return ApiCredential._({'Authorization': 'Bearer $token'});
  }

  final Map<String, String> headers;

  Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
    ...headers,
  };
}

Object? decodeJsonResponse(http.Response response) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw ApiException(response.statusCode, response.body);
  }
  if (response.statusCode == 204 || response.body.isEmpty) {
    return null;
  }
  return jsonDecode(response.body);
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() {
    return 'ApiException($statusCode): $body';
  }
}
