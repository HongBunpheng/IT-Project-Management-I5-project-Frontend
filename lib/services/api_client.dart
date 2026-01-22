import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../configs/api_config.dart';
import 'token_storage.dart';

class ApiClient {
  final http.Client _http;
  final TokenStorage _tokenStorage;

  ApiClient({http.Client? httpClient, TokenStorage? tokenStorage})
    : _http = httpClient ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<http.Response> getJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: queryParameters?.map((k, v) => MapEntry(k, '$v')),
    );
    final token = await _tokenStorage.readToken();

    return _http
        .get(
          uri,
          headers: <String, String>{
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
            ...?headers,
          },
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<http.Response> postJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final token = await _tokenStorage.readToken();

    return _http
        .post(
          uri,
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
            ...?headers,
          },
          body: jsonEncode(body ?? const <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<http.Response> putJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final token = await _tokenStorage.readToken();

    return _http
        .put(
          uri,
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
            ...?headers,
          },
          body: jsonEncode(body ?? const <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 20));
  }

  Future<http.Response> deleteJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final token = await _tokenStorage.readToken();

    return _http
        .delete(
          uri,
          headers: <String, String>{
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
            ...?headers,
          },
        )
        .timeout(const Duration(seconds: 20));
  }
}
