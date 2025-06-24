// lib/features/auth/data/auth_repository.dart

import 'dart:async';
import 'package:afrimarket/core/utils/logger.dart' as app_logger;
import 'package:afrimarket/features/auth/domain/models/user.dart';
import 'package:afrimarket/services/network_client.dart';
import 'package:afrimarket/services/secure_storage.dart';
import 'package:afrimarket/services/cloud_storage.dart' as cloud_storage;
import 'package:dio/dio.dart';

abstract class AuthRepository {
  // Authentication operations
  Future<User> login(String email, String password);
  Future<User> signup(User newUser);
  Future<void> resetPassword(String email);
  Future<void> logout();

  // User management
  Future<User?> getCachedUser();
  Future<void> updateUserProfile(User updatedUser);
  Future<void> verifyPhoneNumber(String phoneNumber);

  // Session management
  Future<void> cacheUserSession(User user);
  Future<void> clearUserSession();

  // Security
  Future<void> setVerificationStatus(bool emailVerified, bool phoneVerified);
}

class AuthRepositoryImpl implements AuthRepository {
  final NetworkClient _networkClient;
  final SecureStorage _secureStorage;
  final cloud_storage.CloudStorageService _cloudStorage;

  AuthRepositoryImpl({
    required NetworkClient networkClient,
    required SecureStorage secureStorage,
    required cloud_storage.CloudStorageService cloudStorage,
  })  : _networkClient = networkClient,
        _secureStorage = secureStorage,
        _cloudStorage = cloudStorage;

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await _networkClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final user = User.fromJson(response.data['user']);
      await cacheUserSession(user);
      return user;
    } on DioException catch (e) {
      app_logger.logger.e('Login failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<User> signup(User newUser) async {
    try {
      final response = await _networkClient.post(
        '/auth/signup',
        data: newUser.toJson(),
      );

      final createdUser = User.fromJson(response.data['user']);
      await cacheUserSession(createdUser);
      return createdUser;
    } on DioException catch (e) {
      app_logger.logger.e('Signup failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _networkClient.post(
        '/auth/reset-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      app_logger.logger.e('Password reset failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _networkClient.post('/auth/logout', data: {});
      await clearUserSession();
    } on DioException catch (e) {
      app_logger.logger.e('Logout failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<User?> getCachedUser() async {
    try {
      final credentials = await _secureStorage.getUserCredentials();
      final tokens = await _secureStorage.getAuthTokens();

      if (credentials['userId'] == null || tokens['authToken'] == null) {
        return null;
      }

      return User(
        id: credentials['userId']!,
        email: credentials['email'] ?? '',
        role: _parseUserRole(credentials['role']),
        joinedDate: DateTime.now(),
      );
    } catch (e) {
      app_logger.logger.e('Error retrieving cached user: $e');
      return null;
    }
  }

  @override
  Future<void> cacheUserSession(User user) async {
    try {
      await _secureStorage.saveUserCredentials(
        userId: user.id,
        email: user.email,
        role: user.role.toString().split('.').last,
      );
      await _secureStorage.saveAuthTokens(
        authToken: 'dummy_token', // Replace with actual token
        refreshToken: 'dummy_refresh_token', // Replace with actual refresh token
      );
    } catch (e) {
      app_logger.logger.e('Caching user session failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearUserSession() async {
    try {
      await _secureStorage.saveAuthTokens(authToken: '', refreshToken: '');
    } catch (e) {
      app_logger.logger.e('Clearing user session failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile(User updatedUser) async {
    try {
      if (updatedUser.profilePictureUrl != null && updatedUser.profilePictureUrl!.startsWith('file:')) {
        final downloadUrl = await _cloudStorage.uploadFile(
          updatedUser.profilePictureUrl!,
          'user-profiles/${updatedUser.id}',
        );
        updatedUser = updatedUser.copyWith(profilePictureUrl: downloadUrl);
      }

      await _networkClient.put(
        '/users/${updatedUser.id}',
        data: updatedUser.toJson(),
      );
      await cacheUserSession(updatedUser);
    } on DioException catch (e) {
      app_logger.logger.e('Updating user profile failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    try {
      if (!phoneNumber.startsWith('+')) {
        throw FormatException('Phone number must include country code');
      }

      await _networkClient.post(
        '/auth/verify-phone',
        data: {'phoneNumber': phoneNumber},
      );
    } on DioException catch (e) {
      app_logger.logger.e('Phone verification failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> setVerificationStatus(
    bool emailVerified,
    bool phoneVerified,
  ) async {
    try {
      final userId = (await _secureStorage.getUserCredentials())['userId'];
      if (userId == null) return;

      app_logger.logger.i('Verification status updated - Email: $emailVerified, Phone: $phoneVerified');
    } catch (e) {
      app_logger.logger.e('Updating verification status failed: $e');
    }
  }

  UserRole _parseUserRole(String? roleString) {
    if (roleString == null) return UserRole.buyer;
    return UserRole.values.firstWhere(
      (role) => role.toString().split('.').last == roleString,
      orElse: () => UserRole.buyer,
    );
  }
}
