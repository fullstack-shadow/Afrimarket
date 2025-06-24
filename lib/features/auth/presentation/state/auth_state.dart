import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final bool isAdmin;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.userId,
    this.userEmail,
    this.userName,
    this.isAdmin = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    String? userId,
    String? userEmail,
    String? userName,
    bool? isAdmin,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  @override
  String toString() {
    return 'AuthState(\n'
        '  isLoading: $isLoading,\n'
        '  error: $error,\n'
        '  isAuthenticated: $isAuthenticated,\n'
        '  userId: $userId,\n'
        '  userEmail: $userEmail,\n'
        '  userName: $userName,\n'
        '  isAdmin: $isAdmin\n'
        ')';
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Call repository to perform login
      final success = await ref.read(authRepositoryProvider).login(email, password);
      
      if (success) {
        // Update state on success
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userEmail: email,
          // TODO: Get actual user data from the response
          userId: 'user_123',
          userName: email.split('@').first,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Login failed. Please check your credentials.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred during login: $e',
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Call repository to perform registration
      final success = await ref
          .read(authRepositoryProvider)
          .register(name, email, password);

      if (success) {
        // Update state on success
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userEmail: email,
          userName: name,
          // TODO: Get actual user data from the response
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Registration failed. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred during registration: $e',
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(authRepositoryProvider).logout();
      state = const AuthState(); // Reset to initial state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An error occurred during logout',
      );
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
