/// Form validators for RiderApp.
///
/// Provides validation functions for various input types:
/// - Email validation
/// - Phone number validation (Thai format)
/// - ID card number validation (Thai national ID)
/// - Password validation
/// - General input validation
abstract final class Validators {
  // ============================================================================
  // EMAIL VALIDATION
  // ============================================================================

  /// Validate email format
  ///
  /// Returns null if valid, error message if invalid.
  static String? validateEmail(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Email'} is required';
    }

    final trimmedValue = value.trim();

    // RFC 5322 compliant email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid email address';
    }

    // Additional checks
    if (trimmedValue.length > 254) {
      return 'Email is too long';
    }

    final localPart = trimmedValue.split('@').first;
    if (localPart.length > 64) {
      return 'Email local part is too long';
    }

    return null;
  }

  /// Check if email format is valid (boolean)
  static bool isValidEmail(String? value) {
    return validateEmail(value) == null;
  }

  // ============================================================================
  // PHONE VALIDATION
  // ============================================================================

  /// Validate Thai phone number format
  ///
  /// Accepts formats:
  /// - 0812345678 (10 digits starting with 0)
  /// - +66812345678 (with country code)
  /// - 66812345678 (country code without +)
  ///
  /// Returns null if valid, error message if invalid.
  static String? validatePhone(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Phone number'} is required';
    }

    // Remove all non-digit characters except + for country code
    String cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Handle Thai country code
    if (cleaned.startsWith('+66')) {
      cleaned = '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('66') && cleaned.length > 10) {
      cleaned = '0${cleaned.substring(2)}';
    }

    // Thai mobile numbers: 10 digits starting with 0
    // Mobile prefixes: 06, 08, 09
    // Landline prefixes: 02 (Bangkok), 03-07 (regional)
    final thaiPhoneRegex = RegExp(r'^0[0-9]{8,9}$');

    if (!thaiPhoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid Thai phone number';
    }

    // Validate mobile number prefix
    final mobilePrefix = cleaned.substring(0, 2);
    final validMobilePrefixes = ['06', '08', '09'];
    final validLandlinePrefixes = ['02', '03', '04', '05', '06', '07'];

    if (cleaned.length == 10) {
      // Mobile number
      if (!validMobilePrefixes.contains(mobilePrefix)) {
        // Check if it's a valid landline
        if (!validLandlinePrefixes.contains(mobilePrefix)) {
          return 'Please enter a valid phone number';
        }
      }
    } else if (cleaned.length == 9) {
      // Landline number
      if (!validLandlinePrefixes.contains(mobilePrefix)) {
        return 'Please enter a valid phone number';
      }
    }

    return null;
  }

  /// Check if Thai phone number format is valid (boolean)
  static bool isValidPhone(String? value) {
    return validatePhone(value) == null;
  }

  /// Format phone number for display
  static String formatPhoneForDisplay(String? value) {
    if (value == null || value.isEmpty) return '';

    String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    // Handle Thai country code
    if (cleaned.startsWith('66') && cleaned.length > 10) {
      cleaned = '0${cleaned.substring(2)}';
    }

    if (cleaned.length == 10) {
      // Mobile format: 081-234-5678
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 9) {
      // Landline format: 02-123-4567
      return '${cleaned.substring(0, 2)}-${cleaned.substring(2, 5)}-${cleaned.substring(5)}';
    }

    return value;
  }

  /// Format phone number for API (E.164 format)
  static String formatPhoneForApi(String? value) {
    if (value == null || value.isEmpty) return '';

    String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.startsWith('0')) {
      cleaned = '66${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('66')) {
      cleaned = '66$cleaned';
    }

    return '+$cleaned';
  }

  // ============================================================================
  // THAI ID CARD VALIDATION
  // ============================================================================

  /// Validate Thai national ID card number
  ///
  /// Thai ID card is 13 digits with a checksum algorithm.
  ///
  /// Returns null if valid, error message if invalid.
  static String? validateIdCard(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'ID card number'} is required';
    }

    // Remove all non-digit characters
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length != 13) {
      return 'ID card number must be 13 digits';
    }

    // Validate using checksum algorithm
    if (!_validateIdCardChecksum(cleaned)) {
      return 'Invalid ID card number';
    }

    return null;
  }

  /// Validate Thai ID card checksum
  ///
  /// Algorithm:
  /// 1. Multiply each of the first 12 digits by (13 - position) where position is 0-11
  /// 2. Sum all products
  /// 3. Divide by 11 and get remainder
  /// 4. Subtract remainder from 11
  /// 5. If result is 10, check digit is 0; otherwise, result is check digit
  /// 6. Compare with 13th digit
  static bool _validateIdCardChecksum(String idCard) {
    if (idCard.length != 13) return false;

    try {
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        sum += int.parse(idCard[i]) * (13 - i);
      }

      int checkDigit = (11 - (sum % 11)) % 10;
      int lastDigit = int.parse(idCard[12]);

      return checkDigit == lastDigit;
    } catch (e) {
      return false;
    }
  }

  /// Check if Thai ID card number is valid (boolean)
  static bool isValidIdCard(String? value) {
    return validateIdCard(value) == null;
  }

  /// Format ID card for display
  ///
  /// Format: X-XXXX-XXXXX-XX-X
  static String formatIdCardForDisplay(String? value) {
    if (value == null || value.isEmpty) return '';

    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length != 13) return value;

    return '${cleaned[0]}-${cleaned.substring(1, 5)}-${cleaned.substring(5, 10)}-${cleaned.substring(10, 12)}-${cleaned[12]}';
  }

  // ============================================================================
  // PASSWORD VALIDATION
  // ============================================================================

  /// Minimum password length
  static const int minPasswordLength = 8;

  /// Maximum password length
  static const int maxPasswordLength = 128;

  /// Validate password strength
  ///
  /// Requirements:
  /// - At least 8 characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one digit
  /// - At least one special character (optional based on requireSpecialChar)
  ///
  /// Returns null if valid, error message if invalid.
  static String? validatePassword(
    String? value, {
    String? fieldName,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireDigit = true,
    bool requireSpecialChar = false,
    int? minLength,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Password'} is required';
    }

    final effectiveMinLength = minLength ?? minPasswordLength;

    if (value.length < effectiveMinLength) {
      return 'Password must be at least $effectiveMinLength characters';
    }

    if (value.length > maxPasswordLength) {
      return 'Password is too long';
    }

    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (requireDigit && !value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    if (requireSpecialChar &&
        !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  /// Get password strength score (0-5)
  static int getPasswordStrength(String? value) {
    if (value == null || value.isEmpty) return 0;

    int score = 0;

    // Length bonus
    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (value.length >= 16) score++;

    // Character variety
    if (value.contains(RegExp(r'[a-z]'))) score++;
    if (value.contains(RegExp(r'[A-Z]'))) score++;
    if (value.contains(RegExp(r'[0-9]'))) score++;
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    // Cap at 5
    return score > 5 ? 5 : score;
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }

  /// Validate password confirmation
  static String? validateConfirmPassword(
    String? value,
    String? password, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Confirm password'} is required';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // ============================================================================
  // GENERAL VALIDATORS
  // ============================================================================

  /// Validate required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(
    String? value,
    int minLength, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters';
    }

    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String? fieldName,
  }) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'This field'} must be at most $maxLength characters';
    }

    return null;
  }

  /// Validate length range
  static String? validateLengthRange(
    String? value,
    int minLength,
    int maxLength, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (value.length < minLength || value.length > maxLength) {
      return '${fieldName ?? 'This field'} must be between $minLength and $maxLength characters';
    }

    return null;
  }

  /// Validate alphanumeric only
  static String? validateAlphanumeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return '${fieldName ?? 'This field'} can only contain letters and numbers';
    }

    return null;
  }

  /// Validate numeric only
  static String? validateNumeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return '${fieldName ?? 'This field'} must contain only numbers';
    }

    return null;
  }

  /// Validate URL format
  static String? validateUrl(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is optional unless combined with validateRequired
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  // ============================================================================
  // NAME VALIDATION
  // ============================================================================

  /// Validate name (first name, last name)
  static String? validateName(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Name'} is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return '${fieldName ?? 'Name'} must be at least 2 characters';
    }

    if (trimmedValue.length > 50) {
      return '${fieldName ?? 'Name'} is too long';
    }

    // Allow letters, spaces, hyphens, and common name characters
    // Supports Thai, English, and other Unicode letters
    if (!RegExp(r'^[\p{L}\s\-\.]+$', unicode: true).hasMatch(trimmedValue)) {
      return '${fieldName ?? 'Name'} contains invalid characters';
    }

    return null;
  }

  // ============================================================================
  // ADDRESS VALIDATION
  // ============================================================================

  /// Validate postal code (Thai format: 5 digits)
  static String? validatePostalCode(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Postal code'} is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length != 5) {
      return 'Postal code must be 5 digits';
    }

    // Thai postal codes start with 1-9
    if (cleaned.startsWith('0')) {
      return 'Invalid postal code';
    }

    return null;
  }

  // ============================================================================
  // DATE VALIDATION
  // ============================================================================

  /// Validate date of birth (must be in the past, reasonable age)
  static String? validateDateOfBirth(DateTime? value, {String? fieldName}) {
    if (value == null) {
      return '${fieldName ?? 'Date of birth'} is required';
    }

    final now = DateTime.now();

    if (value.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }

    final age = now.year - value.year;

    if (age > 120) {
      return 'Please enter a valid date of birth';
    }

    if (age < 13) {
      return 'You must be at least 13 years old';
    }

    return null;
  }

  // ============================================================================
  // LICENSE PLATE VALIDATION
  // ============================================================================

  /// Validate Thai license plate number
  ///
  /// Thai license plates formats:
  /// - XX-XXXX (2 letters + 4 digits) - older format
  /// - XXX-XXXX (3 letters/numbers + 4 digits) - newer format
  /// - Special formats for taxis, etc.
  static String? validateLicensePlate(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'License plate'} is required';
    }

    final cleaned =
        value.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

    // Validate Thai license plate patterns
    // Pattern 1: XX9999 or XXX9999
    // Pattern 2: 9XX9999 (taxis)
    final patterns = [
      RegExp(r'^[ก-ฮA-Z]{2,3}[0-9]{1,4}$'),
      RegExp(r'^[0-9][ก-ฮA-Z]{2}[0-9]{1,4}$'),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(cleaned)) {
        return null;
      }
    }

    return 'Please enter a valid license plate number';
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Combine multiple validators
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
