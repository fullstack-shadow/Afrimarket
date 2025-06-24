import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminActivityType { order, user, payment, system }

class AdminActivity {
  final String id;
  final AdminActivityType type;
  final String description;
  final DateTime timestamp;
  final String timeAgo;

  AdminActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.timeAgo,
  });

  factory AdminActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inMinutes}m ago';
    }

    return AdminActivity(
      id: doc.id,
      type: AdminActivityType.values[data['type'] ?? 0],
      description: data['description'] ?? '',
      timestamp: timestamp,
      timeAgo: timeAgo,
    );
  }
}
