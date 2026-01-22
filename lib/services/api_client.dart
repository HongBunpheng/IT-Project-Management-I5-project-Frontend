import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  /// Upload multipart form data (for file uploads) using POST
  Future<http.Response> postMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, File>? files,
    Map<String, String>? headers,
  }) async {
    return _multipartRequest('POST', path, fields: fields, files: files, headers: headers);
  }

  /// Upload multipart form data (for file uploads) using PUT
  Future<http.Response> putMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, File>? files,
    Map<String, String>? headers,
  }) async {
    return _multipartRequest('PUT', path, fields: fields, files: files, headers: headers);
  }

  /// Internal method to handle multipart requests
  Future<http.Response> _multipartRequest(
    String method,
    String path, {
    Map<String, String>? fields,
    Map<String, File>? files,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final token = await _tokenStorage.readToken();

    final request = http.MultipartRequest(method, uri);
    
    // Add headers
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
      ...?headers,
    });

    // Add form fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add file fields
    if (files != null) {
      for (final entry in files.entries) {
        final file = entry.value;
        if (await file.exists()) {
          final fileStream = file.openRead();
          final fileLength = await file.length();
          final multipartFile = http.MultipartFile(
            entry.key,
            fileStream,
            fileLength,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    
    return response;
  }
}
