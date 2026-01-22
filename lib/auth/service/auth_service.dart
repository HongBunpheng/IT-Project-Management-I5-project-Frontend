import 'dart:convert';

import '../../services/api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';

class AuthService {
  final ApiClient _api;
  final TokenStorage _tokenStorage;

  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _api = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final identifier = emailOrPhone.trim();
    final passwordTrimmed = password.trim();

    if (identifier.isEmpty || passwordTrimmed.isEmpty) {
      return {
        'statusCode': 400,
        'body': {'message': 'Please enter email/phone and password'},
      };
    }

    try {
      final res = await _api.postJson(
        '/auth/login',
        body: <String, dynamic>{
          'email_or_phone': identifier,
          'emailOrPhone': identifier,
          if (identifier.contains('@'))
            'email': identifier
          else
            'phone': identifier,
          'password': passwordTrimmed,
        },
      );

      final decoded = _safeJsonDecode(res.body);
      final token = _extractToken(decoded);
      if (token != null && token.isNotEmpty) {
        await _tokenStorage.writeToken(token);
        await _storeUserContext();
      }

      return {'statusCode': res.statusCode, 'body': decoded};
    } catch (e) {
      return {
        'statusCode': 0,
        'body': {'message': 'Network error: $e'},
      };
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final nameTrimmed = fullName.trim();
    final emailTrimmed = email.trim();
    final phoneTrimmed = phone.trim();
    final passwordTrimmed = password.trim();

    if (nameTrimmed.isEmpty ||
        emailTrimmed.isEmpty ||
        phoneTrimmed.isEmpty ||
        passwordTrimmed.isEmpty) {
      return {
        'statusCode': 400,
        'body': {'message': 'Please fill in all fields'},
      };
    }

    try {
      final res = await _api.postJson(
        '/auth/register',
        body: <String, dynamic>{
          'name': nameTrimmed,
          'full_name': nameTrimmed,
          'fullName': nameTrimmed,
          'email': emailTrimmed,
          'phone': phoneTrimmed,
          'phone_number': phoneTrimmed,
          'password': passwordTrimmed,
          'password_confirmation': passwordTrimmed,
        },
      );

      final decoded = _safeJsonDecode(res.body);
      final token = _extractToken(decoded);
      if (token != null && token.isNotEmpty) {
        await _tokenStorage.writeToken(token);
        await _storeUserContext();
      }

      return {'statusCode': res.statusCode, 'body': decoded};
    } catch (e) {
      return {
        'statusCode': 0,
        'body': {'message': 'Network error: $e'},
      };
    }
  }

  Future<void> logout() async {
    try {
      await _api.postJson('/auth/logout');
    } catch (_) {
      // ignore
    } finally {
      await _tokenStorage.clearToken();
      await _tokenStorage.clearUserContext();
    }
  }

  Future<Map<String, dynamic>?> me() async {
    try {
      final res = await _api.getJson('/auth/me');
      final decoded = _safeJsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // ignore
    }

    try {
      final res = await _api.getJson('/users/me');
      final decoded = _safeJsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // ignore
    }

    return null;
  }

  Future<void> _storeUserContext() async {
    final decoded = await me();
    if (decoded == null) return;

    final data = asMap(decoded['data']) ?? decoded;
    final user = asMap(data['user']) ?? data;

    final userId = readString(user, const ['id', 'user_id']);
    if (userId != null) {
      await _tokenStorage.writeUserId(userId);
    }

    final groupId = readString(user, const ['group_id', 'groupId']);
    if (groupId != null) {
      await _tokenStorage.writeGroupId(groupId);
    }
  }

  dynamic _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return {'message': body};
    }
  }

  String? _extractToken(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final direct = decoded['token'] ?? decoded['access_token'];
      if (direct is String) return direct;

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final nested = data['token'] ?? data['access_token'];
        if (nested is String) return nested;
      }
    }
    return null;
  }
}
