import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/utils/number_formatter.dart';

void main() {
  group('NumberFormatter - Currency', () {
    test('formatCurrency formats with default symbol and decimals', () {
      expect(NumberFormatter.formatCurrency(1234.56), '\$1,234.56');
    });

    test('formatCurrency handles zero', () {
      expect(NumberFormatter.formatCurrency(0), '\$0.00');
    });

    test('formatCurrency handles negative numbers', () {
      expect(NumberFormatter.formatCurrency(-50.25), '-\$50.25');
    });

    test('formatCurrency uses custom symbol', () {
      final result = NumberFormatter.formatCurrency(100, symbol: '€');
      expect(result, contains('€'));
      expect(result, contains('100'));
    });

    test('formatCurrency uses custom decimal digits', () {
      final result = NumberFormatter.formatCurrency(100.5, decimalDigits: 0);
      expect(result, '\$101'); // Rounds
    });

    test('formatCurrencyCompact abbreviates thousands', () {
      final result = NumberFormatter.formatCurrencyCompact(1500);
      expect(result, contains('K'));
    });

    test('formatCurrencyCompact abbreviates millions', () {
      final result = NumberFormatter.formatCurrencyCompact(2500000);
      expect(result, contains('M'));
    });

    test('formatCurrencySimple has no decimals', () {
      expect(NumberFormatter.formatCurrencySimple(1234.56), '\$1,235');
    });
  });

  group('NumberFormatter - Numbers', () {
    test('formatNumber adds thousands separators', () {
      expect(NumberFormatter.formatNumber(1234567), '1,234,567');
    });

    test('formatNumber handles small numbers', () {
      expect(NumberFormatter.formatNumber(42), '42');
    });

    test('formatCompact abbreviates thousands', () {
      expect(NumberFormatter.formatCompact(1500), '1.5K');
    });

    test('formatCompact abbreviates millions', () {
      expect(NumberFormatter.formatCompact(2500000), '2.5M');
    });

    test('formatCompact abbreviates billions', () {
      expect(NumberFormatter.formatCompact(3500000000), '3.5B');
    });

    test('formatDecimal respects decimal places', () {
      expect(NumberFormatter.formatDecimal(3.14159, decimalPlaces: 2), '3.14');
      expect(NumberFormatter.formatDecimal(3.14159, decimalPlaces: 4), '3.1416');
    });
  });

  group('NumberFormatter - Percentages', () {
    test('formatPercent converts decimal to percent', () {
      expect(NumberFormatter.formatPercent(0.75), '75%');
    });

    test('formatPercent handles 100%', () {
      expect(NumberFormatter.formatPercent(1.0), '100%');
    });

    test('formatPercent handles 0%', () {
      expect(NumberFormatter.formatPercent(0), '0%');
    });

    test('formatPercentPrecise includes decimal places', () {
      expect(NumberFormatter.formatPercentPrecise(0.756), '75.6%');
      expect(
        NumberFormatter.formatPercentPrecise(0.7567, decimalPlaces: 2),
        '75.67%',
      );
    });

    test('formatPercentOf calculates percent of total', () {
      expect(NumberFormatter.formatPercentOf(25, 100), '25%');
      expect(NumberFormatter.formatPercentOf(1, 4), '25%');
    });

    test('formatPercentOf handles zero total', () {
      expect(NumberFormatter.formatPercentOf(10, 0), '0%');
    });
  });

  group('NumberFormatter - Ordinals', () {
    test('formatOrdinal handles 1st', () {
      expect(NumberFormatter.formatOrdinal(1), '1st');
    });

    test('formatOrdinal handles 2nd', () {
      expect(NumberFormatter.formatOrdinal(2), '2nd');
    });

    test('formatOrdinal handles 3rd', () {
      expect(NumberFormatter.formatOrdinal(3), '3rd');
    });

    test('formatOrdinal handles 4th-10th', () {
      expect(NumberFormatter.formatOrdinal(4), '4th');
      expect(NumberFormatter.formatOrdinal(10), '10th');
    });

    test('formatOrdinal handles 11th-13th (exceptions)', () {
      expect(NumberFormatter.formatOrdinal(11), '11th');
      expect(NumberFormatter.formatOrdinal(12), '12th');
      expect(NumberFormatter.formatOrdinal(13), '13th');
    });

    test('formatOrdinal handles 21st, 22nd, 23rd', () {
      expect(NumberFormatter.formatOrdinal(21), '21st');
      expect(NumberFormatter.formatOrdinal(22), '22nd');
      expect(NumberFormatter.formatOrdinal(23), '23rd');
    });

    test('formatOrdinal handles large numbers', () {
      expect(NumberFormatter.formatOrdinal(101), '101st');
      expect(NumberFormatter.formatOrdinal(111), '111th');
      expect(NumberFormatter.formatOrdinal(112), '112th');
    });
  });

  group('NumberFormatter - File Size', () {
    test('formatFileSize handles bytes', () {
      expect(NumberFormatter.formatFileSize(500), '500 B');
    });

    test('formatFileSize handles kilobytes', () {
      expect(NumberFormatter.formatFileSize(1536), '1.5 KB');
    });

    test('formatFileSize handles megabytes', () {
      expect(NumberFormatter.formatFileSize(2621440), '2.5 MB');
    });

    test('formatFileSize handles gigabytes', () {
      expect(NumberFormatter.formatFileSize(3758096384), '3.5 GB');
    });
  });

  group('NumberFormatter - Phone Numbers', () {
    test('formatPhoneNumber formats 10-digit number', () {
      expect(
        NumberFormatter.formatPhoneNumber('1234567890'),
        '(123) 456-7890',
      );
    });

    test('formatPhoneNumber formats 11-digit with country code', () {
      expect(
        NumberFormatter.formatPhoneNumber('11234567890'),
        '+1 (123) 456-7890',
      );
    });

    test('formatPhoneNumber handles already formatted number', () {
      expect(
        NumberFormatter.formatPhoneNumber('(123) 456-7890'),
        '(123) 456-7890',
      );
    });

    test('formatPhoneNumber returns original for invalid length', () {
      expect(NumberFormatter.formatPhoneNumber('12345'), '12345');
    });
  });

  group('NumberFormatter - Ratings and Scores', () {
    test('formatRating formats with max', () {
      expect(NumberFormatter.formatRating(4.5, max: 5), '4.5/5');
    });

    test('formatRating formats without max', () {
      expect(NumberFormatter.formatRating(4.5), '4.5');
    });

    test('formatRating respects decimal places', () {
      expect(
        NumberFormatter.formatRating(4.567, decimalPlaces: 2),
        '4.57',
      );
    });

    test('formatScore formats with total', () {
      expect(NumberFormatter.formatScore(85, total: 100), '85/100');
    });

    test('formatScore formats with suffix', () {
      expect(NumberFormatter.formatScore(1500, suffix: 'points'), '1500 points');
    });
  });

  group('NumberFormatter - Counts', () {
    test('formatCount uses singular for 1', () {
      expect(NumberFormatter.formatCount(1, 'patient'), '1 patient');
    });

    test('formatCount uses plural for 0', () {
      expect(NumberFormatter.formatCount(0, 'patient'), '0 patients');
    });

    test('formatCount uses plural for > 1', () {
      expect(NumberFormatter.formatCount(5, 'patient'), '5 patients');
    });

    test('formatCount uses custom plural', () {
      expect(
        NumberFormatter.formatCount(3, 'person', plural: 'people'),
        '3 people',
      );
    });

    test('formatCountCompact abbreviates large counts', () {
      final result = NumberFormatter.formatCountCompact(1500, 'patient');
      expect(result, contains('K'));
      expect(result, contains('patients'));
    });
  });

  group('NumberFormatter - Ranges', () {
    test('formatRange with spacing', () {
      expect(NumberFormatter.formatRange(10, 20), '10 - 20');
    });

    test('formatRange without spacing', () {
      expect(NumberFormatter.formatRange(10, 20, spaced: false), '10-20');
    });

    test('formatRange handles large numbers', () {
      expect(NumberFormatter.formatRange(1000, 5000), '1,000 - 5,000');
    });

    test('formatCurrencyRange formats both values', () {
      expect(
        NumberFormatter.formatCurrencyRange(100, 500),
        '\$100.00 - \$500.00',
      );
    });
  });

  group('NumberFormatter - Parsing', () {
    test('parseCurrency extracts number', () {
      expect(NumberFormatter.parseCurrency('\$1,234.56'), 1234.56);
    });

    test('parseCurrency handles plain number', () {
      expect(NumberFormatter.parseCurrency('100'), 100);
    });

    test('parseCurrency returns null for invalid', () {
      expect(NumberFormatter.parseCurrency('invalid'), isNull);
    });

    test('parsePercent extracts decimal', () {
      expect(NumberFormatter.parsePercent('75%'), 0.75);
    });

    test('parsePercent handles number without symbol', () {
      expect(NumberFormatter.parsePercent('50'), 0.5);
    });

    test('parsePercent returns null for invalid', () {
      expect(NumberFormatter.parsePercent('invalid'), isNull);
    });
  });
}
