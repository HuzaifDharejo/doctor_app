/// Centralized app routing with named routes
library;

import 'package:flutter/material.dart';
import '../../db/doctor_db.dart';
import '../../ui/screens/add_appointment_screen.dart';
import '../../ui/screens/add_invoice_screen.dart';
import '../../ui/screens/add_patient_screen.dart';
import '../../ui/screens/add_prescription_screen.dart';
import '../../ui/screens/allergy_management_screen.dart';
import '../../ui/screens/appointments_screen.dart';
import '../../ui/screens/billing_screen.dart';
import '../../ui/screens/clinical_analytics_screen.dart';
import '../../ui/screens/clinical_dashboard.dart';
import '../../ui/screens/clinical_letters_screen.dart';
import '../../ui/screens/clinical_reminders_screen.dart';
import '../../ui/screens/communications_screen.dart';
import '../../ui/screens/consent_screen.dart';
import '../../ui/screens/dashboard_screen.dart';
import '../../ui/screens/data_export_screen.dart';
import '../../ui/screens/family_history_screen.dart';
import '../../ui/screens/follow_ups_screen.dart';
import '../../ui/screens/global_search_screen.dart';
import '../../ui/screens/growth_chart_screen.dart';
import '../../ui/screens/immunizations_screen.dart';
import '../../ui/screens/insurance_screen.dart';
import '../../ui/screens/invoice_detail_screen.dart';
import '../../ui/screens/lab_orders_screen.dart';
import '../../ui/screens/medical_record_detail_screen.dart';
import '../../ui/screens/medical_records_list_screen.dart';
import '../../ui/screens/medical_reference_screen.dart';
import '../../ui/screens/doctor_profile_screen.dart';
import '../../ui/screens/notifications_screen.dart';
import '../../ui/screens/offline_sync_screen.dart';
import '../../ui/screens/onboarding_screen.dart';
import '../../ui/screens/patient_view/patient_view.dart';
import '../../ui/screens/patients_screen.dart';
import '../../ui/screens/prescriptions_screen.dart';
import '../../ui/screens/problem_list_screen.dart';
import '../../ui/screens/psychiatric_assessment_screen.dart';
import '../../ui/screens/pulmonary_evaluation_screen.dart';
import '../../ui/screens/records/records.dart';
import '../../ui/screens/recurring_appointments_screen.dart';
import '../../ui/screens/referrals_screen.dart';
import '../../ui/screens/settings_screen.dart';
import '../../ui/screens/treatment_dashboard.dart';
import '../../ui/screens/treatment_progress_screen.dart';
import '../../ui/screens/user_manual_screen.dart';
import '../../ui/screens/vital_signs_screen.dart';
import '../../ui/screens/waitlist_screen.dart';
import '../../ui/screens/backup_settings_screen.dart';

/// Route names as constants
abstract class AppRoutes {
  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String patients = '/patients';
  static const String patientView = '/patients/view';
  static const String patientViewModern = '/patients/view/modern';
  static const String addPatient = '/patients/add';
  static const String editPatient = '/patients/edit';
  static const String appointments = '/appointments';
  static const String addAppointment = '/appointments/add';
  static const String prescriptions = '/prescriptions';
  static const String addPrescription = '/prescriptions/add';
  static const String billing = '/billing';
  static const String addInvoice = '/billing/add';
  static const String invoiceDetail = '/billing/detail';
  static const String settings = '/settings';
  static const String doctorProfile = '/doctor-profile';
  static const String psychiatricAssessment = '/psychiatric-assessment';
  static const String pulmonaryEvaluation = '/pulmonary-evaluation';
  static const String addMedicalRecord = '/medical-records/add';
  static const String medicalRecordsList = '/medical-records';
  static const String medicalRecordDetail = '/medical-records/detail';
  static const String userManual = '/user-manual';
  static const String treatmentDashboard = '/treatment-dashboard';
  static const String treatmentProgress = '/treatment-progress';
  static const String treatmentOutcomes = '/treatment-outcomes';
  static const String allergyManagement = '/allergy-management';
  static const String notifications = '/notifications';
  static const String communications = '/communications';
  static const String medicalReference = '/medical-reference';
  static const String clinicalAnalytics = '/clinical-analytics';
  static const String clinicalDashboard = '/clinical-dashboard';
  static const String offlineSync = '/offline-sync';
  static const String dataExport = '/data-export';
  static const String vitalSigns = '/vital-signs';
  static const String followUps = '/follow-ups';
  static const String labResults = '/lab-results';
  static const String onboarding = '/onboarding';
  static const String backupSettings = '/backup-settings';
  
