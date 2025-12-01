/// Application-wide constants
library;

/// Application metadata and configuration
abstract class AppConstants {
  // App Info
  static const String appName = 'Doctor App';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Comprehensive Medical Practice Management System';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String onboardingKey = 'onboarding_complete';

  // API Configuration
  static const String baseUrl = 'https://api.doctorapp.com';
  static const int requestTimeout = 30;
  static const int maxRetries = 3;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = [
    'jpg',
    'jpeg',
    'png',
    'pdf',
    'doc',
    'docx'
  ];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Cache Duration
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration mediumCacheDuration = Duration(hours: 1);
  static const Duration longCacheDuration = Duration(days: 1);

  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxSyncRetries = 3;
  static const Duration syncRetryDelay = Duration(seconds: 5);

  // Notification
  static const String notificationChannelId = 'doctor_app_channel';
  static const String notificationChannelName = 'Doctor App Notifications';
}

/// Database table names
abstract class DbTables {
  static const String patients = 'patients';
  static const String appointments = 'appointments';
  static const String prescriptions = 'prescriptions';
  static const String medicalRecords = 'medical_records';
  static const String billing = 'billing';
  static const String vitals = 'vitals';
  static const String syncQueue = 'sync_queue';
  static const String cacheMetadata = 'cache_metadata';
}

// Note:
// Route name constants have been centralized under core/routing/app_router.dart (AppRoutes).
// UI string constants are defined in core/constants/app_strings.dart (AppStrings).
// This file intentionally does not define AppRoutes or AppStrings to avoid
// symbol duplication and ambiguous exports.
