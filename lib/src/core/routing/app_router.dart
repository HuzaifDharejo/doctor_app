/// Centralized app routing with named routes
library;

import 'package:flutter/material.dart';
import '../../db/doctor_db.dart';
import '../../services/doctor_auth_service.dart';
import '../../ui/screens/add_appointment_screen.dart';
import '../../ui/screens/add_invoice_screen.dart';
import '../../ui/screens/add_medical_record_screen.dart';
import '../../ui/screens/add_patient_screen.dart';
import '../../ui/screens/add_prescription_screen.dart';
import '../../ui/screens/appointments_screen.dart';
import '../../ui/screens/billing_screen.dart';
import '../../ui/screens/doctor_dashboard_screen.dart';
import '../../ui/screens/doctor_login_screen.dart';
import '../../ui/screens/doctor_profile_screen.dart';
import '../../ui/screens/patient_view_screen_modern.dart';
import '../../ui/screens/patients_screen.dart';
import '../../ui/screens/prescriptions_screen.dart';
import '../../ui/screens/psychiatric_assessment_screen_modern.dart';
import '../../ui/screens/pulmonary_evaluation_screen_modern.dart';
import '../../ui/screens/records/records.dart';
import '../../ui/screens/settings_screen.dart';
import '../../ui/screens/user_manual_screen.dart';
import '../../ui/screens/treatment_dashboard.dart';

/// Route names as constants
abstract class AppRoutes {
  static const String home = '/';
  static const String doctorLogin = '/doctor-login';
  static const String doctorDashboard = '/doctor-dashboard';
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
  static const String settings = '/settings';
  static const String doctorProfile = '/doctor-profile';
  static const String psychiatricAssessment = '/psychiatric-assessment';
  static const String psychiatricAssessmentModern = '/psychiatric-assessment/modern';
  static const String pulmonaryEvaluationModern = '/pulmonary-evaluation/modern';
  static const String addMedicalRecord = '/medical-records/add';
  static const String userManual = '/user-manual';
  static const String treatmentDashboard = '/treatment-dashboard';
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

/// App router configuration
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.doctorLogin:
        return _buildRoute(const DoctorLoginScreen(), settings);
        
      case AppRoutes.doctorDashboard:
        return _buildRoute(const DoctorDashboardScreen(), settings);
        
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
      case AppRoutes.psychiatricAssessmentModern:
        final args = settings.arguments as PsychiatricAssessmentArgs?;
        return _buildRoute(
          PsychiatricAssessmentScreenModern(preselectedPatient: args?.patient),
          settings,
        );
        
      case AppRoutes.pulmonaryEvaluationModern:
        final args = settings.arguments as PulmonaryEvaluationArgs?;
        return _buildRoute(
          PulmonaryEvaluationScreenModern(preselectedPatient: args?.patient),
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
        
      case AppRoutes.treatmentDashboard:
        final args = settings.arguments as TreatmentDashboardArgs;
        return _buildRoute(
          TreatmentDashboard(patientId: args.patientId, patientName: args.patientName),
          settings,
        );
        
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

  /// Navigate to psychiatric assessment
  Future<void> goToPsychiatricAssessment() =>
      pushNamed(AppRoutes.psychiatricAssessment);

  /// Navigate to modern patient view
  Future<void> goToPatientViewModern(Patient patient) {
    return pushNamed(
      AppRoutes.patientViewModern,
      arguments: PatientViewArgs(patient: patient),
    );
  }

  /// Navigate to modern psychiatric assessment
  Future<void> goToPsychiatricAssessmentModern({Patient? patient}) {
    return pushNamed(
      AppRoutes.psychiatricAssessmentModern,
      arguments: PsychiatricAssessmentArgs(patient: patient),
    );
  }

  /// Navigate to modern pulmonary evaluation
  Future<void> goToPulmonaryEvaluationModern({Patient? patient}) {
    return pushNamed(
      AppRoutes.pulmonaryEvaluationModern,
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
}
