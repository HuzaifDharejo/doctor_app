import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/doctor_db.dart';
import '../services/allergy_management_service.dart';
import '../services/clinical_analytics_service.dart';
import '../services/communication_service.dart';
import '../services/data_export_service.dart';
import '../services/doctor_settings_service.dart';
import '../services/drug_reference_service.dart';
import '../services/localization_service.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';
import '../services/offline_sync_service.dart';
import '../services/seed_data_service.dart';
import '../services/treatment_efficacy_service.dart';

/// Flag to track if database has been seeded
bool _databaseSeeded = false;

final doctorDbProvider = FutureProvider<DoctorDatabase>((ref) async {
  log
    ..i('DB', 'Initializing database...')
    ..startMetric('database_init');
  
  // Use singleton instance to prevent multiple database connections
  final db = DoctorDatabase.instance;
  
  // Only seed once per app session
  if (!_databaseSeeded) {
    try {
      log.d('DB', 'Starting database seeding...');
      await seedSampleData(db);
      _databaseSeeded = true;
      log.i('DB', 'Database seeding completed');
    } catch (e, st) {
      log.w('DB', 'Database seeding failed', error: e, stackTrace: st);
    }
  } else {
    log.d('DB', 'Database already seeded, skipping...');
  }
  
  log
    ..stopMetric('database_init')
    ..i('DB', 'Database initialized successfully');
  return db;
});

// Doctor profile/settings provider
final doctorSettingsProvider = ChangeNotifierProvider<DoctorSettingsService>((ref) {
  log.d('SETTINGS', 'Loading doctor settings...');
  return DoctorSettingsService()..loadProfile();
});

// App settings provider (notifications, dark mode, language, etc.)
final appSettingsProvider = ChangeNotifierProvider<AppSettingsService>((ref) {
  log.d('SETTINGS', 'Loading app settings...');
  return AppSettingsService()..loadSettings();
});

// Allergy management service provider
final allergyManagementProvider = Provider<AllergyManagementService>((ref) {
  log.d('ALLERGY', 'Initializing allergy management service...');
  return const AllergyManagementService();
});

// Treatment efficacy service provider
final treatmentEfficacyProvider = Provider<TreatmentEfficacyService>((ref) {
  log.d('EFFICACY', 'Initializing treatment efficacy service...');
  return const TreatmentEfficacyService();
});

// Notification service provider
final notificationProvider = Provider<NotificationService>((ref) {
  log.d('NOTIFICATION', 'Initializing notification service...');
  return const NotificationService();
});

// Communication service provider
final communicationProvider = Provider<CommunicationService>((ref) {
  log.d('COMMUNICATION', 'Initializing communication service...');
  return CommunicationService();
});

// Drug reference service provider
final drugReferenceProvider = Provider<DrugReferenceService>((ref) {
  log.d('DRUG_REFERENCE', 'Initializing drug reference service...');
  return const DrugReferenceService();
});

// Clinical analytics service provider
final clinicalAnalyticsProvider = Provider<ClinicalAnalyticsService>((ref) {
  log.d('ANALYTICS', 'Initializing clinical analytics service...');
  return const ClinicalAnalyticsService();
});

// Offline sync service provider
final offlineSyncProvider = ChangeNotifierProvider<OfflineSyncService>((ref) {
  log.d('OFFLINE_SYNC', 'Initializing offline sync service...');
  return OfflineSyncService();
});

// Localization service provider
final localizationProvider = ChangeNotifierProvider<LocalizationService>((ref) {
  log.d('LOCALIZATION', 'Initializing localization service...');
  return LocalizationService();
});

// Data export service provider
final dataExportProvider = Provider<DataExportService>((ref) {
  log.d('DATA_EXPORT', 'Initializing data export service...');
  return DataExportService();
});