  // New clinical feature routes
  static const String referrals = '/referrals';
  static const String immunizations = '/immunizations';
  static const String familyHistory = '/family-history';
  static const String problemList = '/problem-list';
  static const String labOrders = '/lab-orders';
  static const String clinicalReminders = '/clinical-reminders';
  static const String waitlist = '/waitlist';
  static const String recurringAppointments = '/recurring-appointments';
  static const String clinicalLetters = '/clinical-letters';
  static const String consents = '/consents';
  static const String insurance = '/insurance';
  static const String growthCharts = '/growth-charts';
  static const String globalSearch = '/global-search';
}

/// Route arguments for type-safe navigation
class PatientViewArgs {
  const PatientViewArgs({required this.patient});
  final Patient patient;
}

class AddAppointmentArgs {
  const AddAppointmentArgs({this.patient, this.initialDate});
  final Patient? patient;
  final DateTime? initialDate;
}

class AddPrescriptionArgs {
  const AddPrescriptionArgs({this.patient});
  final Patient? patient;
}

class AddMedicalRecordArgs {
  const AddMedicalRecordArgs({this.patient});
  final Patient? patient;
}

class PsychiatricAssessmentArgs {
  const PsychiatricAssessmentArgs({this.patient});
  final Patient? patient;
}

class PulmonaryEvaluationArgs {
  const PulmonaryEvaluationArgs({this.patient});
  final Patient? patient;
}

class AddInvoiceArgs {
  const AddInvoiceArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

class TreatmentDashboardArgs {
  const TreatmentDashboardArgs({required this.patientId, required this.patientName});
  final int patientId;
  final String patientName;
}

class VitalSignsArgs {
  const VitalSignsArgs({required this.patientId, required this.patientName});
  final int patientId;
  final String patientName;
}

class FollowUpsArgs {
  const FollowUpsArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

class TreatmentProgressArgs {
  const TreatmentProgressArgs({required this.patientId, required this.patientName});
  final int patientId;
  final String patientName;
}

class TreatmentOutcomesArgs {
  const TreatmentOutcomesArgs({required this.patientId, required this.patientName});
  final int patientId;
  final String patientName;
}

class LabResultsArgs {
  const LabResultsArgs({required this.patientId, required this.patientName});
  final int patientId;
  final String patientName;
}

class InvoiceDetailArgs {
  const InvoiceDetailArgs({required this.invoice, this.patient});
  final Invoice invoice;
  final Patient? patient;
}

class MedicalRecordDetailArgs {
  const MedicalRecordDetailArgs({required this.record, required this.patient});
  final MedicalRecord record;
  final Patient patient;
}

class MedicalRecordsListArgs {
  const MedicalRecordsListArgs({this.filterRecordType});
  final String? filterRecordType;
}

// New clinical feature route arguments
class ReferralsArgs {
  const ReferralsArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

class ImmunizationsArgs {
  const ImmunizationsArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

class FamilyHistoryArgs {
  const FamilyHistoryArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

class ProblemListArgs {
  const ProblemListArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

class LabOrdersArgs {
  const LabOrdersArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

class ClinicalRemindersArgs {
  const ClinicalRemindersArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

class GrowthChartsArgs {
  const GrowthChartsArgs({required this.patientId, required this.patientName});
  final int patientId;
  final String patientName;
}

class ConsentsArgs {
  const ConsentsArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

class InsuranceArgs {
  const InsuranceArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

class ClinicalLettersArgs {
  const ClinicalLettersArgs({this.patientId, this.patientName});
  final int? patientId;
  final String? patientName;
}

/// App router configuration
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.patients:
        return _buildRoute(const PatientsScreen(), settings);
        
