# 🏥 Doctor Clinic Management App

A comprehensive **offline-first** Flutter application for single-doctor clinic management. A complete solution for patient care, appointments, prescriptions, billing, clinical assessments, and more — all with a beautiful Material Design 3 interface and full dark mode support.

![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20Web%20|%20Windows-blue)
![Features](https://img.shields.io/badge/Features-34+-brightgreen)
![Tests](https://img.shields.io/badge/Tests-776+-blue)

---

## ✨ Features

### 📋 Core Modules
- **👥 Patient Management** — Full demographics, emergency contacts, medical history, allergies, risk levels, and patient photos
- **📅 Appointments** — Schedule, track, check-in/out with recurring appointments and waitlist management
- **💊 Prescriptions** — Multi-medication prescriptions with drug interactions, allergy checking, and PDF generation
- **📁 Medical Records** — Multiple record types including consultations, lab results, imaging, and procedures
- **💰 Billing & Invoicing** — Line items, taxes, discounts, payment tracking, and professional PDF receipts

### 🏥 Clinical Features
- **🧠 Psychiatric Assessment** — Full MSE (11 domains), DSM-5 diagnoses, risk assessment, and safety planning
- **🫁 Pulmonary Evaluation** — Respiratory symptoms, red flags, vitals, and common diagnoses
- **📊 Vital Signs** — BP, pulse, temp, SpO2, BMI calculation, and abnormal value alerts
- **🔔 Clinical Reminders** — Screening reminders, immunization due dates, and medication reviews
- **📤 Referrals** — External specialist referrals with urgency levels and status tracking
- **📝 Clinical Letters** — Referral letters, disability forms, work excuses, and digital signatures
- **👨‍👩‍👧 Family History** — Hereditary conditions, genetic disorders, and cause of death tracking
- **💉 Immunizations** — Vaccination records, dose tracking, and adverse event documentation
- **📋 Problem List** — Active/chronic conditions with ICD-10 coding and priority ranking
- **🔬 Lab Orders** — Order management, results review, and abnormal flagging
- **📈 Growth Charts** — Pediatric height/weight tracking with WHO/CDC percentiles
- **✍️ Consent Management** — Digital signatures, witness signatures, and expiration tracking
- **🏥 Insurance** — Primary/secondary insurance, card photos, claims, and pre-authorization

### ⚙️ Administrative Features
- **📊 Dashboard** — Today's summary, quick stats, upcoming appointments, and recent activity
- **👨‍⚕️ Doctor Profile** — Credentials, clinic info, working hours, fees, and digital signature
- **⚙️ Settings** — Theme toggle, language, notifications, and app lock configuration
- **💾 Backup & Restore** — Local and Google Drive backup with encryption
- **📤 Data Export** — CSV/PDF export for patients, appointments, invoices, and reports
- **📱 Communications** — SMS, WhatsApp, email integration, and bulk messaging

### 🧠 Smart Features
- **🎤 Voice Dictation** — Speech-to-text for all text fields with continuous mode support
- **💡 Auto-Suggestions** — Intelligent suggestions for diagnoses, medications, symptoms, and procedures
- **⚠️ Drug Interactions** — Automatic drug-drug interaction and allergy cross-reference warnings
- **📷 OCR Scanning** — Extract text from lab reports and documents with auto-fill
- **🔍 Global Search** — Instant search across patients, appointments, and records
- **📈 Treatment Analytics** — Outcome tracking, medication response, and visual charts

### 🔐 Security & Compliance
- **🔒 App Lock** — PIN and biometric (fingerprint/Face ID) authentication
- **📜 Audit Logging** — HIPAA-compliant access logging with before/after tracking
- **🔐 Encryption** — AES encryption for backups and cloud storage
- **🔔 Local Notifications** — Appointment reminders, follow-ups, and medication alerts

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.38+ (stable channel)
- Dart SDK 3.10+
- Android Studio / VS Code with Flutter extensions
- For Android: Android SDK with API 21+

### Installation

```bash
# Clone the repository
git clone https://github.com/HuzaifDharejo/doctor_app.git

# Navigate to project directory
cd doctor_app

# Install dependencies
flutter pub get

# Generate database files
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Run on Specific Platforms

```bash
# Web (Chrome)
flutter run -d chrome

# Windows Desktop
flutter run -d windows

# Android (with device/emulator connected)
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Build Release APK
flutter build apk --release
```

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter 3.38+** | Cross-platform UI framework |
| **Dart 3.10+** | Programming language |
| **Drift 2.23+** | SQLite database ORM with type-safe queries |
| **Riverpod 2.6+** | State management & dependency injection |
| **Material Design 3** | Modern UI components with dark mode |
| **FL Chart** | Beautiful charts for analytics |
| **Local Auth** | Biometric/PIN authentication |
| **Flutter Local Notifications** | Appointment & medication reminders |
| **Google ML Kit** | OCR text recognition |
| **Speech to Text** | Voice dictation for notes |
| **Google Drive API** | Cloud backup storage |
| **PDF / Printing** | Document generation & printing |

---

## 🏗️ Architecture & Best Practices

This project follows modern Flutter best practices and clean architecture principles:

### Code Quality
- **Strict Type Safety** — Enabled `strict-casts`, `strict-inference`, and `strict-raw-types` for maximum type safety
- **Comprehensive Linting** — 40+ lint rules configured in `analysis_options.yaml`
- **Zero Analyzer Errors** — All code passes strict static analysis

### Design Patterns
- **Result Type** — Functional error handling with `Result<T, E>` sealed classes (no exceptions for expected errors)
- **Repository Pattern** — Clean data layer abstraction between UI and database
- **Provider Pattern** — Riverpod for dependency injection and state management

### Utilities
- **Validators** — Centralized form validation with composable validators
- **Debouncer** — Rate-limiting for search and input operations
- **Date Formatters** — Consistent date/time formatting across the app
- **App Exceptions** — Typed exception hierarchy for better error categorization
- **Logger Service** — Developer-focused logging for debugging and error tracking

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
└── src/
    ├── app.dart                 # App configuration with theme & routing
    ├── core/                    # Core utilities and patterns
    │   ├── components/          # Reusable UI components
    │   ├── extensions/          # Dart extensions
    │   ├── mixins/              # Widget mixins
    │   ├── routing/             # Navigation & routes
    │   ├── theme/               # Design tokens
    │   ├── utils/               # Utilities (Result, validators, etc.)
    │   └── widgets/             # Core widgets
    ├── data/                    # Demo data & seeds
    ├── db/
    │   ├── doctor_db.dart       # Drift database schema (35+ tables)
    │   └── schema_v2/           # Database migrations
    ├── extensions/              # Model extensions
    ├── models/                  # Data models (19+ files)
    ├── providers/
    │   └── db_provider.dart     # Riverpod providers
    ├── services/                # Business logic (50+ services)
    │   ├── voice_dictation_service.dart
    │   ├── referral_service.dart
    │   ├── waitlist_service.dart
    │   ├── clinical_letter_service.dart
    │   ├── clinical_reminder_service.dart
    │   ├── backup_service.dart
    │   ├── pdf_service.dart
    │   └── ...
    ├── theme/
    │   └── app_theme.dart       # Light & dark theme definitions
    └── ui/
        ├── screens/             # All app screens (55+ screens)
        │   ├── dashboard_screen.dart
        │   ├── patients_screen.dart
        │   ├── patient_view/    # Patient detail tabs
        │   ├── appointments_screen.dart
        │   ├── waitlist_screen.dart
        │   ├── recurring_appointments_screen.dart
        │   ├── prescriptions_screen.dart
        │   ├── billing_screen.dart
        │   ├── psychiatric_assessment_screen_modern.dart
        │   ├── pulmonary_evaluation_screen_modern.dart
        │   ├── clinical_letters_screen.dart
        │   ├── clinical_reminders_screen.dart
        │   ├── referrals_screen.dart
        │   └── ...
        └── widgets/             # Reusable UI components (30+ widgets)
            ├── voice_dictation_button.dart
            ├── suggestion_text_field.dart
            └── ...

test/
├── unit/                        # Unit tests
├── widget/                      # Widget tests
├── integration/                 # Integration tests
└── helpers/                     # Test utilities
```

---

## 📱 Screenshots

| Dashboard | Patients | Prescriptions |
|:---------:|:--------:|:-------------:|
| *Overview with stats* | *Patient list & search* | *Prescription management* |

| Psychiatric Assessment | Billing | Settings |
|:----------------------:|:-------:|:--------:|
| *Full MSE documentation* | *Invoice tracking* | *Theme & backup* |

---

## 🔑 Key Screens

### Clinical Screens
- **Dashboard** — Overview with quick stats, upcoming appointments, and recent activity
- **Patients** — Patient list with search, filtering, risk badges, and quick actions
- **Patient Details** — 6-tab interface (Overview, Records, Appointments, Prescriptions, Billing, Documents)
- **Appointments** — Calendar view with check-in/out, recurring appointments, and waitlist
- **Prescriptions** — Multi-medication prescriptions with drug interaction warnings
- **Billing** — Invoice management with payment tracking and PDF receipts

### Clinical Assessment Screens
- **Psychiatric Assessment** — Full MSE documentation, DSM-5 diagnoses, risk assessment
- **Pulmonary Evaluation** — Respiratory symptoms, red flags, and common diagnoses
- **Vital Signs** — Comprehensive vitals with trending and alerts
- **Lab Orders** — Order management and results review with abnormal flagging

### Administrative Screens
- **Doctor Profile** — Clinic and doctor information with digital signature
- **Settings** — Theme, backup, notifications, and security settings
- **Audit Logs** — HIPAA-compliant access and change logging
- **Data Export** — CSV/PDF export for compliance and reporting

### Additional Features
- **Waitlist** — Fill cancelled appointment slots with priority queue
- **Recurring Appointments** — Daily, weekly, monthly patterns for chronic care
- **Clinical Letters** — Medical letters, forms, and certificates with templates
- **Clinical Reminders** — Screening and preventive care reminders
- **Referrals** — External specialist referral management

---

## 📊 Database Schema

The app uses **Drift ORM** with **35+ tables** for comprehensive data management:

### Core Tables
- `Patients` — Demographics, contacts, medical history
- `Appointments` — Scheduling with status tracking
- `Prescriptions` — Medications with dosage details
- `MedicalRecords` — Clinical documentation (JSON storage)
- `Invoices` — Billing and payments

### Clinical Tables
- `Encounters` — Visit tracking
- `Diagnoses` — ICD-10 coded diagnoses
- `ClinicalNotes` — SOAP notes
- `VitalSigns` — Vital measurements with thresholds
- `TreatmentOutcomes` — Outcome tracking

### Extended Features
- `Referrals` — External specialist referrals
- `Immunizations` — Vaccine records
- `FamilyMedicalHistory` — Hereditary conditions
- `PatientConsents` — Consent forms with signatures
- `InsuranceInfo` — Insurance and claims
- `LabOrders` — Lab order management
- `ProblemList` — Active/chronic problems
- `ClinicalReminders` — Screening reminders
- `AppointmentWaitlist` — Waitlist queue
- `RecurringAppointments` — Recurring patterns
- `ClinicalLetters` — Medical letters
- `AuditLogs` — HIPAA compliance logging

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author & Developer

### 👨‍⚕️ Project Owner
**Dr. Raees Ahmed Dharejo**

### 💻 Developer
**Huzaif Imtiaz Dharejo**

[![GitHub](https://img.shields.io/badge/GitHub-HuzaifDharejo-181717?logo=github)](https://github.com/HuzaifDharejo)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Huzaif%20Imtiaz-0A66C2?logo=linkedin)](https://www.linkedin.com/in/huzaif-imtiaz/)
[![Email](https://img.shields.io/badge/Email-Huzaifdharejo%40gmail.com-EA4335?logo=gmail)](mailto:Huzaifdharejo@gmail.com)

---

## 📈 Stats

| Metric | Count |
|--------|-------|
| **Screens** | 55+ |
| **Services** | 50+ |
| **Database Tables** | 35+ |
| **Models** | 19+ |
| **Widgets** | 30+ |
| **Unit Tests** | 776+ |
| **Features** | 34 |

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Drift team for the excellent database ORM
- All contributors and users of this app
