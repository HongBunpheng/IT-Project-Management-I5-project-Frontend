import 'dart:convert';

import 'package:cg_intern_project/services/api_client.dart';
import 'package:cg_intern_project/services/event_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this._body);

  final String _body;
  String? lastPath;

  @override
  Future<http.Response> getJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastPath = path;
    return http.Response(_body, 200);
  }

  @override
  Future<http.Response> postJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> putJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> deleteJson(
    String path, {
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('EventService.list parses root list response', () async {
    final fake = _FakeApiClient(
      jsonEncode([
        {'id': 1, 'title': 'Midterm Exam', 'type': 'exam'},
      ]),
    );
    final service = EventService(apiClient: fake);

    final events = await service.list();

    expect(fake.lastPath, '/events');
    expect(events, hasLength(1));
    expect(events.first['title'], 'Midterm Exam');
  });

  test('EventService.list parses {data: [...]} response', () async {
    final fake = _FakeApiClient(
      jsonEncode({
        'data': [
          {'id': 1, 'title': 'Midterm Exam', 'type': 'exam'},
        ],
      }),
    );
    final service = EventService(apiClient: fake);

    final events = await service.list();

    expect(events, hasLength(1));
    expect(events.first['type'], 'exam');
  });
}
