import 'package:cloud_firestore/cloud_firestore.dart';

class Referral {
  final String id;
  final String referrerId;
  final String refereeId;
  final DateTime timestamp;
  final bool isCompleted;
  final String? rewardGiven;

  Referral({
    required this.id,
    required this.referrerId,
    required this.refereeId,
    required this.timestamp,
    this.isCompleted = false,
    this.rewardGiven,
  });

  factory Referral.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Referral(
      id: doc.id,
      referrerId: data['referrer_id'],
      refereeId: data['referee_id'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isCompleted: data['is_completed'] ?? false,
      rewardGiven: data['reward_given'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'referrer_id': referrerId,
      'referee_id': refereeId,
      'timestamp': timestamp,
      'is_completed': isCompleted,
      if (rewardGiven != null) 'reward_given': rewardGiven,
    };
  }
}