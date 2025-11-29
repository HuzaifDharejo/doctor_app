/// DateTime extensions for common operations
library;

import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }
  
  /// Check if date is in this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
           isBefore(endOfWeek.add(const Duration(days: 1)));
  }
  
  /// Check if date is in the past
  bool get isPast => isBefore(DateTime.now());
  
  /// Check if date is in the future
  bool get isFuture => isAfter(DateTime.now());
  
  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);
  
  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  
  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);
  
  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0);
  
  /// Get start of year
  DateTime get startOfYear => DateTime(year, 1, 1);
  
  /// Get end of year
  DateTime get endOfYear => DateTime(year, 12, 31);
  
  /// Format date (e.g., "Jan 15, 2024")
  String get formatted => DateFormat('MMM d, yyyy').format(this);
  
  /// Format date short (e.g., "Jan 15")
  String get formattedShort => DateFormat('MMM d').format(this);
  
  /// Format date long (e.g., "January 15, 2024")
  String get formattedLong => DateFormat('MMMM d, yyyy').format(this);
  
  /// Format time (e.g., "2:30 PM")
  String get formattedTime => DateFormat('h:mm a').format(this);
  
  /// Format time 24h (e.g., "14:30")
  String get formattedTime24 => DateFormat('HH:mm').format(this);
  
  /// Format date and time (e.g., "Jan 15, 2:30 PM")
  String get formattedDateTime => DateFormat('MMM d, h:mm a').format(this);
  
  /// Format as relative (e.g., "Today", "Yesterday", "Jan 15")
  String get relative {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return formattedShort;
  }
  
  /// Format as relative with time
  String get relativeWithTime {
    if (isToday) return 'Today, $formattedTime';
    if (isYesterday) return 'Yesterday, $formattedTime';
    if (isTomorrow) return 'Tomorrow, $formattedTime';
    return formattedDateTime;
  }
  
  /// Get age from birthdate
  int get age {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }
  
  /// Get days between two dates
  int daysBetween(DateTime other) {
    return startOfDay.difference(other.startOfDay).inDays.abs();
  }
  
  /// Add business days
  DateTime addBusinessDays(int days) {
    DateTime result = this;
    int addedDays = 0;
    while (addedDays < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday && result.weekday != DateTime.sunday) {
        addedDays++;
      }
    }
    return result;
  }
}

extension NullableDateTimeExtension on DateTime? {
  /// Check if date is null
  bool get isNull => this == null;
  
  /// Check if date is not null
  bool get isNotNull => this != null;
  
  /// Get formatted or default
  String formattedOrDefault(String defaultValue) {
    return this?.formatted ?? defaultValue;
  }
}
