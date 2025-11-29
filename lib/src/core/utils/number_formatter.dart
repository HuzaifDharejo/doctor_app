import 'package:intl/intl.dart';

/// Utility class for consistent number and currency formatting.
///
/// This class provides standardized formatters for:
/// - Currency display
/// - Large numbers with abbreviations
/// - Percentages
/// - Decimal numbers
///
/// Example:
/// ```dart
/// print(NumberFormatter.formatCurrency(1234.56)); // "$1,234.56"
/// print(NumberFormatter.formatCompact(1500000)); // "1.5M"
/// print(NumberFormatter.formatPercent(0.756)); // "75.6%"
/// ```
class NumberFormatter {
  NumberFormatter._();

  // ===== Currency Formatters =====

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _currencyCompactFormat = NumberFormat.compactCurrency(
    symbol: '\$',
  );

  static final NumberFormat _currencySimpleFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );

  // ===== Number Formatters =====

  static final NumberFormat _decimalFormat = NumberFormat.decimalPattern();

  static final NumberFormat _compactFormat = NumberFormat.compact();

  static final NumberFormat _percentFormat = NumberFormat.percentPattern();

  // ===== Currency Methods =====

  /// Formats a number as currency: "$1,234.56"
  static String formatCurrency(num amount, {String? symbol, int? decimalDigits}) {
    if (symbol != null || decimalDigits != null) {
      return NumberFormat.currency(
        symbol: symbol ?? '\$',
        decimalDigits: decimalDigits ?? 2,
      ).format(amount);
    }
    return _currencyFormat.format(amount);
  }

  /// Formats a number as compact currency: "$1.2K", "$3.5M"
  static String formatCurrencyCompact(num amount, {String? symbol}) {
    if (symbol != null) {
      return NumberFormat.compactCurrency(symbol: symbol).format(amount);
    }
    return _currencyCompactFormat.format(amount);
  }

  /// Formats a number as simple currency (no decimals): "$1,235"
  static String formatCurrencySimple(num amount, {String? symbol}) {
    if (symbol != null) {
      return NumberFormat.currency(symbol: symbol, decimalDigits: 0).format(amount);
    }
    return _currencySimpleFormat.format(amount);
  }

  // ===== Number Methods =====

  /// Formats a number with thousands separators: "1,234,567"
  static String formatNumber(num value) {
    return _decimalFormat.format(value);
  }

  /// Formats a large number with suffix: "1.5K", "2.3M", "4.1B"
  static String formatCompact(num value) {
    return _compactFormat.format(value);
  }

  /// Formats a decimal number with specified precision.
  static String formatDecimal(num value, {int decimalPlaces = 2}) {
    return value.toStringAsFixed(decimalPlaces);
  }

  // ===== Percentage Methods =====

  /// Formats a decimal as percentage: 0.756 → "76%"
  static String formatPercent(num value) {
    return _percentFormat.format(value);
  }

  /// Formats a percentage with specified precision: 0.756 → "75.6%"
  static String formatPercentPrecise(num value, {int decimalPlaces = 1}) {
    return '${(value * 100).toStringAsFixed(decimalPlaces)}%';
  }

  /// Formats a number as a percentage of total: 25 of 100 → "25%"
  static String formatPercentOf(num value, num total) {
    if (total == 0) return '0%';
    return formatPercent(value / total);
  }

  // ===== Ordinal Methods =====

  /// Formats a number as ordinal: 1 → "1st", 2 → "2nd", 3 → "3rd"
  static String formatOrdinal(int number) {
    if (number < 0) return number.toString();

    final lastTwo = number % 100;
    final lastOne = number % 10;

    String suffix;
    if (lastTwo >= 11 && lastTwo <= 13) {
      suffix = 'th';
    } else {
      switch (lastOne) {
        case 1:
          suffix = 'st';
        case 2:
          suffix = 'nd';
        case 3:
          suffix = 'rd';
        default:
          suffix = 'th';
      }
    }

    return '$number$suffix';
  }

  // ===== File Size Methods =====

  /// Formats bytes as human-readable size: "1.5 KB", "2.3 MB", "4.1 GB"
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // ===== Phone Number Methods =====

  /// Formats a phone number: "1234567890" → "(123) 456-7890"
  static String formatPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11 && digits.startsWith('1')) {
      return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    } else {
      return phone;
    }
  }

  // ===== Rating/Score Methods =====

  /// Formats a rating with optional max: "4.5/5" or "4.5"
  static String formatRating(num rating, {num? max, int decimalPlaces = 1}) {
    final formatted = rating.toStringAsFixed(decimalPlaces);
    if (max != null) {
      return '$formatted/${max.toInt()}';
    }
    return formatted;
  }

  /// Formats a score: "85/100" or "85 points"
  static String formatScore(num score, {num? total, String? suffix}) {
    final scoreInt = score.round();
    if (total != null) {
      return '$scoreInt/${total.round()}';
    } else if (suffix != null) {
      return '$scoreInt $suffix';
    }
    return scoreInt.toString();
  }

  // ===== Count Methods =====

  /// Formats a count with proper pluralization: "1 item", "5 items"
  static String formatCount(int count, String singular, {String? plural}) {
    final pluralWord = plural ?? '${singular}s';
    return '$count ${count == 1 ? singular : pluralWord}';
  }

  /// Formats a count compactly: "1.2K patients"
  static String formatCountCompact(int count, String singular, {String? plural}) {
    final pluralWord = plural ?? '${singular}s';
    final formatted = formatCompact(count);
    return '$formatted ${count == 1 ? singular : pluralWord}';
  }

  // ===== Range Methods =====

  /// Formats a number range: "10 - 20" or "10-20"
  static String formatRange(num min, num max, {bool spaced = true}) {
    final separator = spaced ? ' - ' : '-';
    return '${formatNumber(min)}$separator${formatNumber(max)}';
  }

  /// Formats a currency range: "$10 - $20"
  static String formatCurrencyRange(num min, num max) {
    return '${formatCurrency(min)} - ${formatCurrency(max)}';
  }

  // ===== Validation Helpers =====

  /// Parses a currency string to a number.
  static num? parseCurrency(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return num.tryParse(cleaned);
  }

  /// Parses a percentage string to a decimal.
  static num? parsePercent(String value) {
    final cleaned = value.replaceAll('%', '').trim();
    final parsed = num.tryParse(cleaned);
    return parsed != null ? parsed / 100 : null;
  }
}