      case AppRoutes.addPatient:
        return _buildRoute(const AddPatientScreen(), settings);
        
      case AppRoutes.patientView:
      case AppRoutes.patientViewModern:
        final args = settings.arguments! as PatientViewArgs;
        return _buildRoute(PatientViewScreenModern(patient: args.patient), settings);
        
      case AppRoutes.appointments:
        return _buildRoute(const AppointmentsScreen(), settings);
        
      case AppRoutes.addAppointment:
        final args = settings.arguments as AddAppointmentArgs?;
        return _buildRoute(
          AddAppointmentScreen(
            preselectedPatient: args?.patient,
            initialDate: args?.initialDate,
          ),
          settings,
        );
        
      case AppRoutes.prescriptions:
        return _buildRoute(const PrescriptionsScreen(), settings);
        
      case AppRoutes.addPrescription:
        final args = settings.arguments as AddPrescriptionArgs?;
        return _buildRoute(
          AddPrescriptionScreen(preselectedPatient: args?.patient),
          settings,
        );
        
      case AppRoutes.billing:
        return _buildRoute(const BillingScreen(), settings);
        
      case AppRoutes.addInvoice:
        final args = settings.arguments as AddInvoiceArgs?;
        return _buildRoute(
          AddInvoiceScreen(patientId: args?.patientId),
          settings,
        );
        
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);
        
      case AppRoutes.doctorProfile:
        return _buildRoute(const DoctorProfileScreen(), settings);
        
      case AppRoutes.psychiatricAssessment:
        final args = settings.arguments as PsychiatricAssessmentArgs?;
        return _buildRoute(
          PsychiatricAssessmentScreen(preselectedPatient: args?.patient),
          settings,
        );
        
      case AppRoutes.pulmonaryEvaluation:
        final args = settings.arguments as PulmonaryEvaluationArgs?;
        return _buildRoute(
          PulmonaryEvaluationScreen(preselectedPatient: args?.patient),
          settings,
        );
        
      case AppRoutes.addMedicalRecord:
        final args = settings.arguments as AddMedicalRecordArgs?;
        return _buildRoute(
          SelectRecordTypeScreen(preselectedPatient: args?.patient),
          settings,
        );
        
      case AppRoutes.userManual:
        return _buildRoute(const UserManualScreen(), settings);
        
      case AppRoutes.backupSettings:
        return _buildRoute(const BackupSettingsScreen(), settings);
        
      case AppRoutes.treatmentDashboard:
        final args = settings.arguments as TreatmentDashboardArgs;
        return _buildRoute(
          TreatmentDashboard(patientId: args.patientId, patientName: args.patientName),
          settings,
        );
        
      case AppRoutes.allergyManagement:
        return _buildRoute(const AllergyManagementScreen(), settings);
        
      case AppRoutes.notifications:
        return _buildRoute(const NotificationsScreen(), settings);
        
      case AppRoutes.communications:
        return _buildRoute(const CommunicationsScreen(), settings);
        
      case AppRoutes.medicalReference:
        return _buildRoute(const MedicalReferenceScreen(), settings);
        
      case AppRoutes.clinicalAnalytics:
        return _buildRoute(const ClinicalAnalyticsScreen(), settings);
        
      case AppRoutes.clinicalDashboard:
        return _buildRoute(const ClinicalDashboard(), settings);
        
      case AppRoutes.offlineSync:
        return _buildRoute(const OfflineSyncScreen(), settings);
        
      case AppRoutes.dataExport:
        return _buildRoute(const DataExportScreen(), settings);
        
      case AppRoutes.vitalSigns:
        final args = settings.arguments as VitalSignsArgs;
        return _buildRoute(
          VitalSignsScreen(patientId: args.patientId, patientName: args.patientName),
          settings,
        );
        
      case AppRoutes.followUps:
        final args = settings.arguments as FollowUpsArgs?;
        return _buildRoute(
          FollowUpsScreen(patientId: args?.patientId, patientName: args?.patientName),
          settings,
        );
        
