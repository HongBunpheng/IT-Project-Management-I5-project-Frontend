import 'dart:convert';

import '../../services/api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/json_utils.dart';
import '../../account/service/account_service.dart';

class AuthService {
  final ApiClient _api;
  final TokenStorage _tokenStorage;
  final AccountService _accountService;

  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    AccountService? accountService,
  })  : _api = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _accountService = accountService ?? AccountService();

  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final identifier = emailOrPhone.trim();
    final passwordTrimmed = password.trim();

    if (identifier.isEmpty || passwordTrimmed.isEmpty) {
      return {
        'statusCode': 400,
        'body': {'message': 'Please enter email and password'},
      };
    }

    // Validate email format
    if (!identifier.contains('@')) {
      return {
        'statusCode': 400,
        'body': {'message': 'Please enter a valid email address'},
      };
    }

    try {
      final res = await _api.postJson(
        '/auth/login',
        body: <String, dynamic>{
          'email': identifier,
          'password': passwordTrimmed,
        },
      );

      final decoded = _safeJsonDecode(res.body);
      final token = _extractToken(decoded);
      if (token != null && token.isNotEmpty) {
        await _tokenStorage.writeToken(token);
        // Store email securely for remember me functionality
        await _tokenStorage.writeEmail(identifier);
        await _tokenStorage.writeLastLogin(DateTime.now());
        
        // Try to store user context from login response first (might have some data)
        await _storeUserContextFromDecoded(decoded);
        
        // Always fetch from /auth/me to ensure we have full name and all user data
        // This is important because login response might not include full name
        await _storeUserContext();
        
        // Double-check: if still no full name, retry once more after a short delay
        final storedFullName = await _tokenStorage.readFullName();
        if (storedFullName == null || storedFullName.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 500));
          await _storeUserContext();
        }
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
      // Generate username from email (before @) or use name
      final userName = emailTrimmed.split('@').first.isNotEmpty
          ? emailTrimmed.split('@').first
          : nameTrimmed.toLowerCase().replaceAll(' ', '_');
      
      final res = await _api.postJson(
        '/auth/register',
        body: <String, dynamic>{
          'name': nameTrimmed,
          'full_name': nameTrimmed,
          'fullName': nameTrimmed,
          'user_name': userName,
          'userName': userName,
          'username': userName,
          'email': emailTrimmed,
          'phone': phoneTrimmed,
          'phone_number': phoneTrimmed,
          'password': passwordTrimmed,
          'password_confirmation': passwordTrimmed,
          'role': 'student',
        },
      );

      final decoded = _safeJsonDecode(res.body);
      final token = _extractToken(decoded);
      if (token != null && token.isNotEmpty) {
        await _tokenStorage.writeToken(token);
        // Store email/phone securely for remember me functionality
        await _tokenStorage.writeEmail(emailTrimmed);
        await _tokenStorage.writePhone(phoneTrimmed);
        // Store full name immediately since we have it from registration
        await _tokenStorage.writeFullName(nameTrimmed);
        await _tokenStorage.writeLastLogin(DateTime.now());
        
        // Try to store user context from response first (might have some data)
        await _storeUserContextFromDecoded(decoded);
        
        // Always fetch from /auth/me to ensure we have complete user data
        // This is important because registration response might not include all fields
        await _storeUserContext();
        
        // Double-check: if still no user ID, retry multiple times
        var userId = await _tokenStorage.readUserId();
        if (userId == null || userId.isEmpty) {
          // Retry up to 3 times with increasing delays
          for (int i = 0; i < 3; i++) {
            await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
            await _storeUserContext();
            userId = await _tokenStorage.readUserId();
            if (userId != null && userId.isNotEmpty) break;
          }
        }
        
        // Final verification: ensure full name and email are stored
        final storedFullName = await _tokenStorage.readFullName();
        final storedEmail = await _tokenStorage.readEmail();
        if (storedFullName == null || storedFullName.isEmpty) {
          // If full name is missing, use the one from registration form
          await _tokenStorage.writeFullName(nameTrimmed);
        }
        if (storedEmail == null || storedEmail.isEmpty) {
          // If email is missing, use the one from registration form
          await _tokenStorage.writeEmail(emailTrimmed);
        }
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
      // Clear all secure storage on logout
      await _tokenStorage.clearAll();
    }
  }

  Future<void> _storeUserContext() async {
    final decoded = await _accountService.getProfile();
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

    // Try multiple field names for full name (backend might use different field names)
    // IMPORTANT: Don't use user_name/username as they are different from full_name
    var fullName = readString(user, const ['full_name', 'fullName', 'name']);
    if (fullName == null) {
      // Also check in data level
      fullName = readString(data, const ['full_name', 'fullName', 'name']);
    }
    if (fullName == null) {
      // Check in root level
      fullName = readString(decoded, const ['full_name', 'fullName', 'name']);
    }
    
    // IMPORTANT: Only update full name if API returns a valid value
    // Never overwrite existing stored full name with null or empty
    if (fullName != null && fullName.isNotEmpty) {
      await _tokenStorage.writeFullName(fullName);
    } else {
      // If API doesn't return full name, check if we have one stored
      // If not stored, don't overwrite - preserve what we have
      final existingFullName = await _tokenStorage.readFullName();
      if (existingFullName == null || existingFullName.isEmpty) {
        // Only if we don't have one stored, we can't do anything
        // But don't overwrite with null/empty
      }
    }

    final email = readString(user, const ['email']);
    if (email != null && email.isNotEmpty) {
      await _tokenStorage.writeEmail(email);
    }
  }

  Future<bool> _storeUserContextFromDecoded(dynamic decoded) async {
    final map = asMap(decoded);
    if (map == null) return false;

    // Try multiple response structures
    final data = asMap(map['data']) ?? map;
    final user = asMap(data['user']) ?? 
                 asMap(map['user']) ?? 
                 asMap(data) ?? 
                 map;

    // Try to get user ID from various possible locations
    var userId = readString(user, const ['id', 'user_id', 'userId']);
    if (userId == null) {
      // Also check in data level
      userId = readString(data, const ['id', 'user_id', 'userId']);
    }
    if (userId == null) {
      // Check in root level
      userId = readString(map, const ['id', 'user_id', 'userId']);
    }
    
    var groupId = readString(user, const ['group_id', 'groupId']);
    if (groupId == null) {
      groupId = readString(data, const ['group_id', 'groupId']);
    }
    if (groupId == null) {
      groupId = readString(map, const ['group_id', 'groupId']);
    }

    var fullName = readString(user, const ['full_name', 'fullName', 'name']);
    if (fullName == null) {
      fullName = readString(data, const ['full_name', 'fullName', 'name']);
    }
    if (fullName == null) {
      fullName = readString(map, const ['full_name', 'fullName', 'name']);
    }

    var email = readString(user, const ['email']);
    if (email == null) {
      email = readString(data, const ['email']);
    }
    if (email == null) {
      email = readString(map, const ['email']);
    }

    var wroteAny = false;
    if (userId != null && userId.isNotEmpty) {
      await _tokenStorage.writeUserId(userId);
      wroteAny = true;
    }
    if (groupId != null && groupId.isNotEmpty) {
      await _tokenStorage.writeGroupId(groupId);
      wroteAny = true;
    }
    if (fullName != null && fullName.isNotEmpty) {
      await _tokenStorage.writeFullName(fullName);
      wroteAny = true;
    }
    if (email != null && email.isNotEmpty) {
      await _tokenStorage.writeEmail(email);
      wroteAny = true;
    }

    return wroteAny;
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
