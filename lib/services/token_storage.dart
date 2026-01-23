import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/encryption_helper.dart';

/// Secure storage for authentication tokens and user data
/// All sensitive data is encrypted before storage
class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _groupIdKey = 'group_id';
  static const _emailKey = 'user_email';
  static const _phoneKey = 'user_phone';
  static const _fullNameKey = 'user_full_name';
  static const _rememberMeKey = 'remember_me';
  static const _lastLoginKey = 'last_login';

  // Configure secure storage with additional security options
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Read and decrypt token
  Future<String?> readToken() async {
    try {
      final encrypted = await _storage.read(key: _tokenKey);
      if (encrypted == null) return null;
      return EncryptionHelper.decrypt(encrypted);
    } catch (e) {
      // If decryption fails, try reading as plain (for migration)
      return await _storage.read(key: _tokenKey);
    }
  }

  /// Encrypt and write token
  Future<void> writeToken(String token) async {
    try {
      final encrypted = EncryptionHelper.encrypt(token);
      await _storage.write(key: _tokenKey, value: encrypted);
    } catch (e) {
      // Fallback to plain storage if encryption fails
      await _storage.write(key: _tokenKey, value: token);
    }
  }

  /// Clear token
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  /// Read and decrypt user ID
  Future<String?> readUserId() async {
    try {
      final encrypted = await _storage.read(key: _userIdKey);
      if (encrypted == null) return null;
      return EncryptionHelper.decrypt(encrypted);
    } catch (e) {
      return await _storage.read(key: _userIdKey);
    }
  }

  /// Read and decrypt group ID
  Future<String?> readGroupId() async {
    try {
      final encrypted = await _storage.read(key: _groupIdKey);
      if (encrypted == null) return null;
      return EncryptionHelper.decrypt(encrypted);
    } catch (e) {
      return await _storage.read(key: _groupIdKey);
    }
  }

  /// Encrypt and write user ID
  Future<void> writeUserId(String userId) async {
    try {
      final encrypted = EncryptionHelper.encrypt(userId);
      await _storage.write(key: _userIdKey, value: encrypted);
    } catch (e) {
      await _storage.write(key: _userIdKey, value: userId);
    }
  }

  /// Encrypt and write group ID
  Future<void> writeGroupId(String groupId) async {
    try {
      final encrypted = EncryptionHelper.encrypt(groupId);
      await _storage.write(key: _groupIdKey, value: encrypted);
    } catch (e) {
      await _storage.write(key: _groupIdKey, value: groupId);
    }
  }

  /// Clear all user context
  Future<void> clearUserContext() async {
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _groupIdKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _fullNameKey);
    await _storage.delete(key: _rememberMeKey);
    await _storage.delete(key: _lastLoginKey);
  }

  /// Store user email (encrypted)
  Future<void> writeEmail(String email) async {
    try {
      final encrypted = EncryptionHelper.encrypt(email);
      await _storage.write(key: _emailKey, value: encrypted);
    } catch (e) {
      await _storage.write(key: _emailKey, value: email);
    }
  }

  /// Read user email (decrypted)
  Future<String?> readEmail() async {
    try {
      final encrypted = await _storage.read(key: _emailKey);
      if (encrypted == null) return null;
      return EncryptionHelper.decrypt(encrypted);
    } catch (e) {
      return await _storage.read(key: _emailKey);
    }
  }

  /// Store user phone (encrypted)
  Future<void> writePhone(String phone) async {
    try {
      final encrypted = EncryptionHelper.encrypt(phone);
      await _storage.write(key: _phoneKey, value: encrypted);
    } catch (e) {
      await _storage.write(key: _phoneKey, value: phone);
    }
  }

  /// Read user phone (decrypted)
  Future<String?> readPhone() async {
    try {
      final encrypted = await _storage.read(key: _phoneKey);
      if (encrypted == null) return null;
      return EncryptionHelper.decrypt(encrypted);
    } catch (e) {
      return await _storage.read(key: _phoneKey);
    }
  }

  /// Store user full name (encrypted)
  Future<void> writeFullName(String fullName) async {
    try {
      final encrypted = EncryptionHelper.encrypt(fullName);
      await _storage.write(key: _fullNameKey, value: encrypted);
    } catch (e) {
      await _storage.write(key: _fullNameKey, value: fullName);
    }
  }

  /// Read user full name (decrypted)
  Future<String?> readFullName() async {
    try {
      final encrypted = await _storage.read(key: _fullNameKey);
      if (encrypted == null) return null;
      return EncryptionHelper.decrypt(encrypted);
    } catch (e) {
      return await _storage.read(key: _fullNameKey);
    }
  }

  /// Store remember me preference
  Future<void> writeRememberMe(bool remember) async {
    await _storage.write(key: _rememberMeKey, value: remember.toString());
  }

  /// Read remember me preference
  Future<bool> readRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);
    return value == 'true';
  }

  /// Store last login timestamp
  Future<void> writeLastLogin(DateTime dateTime) async {
    await _storage.write(key: _lastLoginKey, value: dateTime.toIso8601String());
  }

  /// Read last login timestamp
  Future<DateTime?> readLastLogin() async {
    final value = await _storage.read(key: _lastLoginKey);
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }

  /// Clear all stored data (logout)
  Future<void> clearAll() async {
    await clearToken();
    await clearUserContext();
  }
}
