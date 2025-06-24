import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/models/user_role.dart';

class OnboardingRepository {
  final FirebaseFirestore _firestore;

  OnboardingRepository(this._firestore);

  Future<void> saveSellerOnboarding({
    required String userId,
    required String shopName,
    required String category,
  }) async {
    await _firestore.collection('user_onboarding').doc(userId).set({
      'role': UserRole.seller.name,
      'shop_name': shopName,
      'shop_category': category,
      'seller_setup_completed': true,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveBuyerOnboarding({
    required String userId,
    required List<String> interests,
  }) async {
    await _firestore.collection('user_onboarding').doc(userId).set({
      'role': UserRole.buyer.name,
      'interests': interests,
      'buyer_setup_completed': true,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markOnboardingComplete({
    required String userId,
    required UserRole role,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'onboarding_completed': true,
      'is_seller': role == UserRole.seller,
      'updated_at': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('user_onboarding').doc(userId).update({
      'onboarding_completed': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getOnboardingData(String userId) async {
    final doc = await _firestore.collection('user_onboarding').doc(userId).get();
    return doc.data() ?? {};
  }
}