import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  Future<bool> login(String email, String password) async {
    // TODO: Implement actual login logic
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<bool> register(String name, String email, String password) async {
    // TODO: Implement actual registration logic
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<void> logout() async {
    // TODO: Implement actual logout logic
    await Future.delayed(const Duration(milliseconds: 500));
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
