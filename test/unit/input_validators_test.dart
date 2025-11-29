import 'package:doctor_app/src/core/utils/input_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputValidators', () {
    group('validateName', () {
      test('returns valid for normal names', () {
        expect(InputValidators.validateName('John').isValid, isTrue);
        expect(InputValidators.validateName('Mary Jane').isValid, isTrue);
        expect(InputValidators.validateName("O'Connor").isValid, isTrue);
        expect(InputValidators.validateName('Smith-Jones').isValid, isTrue);
      });

      test('returns invalid for empty names', () {
        expect(InputValidators.validateName('').isValid, isFalse);
        expect(InputValidators.validateName('   ').isValid, isFalse);
        expect(InputValidators.validateName(null).isValid, isFalse);
      });

      test('returns invalid for too short names', () {
        expect(InputValidators.validateName('A').isValid, isFalse);
      });

      test('returns invalid for names with invalid characters', () {
        expect(InputValidators.validateName('John123').isValid, isFalse);
        expect(InputValidators.validateName('John@Doe').isValid, isFalse);
      });

      test('uses custom field name in error message', () {
        final result = InputValidators.validateName('', fieldName: 'First name');
        expect(result.errorMessage, contains('First name'));
      });
    });

    group('validatePhone', () {
      test('returns valid for normal phone numbers', () {
        expect(InputValidators.validatePhone('1234567890').isValid, isTrue);
        expect(InputValidators.validatePhone('(123) 456-7890').isValid, isTrue);
        expect(InputValidators.validatePhone('+1 123 456 7890').isValid, isTrue);
        expect(InputValidators.validatePhone('123-456-7890').isValid, isTrue);
      });

      test('returns valid for empty when not required', () {
        expect(InputValidators.validatePhone('').isValid, isTrue);
        expect(InputValidators.validatePhone(null).isValid, isTrue);
      });

      test('returns invalid for empty when required', () {
        expect(InputValidators.validatePhone('', required: true).isValid, isFalse);
        expect(InputValidators.validatePhone(null, required: true).isValid, isFalse);
      });

      test('returns invalid for too short phone numbers', () {
        expect(InputValidators.validatePhone('123456').isValid, isFalse);
      });

      test('returns invalid for too long phone numbers', () {
        expect(InputValidators.validatePhone('1234567890123456').isValid, isFalse);
      });

      test('returns invalid for invalid characters', () {
        expect(InputValidators.validatePhone('123-ABC-7890').isValid, isFalse);
      });
    });

    group('validateEmail', () {
      test('returns valid for normal emails', () {
        expect(InputValidators.validateEmail('test@example.com').isValid, isTrue);
        expect(InputValidators.validateEmail('user.name@domain.co.uk').isValid, isTrue);
        expect(InputValidators.validateEmail('user+tag@example.org').isValid, isTrue);
      });

      test('returns valid for empty when not required', () {
        expect(InputValidators.validateEmail('').isValid, isTrue);
        expect(InputValidators.validateEmail(null).isValid, isTrue);
      });

      test('returns invalid for empty when required', () {
        expect(InputValidators.validateEmail('', required: true).isValid, isFalse);
        expect(InputValidators.validateEmail(null, required: true).isValid, isFalse);
      });

      test('returns invalid for malformed emails', () {
        expect(InputValidators.validateEmail('notanemail').isValid, isFalse);
        expect(InputValidators.validateEmail('missing@domain').isValid, isFalse);
        expect(InputValidators.validateEmail('@nodomain.com').isValid, isFalse);
        expect(InputValidators.validateEmail('spaces in@email.com').isValid, isFalse);
      });
    });

    group('validateDateOfBirth', () {
      test('returns valid for null (optional)', () {
        expect(InputValidators.validateDateOfBirth(null).isValid, isTrue);
      });

      test('returns valid for past dates', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 365 * 30));
        expect(InputValidators.validateDateOfBirth(pastDate).isValid, isTrue);
      });

      test('returns invalid for future dates', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        expect(InputValidators.validateDateOfBirth(futureDate).isValid, isFalse);
      });

      test('returns invalid for dates too far in the past', () {
        final ancientDate = DateTime(1800);
        expect(InputValidators.validateDateOfBirth(ancientDate).isValid, isFalse);
      });
    });

    group('validateAppointmentDate', () {
      test('returns invalid for null', () {
        expect(InputValidators.validateAppointmentDate(null).isValid, isFalse);
      });

      test('returns valid for today', () {
        final today = DateTime.now();
        expect(InputValidators.validateAppointmentDate(today).isValid, isTrue);
      });

      test('returns valid for near future dates', () {
        final nextWeek = DateTime.now().add(const Duration(days: 7));
        expect(InputValidators.validateAppointmentDate(nextWeek).isValid, isTrue);
      });

      test('returns invalid for past dates when not allowed', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(
          InputValidators.validateAppointmentDate(yesterday, allowPast: false).isValid,
          isFalse,
        );
      });

      test('returns invalid for dates too far in the future', () {
        final twoYearsFromNow = DateTime.now().add(const Duration(days: 365 * 2));
        expect(InputValidators.validateAppointmentDate(twoYearsFromNow).isValid, isFalse);
      });
    });

    group('validateAmount', () {
      test('returns valid for normal amounts', () {
        expect(InputValidators.validateAmount(100).isValid, isTrue);
        expect(InputValidators.validateAmount(0).isValid, isTrue);
        expect(InputValidators.validateAmount(999999.99).isValid, isTrue);
      });

      test('returns valid for null when not required', () {
        expect(InputValidators.validateAmount(null).isValid, isTrue);
      });

      test('returns invalid for null when required', () {
        expect(InputValidators.validateAmount(null, required: true).isValid, isFalse);
      });

      test('returns invalid for negative amounts', () {
        expect(InputValidators.validateAmount(-100).isValid, isFalse);
      });

      test('returns invalid for amounts exceeding max', () {
        expect(InputValidators.validateAmount(2000000).isValid, isFalse);
      });

      test('respects custom min and max', () {
        expect(
          InputValidators.validateAmount(50, minAmount: 100).isValid,
          isFalse,
        );
        expect(
          InputValidators.validateAmount(200, maxAmount: 100).isValid,
          isFalse,
        );
      });
    });

    group('validateDosage', () {
      test('returns valid for normal dosages', () {
        expect(InputValidators.validateDosage('500mg').isValid, isTrue);
        expect(InputValidators.validateDosage('1 tablet twice daily').isValid, isTrue);
      });

      test('returns invalid for empty dosage', () {
        expect(InputValidators.validateDosage('').isValid, isFalse);
        expect(InputValidators.validateDosage(null).isValid, isFalse);
      });

      test('returns invalid for too long dosage', () {
        final longDosage = 'a' * 201;
        expect(InputValidators.validateDosage(longDosage).isValid, isFalse);
      });
    });

    group('sanitizeText', () {
      test('trims whitespace', () {
        expect(InputValidators.sanitizeText('  hello  '), equals('hello'));
      });

      test('normalizes internal whitespace', () {
        expect(InputValidators.sanitizeText('hello   world'), equals('hello world'));
      });

      test('removes null bytes', () {
        expect(InputValidators.sanitizeText('hello\x00world'), equals('helloworld'));
      });
    });

    group('formatPhoneForDisplay', () {
      test('formats 10-digit numbers', () {
        expect(
          InputValidators.formatPhoneForDisplay('1234567890'),
          equals('(123) 456-7890'),
        );
      });

      test('formats 11-digit numbers starting with 1', () {
        expect(
          InputValidators.formatPhoneForDisplay('11234567890'),
          equals('+1 (123) 456-7890'),
        );
      });

      test('returns as-is for unrecognized formats', () {
        expect(
          InputValidators.formatPhoneForDisplay('+44 20 7123 4567'),
          equals('+44 20 7123 4567'),
        );
      });
    });

    group('validatePatient', () {
      test('validates all fields and returns map', () {
        final results = InputValidators.validatePatient(
          firstName: 'John',
          lastName: 'Doe',
          phone: '1234567890',
          email: 'john@example.com',
          dateOfBirth: DateTime(1990),
        );

        expect(results.length, equals(5));
        expect(InputValidators.allValid(results), isTrue);
      });

      test('returns errors for invalid fields', () {
        final results = InputValidators.validatePatient(
          firstName: '',
          lastName: 'D',
          phone: '123',
          email: 'invalid',
          dateOfBirth: DateTime.now().add(const Duration(days: 1)),
        );

        expect(InputValidators.allValid(results), isFalse);
        expect(InputValidators.getFirstError(results), isNotNull);
      });
    });
  });
}
