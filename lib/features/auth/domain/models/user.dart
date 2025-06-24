// lib/features/auth/domain/models/user.dart

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// Represents a user in the multi-channel social commerce platform
/// 
/// Includes Africa-specific features:
/// - M-Pesa phone verification
/// - Seller shop relationships
/// - Role-based access control
class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? profilePictureUrl;
  final UserRole role;
  final String? shopId;
  final DateTime joinedDate;
  final DateTime? lastLogin;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? fcmToken;
  final String? referralCode;

  const User({
    @required required this.id,
    @required required this.email,
    this.name,
    this.phoneNumber,
    this.profilePictureUrl,
    this.role = UserRole.buyer,
    this.shopId,
    @required required this.joinedDate,
    this.lastLogin,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.fcmToken,
    this.referralCode,
  });

  /// Creates a new user during registration
  factory User.initial({
    @required String id,
    @required String email,
    String? name,
    String? phoneNumber,
    UserRole role = UserRole.buyer,
    String? referralCode,
  }) {
    return User(
      id: id,
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      role: role,
      joinedDate: DateTime.now(),
      referralCode: referralCode,
    );
  }

  /// Returns a copy of the user with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profilePictureUrl,
    UserRole? role,
    String? shopId,
    DateTime? joinedDate,
    DateTime? lastLogin,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? fcmToken,
    String? referralCode,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      joinedDate: joinedDate ?? this.joinedDate,
      lastLogin: lastLogin ?? this.lastLogin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      fcmToken: fcmToken ?? this.fcmToken,
      referralCode: referralCode ?? this.referralCode,
    );
  }

  /// Converts user to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'role': role.index,
      'shopId': shopId,
      'joinedDate': joinedDate.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'fcmToken': fcmToken,
      'referralCode': referralCode,
    };
  }

  /// Creates user from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      role: UserRole.values[json['role'] as int],
      shopId: json['shopId'] as String?,
      joinedDate: DateTime.parse(json['joinedDate'] as String),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
      fcmToken: json['fcmToken'] as String?,
      referralCode: json['referralCode'] as String?,
    );
  }

  /// Checks if user can perform seller operations
  bool get isSeller => role == UserRole.seller || role == UserRole.sellerAdmin;

  /// Checks if user has admin privileges
  bool get isAdmin => role == UserRole.admin || role == UserRole.sellerAdmin;

  /// Validates phone number format for African countries
  bool get isValidPhoneNumber {
    if (phoneNumber == null) return false;
    // Validate African phone numbers (general pattern with country code)
    return RegExp(r'^\+[1-9]{1}[0-9]{3,14}$').hasMatch(phoneNumber!);
  }

  /// Gets country code from phone number
  String? get countryCode {
    if (!isValidPhoneNumber) return null;
    return phoneNumber!.substring(0, 4); // +254, +234, etc.
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        phoneNumber,
        profilePictureUrl,
        role,
        shopId,
        joinedDate,
        lastLogin,
        isEmailVerified,
        isPhoneVerified,
        fcmToken,
        referralCode,
      ];
}

/// User roles with Africa market hierarchy
enum UserRole {
  buyer,        // Regular customer
  seller,       // Individual seller or small shop
  admin,        // Platform administrator
  sellerAdmin,  // Large shop owner with admin privileges
}