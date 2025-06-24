// Defines the different roles a user can have in the application
enum UserRole {
  seller('seller'),
  buyer('buyer'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  // Convert string to UserRole enum
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value.toLowerCase(),
      orElse: () => UserRole.buyer, // Default to buyer if not found
    );
  }

  // Get display name for the role
  String displayName() {
    switch (this) {
      case UserRole.seller:
        return 'Seller';
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.admin:
        return 'Admin';
    }
  }

  // Get icon for the role
  String get icon {
    switch (this) {
      case UserRole.seller:
        return 'assets/icons/seller.png';
      case UserRole.buyer:
        return 'assets/icons/buyer.png';
      case UserRole.admin:
        return 'assets/icons/admin.png';
    }
  }

  // Check if role has admin privileges
  bool get isAdmin => this == UserRole.admin;

  // Check if role can create listings
  bool get canCreateListings => this == UserRole.seller || this == UserRole.admin;

  // Check if role can access admin dashboard
  bool get canAccessAdminDashboard => this == UserRole.admin;

  // Get the onboarding steps required for this role
  List<String> get requiredOnboardingSteps {
    switch (this) {
      case UserRole.seller:
        return [
          'shop_info',
          'shop_image',
          'location',
          'phone_verification',
          'bank_details'
        ];
      case UserRole.buyer:
        return ['profile_info', 'interests', 'location', 'phone_verification'];
      case UserRole.admin:
        return ['admin_verification'];
    }
  }

  // Get the home route for this role
  String get homeRoute {
    switch (this) {
      case UserRole.seller:
        return '/seller-dashboard';
      case UserRole.buyer:
        return '/home';
      case UserRole.admin:
        return '/admin-dashboard';
    }
  }
}

// Extension for UserRole conversions
extension UserRoleExtensions on String {
  UserRole toUserRole() => UserRole.fromString(this);
}