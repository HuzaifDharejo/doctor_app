/// Data models for the Doctor App
/// 
/// This library exports all the data models used throughout the application.
/// These models provide:
/// - Type safety and validation
/// - JSON serialization/deserialization
/// - Business logic encapsulation
/// - Immutability with copyWith methods
library;

// Core models
export 'appointment.dart';
export 'invoice.dart';
export 'medical_record.dart';
export 'patient.dart';
export 'prescription.dart';
export 'pulmonary_evaluation.dart';

// Clinical features - Referrals & Care Coordination
export 'referral.dart';
export 'clinical_letter.dart';

// Clinical features - Patient History
export 'family_history.dart';
export 'immunization.dart';
export 'problem_list.dart';

// Clinical features - Orders & Results
export 'lab_order.dart';

// Clinical features - Growth & Development
export 'growth_chart.dart';

// Clinical features - Administrative
export 'consent.dart';
export 'insurance.dart';
export 'clinical_reminder.dart';

// Scheduling features
export 'waitlist.dart';
export 'recurring_appointment.dart';
