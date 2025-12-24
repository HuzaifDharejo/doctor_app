import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';
import 'pdf_template_config.dart';

class DoctorProfile { // Base64 encoded profile photo

  DoctorProfile({
    this.name = '',
    this.specialization = '',
    this.qualifications = '',
    this.licenseNumber = '',
    this.experienceYears = 0,
    this.bio = '',
    this.phone = '',
    this.email = '',
    this.clinicName = '',
    this.clinicAddress = '',
    this.clinicPhone = '',
    this.consultationFee = 0,
    this.followUpFee = 0,
    this.emergencyFee = 0,
    this.languages = const [],
    this.workingHours = const {},
    this.signatureData,
    this.photoData,
    PdfTemplateConfig? pdfTemplateConfig,
  }) : pdfTemplateConfig = pdfTemplateConfig ?? PdfTemplateConfig();

  factory DoctorProfile.fromJson(Map<String, dynamic> json) {
    return DoctorProfile(
      name: (json['name'] as String?) ?? '',
      specialization: (json['specialization'] as String?) ?? '',
      qualifications: (json['qualifications'] as String?) ?? '',
      licenseNumber: (json['licenseNumber'] as String?) ?? '',
      experienceYears: (json['experienceYears'] as int?) ?? 0,
      bio: (json['bio'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      clinicName: (json['clinicName'] as String?) ?? '',
      clinicAddress: (json['clinicAddress'] as String?) ?? '',
      clinicPhone: (json['clinicPhone'] as String?) ?? '',
      consultationFee: ((json['consultationFee'] as num?) ?? 0).toDouble(),
      followUpFee: ((json['followUpFee'] as num?) ?? 0).toDouble(),
      emergencyFee: ((json['emergencyFee'] as num?) ?? 0).toDouble(),
      languages: List<String>.from((json['languages'] as List<dynamic>?) ?? []),
      workingHours: Map<String, Map<String, dynamic>>.from(
        ((json['workingHours'] as Map<String, dynamic>?) ?? {}).map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
        ),
      ),
      signatureData: json['signatureData'] as String?,
      photoData: json['photoData'] as String?,
      pdfTemplateConfig: json['pdfTemplateConfig'] != null
          ? PdfTemplateConfig.fromJson(json['pdfTemplateConfig'] as Map<String, dynamic>)
          : null,
    );
  }
  final String name;
  final String specialization;
  final String qualifications;
  final String licenseNumber;
  final int experienceYears;
  final String bio;
  final String phone;
  final String email;
  final String clinicName;
  final String clinicAddress;
  final String clinicPhone;
  final double consultationFee;
  final double followUpFee;
  final double emergencyFee;
  final List<String> languages;
  final Map<String, Map<String, dynamic>> workingHours;
  final String? signatureData; // Base64 encoded signature image
  final String? photoData;
  final PdfTemplateConfig pdfTemplateConfig; // PDF template configuration

  String get initials {
    if (name.isEmpty) return 'DR';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'DR';
  }

  String get displayName => name.isNotEmpty ? name : 'Doctor';

  DoctorProfile copyWith({
    String? name,
    String? specialization,
    String? qualifications,
    String? licenseNumber,
    int? experienceYears,
    String? bio,
    String? phone,
    String? email,
    String? clinicName,
    String? clinicAddress,
    String? clinicPhone,
    double? consultationFee,
    double? followUpFee,
    double? emergencyFee,
    List<String>? languages,
    Map<String, Map<String, dynamic>>? workingHours,
    String? signatureData,
    String? photoData,
    PdfTemplateConfig? pdfTemplateConfig,
  }) {
    return DoctorProfile(
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      qualifications: qualifications ?? this.qualifications,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      clinicPhone: clinicPhone ?? this.clinicPhone,
      consultationFee: consultationFee ?? this.consultationFee,
      followUpFee: followUpFee ?? this.followUpFee,
      emergencyFee: emergencyFee ?? this.emergencyFee,
      languages: languages ?? this.languages,
      workingHours: workingHours ?? this.workingHours,
      signatureData: signatureData ?? this.signatureData,
      photoData: photoData ?? this.photoData,
      pdfTemplateConfig: pdfTemplateConfig ?? this.pdfTemplateConfig,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialization': specialization,
      'qualifications': qualifications,
      'licenseNumber': licenseNumber,
      'experienceYears': experienceYears,
      'bio': bio,
      'phone': phone,
      'email': email,
      'clinicName': clinicName,
      'clinicAddress': clinicAddress,
      'clinicPhone': clinicPhone,
      'consultationFee': consultationFee,
      'followUpFee': followUpFee,
      'emergencyFee': emergencyFee,
      'languages': languages,
      'workingHours': workingHours,
      'signatureData': signatureData,
      'photoData': photoData,
      'pdfTemplateConfig': pdfTemplateConfig.toJson(),
    };
  }

  static DoctorProfile empty() {
    return DoctorProfile(
      workingHours: {
        'Monday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
        'Tuesday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
        'Wednesday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
        'Thursday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
        'Friday': {'enabled': true, 'start': '09:00', 'end': '17:00'},
        'Saturday': {'enabled': false, 'start': '09:00', 'end': '17:00'},
        'Sunday': {'enabled': false, 'start': '09:00', 'end': '17:00'},
      },
    );
  }
}

class DoctorSettingsService extends ChangeNotifier {
  static const String _storageKey = 'doctor_profile';
  DoctorProfile _profile = DoctorProfile.empty();
  bool _isLoaded = false;

