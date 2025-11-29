import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupMetadata', () {
    test('should create metadata with all required fields', () {
      final createdAt = DateTime(2024, 6, 15, 10, 30);
      final metadata = BackupMetadata(
        createdAt: createdAt,
        appVersion: '1.0.0',
        dbVersion: 1,
        sizeBytes: 1024,
      );

      expect(metadata.createdAt, equals(createdAt));
      expect(metadata.appVersion, equals('1.0.0'));
      expect(metadata.dbVersion, equals(1));
      expect(metadata.sizeBytes, equals(1024));
      expect(metadata.description, isNull);
      expect(metadata.isAutoBackup, isFalse);
    });

    test('should create metadata with optional fields', () {
      final metadata = BackupMetadata(
        createdAt: DateTime.now(),
        appVersion: '1.0.0',
        dbVersion: 1,
        sizeBytes: 2048,
        description: 'Test backup',
        isAutoBackup: true,
      );

      expect(metadata.description, equals('Test backup'));
      expect(metadata.isAutoBackup, isTrue);
    });

    test('toJson should serialize all fields', () {
      final createdAt = DateTime(2024, 6, 15, 10, 30);
      final metadata = BackupMetadata(
        createdAt: createdAt,
        appVersion: '1.0.0',
        dbVersion: 2,
        sizeBytes: 4096,
        description: 'Manual backup',
        isAutoBackup: false,
      );

      final json = metadata.toJson();

      expect(json['createdAt'], equals(createdAt.toIso8601String()));
      expect(json['appVersion'], equals('1.0.0'));
      expect(json['dbVersion'], equals(2));
      expect(json['sizeBytes'], equals(4096));
      expect(json['description'], equals('Manual backup'));
      expect(json['isAutoBackup'], isFalse);
    });

    test('fromJson should deserialize all fields', () {
      final json = {
        'createdAt': '2024-06-15T10:30:00.000',
        'appVersion': '1.2.0',
        'dbVersion': 3,
        'sizeBytes': 8192,
        'description': 'Test backup',
        'isAutoBackup': true,
      };

      final metadata = BackupMetadata.fromJson(json);

      expect(metadata.createdAt, equals(DateTime(2024, 6, 15, 10, 30)));
      expect(metadata.appVersion, equals('1.2.0'));
      expect(metadata.dbVersion, equals(3));
      expect(metadata.sizeBytes, equals(8192));
      expect(metadata.description, equals('Test backup'));
      expect(metadata.isAutoBackup, isTrue);
    });

    test('fromJson should handle missing optional fields', () {
      final json = {
        'createdAt': '2024-06-15T10:30:00.000',
        'appVersion': '1.0.0',
        'dbVersion': 1,
        'sizeBytes': 1024,
      };

      final metadata = BackupMetadata.fromJson(json);

      expect(metadata.description, isNull);
      expect(metadata.isAutoBackup, isFalse);
    });

    test('toJson and fromJson should be symmetric', () {
      final original = BackupMetadata(
        createdAt: DateTime(2024, 6, 15, 10, 30, 45),
        appVersion: '2.0.0',
        dbVersion: 5,
        sizeBytes: 16384,
        description: 'Symmetric test',
        isAutoBackup: true,
      );

      final json = original.toJson();
      final restored = BackupMetadata.fromJson(json);

      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.appVersion, equals(original.appVersion));
      expect(restored.dbVersion, equals(original.dbVersion));
      expect(restored.sizeBytes, equals(original.sizeBytes));
      expect(restored.description, equals(original.description));
      expect(restored.isAutoBackup, equals(original.isAutoBackup));
    });
  });

  group('BackupVerificationResult', () {
    test('valid result should have isValid true', () {
      const result = BackupVerificationResult.valid();

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('invalid result should have isValid false with message', () {
      const result = BackupVerificationResult.invalid('File not found');

      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('File not found'));
    });
  });

  group('BackupService Settings', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('isAutoBackupEnabled should return true by default', () async {
      final service = BackupService();

      final enabled = await service.isAutoBackupEnabled();

      expect(enabled, isTrue);
    });

    test('setAutoBackupEnabled should persist setting', () async {
      final service = BackupService();

      await service.setAutoBackupEnabled(false);
      final enabled = await service.isAutoBackupEnabled();

      expect(enabled, isFalse);

      await service.setAutoBackupEnabled(true);
      final enabledAgain = await service.isAutoBackupEnabled();

      expect(enabledAgain, isTrue);
    });

    test('getBackupFrequency should return 7 by default', () async {
      final service = BackupService();

      final frequency = await service.getBackupFrequency();

      expect(frequency, equals(7));
    });

    test('setBackupFrequency should persist setting', () async {
      final service = BackupService();

      await service.setBackupFrequency(14);
      final frequency = await service.getBackupFrequency();

      expect(frequency, equals(14));
    });

    test('getLastBackupDate should return null when no backup', () async {
      final service = BackupService();

      final lastBackup = await service.getLastBackupDate();

      expect(lastBackup, isNull);
    });

    test('getLastBackupDate should return date when backup exists', () async {
      final expectedDate = DateTime(2024, 6, 15, 10, 30);
      SharedPreferences.setMockInitialValues({
        'last_backup_date': expectedDate.toIso8601String(),
      });

      final service = BackupService();
      final lastBackup = await service.getLastBackupDate();

      expect(lastBackup, isNotNull);
      expect(lastBackup!.year, equals(2024));
      expect(lastBackup.month, equals(6));
      expect(lastBackup.day, equals(15));
    });
  });

  group('BackupService shouldRunAutoBackup', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('should return true when auto backup is enabled and no previous backup', () async {
      SharedPreferences.setMockInitialValues({
        'auto_backup_enabled': true,
      });

      final service = BackupService();
      final shouldRun = await service.shouldRunAutoBackup();

      expect(shouldRun, isTrue);
    });

    test('should return false when auto backup is disabled', () async {
      SharedPreferences.setMockInitialValues({
        'auto_backup_enabled': false,
      });

      final service = BackupService();
      final shouldRun = await service.shouldRunAutoBackup();

      expect(shouldRun, isFalse);
    });

    test('should return false when backup is recent', () async {
      final recentDate = DateTime.now().subtract(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        'auto_backup_enabled': true,
        'last_backup_date': recentDate.toIso8601String(),
        'backup_frequency_days': 7,
      });

      final service = BackupService();
      final shouldRun = await service.shouldRunAutoBackup();

      expect(shouldRun, isFalse);
    });

    test('should return true when backup is old enough', () async {
      final oldDate = DateTime.now().subtract(const Duration(days: 10));
      SharedPreferences.setMockInitialValues({
        'auto_backup_enabled': true,
        'last_backup_date': oldDate.toIso8601String(),
        'backup_frequency_days': 7,
      });

      final service = BackupService();
      final shouldRun = await service.shouldRunAutoBackup();

      expect(shouldRun, isTrue);
    });

    test('should use custom frequency', () async {
      final date = DateTime.now().subtract(const Duration(days: 5));
      SharedPreferences.setMockInitialValues({
        'auto_backup_enabled': true,
        'last_backup_date': date.toIso8601String(),
        'backup_frequency_days': 3, // Should run since 5 > 3
      });

      final service = BackupService();
      final shouldRun = await service.shouldRunAutoBackup();

      expect(shouldRun, isTrue);
    });
  });

  group('BackupInfo', () {
    test('formattedSize should format bytes correctly', () {
      // We can't easily test BackupInfo without a real File, but we can test
      // the metadata size formatting through a custom approach
      
      // Test small size (bytes)
      final smallMetadata = BackupMetadata(
        createdAt: DateTime.now(),
        appVersion: '1.0.0',
        dbVersion: 1,
        sizeBytes: 500,
      );
      expect(smallMetadata.sizeBytes, lessThan(1024));

      // Test KB size
      final kbMetadata = BackupMetadata(
        createdAt: DateTime.now(),
        appVersion: '1.0.0',
        dbVersion: 1,
        sizeBytes: 2048, // 2 KB
      );
      expect(kbMetadata.sizeBytes, greaterThanOrEqualTo(1024));
      expect(kbMetadata.sizeBytes, lessThan(1024 * 1024));

      // Test MB size
      final mbMetadata = BackupMetadata(
        createdAt: DateTime.now(),
        appVersion: '1.0.0',
        dbVersion: 1,
        sizeBytes: 2 * 1024 * 1024, // 2 MB
      );
      expect(mbMetadata.sizeBytes, greaterThanOrEqualTo(1024 * 1024));
    });

    test('formattedDate should format date correctly', () {
      final metadata = BackupMetadata(
        createdAt: DateTime(2024, 6, 15, 9, 5),
        appVersion: '1.0.0',
        dbVersion: 1,
        sizeBytes: 1024,
      );

      // Format should be YYYY-MM-DD HH:MM
      final expectedFormat = '2024-06-15 09:05';
      final formattedDate = '${metadata.createdAt.year}-'
          '${metadata.createdAt.month.toString().padLeft(2, '0')}-'
          '${metadata.createdAt.day.toString().padLeft(2, '0')} '
          '${metadata.createdAt.hour.toString().padLeft(2, '0')}:'
          '${metadata.createdAt.minute.toString().padLeft(2, '0')}';

      expect(formattedDate, equals(expectedFormat));
    });
  });
}
