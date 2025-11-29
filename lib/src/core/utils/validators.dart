/// Form validation utilities
/// 
/// Use these validators in forms for consistent validation across the app.
/// Example:
/// ```dart
/// TextFormField(
///   validator: Validators.required('Name is required')
///       .and(Validators.minLength(2, 'Name too short')),
/// )
/// ```
library;

import 'package:flutter/material.dart';

/// Type alias for validator functions
typedef Validator = String? Function(String? value);

/// Chainable validator class
class ValidatorChain {
  final List<Validator> _validators = [];

  ValidatorChain(Validator validator) {
    _validators.add(validator);
  }

  /// Chain another validator
  ValidatorChain and(Validator validator) {
    _validators.add(validator);
    return this;
  }

  /// Execute all validators and return first error
  String? call(String? value) {
    for (final validator in _validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}

/// Collection of reusable form validators
abstract class Validators {
  /// Required field validator
  static ValidatorChain required([String? message]) {
    return ValidatorChain((value) {
      if (value == null || value.trim().isEmpty) {
        return message ?? 'This field is required';
      }
      return null;
    });
  }

  /// Minimum length validator
  static Validator minLength(int length, [String? message]) {
    return (value) {
      if (value != null && value.length < length) {
        return message ?? 'Must be at least $length characters';
      }
      return null;
    };
  }

  /// Maximum length validator
  static Validator maxLength(int length, [String? message]) {
    return (value) {
      if (value != null && value.length > length) {
        return message ?? 'Must be at most $length characters';
      }
      return null;
    };
  }

  /// Email validator
  static Validator email([String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      
      if (!emailRegex.hasMatch(value)) {
        return message ?? 'Please enter a valid email address';
      }
      return null;
    };
  }

  /// Phone number validator (flexible, accepts various formats)
  static Validator phone([String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      // Remove common separators and check if remaining are digits
      final digitsOnly = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
      
      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
        return message ?? 'Please enter a valid phone number';
      }
      
      if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
        return message ?? 'Phone number should only contain digits';
      }
      
      return null;
    };
  }

  /// Numeric value validator
  static Validator numeric([String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      if (double.tryParse(value) == null) {
        return message ?? 'Please enter a valid number';
      }
      return null;
    };
  }

  /// Integer validator
  static Validator integer([String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      if (int.tryParse(value) == null) {
        return message ?? 'Please enter a whole number';
      }
      return null;
    };
  }

  /// Range validator for numbers
  static Validator range(num min, num max, [String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      final number = double.tryParse(value);
      if (number == null) {
        return 'Please enter a valid number';
      }
      
      if (number < min || number > max) {
        return message ?? 'Value must be between $min and $max';
      }
      return null;
    };
  }

  /// Positive number validator
  static Validator positive([String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      final number = double.tryParse(value);
      if (number == null) {
        return 'Please enter a valid number';
      }
      
      if (number <= 0) {
        return message ?? 'Value must be greater than 0';
      }
      return null;
    };
  }

  /// Date validator (checks if string can be parsed as date)
  static Validator date([String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      if (DateTime.tryParse(value) == null) {
        return message ?? 'Please enter a valid date';
      }
      return null;
    };
  }

  /// Future date validator (date must be in the future)
  static Validator futureDate([String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      final date = DateTime.tryParse(value);
      if (date == null) {
        return 'Please enter a valid date';
      }
      
      if (date.isBefore(DateTime.now())) {
        return message ?? 'Date must be in the future';
      }
      return null;
    };
  }

  /// Past date validator (date must be in the past)
  static Validator pastDate([String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      final date = DateTime.tryParse(value);
      if (date == null) {
        return 'Please enter a valid date';
      }
      
      if (date.isAfter(DateTime.now())) {
        return message ?? 'Date must be in the past';
      }
      return null;
    };
  }

  /// Pattern validator using regex
  static Validator pattern(RegExp pattern, [String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      if (!pattern.hasMatch(value)) {
        return message ?? 'Invalid format';
      }
      return null;
    };
  }

  /// Matches another field (useful for confirm password)
  static Validator matches(TextEditingController controller, [String? message]) {
    return (value) {
      if (value != controller.text) {
        return message ?? 'Fields do not match';
      }
      return null;
    };
  }

  /// Custom validator
  static Validator custom(bool Function(String? value) validator, [String? message]) {
    return (value) {
      if (!validator(value)) {
        return message ?? 'Invalid value';
      }
      return null;
    };
  }

  /// Age validator (for date of birth)
  static Validator ageRange(int minAge, int maxAge, [String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      final dob = DateTime.tryParse(value);
      if (dob == null) {
        return 'Please enter a valid date';
      }
      
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      
      if (age < minAge || age > maxAge) {
        return message ?? 'Age must be between $minAge and $maxAge years';
      }
      return null;
    };
  }

  /// Name validator (allows letters, spaces, hyphens, apostrophes)
  static Validator name([String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
      
      if (!nameRegex.hasMatch(value)) {
        return message ?? 'Please enter a valid name';
      }
      return null;
    };
  }

  /// CNIC validator (Pakistani National ID)
  static Validator cnic([String? message]) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      
      // Remove dashes for validation
      final clean = value.replaceAll('-', '');
      
      if (clean.length != 13 || !RegExp(r'^\d{13}$').hasMatch(clean)) {
        return message ?? 'Please enter a valid CNIC (e.g., 12345-1234567-1)';
      }
      return null;
    };
  }

  /// Combine multiple validators (all must pass)
  static Validator all(List<Validator> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Optional wrapper (only validates if value is not empty)
  static Validator optional(Validator validator) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      return validator(value);
    };
  }
}

/// Extension for easier validator chaining
extension ValidatorExtension on Validator {
  /// Chain another validator
  ValidatorChain and(Validator other) {
    return ValidatorChain(this).and(other);
  }
}
