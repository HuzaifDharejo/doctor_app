import 'package:intl/intl.dart';

/// Utility class for consistent date and time formatting throughout the app.
///
/// This class provides standardized formatters for various date/time needs:
/// - Display formats for UI (human-readable)
/// - Input/output formats for data storage
/// - Relative time descriptions
///
/// Example:
/// ```dart
/// final date = DateTime.now();
/// print(DateTimeFormatter.formatDate(date)); // "Feb 3, 2025"
/// print(DateTimeFormatter.formatRelative(date)); // "Today"
/// print(DateTimeFormatter.formatTime(date)); // "2:30 PM"
/// ```
class DateTimeFormatter {
  DateTimeFormatter._();

  // ===== Date Formatters =====

  /// Standard date format: "Feb 3, 2025"
  static final DateFormat _dateFormat = DateFormat.yMMMd();

  /// Short date format: "2/3/25"
  static final DateFormat _shortDateFormat = DateFormat.yMd();

  /// Long date format: "Monday, February 3, 2025"
  static final DateFormat _longDateFormat = DateFormat.yMMMMEEEEd();

  /// Month and day: "Feb 3"
  static final DateFormat _monthDayFormat = DateFormat.MMMd();

  /// Month and year: "February 2025"
  static final DateFormat _monthYearFormat = DateFormat.yMMMM();

  // ===== Time Formatters =====

  /// Standard time format: "2:30 PM"
  static final DateFormat _timeFormat = DateFormat.jm();

  /// 24-hour time format: "14:30"
  static final DateFormat _time24Format = DateFormat.Hm();

  // ===== Combined Formatters =====

  /// Date and time: "Feb 3, 2025 at 2:30 PM"
  static final DateFormat _dateTimeFormat = DateFormat.yMMMd().add_jm();

  /// Short date and time: "2/3/25 2:30 PM"
  static final DateFormat _shortDateTimeFormat = DateFormat.yMd().add_jm();

  // ===== Public Format Methods =====

  /// Formats a date in standard format: "Feb 3, 2025"
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formats a date in short format: "2/3/25"
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Formats a date in long format: "Monday, February 3, 2025"
  static String formatLongDate(DateTime date) {
    return _longDateFormat.format(date);
  }

  /// Formats as month and day: "Feb 3"
  static String formatMonthDay(DateTime date) {
    return _monthDayFormat.format(date);
  }

  /// Formats as month and year: "February 2025"
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Formats time: "2:30 PM"
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  /// Formats time in 24-hour format: "14:30"
  static String formatTime24(DateTime time) {
    return _time24Format.format(time);
  }

  /// Formats date and time: "Feb 3, 2025 at 2:30 PM"
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Formats short date and time: "2/3/25 2:30 PM"
  static String formatShortDateTime(DateTime dateTime) {
    return _shortDateTimeFormat.format(dateTime);
  }

  // ===== Relative Time Methods =====

