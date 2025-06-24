import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/core/utils/validators.dart';

void main() {
  group('Email Validator', () {
    test('should return null for valid email', () {
      expect(validateEmail('test@example.com'), isNull);
      expect(validateEmail('user.name+tag@domain.co.uk'), isNull);
      expect(validateEmail('first.last@sub.domain.com'), isNull);
    });

    test('should return error for invalid email', () {
      expect(validateEmail('plainaddress'), equals('Enter a valid email'));
      expect(validateEmail('@missingusername.com'), equals('Enter a valid email'));
      expect(validateEmail('user@.com'), equals('Enter a valid email'));
      expect(validateEmail('user@domain..com'), equals('Enter a valid email'));
    });

    test('should return error for empty email', () {
      expect(validateEmail(''), equals('Email is required'));
      expect(validateEmail(null), equals('Email is required'));
    });
  });

  group('Password Validator', () {
    test('should return null for valid password', () {
      expect(validatePassword('SecurePass123!'), isNull);
      expect(validatePassword('LongPassword@1'), isNull);
    });

    test('should return error for weak password', () {
      expect(validatePassword('short'), 
          equals('Password must be at least 8 characters'));
      expect(validatePassword('nouppercase1!'), 
          equals('Password must contain uppercase letters'));
      expect(validatePassword('NOLOWERCASE1!'), 
          equals('Password must contain lowercase letters'));
      expect(validatePassword('NoNumbers!'), 
          equals('Password must contain numbers'));
      expect(validatePassword('NoSpecial123'), 
          equals('Password must contain special characters'));
    });

    test('should return error for empty password', () {
      expect(validatePassword(''), equals('Password is required'));
      expect(validatePassword(null), equals('Password is required'));
    });
  });

  group('Phone Number Validator', () {
    test('should return null for valid phone numbers', () {
      expect(validatePhone('+254712345678'), isNull); // Kenya
      expect(validatePhone('+2348012345678'), isNull); // Nigeria
      expect(validatePhone('+27731234567'), isNull); // South Africa
      expect(validatePhone('+255712345678'), isNull); // Tanzania
    });

    test('should return error for invalid phone numbers', () {
      expect(validatePhone('0712345678'), 
          equals('Phone must start with country code'));
      expect(validatePhone('+254712'), 
          equals('Enter a valid phone number'));
      expect(validatePhone('+254abcd1234'), 
          equals('Phone must contain only numbers'));
    });

    test('should return error for empty phone', () {
      expect(validatePhone(''), equals('Phone number is required'));
      expect(validatePhone(null), equals('Phone number is required'));
    });
  });

  group('Name Validator', () {
    test('should return null for valid names', () {
      expect(validateName('John Doe'), isNull);
      expect(validateName('Jane-Smith'), isNull);
      expect(validateName('María José'), isNull);
    });

    test('should return error for invalid names', () {
      expect(validateName('J0hn'), 
          equals('Name can only contain letters and spaces'));
      expect(validateName('John@Doe'), 
          equals('Name can only contain letters and spaces'));
    });

    test('should return error for empty name', () {
      expect(validateName(''), equals('Name is required'));
      expect(validateName(null), equals('Name is required'));
    });
  });

  group('Required Field Validator', () {
    test('should return null for non-empty values', () {
      expect(validateRequired('Text'), isNull);
      expect(validateRequired('   trimmed   ', fieldName: 'Field'), isNull);
    });

    test('should return error for empty values', () {
      expect(validateRequired(''), equals('Field is required'));
      expect(validateRequired('   ', fieldName: 'Description'), 
          equals('Description is required'));
      expect(validateRequired(null, fieldName: 'Address'), 
          equals('Address is required'));
    });
  });

  group('Numeric Validator', () {
    test('should return null for numeric values', () {
      expect(validateNumeric('123'), isNull);
      expect(validateNumeric('123.45'), isNull);
      expect(validateNumeric('0.5'), isNull);
    });

    test('should return error for non-numeric values', () {
      expect(validateNumeric('abc'), equals('Enter a valid number'));
      expect(validateNumeric('123abc'), equals('Enter a valid number'));
    });

    test('should return null for empty values when not required', () {
      expect(validateNumeric(''), isNull);
      expect(validateNumeric(null), isNull);
    });
  });

  group('Date Validator', () {
    test('should return null for valid dates', () {
      expect(validateDate('2023-12-31'), isNull);
      expect(validateDate('01/01/2023'), isNull);
    });

    test('should return error for invalid dates', () {
      expect(validateDate('2023-02-30'), 
          equals('Enter a valid date (YYYY-MM-DD)'));
      expect(validateDate('31/12/2023'), 
          equals('Enter a valid date (YYYY-MM-DD)'));
      expect(validateDate('not-a-date'), 
          equals('Enter a valid date (YYYY-MM-DD)'));
    });

    test('should return custom error for empty date', () {
      expect(validateDate('', fieldName: 'Birth Date'), 
          equals('Birth Date is required'));
    });
  });

  group('Price Validator', () {
    test('should return null for valid prices', () {
      expect(validatePrice('100'), isNull);
      expect(validatePrice('99.99'), isNull);
      expect(validatePrice('0.99'), isNull);
    });

    test('should return error for invalid prices', () {
      expect(validatePrice('abc'), equals('Enter a valid price'));
      expect(validatePrice('-10'), equals('Price must be positive'));
      expect(validatePrice('100.001'), equals('Maximum 2 decimal places'));
    });
  });

  group('OTP Code Validator', () {
    test('should return null for valid OTP codes', () {
      expect(validateOtp('123456'), isNull);
      expect(validateOtp('000000'), isNull);
    });

    test('should return error for invalid OTP codes', () {
      expect(validateOtp('123'), equals('OTP must be 6 digits'));
      expect(validateOtp('abcdef'), equals('OTP must contain only numbers'));
      expect(validateOtp('1234567'), equals('OTP must be 6 digits'));
    });
  });

  group('Address Validator', () {
    test('should return null for valid addresses', () {
      expect(validateAddress('123 Main St, Nairobi'), isNull);
      expect(validateAddress('P.O. Box 123-456'), isNull);
    });

    test('should return error for invalid addresses', () {
      expect(validateAddress('Short'), 
          equals('Address must be at least 10 characters'));
      expect(validateAddress('A'.repeat(201)), 
          equals('Address cannot exceed 200 characters'));
    });
  });

  group('Card Validator', () {
    test('should return null for valid card numbers', () {
      expect(validateCardNumber('4111111111111111'), isNull); // Visa
      expect(validateCardNumber('5500000000000004'), isNull); // Mastercard
    });

    test('should return error for invalid card numbers', () {
      expect(validateCardNumber('1234567812345678'), 
          equals('Enter a valid card number'));
      expect(validateCardNumber('4111-1111-1111-1111'), 
          equals('Card number must contain only numbers'));
      expect(validateCardNumber('411111'), 
          equals('Card number must be 16 digits'));
    });
  });

  group('CVV Validator', () {
    test('should return null for valid CVV', () {
      expect(validateCvv('123'), isNull);
      expect(validateCvv('000'), isNull);
    });

    test('should return error for invalid CVV', () {
      expect(validateCvv('12'), equals('CVV must be 3 digits'));
      expect(validateCvv('abcd'), equals('CVV must contain only numbers'));
      expect(validateCvv('1234'), equals('CVV must be 3 digits'));
    });
  });

  group('Expiry Date Validator', () {
    test('should return null for valid expiry dates', () {
      expect(validateExpiryDate('12/25'), isNull);
      expect(validateExpiryDate('01/30'), isNull);
    });

    test('should return error for invalid expiry dates', () {
      expect(validateExpiryDate('13/25'), 
          equals('Enter a valid month (01-12)'));
      expect(validateExpiryDate('00/25'), 
          equals('Enter a valid month (01-12)'));
      expect(validateExpiryDate('12/2'), 
          equals('Format must be MM/YY'));
      expect(validateExpiryDate('past/date'), 
          equals('Format must be MM/YY'));
    });

    test('should return error for past expiry dates', () {
      final lastMonth = DateTime.now().subtract(const Duration(days: 30));
      final pastDate = '${lastMonth.month.toString().padLeft(2, '0')}'
                       '/${lastMonth.year.toString().substring(2)}';
      
      expect(validateExpiryDate(pastDate), 
          equals('Card has expired'));
    });
  });
}