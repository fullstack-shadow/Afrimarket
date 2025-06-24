import 'package:flutter/material.dart';

import 'onboarding_model.dart';
import 'user_role.dart';
import '../../data/onboarding_repository.dart';

// Temporary interfaces for missing dependencies
abstract class AuthService {
  String? get currentUserId;
  Future<void> updateUserRole({required bool isSeller});
}

abstract class AppRouter {
  static void pushNamed(String route) {}
  static void pushReplacementNamed(String route) {}
}

class OnboardingController extends ChangeNotifier {
  final OnboardingRepository _repository;
  final AuthService _authService;

  OnboardingController({
    required OnboardingRepository repository,
    required AuthService authService,
  })  : _repository = repository,
        _authService = authService;

  bool _isSubmitting = false;
  UserRole? _selectedRole;
  OnboardingData _onboardingData = const OnboardingData();

  bool get isSubmitting => _isSubmitting;
  UserRole? get selectedRole => _selectedRole;
  OnboardingData get onboardingData => _onboardingData;

  void selectRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  void nextScreen() {
    final role = _selectedRole;
    if (role == null) {
      AppRouter.pushNamed('/onboarding/role');
    } else if (role == UserRole.seller && !_onboardingData.sellerCompleted) {
      AppRouter.pushNamed('/onboarding/seller');
    } else if (role == UserRole.buyer && !_onboardingData.buyerCompleted) {
      AppRouter.pushNamed('/onboarding/buyer');
    } else {
      AppRouter.pushNamed('/onboarding/complete');
    }
  }

  Future<void> completeSellerOnboarding({
    required String shopName,
    required String category,
  }) async {
    try {
      _isSubmitting = true;
      notifyListeners();

      await _repository.saveSellerOnboarding(
        userId: _authService.currentUserId!,
        shopName: shopName,
        category: category,
      );

      _onboardingData = _onboardingData.copyWith(
        sellerCompleted: true,
        shopName: shopName,
        shopCategory: category,
      );

      nextScreen();
    } catch (e) {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> completeBuyerOnboarding({
    required List<String> interests,
  }) async {
    try {
      _isSubmitting = true;
      notifyListeners();

      await _repository.saveBuyerOnboarding(
        userId: _authService.currentUserId!,
        interests: interests,
      );

      _onboardingData = _onboardingData.copyWith(
        buyerCompleted: true,
        interests: interests,
      );

      nextScreen();
    } catch (e) {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    try {
      _isSubmitting = true;
      notifyListeners();

      await _repository.markOnboardingComplete(
        userId: _authService.currentUserId!,
        role: _selectedRole!,
      );

      // Update user role in auth service
      await _authService.updateUserRole(
        isSeller: _selectedRole == UserRole.seller,
      );

      // Navigate to appropriate home screen
      if (_selectedRole == UserRole.seller) {
        AppRouter.pushReplacementNamed('/seller');
      } else {
        AppRouter.pushReplacementNamed('/home');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}