      case AppRoutes.labResults:
        final args = settings.arguments as LabResultsArgs;
        return _buildRoute(
          LabOrdersScreen(patientId: args.patientId),
          settings,
        );
        
      case AppRoutes.treatmentProgress:
        final args = settings.arguments as TreatmentProgressArgs;
        return _buildRoute(
          TreatmentProgressScreen(patientId: args.patientId, patientName: args.patientName),
          settings,
        );
        
      case AppRoutes.treatmentOutcomes:
        final args = settings.arguments as TreatmentOutcomesArgs;
        return _buildRoute(
          TreatmentProgressScreen(patientId: args.patientId, patientName: args.patientName),
          settings,
        );
        
      case AppRoutes.invoiceDetail:
        final args = settings.arguments as InvoiceDetailArgs;
        return _buildRoute(
          InvoiceDetailScreen(invoice: args.invoice, patient: args.patient),
          settings,
        );
        
      case AppRoutes.medicalRecordsList:
        final args = settings.arguments as MedicalRecordsListArgs?;
        return _buildRoute(
          MedicalRecordsListScreen(filterRecordType: args?.filterRecordType),
          settings,
        );
        
      case AppRoutes.medicalRecordDetail:
        final args = settings.arguments as MedicalRecordDetailArgs;
        return _buildRoute(
          MedicalRecordDetailScreen(record: args.record, patient: args.patient),
          settings,
        );
        
      case AppRoutes.onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
        
      case AppRoutes.dashboard:
        return _buildRoute(const DashboardScreen(), settings);
        
      // New clinical feature routes
      case AppRoutes.referrals:
        final args = settings.arguments as ReferralsArgs?;
        return _buildRoute(
          ReferralsScreen(patientId: args?.patientId),
          settings,
        );
        
      case AppRoutes.immunizations:
        final args = settings.arguments as ImmunizationsArgs?;
        return _buildRoute(
          ImmunizationsScreen(patientId: args?.patientId),
          settings,
        );
        
      case AppRoutes.familyHistory:
        final args = settings.arguments as FamilyHistoryArgs?;
        return _buildRoute(
          FamilyHistoryScreen(patientId: args?.patientId),
          settings,
        );
        
      case AppRoutes.problemList:
        final args = settings.arguments as ProblemListArgs?;
        return _buildRoute(
          ProblemListScreen(patientId: args?.patientId),
          settings,
        );
        
      case AppRoutes.labOrders:
        final args = settings.arguments as LabOrdersArgs?;
        return _buildRoute(
          LabOrdersScreen(patientId: args?.patientId),
          settings,
        );
        
      case AppRoutes.clinicalReminders:
        final args = settings.arguments as ClinicalRemindersArgs?;
        return _buildRoute(
          ClinicalRemindersScreen(patientId: args?.patientId),
          settings,
        );
        
      case AppRoutes.waitlist:
        return _buildRoute(const WaitlistScreen(), settings);
        
      case AppRoutes.recurringAppointments:
        return _buildRoute(const RecurringAppointmentsScreen(), settings);
        
      case AppRoutes.clinicalLetters:
        return _buildRoute(
          const ClinicalLettersScreen(),
          settings,
        );
        
      case AppRoutes.consents:
        return _buildRoute(
          const ConsentScreen(),
          settings,
        );
        
      case AppRoutes.insurance:
        return _buildRoute(
          const InsuranceScreen(),
          settings,
        );
        
      case AppRoutes.growthCharts:
        final args = settings.arguments as GrowthChartsArgs;
        return _buildRoute(
          GrowthChartScreen(patientId: args.patientId),
          settings,
        );
        
      case AppRoutes.globalSearch:
        return _buildRoute(const GlobalSearchScreen(), settings);
        
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute<T> _buildRoute<T>(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: settings,
    );
  }

