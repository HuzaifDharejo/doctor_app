import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/doctor_db.dart';
import '../services/allergy_management_service.dart';
import '../services/doctor_settings_service.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';
import '../services/seed_data_service.dart';
import '../services/treatment_efficacy_service.dart';

final doctorDbProvider = FutureProvider<DoctorDatabase>((ref) async {
  log
    ..i('DB', 'Initializing database...')
    ..startMetric('database_init');
  
  final db = DoctorDatabase();
  ref.onDispose(() {
    log.i('DB', 'Closing database connection');
    db.close();
  });
  
  // Seed sample data on first launch
  try {
    log.d('DB', 'Starting database seeding...');
    await seedSampleData(db);
    log.i('DB', 'Database seeding completed');
  } catch (e, st) {
    log.w('DB', 'Database seeding failed', error: e, stackTrace: st);
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

