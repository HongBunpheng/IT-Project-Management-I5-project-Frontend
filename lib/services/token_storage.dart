import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _groupIdKey = 'group_id';

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<String?> readUserId() => _storage.read(key: _userIdKey);

  Future<String?> readGroupId() => _storage.read(key: _groupIdKey);

  Future<void> writeUserId(String userId) =>
      _storage.write(key: _userIdKey, value: userId);

  Future<void> writeGroupId(String groupId) =>
      _storage.write(key: _groupIdKey, value: groupId);

  Future<void> clearUserContext() async {
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _groupIdKey);
  }
}