  DoctorProfile get profile => _profile;
  bool get isLoaded => _isLoaded;
  bool get isProfileSetup => _profile.name.isNotEmpty;

  Future<void> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _profile = DoctorProfile.fromJson(json);
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e, stackTrace) {
      log.e('DOCTOR_SETTINGS', 'Error loading doctor profile', error: e, stackTrace: stackTrace);
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> saveProfile(DoctorProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(profile.toJson());
      await prefs.setString(_storageKey, jsonString);
      _profile = profile;
      notifyListeners();
    } catch (e, stackTrace) {
      log.e('DOCTOR_SETTINGS', 'Error saving doctor profile', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? specialization,
    String? qualifications,
    String? licenseNumber,
    int? experienceYears,
    String? bio,
    String? phone,
    String? email,
    String? clinicName,
    String? clinicAddress,
    String? clinicPhone,
    double? consultationFee,
    double? followUpFee,
    double? emergencyFee,
    List<String>? languages,
    Map<String, Map<String, dynamic>>? workingHours,
  }) async {
    final updatedProfile = _profile.copyWith(
      name: name,
      specialization: specialization,
      qualifications: qualifications,
      licenseNumber: licenseNumber,
      experienceYears: experienceYears,
      bio: bio,
      phone: phone,
      email: email,
      clinicName: clinicName,
      clinicAddress: clinicAddress,
      clinicPhone: clinicPhone,
      consultationFee: consultationFee,
      followUpFee: followUpFee,
      emergencyFee: emergencyFee,
      languages: languages,
      workingHours: workingHours,
    );
    await saveProfile(updatedProfile);
  }

  Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _profile = DoctorProfile.empty();
      notifyListeners();
    } catch (e, stackTrace) {
      log.e('DOCTOR_SETTINGS', 'Error clearing doctor profile', error: e, stackTrace: stackTrace);
    }
  }
}

// App Settings Service for general app preferences
class AppSettings {

  AppSettings({
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.language = 'English',
    this.lastBackupDate,
    this.onboardingComplete = false,
    this.hasSeenDashboardTutorial = false,
    this.autoSyncAppointments = true,
    this.calendarReminders = true,
    this.examModeEnabled = false,
    List<String>? enabledMedicalRecordTypes,
  }) : enabledMedicalRecordTypes = enabledMedicalRecordTypes ?? List.from(allMedicalRecordTypes);

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // Merge saved enabled types with any new types added to allMedicalRecordTypes
    List<String>? enabledTypes;
    if (json['enabledMedicalRecordTypes'] != null) {
      final savedTypes = List<String>.from(json['enabledMedicalRecordTypes'] as Iterable);
      // Find any new types that weren't in saved settings and add them
      final newTypes = allMedicalRecordTypes.where((t) => !savedTypes.contains(t)).toList();
      enabledTypes = [...savedTypes, ...newTypes];
    }
    
