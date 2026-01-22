import 'dart:convert';

import '../utils/json_utils.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _api;

  NotificationService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _api.getJson('/notifications');
    final decoded = _safeDecode(res.body);
    final data = decoded is Map<String, dynamic>
        ? (asList(decoded['data']) ??
              asList(decoded['notifications']) ??
              asList(decoded))
        : asList(decoded);

    return (data ?? const [])
        .map((e) => asMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _api.putJson('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _api.putJson('/notifications/read-all');
  }

  dynamic _safeDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
