import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/referral.dart';

class ReferralRepository {
  final FirebaseFirestore _firestore;

  ReferralRepository(this._firestore);

  Future<void> recordReferral({
    required String referrerId,
    required String refereeId,
  }) async {
    await _firestore.collection('referrals').add({
      'referrer_id': referrerId,
      'referee_id': refereeId,
      'timestamp': FieldValue.serverTimestamp(),
      'is_completed': false,
    });

    // Increment referral count
    await _firestore.collection('user_referrals').doc(referrerId).update({
      'referral_count': FieldValue.increment(1),
    });
  }

  Future<int> getReferralCount(String userId) async {
    final doc = await _firestore.collection('user_referrals').doc(userId).get();
    return doc.data()?['referral_count'] ?? 0;
  }

  Stream<List<Referral>> getReferralsStream(String userId) {
    return _firestore
        .collection('referrals')
        .where('referrer_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Referral.fromFirestore(doc))
            .toList());
  }

  Future<void> markReferralComplete(String referralId, String reward) async {
    await _firestore.collection('referrals').doc(referralId).update({
      'is_completed': true,
      'reward_given': reward,
    });
  }
}