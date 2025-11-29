/// String extensions for common transformations
library;

extension StringExtension on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  /// Capitalize each word
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }
  
  /// Get initials from name
  String get initials {
    if (isEmpty) return '';
    final words = trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, words[0].length.clamp(0, 2)).toUpperCase();
    }
    return words.take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
  }
  
  /// Truncate string with ellipsis
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }
  
  /// Check if string is valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
  
  /// Check if string is valid phone
  bool get isValidPhone {
    return RegExp(r'^[+]?[\d\s-]{10,}$').hasMatch(this);
  }
  
  /// Check if string is numeric
  bool get isNumeric {
    return double.tryParse(this) != null;
  }
  
  /// Remove extra whitespace
  String get trimmed {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  
  /// Convert to nullable (empty string becomes null)
  String? get nullIfEmpty => isEmpty ? null : this;
}

extension NullableStringExtension on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  
  /// Check if string is not null or empty
  bool get isNotNullOrEmpty => !isNullOrEmpty;
  
  /// Get value or default
  String orDefault(String defaultValue) => isNullOrEmpty ? defaultValue : this!;
}
