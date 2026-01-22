import 'dart:convert';

import '../utils/json_utils.dart';
import 'api_client.dart';

class TimetableService {
  final ApiClient _api;

  TimetableService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<Map<String, dynamic>>> listByUser(String userId) async {
    final res = await _api.getJson('/timetable/user/$userId');
    final decoded = _safeDecode(res.body);
    final data = decoded is Map<String, dynamic>
        ? (asList(decoded['data']) ??
              asList(decoded['timetable']) ??
              asList(decoded))
        : asList(decoded);

    return (data ?? const [])
        .map((e) => asMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> listByGroup(String groupId) async {
    final res = await _api.getJson('/timetable/group/$groupId');
    final decoded = _safeDecode(res.body);
    final data = decoded is Map<String, dynamic>
        ? (asList(decoded['data']) ??
              asList(decoded['timetable']) ??
              asList(decoded))
        : asList(decoded);

    return (data ?? const [])
        .map((e) => asMap(e))
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
