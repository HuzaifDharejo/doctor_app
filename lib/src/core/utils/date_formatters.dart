/// Date formatting utilities
/// 
/// Centralized date formatting for consistent display across the app.
/// Example:
/// ```dart
/// final date = DateTime.now();
/// print(DateFormatters.fullDate(date)); // "Friday, November 29, 2025"
/// print(DateFormatters.timeAgo(date));  // "just now"
/// ```
library;

import 'package:intl/intl.dart';

/// Centralized date formatting utilities
abstract class DateFormatters {
  // Pre-configured formatters for performance
  static final _fullDate = DateFormat('EEEE, MMMM d, yyyy');
  static final _shortDate = DateFormat('MMM d, yyyy');
  static final _numericDate = DateFormat('MM/dd/yyyy');
  static final _isoDate = DateFormat('yyyy-MM-dd');
  static final _time12h = DateFormat('h:mm a');
  static final _time24h = DateFormat('HH:mm');
  static final _dateTime12h = DateFormat('MMM d, yyyy h:mm a');
  static final _dateTime24h = DateFormat('MMM d, yyyy HH:mm');
  static final _weekday = DateFormat('EEEE');
  static final _monthYear = DateFormat('MMMM yyyy');
  static final _dayMonth = DateFormat('d MMM');
  static final _shortWeekday = DateFormat('EEE');

  // --- Date Formatters ---

  /// Full date: "Friday, November 29, 2025"
  static String fullDate(DateTime date) => _fullDate.format(date);

  /// Short date: "Nov 29, 2025"
  static String shortDate(DateTime date) => _shortDate.format(date);

  /// Numeric date: "11/29/2025"
  static String numericDate(DateTime date) => _numericDate.format(date);

  /// ISO date: "2025-11-29"
  static String isoDate(DateTime date) => _isoDate.format(date);

  /// Weekday: "Friday"
  static String weekday(DateTime date) => _weekday.format(date);

  /// Short weekday: "Fri"
  static String shortWeekday(DateTime date) => _shortWeekday.format(date);

  /// Month and year: "November 2025"
  static String monthYear(DateTime date) => _monthYear.format(date);

  /// Day and month: "29 Nov"
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  // --- Time Formatters ---

  /// 12-hour time: "2:30 PM"
  static String time12h(DateTime time) => _time12h.format(time);

  /// 24-hour time: "14:30"
  static String time24h(DateTime time) => _time24h.format(time);

  /// Time with optional 24h format
  static String time(DateTime time, {bool use24h = false}) =>
      use24h ? _time24h.format(time) : _time12h.format(time);

  // --- DateTime Formatters ---

  /// Full date and time: "Nov 29, 2025 2:30 PM"
  static String dateTime(DateTime dateTime, {bool use24h = false}) =>
      use24h ? _dateTime24h.format(dateTime) : _dateTime12h.format(dateTime);

  /// Short date and time: "Nov 29, 2:30 PM"
  static String shortDateTime(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year) {
      return '${_dayMonth.format(dateTime)}, ${_time12h.format(dateTime)}';
    }
    return _dateTime12h.format(dateTime);
  }

  // --- Relative Time ---

  /// Time ago: "just now", "5 minutes ago", "yesterday", etc.
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Time until: "in 5 minutes", "tomorrow", etc.
  static String timeUntil(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return timeAgo(dateTime);
    }

    if (difference.inSeconds < 60) {
      return 'in a moment';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'in $hours ${hours == 1 ? 'hour' : 'hours'}';
    } else if (difference.inDays == 1) {
      return 'tomorrow';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'in $days ${days == 1 ? 'day' : 'days'}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'in $weeks ${weeks == 1 ? 'week' : 'weeks'}';
    } else {
      return shortDate(dateTime);
    }
  }

  /// Smart date: "Today", "Yesterday", "Tomorrow", or the date
  static String smartDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = dateOnly.difference(today).inDays;

    switch (difference) {
      case 0:
        return 'Today';
      case -1:
        return 'Yesterday';
      case 1:
        return 'Tomorrow';
      default:
        if (difference > 1 && difference < 7) {
          return _weekday.format(date);
        } else if (date.year == now.year) {
          return _dayMonth.format(date);
        } else {
          return shortDate(date);
        }
    }
  }

  /// Smart date with time: "Today at 2:30 PM", "Yesterday at 10:00 AM", etc.
  static String smartDateTime(DateTime dateTime) {
    return '${smartDate(dateTime)} at ${time12h(dateTime)}';
  }

  // --- Age Calculation ---

  /// Calculate age from date of birth
  static int calculateAge(DateTime dateOfBirth) {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Age as string: "25 years", "3 months", "10 days"
  static String ageString(DateTime dateOfBirth) {
    final age = calculateAge(dateOfBirth);
    if (age >= 1) {
      return '$age ${age == 1 ? 'year' : 'years'}';
    }
    
    final now = DateTime.now();
    final months = (now.year - dateOfBirth.year) * 12 + now.month - dateOfBirth.month;
    if (months >= 1) {
      return '$months ${months == 1 ? 'month' : 'months'}';
    }
    
    final days = now.difference(dateOfBirth).inDays;
    return '$days ${days == 1 ? 'day' : 'days'}';
  }

  // --- Duration Formatting ---

  /// Format duration: "1h 30m", "45m", "2h"
  static String duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Format duration in minutes: "90 min", "45 min"
  static String durationMinutes(Duration duration) {
    return '${duration.inMinutes} min';
  }

  // --- Range Formatting ---

  /// Date range: "Nov 1 - Nov 30, 2025" or "Nov 29 - Dec 5, 2025"
  static String dateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} - ${_dayMonth.format(end)}, ${end.year}';
    } else if (start.year == end.year) {
      return '${_dayMonth.format(start)} - ${_dayMonth.format(end)}, ${end.year}';
    } else {
      return '${shortDate(start)} - ${shortDate(end)}';
    }
  }

  /// Time range: "9:00 AM - 5:00 PM"
  static String timeRange(DateTime start, DateTime end) {
    return '${time12h(start)} - ${time12h(end)}';
  }

  // --- Parsing ---

  /// Try to parse a date string in multiple formats
  static DateTime? tryParse(String input) {
    final formats = [
      'yyyy-MM-dd',
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'yyyy/MM/dd',
      'MMM d, yyyy',
      'MMMM d, yyyy',
      'd MMM yyyy',
      'd MMMM yyyy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parseStrict(input);
      } catch (_) {
        continue;
      }
    }

    // Try ISO8601 as fallback
    return DateTime.tryParse(input);
  }
}

/// Extension on DateTime for easier formatting
extension DateTimeFormatting on DateTime {
  /// Format as full date
  String get fullDate => DateFormatters.fullDate(this);

  /// Format as short date
  String get shortDate => DateFormatters.shortDate(this);

  /// Format as time (12h)
  String get time12h => DateFormatters.time12h(this);

  /// Format as time (24h)
  String get time24h => DateFormatters.time24h(this);

  /// Format as smart date
  String get smartDate => DateFormatters.smartDate(this);

  /// Format as time ago
  String get timeAgo => DateFormatters.timeAgo(this);

  /// Format as smart date time
  String get smartDateTime => DateFormatters.smartDateTime(this);

  /// Get age from this date (assuming it's a birth date)
  int get age => DateFormatters.calculateAge(this);

  /// Get age string from this date
  String get ageString => DateFormatters.ageString(this);
  
  /// Check if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if this date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Check if this date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  /// Check if this date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if this date is in the future
  bool get isFuture => isAfter(DateTime.now());
  
  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);
  
  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}
