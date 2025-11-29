/// Utility class for common string operations.
/// 
/// Provides methods for truncating, capitalizing, sanitizing,
/// and transforming strings in a consistent manner across the app.
class StringUtils {
  StringUtils._();

  /// Truncates a string to the specified maximum length.
  /// 
  /// If [addEllipsis] is true (default), appends '...' when truncated.
  /// The ellipsis is included in the max length calculation.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.truncate('Hello World', 8); // 'Hello...'
  /// StringUtils.truncate('Hello World', 8, addEllipsis: false); // 'Hello Wo'
  /// StringUtils.truncate('Hi', 10); // 'Hi' (no truncation needed)
  /// ```
  static String truncate(
    String text,
    int maxLength, {
    bool addEllipsis = true,
    String ellipsis = '...',
  }) {
    if (text.length <= maxLength) return text;
    
    if (addEllipsis) {
      final truncateAt = maxLength - ellipsis.length;
      if (truncateAt <= 0) return ellipsis.substring(0, maxLength);
      return '${text.substring(0, truncateAt)}$ellipsis';
    }
    
    return text.substring(0, maxLength);
  }

  /// Truncates at word boundaries to avoid cutting words.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.truncateAtWord('Hello World Test', 12); // 'Hello World...'
  /// ```
  static String truncateAtWord(
    String text,
    int maxLength, {
    String ellipsis = '...',
  }) {
    if (text.length <= maxLength) return text;
    
    final targetLength = maxLength - ellipsis.length;
    if (targetLength <= 0) return ellipsis.substring(0, maxLength);
    
    // Find last space before target length
    var lastSpace = text.lastIndexOf(' ', targetLength);
    if (lastSpace <= 0) {
      // No space found, fall back to regular truncation
      return '${text.substring(0, targetLength)}$ellipsis';
    }
    
    return '${text.substring(0, lastSpace)}$ellipsis';
  }

  /// Capitalizes the first letter of a string.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.capitalize('hello'); // 'Hello'
  /// StringUtils.capitalize('HELLO'); // 'HELLO'
  /// StringUtils.capitalize(''); // ''
  /// ```
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  /// Capitalizes the first letter of each word.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.titleCase('hello world'); // 'Hello World'
  /// StringUtils.titleCase('HELLO WORLD'); // 'Hello World'
  /// ```
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  /// Converts string to sentence case (first letter uppercase, rest lowercase).
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.sentenceCase('HELLO WORLD'); // 'Hello world'
  /// ```
  static String sentenceCase(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  /// Converts a camelCase or PascalCase string to readable words.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.camelToWords('firstName'); // 'First Name'
  /// StringUtils.camelToWords('XMLParser'); // 'XML Parser'
  /// StringUtils.camelToWords('patientMedicalHistory'); // 'Patient Medical History'
  /// ```
  static String camelToWords(String text) {
    if (text.isEmpty) return text;
    
    // Insert space before uppercase letters (but not consecutive ones)
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (i > 0 && char == char.toUpperCase() && char != char.toLowerCase()) {
        // Check if previous char is lowercase or next char is lowercase
        final prevIsLower = text[i - 1] == text[i - 1].toLowerCase() &&
                           text[i - 1] != text[i - 1].toUpperCase();
        final nextIsLower = i + 1 < text.length &&
                           text[i + 1] == text[i + 1].toLowerCase() &&
                           text[i + 1] != text[i + 1].toUpperCase();
        if (prevIsLower || nextIsLower) {
          buffer.write(' ');
        }
      }
      buffer.write(char);
    }
    return titleCase(buffer.toString());
  }

  /// Converts a snake_case string to readable words.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.snakeToWords('first_name'); // 'First Name'
  /// StringUtils.snakeToWords('patient_medical_history'); // 'Patient Medical History'
  /// ```
  static String snakeToWords(String text) {
    if (text.isEmpty) return text;
    return titleCase(text.replaceAll('_', ' '));
  }