    return AppSettings(
      notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
      darkModeEnabled: (json['darkModeEnabled'] as bool?) ?? false,
      language: (json['language'] as String?) ?? 'English',
      lastBackupDate: json['lastBackupDate'] != null 
          ? DateTime.parse(json['lastBackupDate'] as String) 
          : null,
      onboardingComplete: (json['onboardingComplete'] as bool?) ?? false,
      hasSeenDashboardTutorial: (json['hasSeenDashboardTutorial'] as bool?) ?? false,
      autoSyncAppointments: (json['autoSyncAppointments'] as bool?) ?? true,
      calendarReminders: (json['calendarReminders'] as bool?) ?? true,
      examModeEnabled: (json['examModeEnabled'] as bool?) ?? false,
      enabledMedicalRecordTypes: enabledTypes,
    );
  }
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String language;
  final DateTime? lastBackupDate;
  final bool onboardingComplete;
  final bool hasSeenDashboardTutorial;
  final bool autoSyncAppointments;
  final bool calendarReminders;
  final bool examModeEnabled;
  final List<String> enabledMedicalRecordTypes;

  // Default medical record types
  static const List<String> allMedicalRecordTypes = [
    // Core record types
    'general',
    'follow_up',
    'vitals',
    'lab_result',
    'imaging',
    'procedure',
    'referral',
    'certificate',
    // Mental health types
    'pulmonary_evaluation',
    'psychiatric_assessment',
    'therapy_session',
    'psychiatrist_note',
    // Specialty examination types
    'cardiac_examination',
    'pediatric_checkup',
    'eye_examination',
    'skin_examination',
    'ent_examination',
    'orthopedic_examination',
    'gyn_examination',
    'neuro_examination',
    'gi_examination',
  ];

  static const Map<String, String> medicalRecordTypeLabels = {
    'general': 'General Consultation',
    'follow_up': 'Follow-up Visit',
    'vitals': 'Vital Signs',
    'lab_result': 'Lab Result',
    'imaging': 'Imaging/Radiology',
    'procedure': 'Procedure',
    'referral': 'Referral',
    'certificate': 'Medical Certificate',
    'pulmonary_evaluation': 'Pulmonary Evaluation',
    'psychiatric_assessment': 'Psychiatric Assessment',
    'therapy_session': 'Therapy Session Note',
    'psychiatrist_note': 'Psychiatrist Note',
    'cardiac_examination': 'Cardiac Examination',
    'pediatric_checkup': 'Pediatric Checkup',
    'eye_examination': 'Eye Examination',
    'skin_examination': 'Skin Examination',
    'ent_examination': 'ENT Examination',
    'orthopedic_examination': 'Orthopedic Examination',
    'gyn_examination': 'GYN/OB Examination',
    'neuro_examination': 'Neuro Examination',
    'gi_examination': 'GI Examination',
  };

  static const Map<String, String> medicalRecordTypeDescriptions = {
    'general': 'Standard consultation notes and diagnosis',
    'follow_up': 'Follow-up visit notes and progress tracking',
    'vitals': 'Blood pressure, heart rate, temperature, weight',
    'lab_result': 'Laboratory test results and interpretations',
    'imaging': 'X-ray, CT, MRI and other imaging reports',
    'procedure': 'Surgical or clinical procedures performed',
    'referral': 'Referrals to specialists or other providers',
    'certificate': 'Medical certificates and official documents',
    'pulmonary_evaluation': 'Respiratory assessment with chest examination',
    'psychiatric_assessment': 'Mental status examination and risk assessment',
    'therapy_session': 'Therapist session notes with interventions',
    'psychiatrist_note': 'Psychiatric evaluation and medication management',
    'cardiac_examination': 'Heart sounds, ECG, Echo examination',
    'pediatric_checkup': 'Growth, development assessment',
    'eye_examination': 'Visual acuity, IOP examination',
    'skin_examination': 'Dermatology examination',
    'ent_examination': 'Ear, Nose, Throat examination',
    'orthopedic_examination': 'Joints, ROM, strength examination',
    'gyn_examination': 'Gynecologic examination',
    'neuro_examination': 'Neurological examination',
    'gi_examination': 'Abdominal examination',
  };

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? language,
    DateTime? lastBackupDate,
    bool? onboardingComplete,
    bool? hasSeenDashboardTutorial,
    bool? autoSyncAppointments,
    bool? calendarReminders,
    bool? examModeEnabled,
    List<String>? enabledMedicalRecordTypes,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      language: language ?? this.language,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      hasSeenDashboardTutorial: hasSeenDashboardTutorial ?? this.hasSeenDashboardTutorial,
      autoSyncAppointments: autoSyncAppointments ?? this.autoSyncAppointments,
      calendarReminders: calendarReminders ?? this.calendarReminders,
      examModeEnabled: examModeEnabled ?? this.examModeEnabled,
      enabledMedicalRecordTypes: enabledMedicalRecordTypes ?? this.enabledMedicalRecordTypes,
    );
  }

  Map<String, dynamic> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'darkModeEnabled': darkModeEnabled,
    'language': language,
    'lastBackupDate': lastBackupDate?.toIso8601String(),
    'onboardingComplete': onboardingComplete,
    'hasSeenDashboardTutorial': hasSeenDashboardTutorial,
    'autoSyncAppointments': autoSyncAppointments,
    'calendarReminders': calendarReminders,
    'examModeEnabled': examModeEnabled,
    'enabledMedicalRecordTypes': enabledMedicalRecordTypes,
  };
}

