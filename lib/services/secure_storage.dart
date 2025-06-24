import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAuthToken = 'auth_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserRole = 'user_role';

  Future<void> saveAuthTokens({
    required String authToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAuthToken, value: authToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
  }

  Future<Map<String, String?>> getAuthTokens() async {
    final results = await Future.wait([
      _storage.read(key: _keyAuthToken),
      _storage.read(key: _keyRefreshToken),
    ]);
    return {
      'authToken': results[0],
      'refreshToken': results[1],
    };
  }

  Future<void> saveUserCredentials({
    required String userId,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyUserRole, value: role),
    ]);
  }

  Future<Map<String, String?>> getUserCredentials() async {
    final results = await Future.wait([
      _storage.read(key: _keyUserId),
      _storage.read(key: _keyUserRole),
    ]);
    return {
      'userId': results[0],
      'role': results[1],
    };
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}