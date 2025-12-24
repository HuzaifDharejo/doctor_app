import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/doctor_db.dart';
import '../services/allergy_management_service.dart';
import '../services/clinical_analytics_service.dart';
import '../services/clinical_letter_service.dart';
import '../services/clinical_reminder_service.dart';
import '../services/communication_service.dart';
import '../services/consent_service.dart';
import '../services/data_export_service.dart';
import '../services/doctor_settings_service.dart';
import '../services/drug_reference_service.dart';
import '../services/dynamic_suggestions_service.dart';
import '../services/family_history_service.dart';
import '../services/growth_chart_service.dart';
import '../services/immunization_service.dart';
import '../services/insurance_service.dart';
import '../services/lab_order_service.dart';
import '../services/localization_service.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';
import '../services/offline_sync_service.dart';
import '../services/problem_list_service.dart';
import '../services/recurring_appointment_service.dart';
import '../services/referral_service.dart';
import '../services/treatment_efficacy_service.dart';
import '../services/waitlist_service.dart';


final doctorDbProvider = FutureProvider<DoctorDatabase>((ref) async {
  log
    ..i('DB', 'Initializing database...')
    ..startMetric('database_init');
  
  // Use singleton instance to prevent multiple database connections
  final db = DoctorDatabase.instance;
  
  // Database initialized - no auto-seeding
  
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

// ═══════════════════════════════════════════════════════════════════════════════
// NEW CLINICAL SERVICES PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

// Referral service provider
final referralProvider = Provider<ReferralService>((ref) {
  log.d('REFERRAL', 'Initializing referral service...');
  return ReferralService();
});

// Immunization service provider
final immunizationProvider = Provider<ImmunizationService>((ref) {
  log.d('IMMUNIZATION', 'Initializing immunization service...');
  return ImmunizationService();
});

// Family history service provider
final familyHistoryProvider = Provider<FamilyHistoryService>((ref) {
  log.d('FAMILY_HISTORY', 'Initializing family history service...');
  return FamilyHistoryService();
});

// Consent service provider
final consentProvider = Provider<ConsentService>((ref) {
  log.d('CONSENT', 'Initializing consent service...');
  return ConsentService();
});

// Insurance service provider
final insuranceProvider = Provider<InsuranceService>((ref) {
  log.d('INSURANCE', 'Initializing insurance service...');
  return InsuranceService();
});

// Lab order service provider
final labOrderProvider = Provider<LabOrderService>((ref) {
  log.d('LAB_ORDER', 'Initializing lab order service...');
  return LabOrderService();
});

// Problem list service provider
final problemListProvider = Provider<ProblemListService>((ref) {
  log.d('PROBLEM_LIST', 'Initializing problem list service...');
  return ProblemListService();
});

// Growth chart service provider
final growthChartProvider = Provider<GrowthChartService>((ref) {
  log.d('GROWTH_CHART', 'Initializing growth chart service...');
  return GrowthChartService();
});

// Clinical reminder service provider
final clinicalReminderProvider = Provider<ClinicalReminderService>((ref) {
  log.d('CLINICAL_REMINDER', 'Initializing clinical reminder service...');
  return ClinicalReminderService();
});

// Waitlist service provider
final waitlistProvider = Provider<WaitlistService>((ref) {
  log.d('WAITLIST', 'Initializing waitlist service...');
  return WaitlistService();
});

// Recurring appointment service provider
final recurringAppointmentProvider = Provider<RecurringAppointmentService>((ref) {
  log.d('RECURRING_APPOINTMENT', 'Initializing recurring appointment service...');
  return RecurringAppointmentService();
});

// Clinical letter service provider
final clinicalLetterProvider = Provider<ClinicalLetterService>((ref) {
  log.d('CLINICAL_LETTER', 'Initializing clinical letter service...');
  return ClinicalLetterService();
});

// Dynamic suggestions service provider
// Provides suggestions that learn from user input
final dynamicSuggestionsProvider = FutureProvider<DynamicSuggestionsService>((ref) async {
  log.d('SUGGESTIONS', 'Initializing dynamic suggestions service...');
  final db = await ref.watch(doctorDbProvider.future);
  final service = DynamicSuggestionsService(db);
  await service.initialize();
  log.i('SUGGESTIONS', 'Dynamic suggestions service initialized');
  return service;
});
