import 'package:flutter/material.dart';
import '../../domain/models/onboarding_model.dart';

class OnboardingController extends ChangeNotifier {
  bool _isSubmitting = false;
  OnboardingData _onboardingData = const OnboardingData();

  bool get isSubmitting => _isSubmitting;
  OnboardingData get onboardingData => _onboardingData;

  Future<void> completeBuyerProfile({
    required String name,
    required String address,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      // TODO: Implement buyer profile completion logic
      await Future.delayed(const Duration(seconds: 1));
      
      _onboardingData = _onboardingData.copyWith(
        buyerCompleted: true,
      );
      
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Add other onboarding methods as needed
  Future<void> completeSellerOnboarding({
    required String shopName,
    required String category,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      _onboardingData = _onboardingData.copyWith(
        sellerCompleted: true,
        shopName: shopName,
        shopCategory: category,
      );
      
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void updateSelectedRole(String role) {
    // Handle role selection if needed
    notifyListeners();
  }
}
