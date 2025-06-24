import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_package;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Secure encryption service for sensitive data
///
/// Principles:
/// 1. Readability: Clear method names and documentation
/// 2. Security: Industry-standard algorithms (AES-256)
/// 3. Modularity: Separate encryption/decryption concerns
/// 4. Testability: Mockable implementation
/// 5. Safety: Input validation and error handling
abstract class EncryptionService {
  /// Encrypts plaintext using AES-256-CBC with random IV
  ///
  /// [plaintext] - Data to encrypt (UTF-8 encoded)
  /// Returns base64 encoded string containing IV + ciphertext
  Future<String> encrypt(String plaintext);

  /// Decrypts ciphertext encrypted with encrypt()
  ///
  /// [ciphertext] - base64 encoded IV + ciphertext
  /// Returns original UTF-8 plaintext
  Future<String> decrypt(String ciphertext);

  /// Generates a cryptographically secure random key
  static Future<String> generateEncryptionKey() async {
    try {
      final key = encrypt_package.Key.fromSecureRandom(32);
      return base64Url.encode(key.bytes);
    } catch (e) {
      throw EncryptionException('Failed to generate encryption key: $e');
    }
  }

  /// Hashes data using SHA-256 for non-reversible operations
  Future<String> hashData(String data);
}

/// Implementation of EncryptionService using encrypt package
class AesEncryptionService implements EncryptionService {
  final encrypt_package.Encrypter _encrypter;
  final encrypt_package.Key _key;
  static const _ivLength = 16; // 128 bits for AES block size

  AesEncryptionService({required String encryptionKey})
      : _key = encrypt_package.Key.fromBase64(encryptionKey),
        _encrypter = encrypt_package.Encrypter(
          encrypt_package.AES(
            encrypt_package.Key.fromBase64(encryptionKey),
            mode: encrypt_package.AESMode.cbc,
          ),
        ) {
    if (_key.bytes.length != 32) {
      throw ArgumentError('Encryption key must be 32 bytes (AES-256)');
    }
  }

  @override
  Future<String> encrypt(String plaintext) async {
    if (plaintext.isEmpty) {
      throw ArgumentError('Plaintext cannot be empty');
    }

    try {
      // Generate random IV
      final iv = encrypt_package.IV.fromSecureRandom(_ivLength);

      // Encrypt the data
      final encrypted = _encrypter.encrypt(plaintext, iv: iv);

      // Combine IV + ciphertext
      final result = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);

      return base64Url.encode(result);
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  @override
  Future<String> decrypt(String ciphertext) async {
    if (ciphertext.isEmpty) {
      throw ArgumentError('Ciphertext cannot be empty');
    }

    try {
      // Decode base64
      final combined = base64Url.decode(ciphertext);

      // Extract IV (first 16 bytes)
      if (combined.length < _ivLength) {
        throw ArgumentError('Invalid ciphertext format');
      }
      final iv = encrypt_package.IV(Uint8List.sublistView(combined, 0, _ivLength));
      final encrypted = encrypt_package.Encrypted(Uint8List.sublistView(combined, _ivLength, combined.length));

      // Decrypt the data
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  @override
  Future<String> hashData(String data) async {
    if (data.isEmpty) {
      throw ArgumentError('Data cannot be empty for hashing');
    }
    try {
      final bytes = utf8.encode(data);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw EncryptionException('Hashing failed: $e');
    }
  }
}

/// Mock implementation for testing
class MockEncryptionService implements EncryptionService {
  final Map<String, String> _storage = {};

  @override
  Future<String> decrypt(String ciphertext) async {
    // In mock, we just return the same text as we stored
    return _storage.entries
        .firstWhere(
          (entry) => entry.value == ciphertext,
          orElse: () => throw Exception('Ciphertext not found'),
        )
        .key;
  }

  @override
  Future<String> encrypt(String plaintext) async {
    // In mock, we just store and return the same text
    _storage[plaintext] = plaintext;
    return plaintext;
  }

  @override
  Future<String> hashData(String data) async {
    // Simple mock hash
    return 'hashed_${data.length}';
  }
}

/// Custom encryption exceptions
class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}

/// Provider for encryption service
final encryptionServiceProvider = FutureProvider<EncryptionService>((ref) async {
  // In tests, use mock implementation
  if (kDebugMode && const bool.fromEnvironment('TEST_MODE')) {
    return MockEncryptionService();
  }

  // Get encryption key from secure storage
  final secureStorage = ref.read(secureStorageProvider);
  final encryptionKey = await secureStorage.getEncryptionKey();

  if (encryptionKey.isEmpty) {
    throw StateError('No encryption key found in secure storage');
  }

  return AesEncryptionService(encryptionKey: encryptionKey);
});

/// Secure storage abstraction
abstract class SecureStorage {
  /// Get the encryption key from secure storage
  Future<String> getEncryptionKey();

  /// Save the encryption key to secure storage
  Future<void> saveEncryptionKey(String key);

  /// Check if encryption key exists
  Future<bool> hasEncryptionKey();
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return throw UnimplementedError('SecureStorage provider must be overridden');
});
