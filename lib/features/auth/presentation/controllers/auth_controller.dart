import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:afrimarket/features/auth/domain/models/user.dart';
import 'package:afrimarket/features/auth/presentation/state/auth_state.dart';
import 'package:afrimarket/features/auth/data/repositories/auth_repository.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthState());

  User? get currentUser => state.userId != null 
      ? User(
          id: state.userId!,
          email: state.userEmail ?? '',
          name: state.userName,
          joinedDate: DateTime.now(), // Required field
          role: state.isAdmin ? UserRole.admin : UserRole.buyer,
        )
      : null;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final success = await _authRepository.login(email, password);
      
      if (success) {
        // In a real app, you would fetch the user data here
        // For now, we'll create a placeholder user
        final user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: email.split('@').first,
          joinedDate: DateTime.now(),
          role: UserRole.buyer,
        );
        
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userId: user.id,
          userEmail: user.email,
          userName: user.name,
          isAdmin: user.role == UserRole.admin,
        );
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final success = await _authRepository.register(name, email, password);
      
      if (success) {
        // In a real app, you would fetch the newly created user data here
        final user = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: name,
          joinedDate: DateTime.now(),
          role: UserRole.buyer,
        );
        
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userId: user.id,
          userEmail: user.email,
          userName: user.name,
          isAdmin: user.role == UserRole.admin,
        );
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      state = const AuthState(); // Reset to initial state
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
      rethrow;
    }
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}