  /// Converts a kebab-case string to readable words.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.kebabToWords('first-name'); // 'First Name'
  /// ```
  static String kebabToWords(String text) {
    if (text.isEmpty) return text;
    return titleCase(text.replaceAll('-', ' '));
  }

  /// Removes all whitespace from a string.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.removeWhitespace('hello world'); // 'helloworld'
  /// StringUtils.removeWhitespace('  a  b  c  '); // 'abc'
  /// ```
  static String removeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), '');
  }

  /// Normalizes whitespace (multiple spaces to single space, trim).
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.normalizeWhitespace('  hello   world  '); // 'hello world'
  /// ```
  static String normalizeWhitespace(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Checks if string is null, empty, or contains only whitespace.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.isBlank(null); // true
  /// StringUtils.isBlank(''); // true
  /// StringUtils.isBlank('   '); // true
  /// StringUtils.isBlank('hello'); // false
  /// ```
  static bool isBlank(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// Checks if string is not null, not empty, and contains non-whitespace.
  static bool isNotBlank(String? text) => !isBlank(text);

  /// Returns null if string is blank, otherwise returns the trimmed string.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.nullIfBlank('  hello  '); // 'hello'
  /// StringUtils.nullIfBlank('   '); // null
  /// StringUtils.nullIfBlank(''); // null
  /// ```
  static String? nullIfBlank(String? text) {
    if (isBlank(text)) return null;
    return text!.trim();
  }

  /// Returns default value if string is blank, otherwise returns trimmed string.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.defaultIfBlank('hello', 'default'); // 'hello'
  /// StringUtils.defaultIfBlank('', 'default'); // 'default'
  /// StringUtils.defaultIfBlank(null, 'default'); // 'default'
  /// ```
  static String defaultIfBlank(String? text, String defaultValue) {
    if (isBlank(text)) return defaultValue;
    return text!.trim();
  }

  /// Extracts initials from a name.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.getInitials('John Doe'); // 'JD'
  /// StringUtils.getInitials('John'); // 'J'
  /// StringUtils.getInitials('John Michael Doe'); // 'JD'
  /// StringUtils.getInitials(''); // ''
  /// ```
  static String getInitials(String name, {int maxInitials = 2}) {
    if (name.isEmpty) return '';
    
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = StringBuffer();
    
    for (var i = 0; i < words.length && initials.length < maxInitials; i++) {
      if (words[i].isNotEmpty) {
        // Skip if we already have max initials
        if (maxInitials == 2 && i > 0 && i < words.length - 1) continue;
        initials.write(words[i][0].toUpperCase());
      }
    }
    
    return initials.toString();
  }

  /// Masks part of a string, keeping visible characters at start and end.
  /// 
  /// Useful for masking sensitive data like phone numbers or emails.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.mask('1234567890', visibleStart: 2, visibleEnd: 2); // '12******90'
  /// StringUtils.mask('email@example.com', visibleStart: 3, visibleEnd: 4); // 'ema**********@example.com'
  /// ```
  static String mask(
    String text, {
    int visibleStart = 0,
    int visibleEnd = 0,
    String maskChar = '*',
  }) {
    if (text.isEmpty) return text;
    
    final totalVisible = visibleStart + visibleEnd;
    if (text.length <= totalVisible) return text;
    
    final maskedLength = text.length - totalVisible;
    final masked = maskChar * maskedLength;
    
    return '${text.substring(0, visibleStart)}$masked${text.substring(text.length - visibleEnd)}';
  }

  /// Masks an email address, keeping domain visible.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.maskEmail('john.doe@example.com'); // 'joh****@example.com'
  /// ```
  static String maskEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return mask(email, visibleStart: 1);
    
    final localPart = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    
    final visibleLocal = localPart.length > 3 ? 3 : 1;
    final maskedLocal = mask(localPart, visibleStart: visibleLocal);
    
    return '$maskedLocal$domain';
  }

  /// Masks a phone number, keeping last 4 digits visible.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.maskPhone('1234567890'); // '******7890'
  /// ```
  static String maskPhone(String phone) {
    // Remove non-digits for masking
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length <= 4) return phone;
    
    return mask(digitsOnly, visibleEnd: 4);
  }

  /// Extracts only digits from a string.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.extractDigits('+1 (234) 567-8900'); // '12345678900'
  /// ```
  static String extractDigits(String text) {
    return text.replaceAll(RegExp(r'\D'), '');
  }

  /// Extracts only letters from a string.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.extractLetters('Hello123World!'); // 'HelloWorld'
  /// ```
  static String extractLetters(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
  }

  /// Extracts alphanumeric characters only.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.extractAlphanumeric('Hello, World! 123'); // 'HelloWorld123'
  /// ```
  static String extractAlphanumeric(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  /// Checks if string contains only digits.
  static bool isNumeric(String text) {
    if (text.isEmpty) return false;
    return RegExp(r'^\d+$').hasMatch(text);
  }

  /// Checks if string contains only letters.
  static bool isAlpha(String text) {
    if (text.isEmpty) return false;
    return RegExp(r'^[a-zA-Z]+$').hasMatch(text);
  }

  /// Checks if string contains only alphanumeric characters.
  static bool isAlphanumeric(String text) {
    if (text.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(text);
  }

  /// Pluralizes a word based on count.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.pluralize(1, 'patient'); // '1 patient'
  /// StringUtils.pluralize(5, 'patient'); // '5 patients'
  /// StringUtils.pluralize(0, 'item', 'items'); // '0 items'
  /// ```
  static String pluralize(int count, String singular, [String? plural]) {
    final word = count == 1 ? singular : (plural ?? '${singular}s');
    return '$count $word';
  }

  /// Joins strings with separator, filtering out blank values.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.joinNonBlank([' ', 'hello', '', 'world', null], ', '); // 'hello, world'
  /// ```
  static String joinNonBlank(List<String?> strings, String separator) {
    return strings
        .where((s) => isNotBlank(s))
        .map((s) => s!.trim())
        .join(separator);
  }

  /// Wraps text at specified width.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.wordWrap('Hello World Test', 12); // 'Hello World\nTest'
  /// ```
  static String wordWrap(String text, int width) {
    if (text.length <= width) return text;
    
    final lines = <String>[];
    var currentLine = StringBuffer();
    final words = text.split(' ');
    
    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine.write(word);
      } else if (currentLine.length + 1 + word.length <= width) {
        currentLine.write(' $word');
      } else {
        lines.add(currentLine.toString());
        currentLine = StringBuffer(word);
      }
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine.toString());
    }
    
    return lines.join('\n');
  }

  /// Reverses a string.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.reverse('hello'); // 'olleh'
  /// ```
  static String reverse(String text) {
    return text.split('').reversed.join();
  }

  /// Counts occurrences of a substring.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.countOccurrences('hello hello world', 'hello'); // 2
  /// ```
  static int countOccurrences(String text, String substring) {
    if (text.isEmpty || substring.isEmpty) return 0;
    
    var count = 0;
    var start = 0;
    while (true) {
      final index = text.indexOf(substring, start);
      if (index < 0) break;
      count++;
      start = index + substring.length;
    }
    return count;
  }

  /// Removes diacritics (accents) from text.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.removeDiacritics('résumé'); // 'resume'
  /// StringUtils.removeDiacritics('naïve'); // 'naive'
  /// ```
  static String removeDiacritics(String text) {
    const diacritics = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const replacements = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    
    final result = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final index = diacritics.indexOf(char);
      result.write(index >= 0 ? replacements[index] : char);
    }
    return result.toString();
  }

  /// Slugifies a string for URL-friendly format.
  /// 
  /// Example:
  /// ```dart
  /// StringUtils.slugify('Hello World!'); // 'hello-world'
  /// StringUtils.slugify('Résumé File'); // 'resume-file'
  /// ```
  static String slugify(String text) {
    var result = removeDiacritics(text.toLowerCase());
    result = result.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    result = result.replaceAll(RegExp(r'[\s-]+'), '-');
    result = result.replaceAll(RegExp(r'^-+|-+$'), '');
    return result;
  }
}
