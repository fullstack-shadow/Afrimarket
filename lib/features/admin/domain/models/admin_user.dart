import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String id;
  final String name;
  final String email;
  final bool isSeller;
  final bool isActive;
  final DateTime joinedDate;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.isSeller,
    required this.isActive,
    required this.joinedDate,
  });

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      name: data['name'] ?? 'No Name',
      email: data['email'] ?? '',
      isSeller: data['is_seller'] ?? false,
      isActive: data['is_active'] ?? true,
      joinedDate: (data['joined_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  AdminUser copyWith({
    bool? isActive,
  }) {
    return AdminUser(
      id: id,
      name: name,
      email: email,
      isSeller: isSeller,
      isActive: isActive ?? this.isActive,
      joinedDate: joinedDate,
    );
  }
}
