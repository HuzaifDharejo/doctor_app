# 🏥 Doctor Clinic Management App

A comprehensive **offline-first** Flutter application designed for psychiatry clinics. Manage patients, appointments, prescriptions, billing, and psychiatric assessments — all with a beautiful Material Design 3 interface and full dark mode support.

![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20Web%20|%20Windows-blue)

---

## ✨ Features

### Core Functionality
- **👥 Patient Management** — Add, view, and manage patient profiles with detailed medical history
- **📅 Appointments** — Schedule and track patient appointments with reminders and notifications
- **💊 Prescriptions** — Create and manage prescriptions with medication details, dosage, and instructions
- **💰 Billing & Invoicing** — Generate and track invoices with payment status and history

### Medical Records
- **🧠 Psychiatric Assessments** — Comprehensive psychiatric evaluation forms
- **📋 Mental State Examination (MSE)** — Full MSE documentation with all domains
- **⚠️ Risk Assessments** — Suicidal/homicidal risk evaluation and safety planning
- **📝 Clinical Notes** — Detailed progress notes and treatment documentation

### Smart Features
- **💡 Auto-Suggestions** — Intelligent text suggestions for all input fields based on common medical terms
- **👨‍⚕️ Doctor Profile** — Manage clinic information, credentials, and signature
- **🌙 Dark Mode** — Full theme support for light and dark modes
- **📴 Offline First** — Local SQLite database with Drift ORM - works without internet
- **💾 Data Backup** — Export and import database for backup/restore
- **🔒 Local Auth** — Biometric/PIN authentication for secure access

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
| **Riverpod 2.6+** | State management |
| **Material Design 3** | Modern UI components |
| **FL Chart** | Beautiful charts for analytics |
| **Local Auth** | Biometric authentication |
| **Flutter Local Notifications** | Appointment reminders |

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
    │   ├── core.dart            # Barrel export
    │   ├── data/
    │   │   └── repositories.dart # Repository base classes
    │   └── utils/
    │       ├── result.dart      # Result<T,E> type for error handling
    │       ├── app_exceptions.dart # Typed exception hierarchy
    │       ├── validators.dart  # Form validation utilities
    │       ├── debouncer.dart   # Rate-limiting utility
    │       └── date_formatters.dart # Date formatting helpers
    ├── db/
    │   └── doctor_db.dart       # Drift database schema & queries
    ├── models/                  # Data models
    │   ├── patient.dart
    │   ├── appointment.dart
    │   ├── prescription.dart
    │   └── ...
    ├── providers/
    │   └── db_provider.dart     # Riverpod providers for state management
    ├── services/
    │   ├── backup_service.dart  # Database backup/restore functionality
    │   ├── logger_service.dart  # Developer logging service
    │   ├── suggestions_service.dart # Auto-suggestion data
    │   ├── doctor_settings_service.dart # Doctor profile settings
    │   ├── pdf_service.dart     # PDF generation for prescriptions
    │   └── search_service.dart  # Global search functionality
    ├── theme/
    │   └── app_theme.dart       # Light & dark theme definitions
    └── ui/
        ├── screens/             # All app screens
        │   ├── dashboard_screen.dart
        │   ├── patients_screen.dart
        │   ├── patient_view_screen.dart
        │   ├── appointments_screen.dart
        │   ├── prescriptions_screen.dart
        │   ├── billing_screen.dart
        │   ├── psychiatric_assessment_screen.dart
        │   ├── medical_record_detail_screen.dart
        │   ├── medical_records_list_screen.dart
        │   └── settings_screen.dart
        └── widgets/             # Reusable UI components
            ├── patient_card.dart
            ├── suggestion_text_field.dart
            ├── debug_console.dart   # Developer debug panel
            ├── medical_record_widgets.dart
            └── ...
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

- **Dashboard** — Overview with quick stats, upcoming appointments, and recent activity
- **Patients** — Patient list with search, filtering, and quick actions
- **Patient Details** — Full patient profile with tabs for records, appointments, prescriptions, and billing
- **Appointments** — Calendar view with appointment management and reminders
- **Prescriptions** — Prescription list, creation, and printing
- **Billing** — Invoice management with payment tracking and receipts
- **Psychiatric Assessment** — Comprehensive forms for psychiatric evaluations
- **Settings** — Theme toggle, backup/restore, notifications, and app preferences
- **Doctor Profile** — Clinic and doctor information management

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

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Drift team for the excellent database ORM
- All contributors and users of this app
