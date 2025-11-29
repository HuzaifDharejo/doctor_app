import 'package:doctor_app/src/services/doctor_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DoctorProfile', () {
    test('empty() creates profile with default working hours', () {
      final profile = DoctorProfile.empty();

      expect(profile.name, isEmpty);
      expect(profile.workingHours, isNotEmpty);
      expect(profile.workingHours['Monday']!['enabled'], isTrue);
      expect(profile.workingHours['Saturday']!['enabled'], isFalse);
    });

    test('initials returns correct value', () {
      final profile = DoctorProfile(name: 'John Smith');
      expect(profile.initials, equals('JS'));

      final singleName = DoctorProfile(name: 'John');
      expect(singleName.initials, equals('J'));

      final empty = DoctorProfile(name: '');
      expect(empty.initials, equals('DR'));
    });

    test('displayName returns name or default', () {
      final profile = DoctorProfile(name: 'Dr. John Smith');
      expect(profile.displayName, equals('Dr. John Smith'));

      final empty = DoctorProfile(name: '');
      expect(empty.displayName, equals('Doctor'));
    });

    test('copyWith creates new instance with updated values', () {
      final original = DoctorProfile(
        name: 'John',
        specialization: 'Cardiology',
        consultationFee: 100,
      );

      final updated = original.copyWith(
        name: 'Jane',
        consultationFee: 150,
      );

      expect(updated.name, equals('Jane'));
      expect(updated.specialization, equals('Cardiology'));
      expect(updated.consultationFee, equals(150));
    });

    test('toJson and fromJson are symmetric', () {
      final original = DoctorProfile(
        name: 'Dr. Test',
        specialization: 'General',
        qualifications: 'MBBS, MD',
        licenseNumber: 'LIC123',
        experienceYears: 10,
        bio: 'Experienced doctor',
        phone: '1234567890',
        email: 'test@example.com',
        clinicName: 'Test Clinic',
        clinicAddress: '123 Main St',
        clinicPhone: '9876543210',
        consultationFee: 200,
        followUpFee: 100,
        emergencyFee: 500,
        languages: ['English', 'Spanish'],
      );

      final json = original.toJson();
      final restored = DoctorProfile.fromJson(json);

      expect(restored.name, equals(original.name));
      expect(restored.specialization, equals(original.specialization));
      expect(restored.qualifications, equals(original.qualifications));
      expect(restored.licenseNumber, equals(original.licenseNumber));
      expect(restored.experienceYears, equals(original.experienceYears));
      expect(restored.bio, equals(original.bio));
      expect(restored.phone, equals(original.phone));
      expect(restored.email, equals(original.email));
      expect(restored.consultationFee, equals(original.consultationFee));
      expect(restored.languages, equals(original.languages));
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{
        'name': 'Test',
      };

      final profile = DoctorProfile.fromJson(json);

      expect(profile.name, equals('Test'));
      expect(profile.specialization, isEmpty);
      expect(profile.experienceYears, equals(0));
      expect(profile.consultationFee, equals(0));
    });
  });

  group('AppSettings', () {
    test('default constructor has expected defaults', () {
      final settings = AppSettings();

      expect(settings.notificationsEnabled, isTrue);
      expect(settings.darkModeEnabled, isFalse);
      expect(settings.language, equals('English'));
      expect(settings.onboardingComplete, isFalse);
      expect(settings.autoSyncAppointments, isTrue);
      expect(settings.calendarReminders, isTrue);
      expect(settings.enabledMedicalRecordTypes, isNotEmpty);
    });

    test('copyWith updates specified fields', () {
      final original = AppSettings();
      final updated = original.copyWith(
        darkModeEnabled: true,
        language: 'Spanish',
      );

      expect(updated.darkModeEnabled, isTrue);
      expect(updated.language, equals('Spanish'));
      expect(updated.notificationsEnabled, isTrue); // unchanged
    });

    test('toJson and fromJson are symmetric', () {
      final original = AppSettings(
        notificationsEnabled: false,
        darkModeEnabled: true,
        language: 'French',
        lastBackupDate: DateTime(2025, 1, 15),
        onboardingComplete: true,
        autoSyncAppointments: false,
        calendarReminders: false,
        enabledMedicalRecordTypes: ['general', 'lab_result'],
      );

      final json = original.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.notificationsEnabled, equals(original.notificationsEnabled));
      expect(restored.darkModeEnabled, equals(original.darkModeEnabled));
      expect(restored.language, equals(original.language));
      expect(restored.onboardingComplete, equals(original.onboardingComplete));
      expect(restored.autoSyncAppointments, equals(original.autoSyncAppointments));
      expect(restored.calendarReminders, equals(original.calendarReminders));
      expect(restored.enabledMedicalRecordTypes, equals(original.enabledMedicalRecordTypes));
    });

    test('allMedicalRecordTypes contains expected types', () {
      expect(AppSettings.allMedicalRecordTypes, contains('general'));
      expect(AppSettings.allMedicalRecordTypes, contains('pulmonary_evaluation'));
      expect(AppSettings.allMedicalRecordTypes, contains('psychiatric_assessment'));
    });

    test('medicalRecordTypeLabels has labels for all types', () {
      for (final type in AppSettings.allMedicalRecordTypes) {
        expect(AppSettings.medicalRecordTypeLabels[type], isNotNull);
      }
    });
  });

  group('DoctorSettingsService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state before loading', () {
      final service = DoctorSettingsService();

      expect(service.isLoaded, isFalse);
      expect(service.isProfileSetup, isFalse);
    });

    test('loadProfile loads from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'doctor_profile': '{"name":"Dr. Test","specialization":"General"}',
      });

      final service = DoctorSettingsService();
      await service.loadProfile();

      expect(service.isLoaded, isTrue);
      expect(service.profile.name, equals('Dr. Test'));
      expect(service.isProfileSetup, isTrue);
    });

    test('saveProfile persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});

      final service = DoctorSettingsService();
      await service.loadProfile();

      final profile = DoctorProfile(name: 'New Doctor', specialization: 'Surgery');
      await service.saveProfile(profile);

      expect(service.profile.name, equals('New Doctor'));

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('doctor_profile'), isNotNull);
    });

    test('updateProfile updates specific fields', () async {
      SharedPreferences.setMockInitialValues({});

      final service = DoctorSettingsService();
      await service.loadProfile();
      await service.saveProfile(DoctorProfile(name: 'Original', phone: '123'));

      await service.updateProfile(phone: '456');

      expect(service.profile.name, equals('Original'));
      expect(service.profile.phone, equals('456'));
    });

    test('clearProfile resets to empty', () async {
      SharedPreferences.setMockInitialValues({
        'doctor_profile': '{"name":"Dr. Test"}',
      });

      final service = DoctorSettingsService();
      await service.loadProfile();
      expect(service.isProfileSetup, isTrue);

      await service.clearProfile();

      expect(service.isProfileSetup, isFalse);
      expect(service.profile.name, isEmpty);
    });
  });

  group('AppSettingsService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('loadSettings loads from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings': '{"darkModeEnabled":true,"language":"French"}',
      });

      final service = AppSettingsService();
      await service.loadSettings();

      expect(service.isLoaded, isTrue);
      expect(service.settings.darkModeEnabled, isTrue);
      expect(service.settings.language, equals('French'));
    });

    test('setNotificationsEnabled updates and persists', () async {
      SharedPreferences.setMockInitialValues({});

      final service = AppSettingsService();
      await service.loadSettings();
      expect(service.settings.notificationsEnabled, isTrue);

      await service.setNotificationsEnabled(false);

      expect(service.settings.notificationsEnabled, isFalse);
    });

    test('setDarkModeEnabled updates and persists', () async {
      SharedPreferences.setMockInitialValues({});

      final service = AppSettingsService();
      await service.loadSettings();

      await service.setDarkModeEnabled(true);

      expect(service.settings.darkModeEnabled, isTrue);
    });

    test('setLanguage updates and persists', () async {
      SharedPreferences.setMockInitialValues({});

      final service = AppSettingsService();
      await service.loadSettings();

      await service.setLanguage('Spanish');

      expect(service.settings.language, equals('Spanish'));
    });

    test('setAutoSyncAppointments updates and persists', () async {
      SharedPreferences.setMockInitialValues({});

      final service = AppSettingsService();
      await service.loadSettings();

      await service.setAutoSyncAppointments(false);

      expect(service.settings.autoSyncAppointments, isFalse);
    });

    test('setCalendarReminders updates and persists', () async {
      SharedPreferences.setMockInitialValues({});

      final service = AppSettingsService();
      await service.loadSettings();

      await service.setCalendarReminders(false);

      expect(service.settings.calendarReminders, isFalse);
    });

    test('toggleMedicalRecordType adds and removes types', () async {
      SharedPreferences.setMockInitialValues({});

      final service = AppSettingsService();
      await service.loadSettings();

      // Initially all enabled
      expect(service.isMedicalRecordTypeEnabled('general'), isTrue);

      // Disable
      await service.toggleMedicalRecordType('general', false);
      expect(service.isMedicalRecordTypeEnabled('general'), isFalse);

      // Re-enable
      await service.toggleMedicalRecordType('general', true);
      expect(service.isMedicalRecordTypeEnabled('general'), isTrue);
    });

    test('clearSettings resets to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings': '{"darkModeEnabled":true}',
      });

      final service = AppSettingsService();
      await service.loadSettings();
      expect(service.settings.darkModeEnabled, isTrue);

      await service.clearSettings();

      expect(service.settings.darkModeEnabled, isFalse);
    });
  });
}
