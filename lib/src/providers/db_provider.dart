import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/doctor_db.dart';
import '../services/seed_data_service.dart';
import '../services/doctor_settings_service.dart';

final doctorDbProvider = FutureProvider<DoctorDatabase>((ref) async {
  final db = DoctorDatabase();
  ref.onDispose(() => db.close());
  
  // Seed sample data on first launch
  try {
    await seedSampleData(db);
  } catch (e) {
    print('Note: Database seeding failed - $e');
  }
  
  return db;
});

// Doctor profile/settings provider
final doctorSettingsProvider = ChangeNotifierProvider<DoctorSettingsService>((ref) {
  final service = DoctorSettingsService();
  service.loadProfile();
  return service;
});

// App settings provider (notifications, dark mode, language, etc.)
final appSettingsProvider = ChangeNotifierProvider<AppSettingsService>((ref) {
  final service = AppSettingsService();
  service.loadSettings();
  return service;
});
