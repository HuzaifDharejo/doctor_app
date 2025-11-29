import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/utils/date_time_formatter.dart';

void main() {
  group('DateTimeFormatter - Date Formatting', () {
    final testDate = DateTime(2025, 2, 3, 14, 30);

    test('formatDate returns standard format', () {
      final result = DateTimeFormatter.formatDate(testDate);
      expect(result, contains('Feb'));
      expect(result, contains('3'));
      expect(result, contains('2025'));
    });

    test('formatShortDate returns short format', () {
      final result = DateTimeFormatter.formatShortDate(testDate);
      expect(result, contains('2'));
      expect(result, contains('3'));
    });

    test('formatLongDate returns full format', () {
      final result = DateTimeFormatter.formatLongDate(testDate);
      expect(result, contains('Monday'));
      expect(result, contains('February'));
      expect(result, contains('3'));
      expect(result, contains('2025'));
    });

    test('formatMonthDay returns month and day', () {
      final result = DateTimeFormatter.formatMonthDay(testDate);
      expect(result, contains('Feb'));
      expect(result, contains('3'));
      expect(result, isNot(contains('2025')));
    });

    test('formatMonthYear returns month and year', () {
      final result = DateTimeFormatter.formatMonthYear(testDate);
      expect(result, contains('February'));
      expect(result, contains('2025'));
    });
  });

  group('DateTimeFormatter - Time Formatting', () {
    final testTime = DateTime(2025, 2, 3, 14, 30);

    test('formatTime returns 12-hour format', () {
      final result = DateTimeFormatter.formatTime(testTime);
      expect(result, contains('2'));
      expect(result, contains('30'));
      expect(result, contains('PM'));
    });

    test('formatTime24 returns 24-hour format', () {
      final result = DateTimeFormatter.formatTime24(testTime);
      expect(result, contains('14'));
      expect(result, contains('30'));
    });

    test('formatDateTime combines date and time', () {
      final result = DateTimeFormatter.formatDateTime(testTime);
      expect(result, contains('Feb'));
      expect(result, contains('3'));
      expect(result, contains('2025'));
      expect(result, contains('PM'));
    });
  });

  group('DateTimeFormatter - Relative Formatting', () {
    final now = DateTime(2025, 2, 3, 12, 0);

    test('formatRelative returns "Today" for same day', () {
      final date = DateTime(2025, 2, 3, 8, 0);
      expect(
        DateTimeFormatter.formatRelative(date, relativeTo: now),
        'Today',
      );
    });

    test('formatRelative returns "Yesterday" for previous day', () {
      final date = DateTime(2025, 2, 2, 12, 0);
      expect(
        DateTimeFormatter.formatRelative(date, relativeTo: now),
        'Yesterday',
      );
    });

    test('formatRelative returns "Tomorrow" for next day', () {
      final date = DateTime(2025, 2, 4, 12, 0);
      expect(
        DateTimeFormatter.formatRelative(date, relativeTo: now),
        'Tomorrow',
      );
    });

    test('formatRelative returns day name within week', () {
      final date = DateTime(2025, 2, 6, 12, 0); // Thursday
      expect(
        DateTimeFormatter.formatRelative(date, relativeTo: now),
        'Thursday',
      );
    });

    test('formatRelative returns "Last [day]" for previous week', () {
      final date = DateTime(2025, 1, 30, 12, 0); // Thursday
      expect(
        DateTimeFormatter.formatRelative(date, relativeTo: now),
        'Last Thursday',
      );
    });

    test('formatRelative returns date for older dates', () {
      final date = DateTime(2025, 1, 15, 12, 0);
      final result = DateTimeFormatter.formatRelative(date, relativeTo: now);
      expect(result, contains('Jan'));
      expect(result, contains('15'));
    });

    test('formatRelativeDateTime includes time', () {
      final date = DateTime(2025, 2, 3, 14, 30);
      final result = DateTimeFormatter.formatRelativeDateTime(date, relativeTo: now);
      expect(result, contains('Today'));
      expect(result, contains('at'));
    });
  });

  group('DateTimeFormatter - Time Ago', () {
    final now = DateTime(2025, 2, 3, 12, 0, 0);

    test('formatTimeAgo returns "just now" for < 1 minute', () {
      final date = now.subtract(const Duration(seconds: 30));
      expect(
        DateTimeFormatter.formatTimeAgo(date, relativeTo: now),
        'just now',
      );
    });

    test('formatTimeAgo returns minutes for < 1 hour', () {
      final date = now.subtract(const Duration(minutes: 5));
      expect(
        DateTimeFormatter.formatTimeAgo(date, relativeTo: now),
        '5 minutes ago',
      );
    });

    test('formatTimeAgo returns singular minute', () {
      final date = now.subtract(const Duration(minutes: 1));
      expect(
        DateTimeFormatter.formatTimeAgo(date, relativeTo: now),
        '1 minute ago',
      );
    });

    test('formatTimeAgo returns hours for < 1 day', () {
      final date = now.subtract(const Duration(hours: 3));
      expect(
        DateTimeFormatter.formatTimeAgo(date, relativeTo: now),
        '3 hours ago',
      );
    });

    test('formatTimeAgo returns singular hour', () {
      final date = now.subtract(const Duration(hours: 1));
      expect(
        DateTimeFormatter.formatTimeAgo(date, relativeTo: now),
        '1 hour ago',
      );
    });

    test('formatTimeAgo returns days for < 1 week', () {
      final date = now.subtract(const Duration(days: 3));
      expect(
        DateTimeFormatter.formatTimeAgo(date, relativeTo: now),
        '3 days ago',
      );
    });

    test('formatTimeAgo returns weeks for < 1 month', () {
      final date = now.subtract(const Duration(days: 14));
      expect(
        DateTimeFormatter.formatTimeAgo(date, relativeTo: now),
        '2 weeks ago',
      );
    });

    test('formatTimeAgo returns months for < 1 year', () {
      final date = now.subtract(const Duration(days: 60));
      expect(
        DateTimeFormatter.formatTimeAgo(date, relativeTo: now),
        '2 months ago',
      );
    });

    test('formatTimeAgo returns years for > 1 year', () {
      final date = now.subtract(const Duration(days: 400));
      expect(
        DateTimeFormatter.formatTimeAgo(date, relativeTo: now),
        '1 year ago',
      );
    });
  });

  group('DateTimeFormatter - Time Until', () {
    final now = DateTime(2025, 2, 3, 12, 0, 0);

    test('formatTimeUntil returns "in a moment" for < 1 minute', () {
      final date = now.add(const Duration(seconds: 30));
      expect(
        DateTimeFormatter.formatTimeUntil(date, relativeTo: now),
        'in a moment',
      );
    });

    test('formatTimeUntil returns minutes for < 1 hour', () {
      final date = now.add(const Duration(minutes: 15));
      expect(
        DateTimeFormatter.formatTimeUntil(date, relativeTo: now),
        'in 15 minutes',
      );
    });

    test('formatTimeUntil returns hours for < 1 day', () {
      final date = now.add(const Duration(hours: 2));
      expect(
        DateTimeFormatter.formatTimeUntil(date, relativeTo: now),
        'in 2 hours',
      );
    });

    test('formatTimeUntil returns days for < 1 week', () {
      final date = now.add(const Duration(days: 5));
      expect(
        DateTimeFormatter.formatTimeUntil(date, relativeTo: now),
        'in 5 days',
      );
    });
  });

  group('DateTimeFormatter - Duration Formatting', () {
    test('formatDuration handles zero duration', () {
      expect(
        DateTimeFormatter.formatDuration(Duration.zero),
        '0 min',
      );
    });

    test('formatDuration handles minutes only', () {
      expect(
        DateTimeFormatter.formatDuration(const Duration(minutes: 45)),
        '45 min',
      );
    });

    test('formatDuration handles hours only', () {
      expect(
        DateTimeFormatter.formatDuration(const Duration(hours: 2)),
        '2 hrs',
      );
    });

    test('formatDuration handles single hour', () {
      expect(
        DateTimeFormatter.formatDuration(const Duration(hours: 1)),
        '1 hr',
      );
    });

    test('formatDuration handles hours and minutes', () {
      expect(
        DateTimeFormatter.formatDuration(const Duration(hours: 1, minutes: 30)),
        '1 hr 30 min',
      );
    });

    test('formatDurationHMS formats with leading zeros', () {
      expect(
        DateTimeFormatter.formatDurationHMS(const Duration(minutes: 5, seconds: 3)),
        '05:03',
      );
    });

    test('formatDurationHMS includes hours when > 0', () {
      expect(
        DateTimeFormatter.formatDurationHMS(
          const Duration(hours: 1, minutes: 5, seconds: 3),
        ),
        '01:05:03',
      );
    });
  });

  group('DateTimeFormatter - Age Calculation', () {
    final now = DateTime(2025, 2, 3);

    test('calculateAge returns correct age', () {
      final birthDate = DateTime(2000, 2, 3);
      expect(
        DateTimeFormatter.calculateAge(birthDate, relativeTo: now),
        25,
      );
    });

    test('calculateAge adjusts for birthday not yet passed', () {
      final birthDate = DateTime(2000, 6, 15);
      expect(
        DateTimeFormatter.calculateAge(birthDate, relativeTo: now),
        24,
      );
    });

    test('formatAge returns days for newborns', () {
      final birthDate = now.subtract(const Duration(days: 15));
      expect(
        DateTimeFormatter.formatAge(birthDate, relativeTo: now),
        '15 days',
      );
    });

    test('formatAge returns months for infants', () {
      final birthDate = now.subtract(const Duration(days: 90));
      expect(
        DateTimeFormatter.formatAge(birthDate, relativeTo: now),
        '3 months',
      );
    });

    test('formatAge returns years for children and adults', () {
      final birthDate = DateTime(2000, 2, 3);
      expect(
        DateTimeFormatter.formatAge(birthDate, relativeTo: now),
        '25 years',
      );
    });
  });

  group('DateTimeFormatter - Range Formatting', () {
    test('formatTimeRange formats time range', () {
      final start = DateTime(2025, 2, 3, 14, 0);
      final end = DateTime(2025, 2, 3, 15, 30);
      final result = DateTimeFormatter.formatTimeRange(start, end);
      expect(result, contains('-'));
      expect(result, contains('PM'));
    });

    test('formatDateRange handles same day', () {
      final start = DateTime(2025, 2, 3);
      final end = DateTime(2025, 2, 3);
      final result = DateTimeFormatter.formatDateRange(start, end);
      expect(result, DateTimeFormatter.formatDate(start));
    });

    test('formatDateRange handles same month', () {
      final start = DateTime(2025, 2, 3);
      final end = DateTime(2025, 2, 15);
      final result = DateTimeFormatter.formatDateRange(start, end);
      expect(result, contains('Feb'));
      expect(result, contains('3'));
      expect(result, contains('15'));
    });

    test('formatDateRange handles different months', () {
      final start = DateTime(2025, 2, 3);
      final end = DateTime(2025, 3, 15);
      final result = DateTimeFormatter.formatDateRange(start, end);
      expect(result, contains('Feb'));
      expect(result, contains('Mar'));
    });

    test('formatDateRange handles different years', () {
      final start = DateTime(2024, 12, 30);
      final end = DateTime(2025, 1, 5);
      final result = DateTimeFormatter.formatDateRange(start, end);
      expect(result, contains('2024'));
      expect(result, contains('2025'));
    });
  });
}