  /// Create a MaterialPageRoute with auto-generated route name from widget type.
  /// Use this instead of MaterialPageRoute directly to enable proper navigation logging.
  /// 
  /// Example:
  /// ```dart
  /// Navigator.push(context, AppRouter.route(const FollowUpsScreen()));
  /// ```
  static MaterialPageRoute<T> route<T>(
    Widget page, {
    String? name,
    bool fullscreenDialog = false,
    bool maintainState = true,
  }) {
    // Auto-generate route name from widget type if not provided
    final routeName = name ?? _widgetToRouteName(page.runtimeType.toString());
    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: RouteSettings(name: routeName),
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
    );
  }

  /// Convert widget class name to route name
  /// e.g., "FollowUpsScreen" -> "/follow-ups-screen"
  static String _widgetToRouteName(String widgetName) {
    // Remove generic type parameters if any
    final baseName = widgetName.split('<').first;
    // Convert PascalCase to kebab-case
    final kebab = baseName
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m.group(1)}-${m.group(2)}',
        )
        .toLowerCase();
    return '/$kebab';
  }
}

/// Navigation helper extension
extension NavigationHelper on BuildContext {
  /// Navigate to a named route
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate and replace current route
  Future<T?> pushReplacementNamed<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushReplacementNamed<T, void>(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate to patient view
  Future<void> goToPatientView(Patient patient) {
    return pushNamed(
      AppRoutes.patientView,
      arguments: PatientViewArgs(patient: patient),
    );
  }

  /// Navigate to add patient screen
  Future<void> goToAddPatient() => pushNamed(AppRoutes.addPatient);

  /// Navigate to add appointment

  Future<void> goToAddAppointment({Patient? patient, DateTime? initialDate}) {
    return pushNamed(
      AppRoutes.addAppointment,
      arguments: AddAppointmentArgs(patient: patient, initialDate: initialDate),
    );
  }

  /// Navigate to add prescription
  Future<void> goToAddPrescription({Patient? patient}) {
    return pushNamed(
      AppRoutes.addPrescription,
      arguments: AddPrescriptionArgs(patient: patient),
    );
  }

  /// Navigate to add invoice
  Future<void> goToAddInvoice({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.addInvoice,
      arguments: AddInvoiceArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to add medical record
  Future<void> goToAddMedicalRecord(Patient patient) {
    return pushNamed(
      AppRoutes.addMedicalRecord,
      arguments: AddMedicalRecordArgs(patient: patient),
    );
  }

  /// Navigate to settings
  Future<void> goToSettings() => pushNamed(AppRoutes.settings);

  /// Navigate to doctor profile
  Future<void> goToDoctorProfile() => pushNamed(AppRoutes.doctorProfile);

  /// Navigate to modern patient view
  Future<void> goToPatientViewModern(Patient patient) {
    return pushNamed(
      AppRoutes.patientViewModern,
      arguments: PatientViewArgs(patient: patient),
    );
  }

  /// Navigate to psychiatric assessment
  Future<void> goToPsychiatricAssessment({Patient? patient}) {
    return pushNamed(
      AppRoutes.psychiatricAssessment,
      arguments: PsychiatricAssessmentArgs(patient: patient),
    );
  }

  /// Navigate to pulmonary evaluation
  Future<void> goToPulmonaryEvaluation({Patient? patient}) {
    return pushNamed(
      AppRoutes.pulmonaryEvaluation,
      arguments: PulmonaryEvaluationArgs(patient: patient),
    );
  }

  /// Navigate to treatment dashboard
  Future<void> goToTreatmentDashboard(int patientId, String patientName) {
    return pushNamed(
      AppRoutes.treatmentDashboard,
      arguments: TreatmentDashboardArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to allergy management
  Future<void> goToAllergyManagement() => pushNamed(AppRoutes.allergyManagement);

  /// Navigate to notifications
  Future<void> goToNotifications() => pushNamed(AppRoutes.notifications);

  /// Navigate to communications
  Future<void> goToCommunications() => pushNamed(AppRoutes.communications);

  /// Navigate to medical reference
  Future<void> goToMedicalReference() => pushNamed(AppRoutes.medicalReference);

  /// Navigate to clinical analytics
  Future<void> goToClinicalAnalytics() => pushNamed(AppRoutes.clinicalAnalytics);

  /// Navigate to clinical dashboard
  Future<void> goToClinicalDashboard() => pushNamed(AppRoutes.clinicalDashboard);

  /// Navigate to offline sync
  Future<void> goToOfflineSync() => pushNamed(AppRoutes.offlineSync);

  /// Navigate to data export
  Future<void> goToDataExport() => pushNamed(AppRoutes.dataExport);

  /// Navigate to vital signs
  Future<void> goToVitalSigns(int patientId, String patientName) {
    return pushNamed(
      AppRoutes.vitalSigns,
      arguments: VitalSignsArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to follow-ups
  Future<void> goToFollowUps({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.followUps,
      arguments: FollowUpsArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to global search
  Future<void> goToGlobalSearch() => pushNamed(AppRoutes.globalSearch);

  /// Navigate to lab results
  Future<void> goToLabResults(int patientId, String patientName) {
    return pushNamed(
      AppRoutes.labResults,
      arguments: LabResultsArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to treatment progress
  Future<void> goToTreatmentProgress(int patientId, String patientName) {
    return pushNamed(
      AppRoutes.treatmentProgress,
      arguments: TreatmentProgressArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to treatment outcomes
  Future<void> goToTreatmentOutcomes(int patientId, String patientName) {
    return pushNamed(
      AppRoutes.treatmentOutcomes,
      arguments: TreatmentOutcomesArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to invoice detail
  Future<void> goToInvoiceDetail(Invoice invoice, {Patient? patient}) {
    return pushNamed(
      AppRoutes.invoiceDetail,
      arguments: InvoiceDetailArgs(invoice: invoice, patient: patient),
    );
  }

  /// Navigate to medical records list
  Future<void> goToMedicalRecordsList({String? filterRecordType}) {
    return pushNamed(
      AppRoutes.medicalRecordsList,
      arguments: MedicalRecordsListArgs(filterRecordType: filterRecordType),
    );
  }

  /// Navigate to medical record detail
  Future<void> goToMedicalRecordDetail(MedicalRecord record, Patient patient) {
    return pushNamed(
      AppRoutes.medicalRecordDetail,
      arguments: MedicalRecordDetailArgs(record: record, patient: patient),
    );
  }

  /// Navigate to onboarding
  Future<void> goToOnboarding() => pushNamed(AppRoutes.onboarding);

  /// Navigate to dashboard
  Future<void> goToDashboard() => pushNamed(AppRoutes.dashboard);

  // New clinical feature navigation helpers
  
  /// Navigate to referrals
  Future<void> goToReferrals({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.referrals,
      arguments: ReferralsArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to immunizations
  Future<void> goToImmunizations({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.immunizations,
      arguments: ImmunizationsArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to family history
  Future<void> goToFamilyHistory({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.familyHistory,
      arguments: FamilyHistoryArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to problem list
  Future<void> goToProblemList({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.problemList,
      arguments: ProblemListArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to lab orders
  Future<void> goToLabOrders({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.labOrders,
      arguments: LabOrdersArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to clinical reminders
  Future<void> goToClinicalReminders({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.clinicalReminders,
      arguments: ClinicalRemindersArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to waitlist
  Future<void> goToWaitlist() => pushNamed(AppRoutes.waitlist);

  /// Navigate to recurring appointments
  Future<void> goToRecurringAppointments() => pushNamed(AppRoutes.recurringAppointments);

  /// Navigate to clinical letters
  Future<void> goToClinicalLetters({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.clinicalLetters,
      arguments: ClinicalLettersArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to consents
  Future<void> goToConsents({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.consents,
      arguments: ConsentsArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to insurance
  Future<void> goToInsurance({int? patientId, String? patientName}) {
    return pushNamed(
      AppRoutes.insurance,
      arguments: InsuranceArgs(patientId: patientId, patientName: patientName),
    );
  }

  /// Navigate to growth charts
  Future<void> goToGrowthCharts(int patientId, String patientName) {
    return pushNamed(
      AppRoutes.growthCharts,
      arguments: GrowthChartsArgs(patientId: patientId, patientName: patientName),
    );
  }
}
