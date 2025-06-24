class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  UserModel({
    required this.id,
    this.email,
    this.phone,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastActiveAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastActiveAt: DateTime.parse(map['lastActiveAt'] as String),
    );
  }
}