  /// Formats a date relative to today.
  ///
  /// Returns:
  /// - "Today" if same day
  /// - "Yesterday" if previous day
  /// - "Tomorrow" if next day
  /// - Day name if within the week ("Monday", "Tuesday", etc.)
  /// - Standard date format otherwise
  static String formatRelative(DateTime date, {DateTime? relativeTo}) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = dateOnly.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 1 && difference < 7) {
      return DateFormat.EEEE().format(date);
    } else if (difference > -7 && difference < 0) {
      return 'Last ${DateFormat.EEEE().format(date)}';
    } else {
      return formatDate(date);
    }
  }

  /// Formats a date and time relative to now.
  ///
  /// Returns:
  /// - "Today at 2:30 PM" if same day
  /// - "Yesterday at 2:30 PM" if previous day
  /// - "Tomorrow at 2:30 PM" if next day
  /// - "Monday at 2:30 PM" if within the week
  /// - "Feb 3, 2025 at 2:30 PM" otherwise
  static String formatRelativeDateTime(DateTime dateTime, {DateTime? relativeTo}) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = dateOnly.difference(today).inDays;
    final timeStr = formatTime(dateTime);

    if (difference == 0) {
      return 'Today at $timeStr';
    } else if (difference == -1) {
      return 'Yesterday at $timeStr';
    } else if (difference == 1) {
      return 'Tomorrow at $timeStr';
    } else if (difference > 1 && difference < 7) {
      return '${DateFormat.EEEE().format(dateTime)} at $timeStr';
    } else if (difference > -7 && difference < 0) {
      return 'Last ${DateFormat.EEEE().format(dateTime)} at $timeStr';
    } else {
      return formatDateTime(dateTime);
    }
  }

  /// Formats a time span as human-readable text.
  ///
  /// Examples:
  /// - "just now" (< 1 minute)
  /// - "5 minutes ago"
  /// - "2 hours ago"
  /// - "3 days ago"
  /// - "2 weeks ago"
  /// - "1 month ago"
  /// - "1 year ago"
  static String formatTimeAgo(DateTime dateTime, {DateTime? relativeTo}) {
    final now = relativeTo ?? DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return formatTimeUntil(dateTime, relativeTo: relativeTo);
    }

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
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

  /// Formats a future time span as human-readable text.
  ///
  /// Examples:
  /// - "in a moment" (< 1 minute)
  /// - "in 5 minutes"
  /// - "in 2 hours"
  /// - "in 3 days"
  static String formatTimeUntil(DateTime dateTime, {DateTime? relativeTo}) {
    final now = relativeTo ?? DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return formatTimeAgo(dateTime, relativeTo: relativeTo);
    }

    if (difference.inSeconds < 60) {
      return 'in a moment';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'in $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'in $hours ${hours == 1 ? 'hour' : 'hours'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'in $days ${days == 1 ? 'day' : 'days'}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'in $weeks ${weeks == 1 ? 'week' : 'weeks'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'in $months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'in $years ${years == 1 ? 'year' : 'years'}';
    }
  }

  // ===== Duration Formatting =====

  /// Formats a duration as human-readable text.
  ///
  /// Examples:
  /// - "0 min" (< 1 minute)
  /// - "5 min"
  /// - "1 hr 30 min"
  /// - "2 hrs"
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return '$minutes min';
    } else if (minutes == 0) {
      return '$hours ${hours == 1 ? 'hr' : 'hrs'}';
    } else {
      return '$hours ${hours == 1 ? 'hr' : 'hrs'} $minutes min';
    }
  }

  /// Formats a duration as HH:MM:SS.
  static String formatDurationHMS(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  // ===== Age Calculation =====

  /// Calculates age in years from a birth date.
  static int calculateAge(DateTime birthDate, {DateTime? relativeTo}) {
    final now = relativeTo ?? DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Formats age as a string with appropriate unit.
  ///
  /// Examples:
  /// - "2 days" (< 1 month)
  /// - "3 months" (< 1 year)
  /// - "25 years"
  static String formatAge(DateTime birthDate, {DateTime? relativeTo}) {
    final now = relativeTo ?? DateTime.now();
    final difference = now.difference(birthDate);

    if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'}';
    } else {
      final years = calculateAge(birthDate, relativeTo: now);
      return '$years ${years == 1 ? 'year' : 'years'}';
    }
  }

  // ===== Time Range Formatting =====

  /// Formats a time range: "2:00 PM - 3:30 PM"
  static String formatTimeRange(DateTime start, DateTime end) {
    return '${formatTime(start)} - ${formatTime(end)}';
  }

  /// Formats a date range.
  ///
  /// Examples:
  /// - "Feb 3, 2025" (same day)
  /// - "Feb 3 - 5, 2025" (same month)
  /// - "Feb 3 - Mar 1, 2025" (different months)
  /// - "Dec 30, 2024 - Jan 2, 2025" (different years)
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return formatDate(start);
    } else if (start.year == end.year && start.month == end.month) {
      return '${formatMonthDay(start)} - ${end.day}, ${start.year}';
    } else if (start.year == end.year) {
      return '${formatMonthDay(start)} - ${formatMonthDay(end)}, ${start.year}';
    } else {
      return '${formatDate(start)} - ${formatDate(end)}';
    }
  }
}
