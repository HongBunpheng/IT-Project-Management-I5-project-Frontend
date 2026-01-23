import 'dart:convert';
import 'dart:io';

import '../../services/api_client.dart';
import '../../configs/api_config.dart';
import '../../utils/json_utils.dart';

class AccountService {
  final ApiClient _api;

  AccountService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  /// Get current user profile
  /// Tries /users/me first, then falls back to /auth/me
  Future<Map<String, dynamic>?> getProfile() async {
    // Try /users/me endpoint first (as per API documentation)
    try {
      final res = await _api.getJson('/users/me');
      if (res.statusCode == 200) {
        final decoded = _safeJsonDecode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {
      // Fallback to /auth/me endpoint
    }

    // Fallback to /auth/me endpoint
    try {
      final res = await _api.getJson('/auth/me');
      if (res.statusCode == 200) {
        final decoded = _safeJsonDecode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {
      // ignore
    }

    return null;
  }

  /// Update user profile
  /// Supports updating user_name, email, phone_number, and avatar
  Future<Map<String, dynamic>?> updateProfile({
    String? userName,
    String? email,
    String? phoneNumber,
    File? avatar,
  }) async {
    try {
      final Map<String, String>? fields;
      if (userName != null || email != null || phoneNumber != null) {
        fields = <String, String>{};
        if (userName != null && userName.isNotEmpty) {
          fields['user_name'] = userName.trim();
        }
        if (email != null && email.isNotEmpty) {
          fields['email'] = email.trim();
        }
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          fields['phone_number'] = phoneNumber.trim();
        }
      } else {
        fields = null;
      }

      final Map<String, File>? files;
      if (avatar != null) {
        files = {'avatar': avatar};
      } else {
        files = null;
      }

      // Use PUT method for profile updates
      final response = await _api.putMultipart(
        '/users/me',
        fields: fields,
        files: files,
      );

      final decoded = _safeJsonDecode(response.body);
      
      // Always return consistent structure with statusCode and body
      return {
        'statusCode': response.statusCode,
        'body': decoded is Map<String, dynamic> ? decoded : {'message': response.body},
      };
    } catch (e) {
      return {
        'statusCode': 0,
        'body': {'message': 'Network error: $e'},
      };
    }
  }

  /// Upload profile avatar
  Future<Map<String, dynamic>?> uploadAvatar(File avatarFile) async {
    return await updateProfile(avatar: avatarFile);
  }

  /// Extract avatar URL from profile response
  /// Handles multiple response formats and constructs full URLs from relative paths
  String? extractAvatarUrl(Map<String, dynamic> response) {
    // Check for avatar_url at root level first (from upload response)
    String? avatarUrl = readString(response, const ['avatar_url']);

    // If no avatar_url at root, check user object
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final user = response['user'];
      if (user is Map<String, dynamic>) {
        avatarUrl = readString(user, const ['avatar_url']);
      }
    }

    // If still no avatar_url, try profile_picture and construct full URL
    if (avatarUrl == null || avatarUrl.isEmpty) {
      final user = response['user'] ?? response;
      final profilePicture = readString(user, const ['profile_picture']);
      if (profilePicture != null && profilePicture.isNotEmpty) {
        if (!profilePicture.startsWith('http')) {
          // Construct full URL from relative path
          final baseUri = Uri.parse(ApiConfig.baseUrl);
          avatarUrl =
              '${baseUri.scheme}://${baseUri.host}${baseUri.port != 80 && baseUri.port != 443 ? ':${baseUri.port}' : ''}/storage/$profilePicture';
        } else {
          avatarUrl = profilePicture;
        }
      }
    }

    // Only return if it's a valid full URL
    if (avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
      return avatarUrl;
    }

    return null;
  }

  /// Extract user data from profile response
  Map<String, dynamic> extractUserData(Map<String, dynamic> response) {
    final user = response['user'] ?? response;
    return asMap(user) ?? {};
  }

  dynamic _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return {'message': body};
    }
  }
}
