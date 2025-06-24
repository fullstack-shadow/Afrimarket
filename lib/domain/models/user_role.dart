/// Represents the different roles a user can have in the application.
enum UserRole {
  /// A buyer who can browse and purchase products
  buyer,
  
  /// A seller who can list and manage products
  seller,
  
  /// An admin with full system access
  admin,
}

/// Extension to provide additional functionality for UserRole
extension UserRoleExtension on UserRole {
  /// Converts the enum value to a string representation
  String get name => toString().split('.').last;
  
  /// Creates a UserRole from a string representation
  static UserRole? fromString(String value) {
    try {
      return UserRole.values.firstWhere(
        (role) => role.name == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
