/// Input validation utilities for the Doctor App
///
/// Provides validation for common input types like phone numbers,
/// emails, dates, and medical data.
library;

/// Result of a validation check
class ValidationResult {
  const ValidationResult.valid() : isValid = true, errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;

  final bool isValid;
  final String? errorMessage;

  @override
  String toString() => isValid ? 'Valid' : 'Invalid: $errorMessage';
}

/// Input validators for common data types
abstract class InputValidators {
  // Private constructor to prevent instantiation
  InputValidators._();

  // ============================================================================
  // NAME VALIDATION
  // ============================================================================

  /// Validates a person's name
  /// - Must not be empty
  /// - Must be at least 2 characters
  /// - Must contain only letters, spaces, hyphens, and apostrophes
  static ValidationResult validateName(String? name, {String fieldName = 'Name'}) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName is required');
    }

    final trimmed = name.trim();

    if (trimmed.length < 2) {
      return ValidationResult.invalid('$fieldName must be at least 2 characters');
    }

    if (trimmed.length > 100) {
      return ValidationResult.invalid('$fieldName must be less than 100 characters');
    }

    // Allow letters (including unicode), spaces, hyphens, apostrophes
    final nameRegex = RegExp(r"^[\p{L}\s\-']+$", unicode: true);
    if (!nameRegex.hasMatch(trimmed)) {
      return ValidationResult.invalid('$fieldName contains invalid characters');
    }

    return const ValidationResult.valid();
  }

  // ============================================================================
  // PHONE VALIDATION
  // ============================================================================

  /// Validates a phone number
  /// - Must contain only digits, spaces, hyphens, parentheses, and plus sign
  /// - Must have at least 7 digits
  /// - Must have no more than 15 digits
  static ValidationResult validatePhone(String? phone, {bool required = false}) {
    if (phone == null || phone.trim().isEmpty) {
      if (required) {
        return const ValidationResult.invalid('Phone number is required');
      }
      return const ValidationResult.valid();
    }

    final trimmed = phone.trim();

    // Remove all formatting characters to count digits
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 7) {
      return const ValidationResult.invalid('Phone number must have at least 7 digits');
    }

    if (digitsOnly.length > 15) {
      return const ValidationResult.invalid('Phone number must have no more than 15 digits');
    }

    // Check for valid characters (digits, spaces, hyphens, parentheses, plus)
    final phoneRegex = RegExp(r'^[\d\s\-\(\)\+]+$');
    if (!phoneRegex.hasMatch(trimmed)) {
      return const ValidationResult.invalid('Phone number contains invalid characters');
    }

    return const ValidationResult.valid();
  }

  // ============================================================================
  // EMAIL VALIDATION
  // ============================================================================

  /// Validates an email address
  static ValidationResult validateEmail(String? email, {bool required = false}) {
    if (email == null || email.trim().isEmpty) {
      if (required) {
        return const ValidationResult.invalid('Email is required');
      }
      return const ValidationResult.valid();
    }

    final trimmed = email.trim().toLowerCase();

    if (trimmed.length > 254) {
      return const ValidationResult.invalid('Email is too long');
    }

    // Must have exactly one @ and at least one . after @
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0 || atIndex == trimmed.length - 1) {
      return const ValidationResult.invalid('Please enter a valid email address');
    }

    final domain = trimmed.substring(atIndex + 1);
    if (!domain.contains('.') || domain.startsWith('.') || domain.endsWith('.')) {
      return const ValidationResult.invalid('Please enter a valid email address');
    }

    // Check for spaces
    if (trimmed.contains(' ')) {
      return const ValidationResult.invalid('Please enter a valid email address');
    }

    // RFC 5322 simplified regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$',
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return const ValidationResult.invalid('Please enter a valid email address');
    }

    return const ValidationResult.valid();
  }

  // ============================================================================
  // DATE VALIDATION
  // ============================================================================

  /// Validates a date of birth
  /// - Must not be in the future
  /// - Must not be more than 150 years ago
  static ValidationResult validateDateOfBirth(DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return const ValidationResult.valid(); // DOB is often optional
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (dateOfBirth.isAfter(today)) {
      return const ValidationResult.invalid('Date of birth cannot be in the future');
    }

    final minDate = DateTime(now.year - 150, now.month, now.day);
    if (dateOfBirth.isBefore(minDate)) {
      return const ValidationResult.invalid('Please enter a valid date of birth');
    }

    return const ValidationResult.valid();
  }

  /// Validates an appointment date
  /// - Must not be more than 1 year in the past (for historical records)
  /// - Must not be more than 1 year in the future
  static ValidationResult validateAppointmentDate(DateTime? date, {bool allowPast = true}) {
    if (date == null) {
      return const ValidationResult.invalid('Appointment date is required');
    }

    final now = DateTime.now();

    if (!allowPast && date.isBefore(DateTime(now.year, now.month, now.day))) {
      return const ValidationResult.invalid('Appointment date cannot be in the past');
    }

    final maxPast = now.subtract(const Duration(days: 365));
    if (date.isBefore(maxPast)) {
      return const ValidationResult.invalid('Appointment date is too far in the past');
    }

    final maxFuture = now.add(const Duration(days: 365));
    if (date.isAfter(maxFuture)) {
      return const ValidationResult.invalid('Appointment date is too far in the future');
    }

    return const ValidationResult.valid();
  }

  // ============================================================================
  // MEDICAL DATA VALIDATION
  // ============================================================================

  /// Validates medical history text
  /// - Sanitizes potentially harmful content
  /// - Limits length
  static ValidationResult validateMedicalText(String? text, {
    int maxLength = 10000,
    String fieldName = 'Text',
  }) {
    if (text == null || text.trim().isEmpty) {
      return const ValidationResult.valid();
    }

    if (text.length > maxLength) {
      return ValidationResult.invalid('$fieldName must be less than $maxLength characters');
    }

    return const ValidationResult.valid();
  }

  /// Validates a monetary amount
  static ValidationResult validateAmount(double? amount, {
    bool required = false,
    double minAmount = 0,
    double maxAmount = 1000000,
  }) {
    if (amount == null) {
      if (required) {
        return const ValidationResult.invalid('Amount is required');
      }
      return const ValidationResult.valid();
    }

    if (amount < minAmount) {
      return ValidationResult.invalid('Amount must be at least $minAmount');
    }

    if (amount > maxAmount) {
      return ValidationResult.invalid('Amount must be less than $maxAmount');
    }

    return const ValidationResult.valid();
  }

  /// Validates prescription dosage
  static ValidationResult validateDosage(String? dosage) {
    if (dosage == null || dosage.trim().isEmpty) {
      return const ValidationResult.invalid('Dosage is required');
    }

    if (dosage.length > 200) {
      return const ValidationResult.invalid('Dosage description is too long');
    }

    return const ValidationResult.valid();
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Sanitizes text input by removing potentially harmful content
  static String sanitizeText(String input) {
    return input
        .trim()
        // Remove null bytes
        .replaceAll('\x00', '')
        // Normalize whitespace
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Formats a phone number for display
  static String formatPhoneForDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    
    return phone; // Return as-is if not a recognized format
  }

  /// Validates all patient fields at once
  static Map<String, ValidationResult> validatePatient({
    required String? firstName,
    required String? lastName,
    String? phone,
    String? email,
    DateTime? dateOfBirth,
  }) {
    return {
      'firstName': validateName(firstName, fieldName: 'First name'),
      'lastName': validateName(lastName, fieldName: 'Last name'),
      'phone': validatePhone(phone),
      'email': validateEmail(email),
      'dateOfBirth': validateDateOfBirth(dateOfBirth),
    };
  }

  /// Returns true if all validations in the map are valid
  static bool allValid(Map<String, ValidationResult> results) {
    return results.values.every((r) => r.isValid);
  }

  /// Returns the first error message from a validation map, or null if all valid
  static String? getFirstError(Map<String, ValidationResult> results) {
    for (final result in results.values) {
      if (!result.isValid) {
        return result.errorMessage;
      }
    }
    return null;
  }
}
