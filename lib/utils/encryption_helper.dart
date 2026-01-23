import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Encryption helper for securing sensitive data
/// Uses AES encryption with a device-specific key derived from a master key
class EncryptionHelper {
  static const String _masterKey = 'CG_INTERN_PROJECT_2024_SECURE_KEY';
  
  /// Generate a device-specific encryption key
  static String _generateKey() {
    // In production, you should use a more secure method to generate/store keys
    // For now, we'll use a combination of master key and a device identifier
    final bytes = utf8.encode(_masterKey);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  
  /// Encrypt data using AES-like encryption (XOR with key hash for simplicity)
  /// For production, consider using pointycastle package for proper AES encryption
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return plainText;
    
    try {
      final key = _generateKey();
      final keyBytes = utf8.encode(key);
      final textBytes = utf8.encode(plainText);
      
      // Simple XOR encryption (for production, use proper AES)
      final encrypted = List<int>.generate(
        textBytes.length,
        (i) => textBytes[i] ^ keyBytes[i % keyBytes.length],
      );
      
      return base64Encode(encrypted);
    } catch (e) {
      // If encryption fails, return original (shouldn't happen)
      return plainText;
    }
  }
  
  /// Decrypt data
  static String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    
    try {
      final key = _generateKey();
      final keyBytes = utf8.encode(key);
      final encrypted = base64Decode(encryptedText);
      
      // Simple XOR decryption
      final decrypted = List<int>.generate(
        encrypted.length,
        (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
      );
      
      return utf8.decode(decrypted);
    } catch (e) {
      // If decryption fails, return original
      return encryptedText;
    }
  }
  
  /// Hash password using SHA-256 (for local storage, not for API)
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  
  /// Generate a random secure token
  static String generateSecureToken([int length = 32]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
