import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/core/utils/string_utils.dart';

void main() {
  group('StringUtils.truncate', () {
    test('should not truncate short strings', () {
      expect(StringUtils.truncate('Hello', 10), equals('Hello'));
    });

    test('should truncate long strings with ellipsis', () {
      expect(StringUtils.truncate('Hello World', 8), equals('Hello...'));
    });

    test('should truncate without ellipsis when disabled', () {
      expect(
        StringUtils.truncate('Hello World', 8, addEllipsis: false),
        equals('Hello Wo'),
      );
    });

    test('should handle custom ellipsis', () {
      expect(
        StringUtils.truncate('Hello World', 9, ellipsis: '…'),
        equals('Hello Wo…'),
      );
    });

    test('should handle very short maxLength', () {
      expect(StringUtils.truncate('Hello', 2), equals('..'));
    });

    test('should handle empty string', () {
      expect(StringUtils.truncate('', 10), equals(''));
    });
  });

  group('StringUtils.truncateAtWord', () {
    test('should truncate at word boundary', () {
      expect(
        StringUtils.truncateAtWord('Hello World Test', 14),
        equals('Hello World...'),
      );
    });

    test('should not truncate short strings', () {
      expect(StringUtils.truncateAtWord('Hello', 10), equals('Hello'));
    });

    test('should fall back when no space found', () {
      expect(
        StringUtils.truncateAtWord('HelloWorldTest', 10),
        equals('HelloWo...'),
      );
    });
  });

  group('StringUtils.capitalize', () {
    test('should capitalize first letter', () {
      expect(StringUtils.capitalize('hello'), equals('Hello'));
    });

    test('should preserve rest of string', () {
      expect(StringUtils.capitalize('hELLO'), equals('HELLO'));
    });

    test('should handle single character', () {
      expect(StringUtils.capitalize('h'), equals('H'));
    });

    test('should handle empty string', () {
      expect(StringUtils.capitalize(''), equals(''));
    });
  });

  group('StringUtils.titleCase', () {
    test('should capitalize each word', () {
      expect(StringUtils.titleCase('hello world'), equals('Hello World'));
    });

    test('should lowercase rest of each word', () {
      expect(StringUtils.titleCase('HELLO WORLD'), equals('Hello World'));
    });

    test('should handle single word', () {
      expect(StringUtils.titleCase('hello'), equals('Hello'));
    });

    test('should handle empty string', () {
      expect(StringUtils.titleCase(''), equals(''));
    });
  });

  group('StringUtils.sentenceCase', () {
    test('should capitalize first letter only', () {
      expect(StringUtils.sentenceCase('HELLO WORLD'), equals('Hello world'));
    });

    test('should handle empty string', () {
      expect(StringUtils.sentenceCase(''), equals(''));
    });
  });

  group('StringUtils.camelToWords', () {
    test('should convert camelCase to words', () {
      expect(StringUtils.camelToWords('firstName'), equals('First Name'));
    });

    test('should handle consecutive uppercase (acronyms)', () {
      expect(StringUtils.camelToWords('XMLParser'), equals('Xml Parser'));
    });

    test('should handle long camelCase', () {
      expect(
        StringUtils.camelToWords('patientMedicalHistory'),
        equals('Patient Medical History'),
      );
    });

    test('should handle single word', () {
      expect(StringUtils.camelToWords('hello'), equals('Hello'));
    });

    test('should handle empty string', () {
      expect(StringUtils.camelToWords(''), equals(''));
    });
  });

  group('StringUtils.snakeToWords', () {
    test('should convert snake_case to words', () {
      expect(StringUtils.snakeToWords('first_name'), equals('First Name'));
    });

    test('should handle multiple underscores', () {
      expect(
        StringUtils.snakeToWords('patient_medical_history'),
        equals('Patient Medical History'),
      );
    });

    test('should handle empty string', () {
      expect(StringUtils.snakeToWords(''), equals(''));
    });
  });

  group('StringUtils.kebabToWords', () {
    test('should convert kebab-case to words', () {
      expect(StringUtils.kebabToWords('first-name'), equals('First Name'));
    });

    test('should handle empty string', () {
      expect(StringUtils.kebabToWords(''), equals(''));
    });
  });

  group('StringUtils.removeWhitespace', () {
    test('should remove all whitespace', () {
      expect(StringUtils.removeWhitespace('hello world'), equals('helloworld'));
    });

    test('should remove multiple spaces', () {
      expect(StringUtils.removeWhitespace('  a  b  c  '), equals('abc'));
    });

    test('should remove tabs and newlines', () {
      expect(StringUtils.removeWhitespace('a\tb\nc'), equals('abc'));
    });
  });

  group('StringUtils.normalizeWhitespace', () {
    test('should normalize multiple spaces', () {
      expect(
        StringUtils.normalizeWhitespace('hello   world'),
        equals('hello world'),
      );
    });

    test('should trim and normalize', () {
      expect(
        StringUtils.normalizeWhitespace('  hello   world  '),
        equals('hello world'),
      );
    });
  });

  group('StringUtils.isBlank', () {
    test('should return true for null', () {
      expect(StringUtils.isBlank(null), isTrue);
    });

    test('should return true for empty string', () {
      expect(StringUtils.isBlank(''), isTrue);
    });

    test('should return true for whitespace only', () {
      expect(StringUtils.isBlank('   '), isTrue);
    });

    test('should return false for non-empty string', () {
      expect(StringUtils.isBlank('hello'), isFalse);
    });

    test('should return false for string with whitespace', () {
      expect(StringUtils.isBlank('  hello  '), isFalse);
    });
  });

  group('StringUtils.isNotBlank', () {
    test('should return false for null', () {
      expect(StringUtils.isNotBlank(null), isFalse);
    });

    test('should return true for non-empty string', () {
      expect(StringUtils.isNotBlank('hello'), isTrue);
    });
  });

  group('StringUtils.nullIfBlank', () {
    test('should return null for blank', () {
      expect(StringUtils.nullIfBlank('   '), isNull);
    });

    test('should return trimmed string for non-blank', () {
      expect(StringUtils.nullIfBlank('  hello  '), equals('hello'));
    });
  });

  group('StringUtils.defaultIfBlank', () {
    test('should return default for blank', () {
      expect(StringUtils.defaultIfBlank('', 'default'), equals('default'));
    });

    test('should return default for null', () {
      expect(StringUtils.defaultIfBlank(null, 'default'), equals('default'));
    });

    test('should return trimmed value for non-blank', () {
      expect(StringUtils.defaultIfBlank('  hello  ', 'default'), equals('hello'));
    });
  });

  group('StringUtils.getInitials', () {
    test('should get two initials from full name', () {
      expect(StringUtils.getInitials('John Doe'), equals('JD'));
    });

    test('should get single initial from single name', () {
      expect(StringUtils.getInitials('John'), equals('J'));
    });

    test('should get first and last initials for multiple names', () {
      expect(StringUtils.getInitials('John Michael Doe'), equals('JD'));
    });

    test('should handle empty string', () {
      expect(StringUtils.getInitials(''), equals(''));
    });

    test('should handle whitespace only', () {
      expect(StringUtils.getInitials('   '), equals(''));
    });

    test('should respect maxInitials parameter', () {
      expect(
        StringUtils.getInitials('John Doe', maxInitials: 1),
        equals('J'),
      );
    });
  });

  group('StringUtils.mask', () {
    test('should mask middle of string', () {
      expect(
        StringUtils.mask('1234567890', visibleStart: 2, visibleEnd: 2),
        equals('12******90'),
      );
    });

    test('should mask with visible start only', () {
      expect(
        StringUtils.mask('1234567890', visibleStart: 3),
        equals('123*******'),
      );
    });

    test('should mask with visible end only', () {
      expect(
        StringUtils.mask('1234567890', visibleEnd: 4),
        equals('******7890'),
      );
    });

    test('should not mask if string too short', () {
      expect(
        StringUtils.mask('12', visibleStart: 2, visibleEnd: 2),
        equals('12'),
      );
    });

    test('should use custom mask character', () {
      expect(
        StringUtils.mask('12345', visibleStart: 1, visibleEnd: 1, maskChar: '#'),
        equals('1###5'),
      );
    });
  });

  group('StringUtils.maskEmail', () {
    test('should mask email local part', () {
      expect(
        StringUtils.maskEmail('john.doe@example.com'),
        equals('joh*****@example.com'),
      );
    });

    test('should handle short local part', () {
      expect(
        StringUtils.maskEmail('ab@example.com'),
        equals('a*@example.com'),
      );
    });
  });

  group('StringUtils.maskPhone', () {
    test('should mask phone keeping last 4 digits', () {
      expect(StringUtils.maskPhone('1234567890'), equals('******7890'));
    });

    test('should handle formatted phone', () {
      expect(StringUtils.maskPhone('+1 (234) 567-8900'), equals('*******8900'));
    });
  });

  group('StringUtils.extractDigits', () {
    test('should extract only digits', () {
      expect(
        StringUtils.extractDigits('+1 (234) 567-8900'),
        equals('12345678900'),
      );
    });

    test('should return empty for no digits', () {
      expect(StringUtils.extractDigits('hello'), equals(''));
    });
  });

  group('StringUtils.extractLetters', () {
    test('should extract only letters', () {
      expect(StringUtils.extractLetters('Hello123World!'), equals('HelloWorld'));
    });
  });

  group('StringUtils.extractAlphanumeric', () {
    test('should extract alphanumeric only', () {
      expect(
        StringUtils.extractAlphanumeric('Hello, World! 123'),
        equals('HelloWorld123'),
      );
    });
  });

  group('StringUtils.isNumeric', () {
    test('should return true for digits only', () {
      expect(StringUtils.isNumeric('12345'), isTrue);
    });

    test('should return false for mixed content', () {
      expect(StringUtils.isNumeric('123abc'), isFalse);
    });

    test('should return false for empty string', () {
      expect(StringUtils.isNumeric(''), isFalse);
    });
  });

  group('StringUtils.isAlpha', () {
    test('should return true for letters only', () {
      expect(StringUtils.isAlpha('Hello'), isTrue);
    });

    test('should return false for mixed content', () {
      expect(StringUtils.isAlpha('Hello123'), isFalse);
    });
  });

  group('StringUtils.isAlphanumeric', () {
    test('should return true for alphanumeric', () {
      expect(StringUtils.isAlphanumeric('Hello123'), isTrue);
    });

    test('should return false for special chars', () {
      expect(StringUtils.isAlphanumeric('Hello!'), isFalse);
    });
  });

  group('StringUtils.pluralize', () {
    test('should use singular for count 1', () {
      expect(StringUtils.pluralize(1, 'patient'), equals('1 patient'));
    });

    test('should use plural for count > 1', () {
      expect(StringUtils.pluralize(5, 'patient'), equals('5 patients'));
    });

    test('should use plural for count 0', () {
      expect(StringUtils.pluralize(0, 'item'), equals('0 items'));
    });

    test('should use custom plural form', () {
      expect(StringUtils.pluralize(2, 'person', 'people'), equals('2 people'));
    });
  });

  group('StringUtils.joinNonBlank', () {
    test('should join non-blank values', () {
      expect(
        StringUtils.joinNonBlank([' ', 'hello', '', 'world', null], ', '),
        equals('hello, world'),
      );
    });

    test('should return empty for all blank', () {
      expect(
        StringUtils.joinNonBlank(['', ' ', null], ', '),
        equals(''),
      );
    });
  });

  group('StringUtils.wordWrap', () {
    test('should wrap at specified width', () {
      expect(
        StringUtils.wordWrap('Hello World Test', 12),
        equals('Hello World\nTest'),
      );
    });

    test('should not wrap short text', () {
      expect(StringUtils.wordWrap('Hello', 10), equals('Hello'));
    });
  });

  group('StringUtils.reverse', () {
    test('should reverse string', () {
      expect(StringUtils.reverse('hello'), equals('olleh'));
    });

    test('should handle empty string', () {
      expect(StringUtils.reverse(''), equals(''));
    });
  });

  group('StringUtils.countOccurrences', () {
    test('should count occurrences', () {
      expect(
        StringUtils.countOccurrences('hello hello world', 'hello'),
        equals(2),
      );
    });

    test('should return 0 for no matches', () {
      expect(StringUtils.countOccurrences('hello', 'world'), equals(0));
    });

    test('should handle empty strings', () {
      expect(StringUtils.countOccurrences('', 'hello'), equals(0));
      expect(StringUtils.countOccurrences('hello', ''), equals(0));
    });
  });

  group('StringUtils.removeDiacritics', () {
    test('should remove accents', () {
      expect(StringUtils.removeDiacritics('résumé'), equals('resume'));
    });

    test('should handle naïve', () {
      expect(StringUtils.removeDiacritics('naïve'), equals('naive'));
    });

    test('should preserve non-accented characters', () {
      expect(StringUtils.removeDiacritics('Hello'), equals('Hello'));
    });
  });

  group('StringUtils.slugify', () {
    test('should create URL-friendly slug', () {
      expect(StringUtils.slugify('Hello World!'), equals('hello-world'));
    });

    test('should handle accents', () {
      expect(StringUtils.slugify('Résumé File'), equals('resume-file'));
    });

    test('should handle multiple spaces', () {
      expect(StringUtils.slugify('Hello   World'), equals('hello-world'));
    });

    test('should trim leading/trailing hyphens', () {
      expect(StringUtils.slugify('  Hello World  '), equals('hello-world'));
    });
  });
}
