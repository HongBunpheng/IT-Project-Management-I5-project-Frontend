import 'dart:convert';

import '../utils/json_utils.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AttendanceService {
  final ApiClient _api;
  final TokenStorage _tokenStorage;

  AttendanceService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _api = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, dynamic>> checkIn({required String code}) async {
    final userId = await _ensureUserId();
    if (userId == null || userId.isEmpty) {
      return {
        'statusCode': 400,
        'body': {'message': 'Missing user id. Please login again.'},
      };
    }

    final res = await _api.postJson(
      '/attendance/check-in',
      body: <String, dynamic>{'code': code, 'qr_code': code, 'user_id': userId},
    );

    final decoded = _safeDecode(res.body);
    return {'statusCode': res.statusCode, 'body': decoded};
  }

  Future<List<Map<String, dynamic>>> myAttendance(String userId) async {
    final res = await _api.getJson('/attendance/user/$userId');
    final decoded = _safeDecode(res.body);
    final data = decoded is Map<String, dynamic>
        ? (asList(decoded['data']) ??
              asList(decoded['attendance']) ??
              asList(decoded))
        : asList(decoded);

    return (data ?? const [])
        .map((e) => asMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> byTimetable(String timetableId) async {
    final res = await _api.getJson('/attendance/timetable/$timetableId');
    final decoded = _safeDecode(res.body);
    final data = decoded is Map<String, dynamic>
        ? (asList(decoded['data']) ??
              asList(decoded['attendance']) ??
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

  Future<String?> _ensureUserId() async {
    final existing = await _tokenStorage.readUserId();
    if (existing != null && existing.isNotEmpty) return existing;

    for (final path in const ['/auth/me', '/users/me']) {
      try {
        final res = await _api.getJson(path);
        final decoded = _safeDecode(res.body);
        final map = asMap(decoded);
        if (map == null) continue;

        final data = asMap(map['data']) ?? map;
        final user = asMap(data['user']) ?? data;
        final id = readString(user, const ['id', 'user_id']);
        if (id != null && id.isNotEmpty) {
          await _tokenStorage.writeUserId(id);
          final groupId = readString(user, const ['group_id', 'groupId']);
          if (groupId != null && groupId.isNotEmpty) {
            await _tokenStorage.writeGroupId(groupId);
          }
          return id;
        }
      } catch (_) {
        // ignore and try next
      }
    }

    return null;
  }
}
