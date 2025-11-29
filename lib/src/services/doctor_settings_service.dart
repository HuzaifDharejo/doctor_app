import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorProfile {
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
  final String? photoData; // Base64 encoded profile photo

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
  });

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
    };
  }

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
    );
  }

  static DoctorProfile empty() {
    return DoctorProfile(
      name: '',
      specialization: '',
      qualifications: '',
      licenseNumber: '',
      experienceYears: 0,
      bio: '',
      phone: '',
      email: '',
      clinicName: '',
      clinicAddress: '',
      clinicPhone: '',
      consultationFee: 0,
      followUpFee: 0,
      emergencyFee: 0,
      languages: [],
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
    } catch (e) {
      debugPrint('Error loading doctor profile: $e');
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
    } catch (e) {
      debugPrint('Error saving doctor profile: $e');
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
    } catch (e) {
      debugPrint('Error clearing doctor profile: $e');
    }
  }
}

// App Settings Service for general app preferences
class AppSettings {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String language;
  final DateTime? lastBackupDate;
  final bool onboardingComplete;
  final List<String> enabledMedicalRecordTypes;

  // Default medical record types
  static const List<String> allMedicalRecordTypes = [
    'general',
    'pulmonary_evaluation',
    'psychiatric_assessment',
    'lab_result',
    'imaging',
    'procedure',
    'follow_up',
  ];

  static const Map<String, String> medicalRecordTypeLabels = {
    'general': 'General Consultation',
    'pulmonary_evaluation': 'Pulmonary Evaluation',
    'psychiatric_assessment': 'Quick Psychiatric Assessment',
    'lab_result': 'Lab Result',
    'imaging': 'Imaging/Radiology',
    'procedure': 'Procedure',
    'follow_up': 'Follow-up Visit',
  };

  static const Map<String, String> medicalRecordTypeDescriptions = {
    'general': 'Standard consultation notes and diagnosis',
    'pulmonary_evaluation': 'Respiratory assessment with chest examination',
    'psychiatric_assessment': 'Mental status examination and risk assessment',
    'lab_result': 'Laboratory test results and interpretations',
    'imaging': 'X-ray, CT, MRI and other imaging reports',
    'procedure': 'Surgical or clinical procedures performed',
    'follow_up': 'Follow-up visit notes and progress tracking',
  };

  AppSettings({
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.language = 'English',
    this.lastBackupDate,
    this.onboardingComplete = false,
    List<String>? enabledMedicalRecordTypes,
  }) : enabledMedicalRecordTypes = enabledMedicalRecordTypes ?? List.from(allMedicalRecordTypes);

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? language,
    DateTime? lastBackupDate,
    bool? onboardingComplete,
    List<String>? enabledMedicalRecordTypes,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      language: language ?? this.language,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      enabledMedicalRecordTypes: enabledMedicalRecordTypes ?? this.enabledMedicalRecordTypes,
    );
  }

  Map<String, dynamic> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'darkModeEnabled': darkModeEnabled,
    'language': language,
    'lastBackupDate': lastBackupDate?.toIso8601String(),
    'onboardingComplete': onboardingComplete,
    'enabledMedicalRecordTypes': enabledMedicalRecordTypes,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
    darkModeEnabled: (json['darkModeEnabled'] as bool?) ?? false,
    language: (json['language'] as String?) ?? 'English',
    lastBackupDate: json['lastBackupDate'] != null 
        ? DateTime.parse(json['lastBackupDate'] as String) 
        : null,
    onboardingComplete: (json['onboardingComplete'] as bool?) ?? false,
    enabledMedicalRecordTypes: json['enabledMedicalRecordTypes'] != null
        ? List<String>.from(json['enabledMedicalRecordTypes'] as Iterable)
        : null,
  );
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
    } catch (e) {
      debugPrint('Error loading app settings: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_settings.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving app settings: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
    notifyListeners();
  }

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
    } catch (e) {
      debugPrint('Error clearing app settings: $e');
    }
  }

  Future<void> setOnboardingComplete(bool complete) async {
    _settings = _settings.copyWith(onboardingComplete: complete);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setEnabledMedicalRecordTypes(List<String> types) async {
    _settings = _settings.copyWith(enabledMedicalRecordTypes: types);
    await _saveSettings();
    notifyListeners();
  }

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
}