class AppSettingsService extends ChangeNotifier {
  static const String _storageKey = 'app_settings';
  AppSettings _settings = AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(json);
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e, stackTrace) {
      log.e('DOCTOR_SETTINGS', 'Error loading app settings', error: e, stackTrace: stackTrace);
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_settings.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e, stackTrace) {
      log.e('DOCTOR_SETTINGS', 'Error saving app settings', error: e, stackTrace: stackTrace);
    }
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> setNotificationsEnabled(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
    notifyListeners();
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> setDarkModeEnabled(bool enabled) async {
    _settings = _settings.copyWith(darkModeEnabled: enabled);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateLastBackupDate() async {
    _settings = _settings.copyWith(lastBackupDate: DateTime.now());
    await _saveSettings();
    notifyListeners();
  }

  Future<void> clearSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _settings = AppSettings();
      notifyListeners();
    } catch (e, stackTrace) {
      log.e('DOCTOR_SETTINGS', 'Error clearing app settings', error: e, stackTrace: stackTrace);
    }
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> setOnboardingComplete(bool complete) async {
    _settings = _settings.copyWith(onboardingComplete: complete);
    await _saveSettings();
    notifyListeners();
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> setHasSeenDashboardTutorial(bool seen) async {
    _settings = _settings.copyWith(hasSeenDashboardTutorial: seen);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setEnabledMedicalRecordTypes(List<String> types) async {
    _settings = _settings.copyWith(enabledMedicalRecordTypes: types);
    await _saveSettings();
    notifyListeners();
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> toggleMedicalRecordType(String type, bool enabled) async {
    final currentTypes = List<String>.from(_settings.enabledMedicalRecordTypes);
    if (enabled && !currentTypes.contains(type)) {
      currentTypes.add(type);
    } else if (!enabled && currentTypes.contains(type)) {
      currentTypes.remove(type);
    }
    await setEnabledMedicalRecordTypes(currentTypes);
  }

  bool isMedicalRecordTypeEnabled(String type) {
    return _settings.enabledMedicalRecordTypes.contains(type);
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> setAutoSyncAppointments(bool enabled) async {
    _settings = _settings.copyWith(autoSyncAppointments: enabled);
    await _saveSettings();
    notifyListeners();
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> setCalendarReminders(bool enabled) async {
    _settings = _settings.copyWith(calendarReminders: enabled);
    await _saveSettings();
    notifyListeners();
  }

  // ignore: avoid_positional_boolean_parameters
  Future<void> setExamModeEnabled(bool enabled) async {
    _settings = _settings.copyWith(examModeEnabled: enabled);
    await _saveSettings();
    notifyListeners();
  }
}
