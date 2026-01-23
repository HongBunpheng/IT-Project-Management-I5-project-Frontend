import 'dart:convert';

import '../utils/json_utils.dart';
import 'api_client.dart';

class EventService {
  final ApiClient _api;

  EventService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.getJson('/events');
    final decoded = _safeDecode(res.body);

    final data = decoded is Map<String, dynamic>
        ? (asList(decoded['data']) ??
              asList(decoded['events']) ??
              asList(decoded['result']) ??
              asList(decoded))
        : asList(decoded);

    return (data ?? const [])
        .map(asMap)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  dynamic _safeDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
