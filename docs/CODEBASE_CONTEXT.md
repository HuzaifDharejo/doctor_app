R# Doctor App - Codebase Context Documentation

**Last Updated:** December 2024  
**Last Analysis:** December 20, 2024  
**Project Type:** Flutter Offline-First Clinic Management System  
**Architecture:** Clean Architecture with Riverpod State Management  
**Database Schema Version:** 13 (50 tables)

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture & Design Patterns](#architecture--design-patterns)
3. [Directory Structure](#directory-structure)
4. [Key Components](#key-components)
5. [Database Schema](#database-schema)
6. [State Management](#state-management)
7. [Navigation & Routing](#navigation--routing)
8. [Services Layer](#services-layer)
9. [UI Components](#ui-components)
10. [Development Workflow](#development-workflow)

---

## 🎯 Project Overview

This is a **comprehensive offline-first clinic management application** built with Flutter for a single-doctor practice. The app handles the complete clinical workflow from patient registration to billing, with extensive clinical documentation capabilities.

### Key Characteristics
- **Offline-First**: Works without internet, syncs when connected
- **Single-Doctor Centric**: All features designed for one doctor's practice
- **HIPAA-Compliant**: Audit logging and security features
- **Cross-Platform**: Android, iOS, Web, Windows support
- **Material Design 3**: Modern UI with full dark mode support

### Tech Stack
- **Framework**: Flutter 3.38+
- **Language**: Dart 3.10+
- **Database**: Drift ORM (SQLite) - 35+ tables
- **State Management**: Riverpod 2.6+
- **UI**: Material Design 3
- **Charts**: FL Chart
- **PDF**: pdf, printing packages
- **Authentication**: local_auth (PIN/Biometric)
- **Notifications**: flutter_local_notifications
- **OCR**: google_mlkit_text_recognition
- **Speech**: speech_to_text
- **Cloud**: Google Drive API

---

## 🏗️ Architecture & Design Patterns

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│         UI Layer (Screens)          │  ← Presentation
├─────────────────────────────────────┤
│      Services Layer (Business)      │  ← Business Logic
├─────────────────────────────────────┤
│    Repository/Data Layer (Drift)    │  ← Data Access
└─────────────────────────────────────┘
```

### Design Patterns Used

1. **Repository Pattern**: Clean data layer abstraction
   - Location: `lib/src/core/data/repositories.dart`
   - Abstracts database operations from UI

2. **Provider Pattern**: Dependency injection with Riverpod
   - Location: `lib/src/providers/`
   - All services and database access via providers

3. **Result Type Pattern**: Functional error handling
   - Location: `lib/src/core/utils/result.dart`
   - No exceptions for expected errors, uses sealed classes

4. **Service Layer Pattern**: Business logic separation
   - Location: `lib/src/services/`
   - 50+ services for different features

5. **Component Pattern**: Reusable UI components
   - Location: `lib/src/core/components/`, `lib/src/core/widgets/`
   - DRY architecture with specialized form components

### Code Quality Standards

- **Strict Type Safety**: Enabled `strict-casts`, `strict-inference`, `strict-raw-types`
- **Comprehensive Linting**: 40+ lint rules in `analysis_options.yaml`
- **Zero Analyzer Errors**: All code passes strict static analysis
- **776+ Tests**: Unit, widget, and integration tests

---

## 📁 Directory Structure

```
lib/
├── main.dart                    # App entry point with error handling
└── src/
    ├── app.dart                 # App configuration, theme, routing setup
    │
    ├── core/                    # Core utilities and patterns
    │   ├── components/          # Reusable UI components (3 files)
    │   │   ├── app_button.dart
    │   │   ├── app_input.dart
    │   │   └── components.dart
    │   │
    │   ├── constants/           # App-wide constants (3 files)
    │   │   ├── app_constants.dart
    │   │   ├── app_strings.dart
    │   │   └── constants.dart
    │   │
    │   ├── data/                # Data layer abstractions (2 files)
    │   │   ├── data.dart
    │   │   └── repositories.dart
    │   │
    │   ├── extensions/          # Dart extensions (5 files)
    │   │   ├── color_extensions.dart
    │   │   ├── context_extensions.dart
    │   │   ├── date_extensions.dart
    │   │   ├── extensions.dart
    │   │   └── string_extensions.dart
    │   │
    │   ├── mixins/              # Widget mixins (1 file)
    │   │   └── responsive_mixin.dart
    │   │
    │   ├── routing/             # Navigation & routes (1 file)
    │   │   └── app_router.dart  # 40+ named routes with type-safe args
    │   │
    │   ├── theme/               # Design tokens (1 file)
    │   │   └── design_tokens.dart
    │   │
    │   ├── utils/               # Utilities (13 files)
    │   │   ├── app_exceptions.dart
    │   │   ├── date_formatters.dart
    │   │   ├── debouncer.dart
    │   │   ├── input_validators.dart
    │   │   ├── number_formatter.dart
    │   │   ├── pagination.dart
    │   │   ├── result.dart       # Result<T, E> sealed class
    │   │   └── string_utils.dart
    │   │
    │   ├── widgets/             # Core reusable widgets (29 files)
    │   │   ├── app_card.dart
    │   │   ├── app_header.dart
    │   │   ├── confirmation_dialog.dart
    │   │   ├── date_time_picker.dart
    │   │   ├── error_display.dart
    │   │   ├── form_field_wrapper.dart
    │   │   ├── loading_button.dart
    │   │   ├── search_field.dart
    │   │   ├── stat_card.dart
    │   │   ├── skeleton_loading.dart
    │   │   ├── shimmer_loading.dart
    │   │   ├── empty_state.dart
    │   │   ├── error_state.dart
    │   │   ├── loading_state.dart
    │   │   └── [15+ more widgets]
    │   │
    │   └── core.dart            # Core module exports
    │
    ├── data/                    # Demo data & seeds (1 file)
    │   └── demo_data.dart
    │
    ├── db/                      # Database layer
    │   ├── doctor_db.dart       # Main Drift schema (35+ tables)
    │   ├── doctor_db.g.dart     # Generated Drift code
    │   ├── doctor_db_native.dart # Native platform implementation
    │   ├── doctor_db_web.dart   # Web platform implementation
    │   │
    │   ├── schema_v2/           # Database migrations V2
    │   │   ├── encounters_schema.dart
    │   │   └── migration_service.dart
    │   │
    │   └── schema_v3/           # Database migrations V3
    │       └── [5 files]
    │
    ├── extensions/              # Model extensions (2 files)
    │   ├── drift_extensions.dart
    │   └── theme_extensions.dart
    │
    ├── models/                  # Data models (19 files)
    │   ├── appointment.dart
    │   ├── clinical_letter.dart
    │   ├── clinical_reminder.dart
    │   ├── consent.dart
    │   ├── family_history.dart
    │   ├── growth_chart.dart
    │   ├── immunization.dart
    │   ├── insurance.dart
    │   ├── invoice.dart
    │   ├── lab_order.dart
    │   ├── medical_record.dart
    │   ├── patient.dart
    │   ├── prescription.dart
    │   ├── problem_list.dart
    │   ├── pulmonary_evaluation.dart
    │   ├── recurring_appointment.dart
    │   ├── referral.dart
    │   ├── waitlist.dart
    │   └── models.dart          # Model exports
    │
    ├── providers/               # Riverpod providers (6 files)
    │   ├── app_lock_provider.dart
    │   ├── audit_provider.dart
    │   ├── db_provider.dart      # Main database provider
    │   ├── encounter_provider.dart
    │   ├── google_calendar_provider.dart
    │   └── migration_provider.dart
    │
    ├── services/                # Business logic (52 files)
    │   ├── allergy_checking_service.dart
    │   ├── allergy_management_service.dart
    │   ├── app_lock_service.dart
    │   ├── audit_service.dart
    │   ├── backup_service.dart
    │   ├── clinical_analytics_service.dart
    │   ├── clinical_calculator_service.dart
    │   ├── clinical_letter_service.dart
    │   ├── clinical_reminder_service.dart
    │   ├── cloud_backup_service.dart
    │   ├── communication_service.dart
    │   ├── consent_service.dart
    │   ├── data_export_service.dart
    │   ├── doctor_settings_service.dart
    │   ├── drug_interaction_service.dart
    │   ├── encounter_service.dart
    │   ├── encryption_service.dart
    │   ├── family_history_service.dart
    │   ├── google_calendar_service.dart
    │   ├── google_drive_backup_service.dart
    │   ├── growth_chart_service.dart
    │   ├── immunization_service.dart
    │   ├── insurance_service.dart
    │   ├── lab_order_service.dart
    │   ├── local_notification_service.dart
    │   ├── localization_service.dart
    │   ├── logger_service.dart   # Centralized logging
    │   ├── ocr_service.dart
    │   ├── offline_sync_service.dart
    │   ├── pdf_service.dart
    │   ├── photo_service.dart
    │   ├── problem_list_service.dart
    │   ├── referral_service.dart
    │   ├── voice_dictation_service.dart
    │   ├── waitlist_service.dart
    │   └── [20+ more services]
    │
    ├── theme/                   # App theming (1 file)
    │   └── app_theme.dart       # Light & dark theme definitions
    │
    ├── ui/                      # UI layer
    │   ├── screens/             # All app screens (145 files total)
    │   │   ├── dashboard_screen_modern.dart
    │   │   ├── patients_screen.dart
    │   │   ├── appointments_screen.dart
    │   │   ├── prescriptions_screen.dart
    │   │   ├── billing_screen.dart
    │   │   ├── settings_screen.dart
    │   │   │
    │   │   ├── patient_view/    # Patient detail module
    │   │   │   ├── patient_view_screen.dart
    │   │   │   ├── patient_timeline_tab.dart
    │   │   │   ├── patient_visits_tab.dart
    │   │   │   ├── patient_clinical_tab.dart
    │   │   │   ├── patient_billing_tab.dart
    │   │   │   └── widgets/     # Patient-specific widgets (10 files)
    │   │   │
    │   │   ├── add_prescription/ # Prescription module
    │   │   │   ├── add_prescription.dart
    │   │   │   └── components/  # Medication components (8 files)
    │   │   │
    │   │   ├── lab_orders/       # Lab orders module
    │   │   │   ├── lab_orders.dart
    │   │   │   └── components/  # Lab order components (8 files)
    │   │   │
    │   │   ├── records/          # Medical records module
    │   │   │   ├── select_record_type_screen.dart
    │   │   │   ├── add_general_record_screen.dart
    │   │   │   ├── add_psychiatric_assessment_screen.dart
    │   │   │   ├── add_pulmonary_screen.dart
    │   │   │   ├── add_lab_result_screen.dart
    │   │   │   ├── add_imaging_screen.dart
    │   │   │   ├── add_procedure_screen.dart
    │   │   │   ├── add_vitals_record_screen.dart
    │   │   │   ├── add_cardiac_exam_screen.dart
    │   │   │   ├── add_ent_exam_screen.dart
    │   │   │   ├── add_eye_exam_screen.dart
    │   │   │   ├── add_gi_exam_screen.dart
    │   │   │   ├── add_neuro_exam_screen.dart
    │   │   │   ├── add_orthopedic_exam_screen.dart
    │   │   │   ├── add_skin_exam_screen.dart
    │   │   │   ├── add_gyn_exam_screen.dart
    │   │   │   ├── add_pediatric_checkup_screen.dart
    │   │   │   ├── add_certificate_screen.dart
    │   │   │   ├── add_follow_up_screen.dart
    │   │   │   ├── add_referral_screen.dart
    │   │   │   └── components/  # Record form components (23 files)
    │   │   │
    │   │   └── settings/        # Settings module (3 files)
    │   │
    │   └── widgets/             # Reusable UI widgets (33 files)
    │       ├── voice_dictation_button.dart
    │       ├── suggestion_text_field.dart
    │       └── records/components/  # Medical record widgets
    │
    └── utils/                   # App-specific utilities (1 file)
        └── pkr_currency.dart
```

---

## 🔑 Key Components

### 1. App Entry Point (`main.dart`)

**Location**: `lib/main.dart`

**Responsibilities**:
- Initialize Flutter bindings
- Configure global error handlers (Flutter errors, async errors)
- Setup logger service with appropriate log levels
- Wrap app in `ProviderScope` for Riverpod
- Launch `DoctorApp` widget

**Key Features**:
- Comprehensive error catching and logging
- Debug mode detection
- Logger configuration based on build mode

### 2. App Configuration (`app.dart`)

**Location**: `lib/src/app.dart`

**Responsibilities**:
- App lifecycle management
- Theme configuration (light/dark mode)
- Localization setup
- Navigation setup with route generation
- App lock wrapper (shows lock screen when locked)
- Home shell with bottom navigation

**Key Components**:
- `DoctorApp`: Main app widget
- `_AppLockWrapper`: Handles app lock state
- `HomeShell`: Bottom navigation with 3 tabs (Dashboard, Patients, Appointments)
- `_LoggingNavigatorObserver`: Tracks navigation for audit logs

**Navigation Structure**:
```
HomeShell (Bottom Nav)
├── Dashboard Tab
├── Patients Tab
└── Appointments Tab
```

### 3. Routing System (`app_router.dart`)

**Location**: `lib/src/core/routing/app_router.dart`

**Features**:
- 51 named routes defined in `AppRoutes` class
- Type-safe route arguments (e.g., `PatientViewArgs`, `AddAppointmentArgs`)
- Navigation helper extensions on `BuildContext`
- Auto-generated route names from widget types
- Route generation with error handling

**Common Routes**:
- `/patients` - Patient list
- `/patients/view` - Patient detail
- `/appointments` - Appointment list
- `/prescriptions` - Prescription list
- `/billing` - Billing/invoices
- `/settings` - App settings
- `/doctor-profile` - Doctor profile

**Usage Example**:
```dart
// Navigate with type-safe arguments
context.goToPatientView(patient);

// Or use named route directly
context.pushNamed(
  AppRoutes.patientView,
  arguments: PatientViewArgs(patient: patient),
);
```

### 4. Database Layer (`doctor_db.dart`)

**Location**: `lib/src/db/doctor_db.dart`

**Technology**: Drift ORM (type-safe SQLite)

**Schema Overview**:
- **50 tables** for comprehensive data management
- **Versioned migrations** (V2, V3, V4, V5, V7) for schema evolution
- **Current schema version**: 13
- **Foreign key relationships** between tables
- **Normalized design**: Most data properly normalized (V5+ reduced JSON storage)
- **Singleton pattern**: Database instance managed as singleton

**Core Tables**:
- `Patients` - Patient demographics and medical info
- `Appointments` - Scheduling with status tracking
- `Prescriptions` - Medications with JSON items
- `MedicalRecords` - Clinical documentation (JSON storage)
- `Invoices` - Billing and payments

**V2 Schema Additions**:
- `Encounters` - Visit tracking
- `Diagnoses` - ICD-10 coded diagnoses
- `ClinicalNotes` - SOAP notes
- `VitalSigns` - Vital measurements
- `TreatmentOutcomes` - Outcome tracking

**V3 Schema Additions**:
- `Referrals` - External specialist referrals
- `Immunizations` - Vaccine records
- `FamilyMedicalHistory` - Family history
- `PatientConsents` - Consent forms
- `InsuranceInfo` - Insurance data
- `LabOrders` - Lab order tracking
- `ProblemList` - Active problems
- `ClinicalReminders` - Screening reminders
- `AppointmentWaitlist` - Waitlist management
- `RecurringAppointments` - Recurring patterns
- `ClinicalLetters` - Medical letters

**Database Provider**:
- Location: `lib/src/providers/db_provider.dart`
- Provides database instance via Riverpod
- Handles initialization and migrations

### 5. State Management (Riverpod)

**Location**: `lib/src/providers/`

**Key Providers**:
- `doctorDbProvider` - Database instance
- `appSettingsProvider` - App settings (theme, onboarding, etc.)
- `doctorSettingsProvider` - Doctor profile and clinic info
- `appLockServiceProvider` - App lock service
- `auditServiceProvider` - Audit logging service
- `localizationProvider` - Localization service

**Usage Pattern**:
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(doctorDbProvider).value;
    final settings = ref.watch(appSettingsProvider);
    
    // Use providers...
  }
}
```

### 6. Services Layer

**Location**: `lib/src/services/`

**Service Categories**:

**Clinical Services**:
- `encounter_service.dart` - Visit/encounter management
- `clinical_analytics_service.dart` - Clinical analytics
- `clinical_calculator_service.dart` - Medical calculators
- `clinical_letter_service.dart` - Medical letter generation
- `clinical_reminder_service.dart` - Screening reminders
- `comprehensive_risk_assessment_service.dart` - Risk assessment

**Patient Management**:
- `allergy_checking_service.dart` - Allergy validation
- `allergy_management_service.dart` - Allergy CRUD
- `family_history_service.dart` - Family history management
- `immunization_service.dart` - Vaccination tracking
- `problem_list_service.dart` - Problem list management
- `growth_chart_service.dart` - Pediatric growth charts

**Prescription & Medications**:
- `drug_interaction_service.dart` - Drug interaction checking
- `drug_reference_service.dart` - Drug reference data
- `prescription_templates.dart` - Prescription templates

**Appointments**:
- `recurring_appointment_service.dart` - Recurring patterns
- `waitlist_service.dart` - Waitlist management

**Billing & Financial**:
- `insurance_service.dart` - Insurance management

**Documentation**:
- `lab_order_service.dart` - Lab order management
- `referral_service.dart` - Referral management
- `consent_service.dart` - Consent form management

**Utilities**:
- `logger_service.dart` - Centralized logging
- `localization_service.dart` - Multi-language support
- `voice_dictation_service.dart` - Speech-to-text
- `ocr_service.dart` - Document text recognition
- `pdf_service.dart` - PDF generation
- `photo_service.dart` - Image handling

**Backup & Sync**:
- `backup_service.dart` - Local backup
- `cloud_backup_service.dart` - Cloud backup
- `google_drive_backup_service.dart` - Google Drive integration
- `offline_sync_service.dart` - Offline sync
- `encryption_service.dart` - Data encryption

**Security**:
- `app_lock_service.dart` - PIN/Biometric lock
- `audit_service.dart` - HIPAA audit logging

**Communication**:
- `communication_service.dart` - SMS/Email
- `whatsapp_service.dart` - WhatsApp integration
- `local_notification_service.dart` - Local notifications
- `google_calendar_service.dart` - Calendar integration

**Data Management**:
- `data_export_service.dart` - CSV/PDF export
- `data_migration_service.dart` - Data migration
- `seed_data_service.dart` - Demo data seeding

**AI & Suggestions**:
- `suggestions_service.dart` - Auto-suggestions
- `dynamic_suggestions_service.dart` - Dynamic suggestions
- `quick_phrases_service.dart` - Quick phrase templates

### 7. UI Components

**Core Components** (`lib/src/core/components/`):
- `app_button.dart` - Standardized button component
- `app_input.dart` - Standardized input field

**Core Widgets** (`lib/src/core/widgets/`):
- `app_card.dart` - Card component
- `app_header.dart` - Screen header
- `confirmation_dialog.dart` - Confirmation dialogs
- `date_time_picker.dart` - Date/time picker
- `error_display.dart` - Error state display
- `form_field_wrapper.dart` - Form field wrapper
- `loading_button.dart` - Button with loading state
- `search_field.dart` - Search input
- `stat_card.dart` - Statistics card

**UI Widgets** (`lib/src/ui/widgets/`):
- `voice_dictation_button.dart` - Voice input button
- `suggestion_text_field.dart` - Text field with suggestions
- `records/components/` - Medical record form components

### 8. Models

**Location**: `lib/src/models/`

**Model Files** (19 total):
- `patient.dart` - Patient model
- `appointment.dart` - Appointment model
- `prescription.dart` - Prescription model
- `medical_record.dart` - Medical record model
- `invoice.dart` - Invoice model
- `clinical_letter.dart` - Clinical letter model
- `referral.dart` - Referral model
- `immunization.dart` - Immunization model
- `family_history.dart` - Family history model
- `problem_list.dart` - Problem list model
- `lab_order.dart` - Lab order model
- `consent.dart` - Consent model
- `insurance.dart` - Insurance model
- `growth_chart.dart` - Growth chart model
- `clinical_reminder.dart` - Clinical reminder model
- `recurring_appointment.dart` - Recurring appointment model
- `waitlist.dart` - Waitlist model
- `pulmonary_evaluation.dart` - Pulmonary evaluation model
- `models.dart` - Model exports

---

## 🗄️ Database Schema

### Core Tables

**Patients Table**:
- Demographics: `firstName`, `lastName`, `age`, `gender`, `bloodType`
- Contact: `phone`, `email`, `address`
- Medical: `medicalHistory`, `allergies`, `chronicConditions`
- Emergency: `emergencyContactName`, `emergencyContactPhone`
- Physical: `height`, `weight` (BMI calculated)
- Metadata: `riskLevel`, `tags`, `createdAt`

**Appointments Table**:
- `patientId` (FK to Patients)
- `appointmentDateTime`
- `durationMinutes`
- `reason`
- `status` (scheduled, checked_in, in_progress, completed, cancelled, no_show)
- `reminderAt`
- `notes`
- `medicalRecordId` (FK to MedicalRecords)

**Prescriptions Table**:
- `patientId` (FK to Patients)
- `encounterId` (FK to Encounters) - V2
- `primaryDiagnosisId` (FK to Diagnoses) - V2
- `itemsJson` - JSON array of medications
- `instructions`
- `isRefillable`
- `appointmentId` (FK to Appointments)
- `medicalRecordId` (FK to MedicalRecords)

**MedicalRecords Table**:
- `patientId` (FK to Patients)
- `encounterId` (FK to Encounters) - V2
- `recordType` (general, psychiatric_assessment, lab_result, imaging, procedure, pulmonary, follow_up)
- `title`
- `description`
- `dataJson` - Flexible JSON storage for form data
- `diagnosis` (deprecated, use Diagnoses table)
- `treatment`
- `doctorNotes`
- `recordDate`
- `createdAt`

**Invoices Table**:
- `patientId` (FK to Patients)
- `invoiceNumber` (auto-generated)
- `invoiceDate`
- `dueDate`
- `itemsJson` - JSON array of line items
- `subtotal`, `discountPercent`, `discountAmount`
- `taxPercent`, `taxAmount`
- `grandTotal`
- `paymentMethod` (Cash, Card, UPI, Insurance)
- `paymentStatus` (Pending, Partial, Paid, Overdue)
- `notes`
- `appointmentId` (FK to Appointments)

### V2 Schema (Encounters)

**Encounters Table**:
- `patientId` (FK to Patients)
- `appointmentId` (FK to Appointments)
- `encounterDate`
- `chiefComplaint`
- `visitType` (new, follow_up, emergency)
- `status` (in_progress, completed, cancelled)

**Diagnoses Table**:
- `encounterId` (FK to Encounters)
- `icd10Code`
- `description`
- `isPrimary`
- `diagnosisDate`

**ClinicalNotes Table**:
- `encounterId` (FK to Encounters)
- `subjective`
- `objective`
- `assessment`
- `plan`

**VitalSigns Table**:
- `encounterId` (FK to Encounters)
- `patientId` (FK to Patients)
- `systolicBP`, `diastolicBP`
- `heartRate`
- `temperature`
- `respiratoryRate`
- `oxygenSaturation`
- `weight`, `height`
- `painLevel`
- `bloodGlucose`
- `recordedAt`

**TreatmentOutcomes Table**:
- `encounterId` (FK to Encounters)
- `patientId` (FK to Patients)
- `treatmentType`
- `outcome` (improved, stable, worsened)
- `notes`
- `followUpDate`

### V3 Schema (Extended Features)

**Referrals Table**:
- `patientId` (FK to Patients)
- `specialty`
- `urgency` (stat, urgent, routine)
- `status` (draft, pending, sent, accepted, scheduled, completed)
- `referralDate`
- `notes`

**Immunizations Table**:
- `patientId` (FK to Patients)
- `vaccineName`
- `doseNumber`
- `administrationDate`
- `manufacturer`
- `lotNumber`
- `nextDueDate`

**FamilyMedicalHistory Table**:
- `patientId` (FK to Patients)
- `familyMember` (father, mother, sibling, etc.)
- `condition`
- `ageOfOnset`
- `isDeceased`
- `causeOfDeath`

**PatientConsents Table**:
- `patientId` (FK to Patients)
- `consentType`
- `signedDate`
- `expirationDate`
- `signatureData` (JSON)
- `witnessSignatureData` (JSON)

**InsuranceInfo Table**:
- `patientId` (FK to Patients)
- `insuranceType` (primary, secondary)
- `insuranceCompany`
- `policyNumber`
- `groupNumber`
- `cardFrontImagePath`
- `cardBackImagePath`

**LabOrders Table**:
- `patientId` (FK to Patients)
- `encounterId` (FK to Encounters)
- `orderDate`
- `testsJson` (JSON array)
- `status` (pending, ordered, resulted, reviewed)
- `resultsJson` (JSON)

**ProblemList Table**:
- `patientId` (FK to Patients)
- `problem`
- `icd10Code`
- `status` (active, resolved, chronic)
- `priority`
- `onsetDate`
- `resolvedDate`

**ClinicalReminders Table**:
- `patientId` (FK to Patients)
- `reminderType` (screening, immunization, lab, follow_up, medication)
- `title`
- `description`
- `dueDate`
- `priority` (high, medium, low)
- `isCompleted`

**AppointmentWaitlist Table**:
- `patientId` (FK to Patients)
- `preferredDate`
- `preferredTime`
- `reason`
- `priority`
- `status` (pending, contacted, scheduled, cancelled)

**RecurringAppointments Table**:
- `patientId` (FK to Patients)
- `pattern` (daily, weekly, monthly)
- `startDate`
- `endDate`
- `durationMinutes`
- `reason`
- `isActive`

**ClinicalLetters Table**:
- `patientId` (FK to Patients)
- `letterType`
- `title`
- `content`
- `signatureData` (JSON)
- `deliveryMethod`
- `sentDate`

**CptCodes Table**:
- CPT/HCPCS code reference data
- Code, description, category
- Used for billing and procedure coding

### V4 Schema (Doctor Productivity Features)

**FavoritePrescriptions Table**:
- Saved prescription templates
- Frequently used medication combinations
- Quick access to common prescriptions

**QuickPhrases Table**:
- Saved text snippets for quick entry
- Common phrases, templates
- Reduces typing in notes

**RecentPatients Table**:
- Recently accessed patients
- Quick access list
- Usage tracking

**ClinicalCalculatorHistory Table**:
- History of clinical calculations
- BMI, GFR, risk scores, etc.
- Audit trail for calculations

### V5 Schema (Normalized Tables - Reduced JSON Storage)

**PrescriptionMedications Table**:
- Individual medications linked to prescriptions
- Medication name, generic name, brand name
- Drug codes (RxNorm, NDC)
- Strength, dosage form, route, frequency, duration
- Quantity, refills, status (active, completed, discontinued)

**InvoiceLineItems Table**:
- Individual line items for invoices
- Item type (service, medication, procedure, lab)
- Description, CPT/HCPCS codes
- Links to appointments, prescriptions, lab orders
- Unit price, quantity, discounts, taxes, total amount

**FamilyConditions Table**:
- Individual conditions for family medical history
- Condition name, ICD code
- Category (cardiovascular, cancer, etc.)
- Age at onset, severity, outcome

**TreatmentSymptoms Table**:
- Individual symptoms for treatment tracking
- Symptom name, severity, frequency
- Links to treatment sessions

**SideEffects Table**:
- Medication side effects tracking
- Side effect name, severity
- Links to medication responses

**Attachments Table**:
- File attachments for medical records
- Images, documents, PDFs
- File path, type, description

**MentalStatusExams Table**:
- Structured mental status examination data
- Appearance, behavior, speech, mood, affect
- Thought process, thought content, cognition
- Links to clinical notes

**LabTestResults Table**:
- Individual lab test results
- Test name, value, unit, reference range
- Status (normal, abnormal, critical)
- Links to lab orders

**ProgressNoteEntries Table**:
- Individual entries in progress notes
- Entry type, content, timestamp
- Links to clinical notes

**TreatmentInterventions Table**:
- Individual treatment interventions
- Intervention type, description
- Links to treatment sessions

**ClaimBillingCodes Table**:
- Billing codes for insurance claims
- CPT codes, modifiers, diagnoses
- Links to insurance claims

**PatientAllergies Table**:
- Normalized patient allergies
- Allergen name, type, severity
- Reaction description
- Replaces comma-separated allergies field

**PatientChronicConditions Table**:
- Normalized patient chronic conditions
- Condition name, ICD code
- Date diagnosed, status
- Replaces comma-separated chronicConditions field

**MedicalRecordFields Table**:
- Normalized medical record field data
- Field name, value, type
- Links to medical records
- Replaces dataJson for structured fields

### V7 Schema (User Suggestions)

**UserSuggestions Table**:
- User-added suggestions that learn from usage
- Suggestion text, category, context
- Usage count, last used date
- Personalized auto-complete suggestions

### Additional Tables

**TreatmentSessions Table**:
- Individual treatment sessions
- Session date, duration, type
- Progress notes, outcomes

**MedicationResponses Table**:
- Patient responses to medications
- Effectiveness, side effects
- Dosage adjustments

**TreatmentGoals Table**:
- Treatment goals and objectives
- Goal description, target date, status
- Progress tracking

**ScheduledFollowUps Table**:
- Scheduled follow-up appointments
- Follow-up type, date, notes
- Completion status

**GrowthMeasurements Table**:
- Pediatric growth measurements
- Height, weight, head circumference
- Growth percentiles, charts

**InsuranceClaims Table**:
- Insurance claim records
- Claim number, status, amount
- Submission and payment dates

**PreAuthorizations Table**:
- Prior authorization requests
- Service type, status, approval date
- Expiration date

**EncounterDiagnoses Table**:
- Junction table for encounter-diagnosis relationships
- Links encounters to multiple diagnoses
- Primary diagnosis flag

---

## 🔄 State Management

### Riverpod Providers

**Database Provider**:
```dart
final doctorDbProvider = FutureProvider<DoctorDb>((ref) async {
  // Initialize database
});
```

**Settings Providers**:
```dart
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  // App settings (theme, onboarding, etc.)
});

final doctorSettingsProvider = StateNotifierProvider<DoctorSettingsNotifier, DoctorSettingsState>((ref) {
  // Doctor profile and clinic info
});
```

**Service Providers**:
```dart
final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(ref.read(doctorDbProvider).value!);
});
```

### Usage in Widgets

**ConsumerWidget Pattern**:
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(doctorDbProvider).value;
    final settings = ref.watch(appSettingsProvider);
    
    if (db == null) return LoadingWidget();
    
    return Scaffold(/* ... */);
  }
}
```

**ConsumerStatefulWidget Pattern**:
```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(doctorDbProvider).value;
    // ...
  }
}
```

---

## 🧭 Navigation & Routing

### Route Definition

**Location**: `lib/src/core/routing/app_router.dart`

**Route Constants**:
```dart
abstract class AppRoutes {
  static const String home = '/';
  static const String patients = '/patients';
  static const String patientView = '/patients/view';
  static const String addPatient = '/patients/add';
  // ... 40+ more routes
}
```

### Type-Safe Route Arguments

```dart
class PatientViewArgs {
  const PatientViewArgs({required this.patient});
  final Patient patient;
}

class AddAppointmentArgs {
  const AddAppointmentArgs({this.patient, this.initialDate});
  final Patient? patient;
  final DateTime? initialDate;
}
```

### Navigation Helpers

**Extension Methods on BuildContext**:
```dart
// Navigate to patient view
context.goToPatientView(patient);

// Navigate to add appointment
context.goToAddAppointment(patient: patient, initialDate: DateTime.now());

// Navigate to add prescription
context.goToAddPrescription(patient: patient);

// Navigate to settings
context.goToSettings();
```

### Route Generation

```dart
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.patients:
        return _buildRoute(const PatientsScreen(), settings);
      case AppRoutes.patientView:
        final args = settings.arguments! as PatientViewArgs;
        return _buildRoute(PatientViewScreenModern(patient: args.patient), settings);
      // ... more routes
    }
  }
}
```

---

## 🛠️ Development Workflow

### Running the App

```bash
# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run on specific platform
flutter run -d chrome      # Web
flutter run -d windows     # Windows
flutter run -d android     # Android
flutter run -d ios         # iOS (macOS only)
```

### Code Generation

**Drift Database**:
```bash
# Watch mode (auto-regenerate on changes)
dart run build_runner watch --delete-conflicting-outputs

# One-time build
dart run build_runner build --delete-conflicting-outputs
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/audit_service_test.dart

# Run with coverage
flutter test --coverage
```

### Linting

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/
```

---

## 📝 Key Conventions

### File Naming
- Screens: `*_screen.dart`
- Services: `*_service.dart`
- Models: `*_model.dart` or just `*.dart`
- Widgets: `*_widget.dart` or descriptive names
- Providers: `*_provider.dart`

### Code Organization
- One class per file (with exceptions for related classes)
- Exports via barrel files (e.g., `models.dart`, `core.dart`)
- Services are stateless classes with methods
- Providers wrap services for dependency injection

### Error Handling
- Use `Result<T, E>` sealed class for expected errors
- Use exceptions only for unexpected errors
- Log all errors via `logger_service.dart`

### Logging
- Use `log` from `logger_service.dart`
- Log levels: `verbose`, `debug`, `info`, `warning`, `error`, `fatal`
- Format: `log.i('CATEGORY', 'Message', extra: {...})`

---

## 🔍 Quick Reference

### Finding Files

**Screens**: `lib/src/ui/screens/`
**Services**: `lib/src/services/`
**Models**: `lib/src/models/`
**Widgets**: `lib/src/core/widgets/` or `lib/src/ui/widgets/`
**Providers**: `lib/src/providers/`
**Database**: `lib/src/db/doctor_db.dart`
**Routing**: `lib/src/core/routing/app_router.dart`
**Constants**: `lib/src/core/constants/`

### Common Imports

```dart
// Core utilities
import 'package:doctor_app/src/core/core.dart';

// Models
import 'package:doctor_app/src/models/models.dart';

// Database
import 'package:doctor_app/src/db/doctor_db.dart';

// Routing
import 'package:doctor_app/src/core/routing/app_router.dart';

// Services
import 'package:doctor_app/src/services/logger_service.dart';
```

---

## 📊 Project Statistics

- **Screens**: 145 files (including screen components)
- **Services**: 52 files
- **Models**: 19 files
- **Core Widgets**: 29 files
- **UI Widgets**: 33 files
- **Total Widgets**: 62 files
- **Database Tables**: 50 tables
- **Routes**: 51 named routes
- **Tests**: 776+
- **Features**: 34+ complete features

---

*This document provides a comprehensive overview of the codebase structure. For specific feature documentation, see `FEATURES.md` in the root directory.*

