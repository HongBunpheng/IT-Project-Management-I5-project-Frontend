import 'dart:convert';

import '../utils/json_utils.dart';
import 'api_client.dart';

class LeaveRequestService {
  final ApiClient _api;

  LeaveRequestService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> create({
    required String reason,
    required String startDateIso,
    required String endDateIso,
  }) async {
    final res = await _api.postJson(
      '/leave-requests',
      body: <String, dynamic>{
        'reason': reason,
        'start_date': startDateIso,
        'end_date': endDateIso,
      },
    );
    final decoded = _safeDecode(res.body);
    return {'statusCode': res.statusCode, 'body': decoded};
  }

  Future<List<Map<String, dynamic>>> byStudent(String userId) async {
    final res = await _api.getJson('/leave-requests/user/$userId');
    final decoded = _safeDecode(res.body);
    final data = decoded is Map<String, dynamic>
        ? (asList(decoded['data']) ??
              asList(decoded['leave_requests']) ??
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
