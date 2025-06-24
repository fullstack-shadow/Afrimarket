/// Collection of input validators following clean code principles
///
/// Features:
/// - Pure functions with single responsibility
/// - Clear validation messages
/// - Type-safe implementations
/// - Composable validators
class Validators {
  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    const pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(pattern).hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates password strength
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }

    return null;
  }

  /// Validates phone numbers (basic international format)
  static String? phone(String? value, {String? countryCode}) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Validate based on country if provided
    switch (countryCode?.toUpperCase()) {
      case 'KE': // Kenya
        if (digitsOnly.length != 9 && digitsOnly.length != 12) {
          return 'Enter a valid Kenyan phone number';
        }
        break;
      case 'NG': // Nigeria
        if (digitsOnly.length != 10 && digitsOnly.length != 13) {
          return 'Enter a valid Nigerian phone number';
        }
        break;
      default: // Generic validation
        if (digitsOnly.length < 8 || digitsOnly.length > 15) {
          return 'Enter a valid phone number';
        }
    }

    return null;
  }

  /// Validates required fields
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validates numeric input
  static String? numeric(String? value) {
    if (value == null || value.isEmpty) return null;
    if (double.tryParse(value) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  /// Validates date strings
  static String? date(String? value) {
    if (value == null || value.isEmpty) return null;
    if (DateTime.tryParse(value) == null) {
      return 'Enter a valid date';
    }
    return null;
  }

  /// Composes multiple validators
  static String? Function(String?) compose(List<String? Function(String?)> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}