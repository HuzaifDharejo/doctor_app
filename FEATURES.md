# 🏥 Doctor App - Complete Feature Documentation

**Version:** 1.0.0  
**Platform:** Android | iOS | Web | Windows  
**Architecture:** Single-Doctor Clinic Management System  
**Database:** Offline-first with Drift ORM (SQLite)  
**Last Updated:** December 10, 2025

---

## 📋 Table of Contents

1. [App Overview](#app-overview)
2. [Core Modules](#core-modules)
3. [Clinical Features](#clinical-features)
4. [Administrative Features](#administrative-features)
5. [Smart Features](#smart-features)
6. [Security & Compliance](#security--compliance)
7. [Technical Architecture](#technical-architecture)
8. [Database Schema](#database-schema)
9. [File Structure](#file-structure)

---

## 🎯 App Overview

This is a **comprehensive offline-first clinic management application** designed for a **single doctor** managing their own practice. It handles the complete clinical workflow from patient registration to billing.

### Design Philosophy
- **Single-Doctor Centric**: All features revolve around one doctor's practice
- **Offline-First**: Works without internet, syncs when connected
- **Privacy-Focused**: Data stored locally on device
- **HIPAA-Compliant**: Audit logging and security features

---

## 📱 Core Modules

### 1. Patient Management ✅
**Screen:** `patients_screen.dart`, `patient_view/`  
**Service:** Database CRUD operations

| Feature | Status | Description |
|---------|--------|-------------|
| Patient Registration | ✅ | Full demographics, contact info |
| Patient List | ✅ | Search, filter, pagination |
| Patient Profile | ✅ | 6-tab modern interface |
| Patient Photos | ✅ | Avatar with camera/gallery |
| Emergency Contacts | ✅ | Contact info and relationship |
| Medical History | ✅ | Conditions, allergies, notes |
| Risk Level Tracking | ✅ | 1-5 risk scoring with badges |
| Patient Tags | ✅ | Custom categorization |

**Patient Data Fields:**
- Demographics: Name, Age, Gender, Blood Type
- Contact: Phone, Email, Address
- Medical: History, Allergies, Chronic Conditions
- Emergency: Contact Name, Phone, Relationship
- Physical: Height, Weight (with BMI calculation)

---

### 2. Appointments ✅
**Screen:** `appointments_screen.dart`, `add_appointment_screen.dart`  
**Service:** `recurring_appointment_service.dart`, `waitlist_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Schedule Appointments | ✅ | Date, time, duration, reason |
| Appointment List | ✅ | Today view, calendar view |
| Status Tracking | ✅ | Scheduled, Checked-in, In-Progress, Completed |
| Reminders | ✅ | Local notifications |
| Recurring Appointments | ✅ | Daily, weekly, monthly patterns |
| Waitlist | ✅ | Fill cancelled slots, priority queue |
| Follow-up Scheduling | ✅ | Auto-generate from visits |
| Check-in/Check-out | ✅ | Time tracking |

**Appointment Statuses:**
- `scheduled` → `checked_in` → `in_progress` → `completed`
- Also: `cancelled`, `no_show`, `rescheduled`

---

### 3. Prescriptions ✅
**Screen:** `prescriptions_screen.dart`, `add_prescription_screen.dart`  
**Service:** `pdf_service.dart`, `prescription_templates.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Create Prescriptions | ✅ | Multiple medications |
| Medication Details | ✅ | Name, dosage, frequency, duration |
| Instructions | ✅ | Custom instructions |
| Print/Share PDF | ✅ | Professional format |
| Templates | ✅ | Save common prescriptions |
| Refill Tracking | ✅ | Mark as refillable |
| Drug Interactions | ✅ | Safety warnings |
| Allergy Checking | ✅ | Cross-reference patient allergies |

**Prescription Fields per Item:**
- Medication Name
- Dosage (e.g., "500mg")
- Frequency (e.g., "TID", "Once daily")
- Duration (e.g., "7 days")
- Route (e.g., "Oral", "Topical")
- Quantity
- Instructions

---

### 4. Medical Records ✅
**Screen:** `medical_records_list_screen.dart`, `add_medical_record_screen.dart`  
**Service:** Database with JSON storage

| Feature | Status | Description |
|---------|--------|-------------|
| General Consultation | ✅ | Chief complaint, diagnosis, treatment |
| Psychiatric Assessment | ✅ | Full MSE, risk assessment |
| Lab Results | ✅ | Test results with ranges |
| Imaging Records | ✅ | X-ray, CT, MRI findings |
| Procedures | ✅ | Procedure notes |
| Pulmonary Evaluation | ✅ | Respiratory assessment |
| Record Templates | ✅ | Quick-fill for common types |
| Document Extraction | ✅ | OCR from images |

**Record Types:**
- `general` - General consultation
- `psychiatric_assessment` - Full psychiatric evaluation
- `lab_result` - Laboratory test results
- `imaging` - Radiology/imaging reports
- `procedure` - Procedure documentation
- `pulmonary` - Respiratory evaluation
- `follow_up` - Follow-up notes

---

### 5. Billing & Invoices ✅
**Screen:** `billing_screen.dart`, `add_invoice_screen.dart`  
**Service:** `pdf_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Create Invoices | ✅ | Line items, taxes, discounts |
| Invoice List | ✅ | Filter by status, date |
| Payment Tracking | ✅ | Pending, Partial, Paid |
| Print/Share PDF | ✅ | Professional receipts |
| Payment Methods | ✅ | Cash, Card, UPI, Insurance |
| Monthly Reports | ✅ | Revenue summaries |
| Link to Appointments | ✅ | Auto-generate from visits |

**Invoice Fields:**
- Invoice Number (auto-generated)
- Patient Info
- Line Items (service, quantity, rate)
- Subtotal, Tax, Discount
- Grand Total
- Payment Status
- Notes

---

## 🏥 Clinical Features

### 6. Psychiatric Assessment ✅
**Screen:** `psychiatric_assessment_screen_modern.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Quick Templates | ✅ | Depression, Anxiety, OCD |
| DSM-5 Diagnosis | ✅ | Autocomplete with 16+ diagnoses |
| Symptom Checklist | ✅ | 12 quick symptom toggles |
| Mental Status Exam | ✅ | All 11 domains |
| Risk Assessment | ✅ | Suicidal/Homicidal risk |
| Safety Planning | ✅ | Crisis contacts, coping |
| Red Flag Detection | ✅ | Auto-highlight warnings |

**MSE Domains:**
1. Appearance
2. Behavior
3. Speech
4. Mood
5. Affect
6. Thought Content
7. Thought Process
8. Perception
9. Cognition
10. Insight
11. Judgment

---

### 7. Pulmonary Evaluation ✅
**Screen:** `pulmonary_evaluation_screen_modern.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Symptom Checklist | ✅ | 11 respiratory symptoms |
| Red Flags | ✅ | 6 critical indicators |
| Vital Signs | ✅ | BP, HR, RR, Temp, SpO2 |
| Physical Exam | ✅ | Chest examination |
| Investigations | ✅ | 8 quick-select options |
| Common Diagnoses | ✅ | 11 pulmonary conditions |
| Assessment & Plan | ✅ | Structured documentation |

---

### 8. Vital Signs ✅
**Screen:** `vital_signs_screen.dart`  
**Service:** `vital_thresholds_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Record Vitals | ✅ | BP, Pulse, Temp, Weight, SpO2 |
| BMI Calculation | ✅ | Automatic from H/W |
| Trending | ✅ | Historical charts |
| Alerts | ✅ | Abnormal value warnings |
| Pain Scale | ✅ | 0-10 rating |
| Blood Glucose | ✅ | Diabetes monitoring |

**Vital Parameters:**
- Blood Pressure (Systolic/Diastolic)
- Heart Rate (bpm)
- Temperature (°C/°F)
- Respiratory Rate
- Oxygen Saturation (SpO2%)
- Weight (kg/lbs)
- Height (cm/ft)
- BMI (calculated)
- Pain Level (0-10)
- Blood Glucose

---

### 9. Clinical Reminders ✅
**Screen:** `clinical_reminders_screen.dart`  
**Service:** `clinical_reminder_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Screening Reminders | ✅ | Mammogram, colonoscopy, etc. |
| Immunization Due | ✅ | Vaccine schedules |
| Lab Follow-ups | ✅ | Pending test reminders |
| Medication Reviews | ✅ | Refill due dates |
| Age/Gender Based | ✅ | Appropriate screenings |
| Priority Levels | ✅ | High, Medium, Low |

**Reminder Types:**
- `screening` - Preventive care screenings
- `immunization` - Vaccine due dates
- `lab` - Lab test reminders
- `follow_up` - Appointment follow-ups
- `medication` - Medication reviews
- `wellness` - General wellness checks

---

### 10. Referrals (External Specialists) ✅
**Screen:** `referrals_screen.dart`  
**Service:** `referral_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Create Referral | ✅ | To external specialists |
| Specialty Selection | ✅ | All medical specialties |
| Urgency Levels | ✅ | Stat, Urgent, Routine |
| Status Tracking | ✅ | Pending → Sent → Completed |
| Pre-Auth Tracking | ✅ | Insurance requirements |
| Consultation Notes | ✅ | Feedback from specialist |

**Referral Workflow:**
`draft` → `pending` → `sent` → `accepted` → `scheduled` → `completed`

---

### 11. Clinical Letters & Templates ✅
**Screen:** `clinical_letters_screen.dart`  
**Service:** `clinical_letter_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Letter Templates | ✅ | Multiple types |
| Custom Letters | ✅ | Free-form composition |
| Digital Signature | ✅ | Sign on screen |
| Print/Share PDF | ✅ | Professional format |
| Delivery Tracking | ✅ | Fax, email, mail |

**Letter Types:**
- Referral Letter
- Disability Form
- FMLA Documentation
- Work Excuse
- School Excuse
- Medical Clearance
- Insurance Letter
- Prior Authorization
- Specialist Summary
- Custom Letter

---

### 12. Family History ✅
**Screen:** `family_history_screen.dart`  
**Service:** `family_history_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Family Members | ✅ | Parents, siblings, grandparents |
| Conditions Tracking | ✅ | Heart disease, diabetes, cancer |
| Cause of Death | ✅ | If deceased |
| Genetic Disorders | ✅ | Hereditary conditions |
| Mental Health History | ✅ | Psychiatric family history |

---

### 13. Immunizations ✅
**Screen:** `immunizations_screen.dart`  
**Service:** `immunization_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Vaccination Records | ✅ | All vaccines given |
| Dose Tracking | ✅ | Series progress |
| Due Date Reminders | ✅ | Next dose scheduling |
| Reaction Tracking | ✅ | Adverse events |
| Manufacturer/Lot | ✅ | Full documentation |

---

### 14. Problem List ✅
**Screen:** `problem_list_screen.dart`  
**Service:** `problem_list_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Active Problems | ✅ | Current conditions |
| Chronic Conditions | ✅ | Ongoing management |
| Problem Status | ✅ | Active, Resolved, Chronic |
| ICD-10 Coding | ✅ | Diagnosis codes |
| Priority Ranking | ✅ | Clinical importance |

---

### 15. Lab Orders ✅
**Screen:** `lab_orders_screen.dart`  
**Service:** `lab_order_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Create Lab Orders | ✅ | Test selection |
| Order Status | ✅ | Pending → Resulted |
| Results Review | ✅ | Mark as reviewed |
| Abnormal Flagging | ✅ | Highlight out-of-range |
| Critical Values | ✅ | Alert on critical results |

---

### 16. Growth Charts (Pediatric) ✅
**Screen:** `growth_chart_screen.dart`  
**Service:** `growth_chart_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Height/Weight Tracking | ✅ | Over time |
| Percentile Calculation | ✅ | WHO/CDC standards |
| Growth Curves | ✅ | Visual charts |
| BMI for Age | ✅ | Pediatric BMI |
| Head Circumference | ✅ | Infant tracking |

---

### 17. Consent Management ✅
**Screen:** `consent_screen.dart`  
**Service:** `consent_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Consent Forms | ✅ | Multiple types |
| Digital Signature | ✅ | Patient/guardian sign |
| Witness Signature | ✅ | When required |
| Expiration Tracking | ✅ | Auto-expire consents |
| Revocation | ✅ | Patient can revoke |

**Consent Types:**
- Treatment Consent
- Procedure Consent
- HIPAA Authorization
- Research Consent
- Medication Consent
- Telehealth Consent
- Photo/Video Release
- Information Release
- Financial Agreement
- Advance Directive

---

### 18. Insurance Management ✅
**Screen:** `insurance_screen.dart`  
**Service:** `insurance_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Insurance Info | ✅ | Primary, Secondary |
| Card Images | ✅ | Front/back photos |
| Eligibility | ✅ | Coverage verification |
| Claims Tracking | ✅ | Submission status |
| Pre-Authorization | ✅ | Auth management |

---

## ⚙️ Administrative Features

### 19. Dashboard ✅
**Screen:** `dashboard_screen.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Today's Summary | ✅ | Appointments, patients |
| Quick Stats | ✅ | Patients, revenue, pending |
| Upcoming Appointments | ✅ | Next appointments list |
| Quick Actions | ✅ | Add patient, appointment |
| Recent Activity | ✅ | Activity feed |
| Wait Time Stats | ✅ | Average wait times |

---

### 20. Doctor Profile ✅
**Screen:** `doctor_profile_screen.dart`  
**Service:** `doctor_settings_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Personal Info | ✅ | Name, credentials |
| Clinic Info | ✅ | Name, address, phone |
| Working Hours | ✅ | Schedule by day |
| Consultation Fees | ✅ | New, follow-up, emergency |
| Digital Signature | ✅ | For prescriptions |
| Logo Upload | ✅ | Clinic branding |

---

### 21. Settings ✅
**Screen:** `settings_screen.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Theme Toggle | ✅ | Light/Dark mode |
| Language | ✅ | Localization support |
| Backup/Restore | ✅ | Database backup |
| Export Data | ✅ | CSV, PDF exports |
| App Lock | ✅ | PIN/Biometric |
| Notifications | ✅ | Reminder settings |

---

### 22. Backup & Restore ✅
**Screen:** `backup_settings_screen.dart`  
**Service:** `backup_service.dart`, `google_drive_backup_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Local Backup | ✅ | Export to file |
| Google Drive | ✅ | Cloud backup |
| Auto-Backup | ✅ | Scheduled backups |
| Encryption | ✅ | Encrypted backups |
| Restore | ✅ | Import from backup |
| Backup History | ✅ | List of backups |

---

### 23. Data Export ✅
**Screen:** `data_export_screen.dart`  
**Service:** `data_export_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Patient Export | ✅ | CSV format |
| Appointment Export | ✅ | Date range filter |
| Invoice Export | ✅ | Financial reports |
| Medical Records | ✅ | Per patient |
| Monthly Reports | ✅ | PDF summaries |

---

### 24. Communications ✅
**Screen:** `communications_screen.dart`  
**Service:** `communication_service.dart`, `whatsapp_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| SMS Integration | ✅ | Send messages |
| WhatsApp | ✅ | Quick messaging |
| Email | ✅ | Email patients |
| Call | ✅ | Direct dial |
| Bulk Messaging | ✅ | Multiple patients |

---

## 🧠 Smart Features

### 25. Voice Dictation ✅ (NEW)
**Widget:** `voice_dictation_button.dart`  
**Service:** `voice_dictation_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Speech-to-Text | ✅ | Real-time transcription |
| Continuous Mode | ✅ | Up to 5 minutes |
| Multi-Language | ✅ | Locale detection |
| Text Fields | ✅ | Integrated in all inputs |
| Visual Feedback | ✅ | Pulsing animation |

---

### 26. Auto-Suggestions ✅
**Service:** `suggestions_service.dart`  
**Widget:** `suggestion_text_field.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Diagnosis Suggestions | ✅ | Common diagnoses |
| Medication Suggestions | ✅ | Drug names |
| Symptom Suggestions | ✅ | Common symptoms |
| Procedure Suggestions | ✅ | Common procedures |
| Smart Append | ✅ | Add to existing text |

---

### 27. Drug Interactions & Allergies ✅
**Service:** `drug_interaction_service.dart`, `allergy_checking_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Interaction Checking | ✅ | Drug-drug interactions |
| Allergy Warnings | ✅ | Cross-reference |
| Severity Levels | ✅ | Minor to Severe |
| Override Option | ✅ | With documentation |

---

### 28. OCR Document Scanning ✅
**Service:** `ocr_service.dart`  
**Widget:** `document_data_extractor.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Text Recognition | ✅ | Google ML Kit |
| Lab Report Extraction | ✅ | Parse values |
| Auto-Fill Forms | ✅ | Populate fields |

---

### 29. Global Search ✅
**Screen:** `global_search_screen.dart`  
**Service:** `search_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Patient Search | ✅ | Name, phone, ID |
| Appointment Search | ✅ | Date, reason |
| Record Search | ✅ | Diagnosis, notes |
| Quick Results | ✅ | Instant filtering |

---

### 30. Treatment Analytics ✅
**Screen:** `clinical_analytics_screen.dart`, `treatment_dashboard.dart`  
**Service:** `clinical_analytics_service.dart`, `treatment_efficacy_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Treatment Outcomes | ✅ | Effectiveness tracking |
| Medication Response | ✅ | Drug efficacy |
| Patient Statistics | ✅ | Demographics |
| Revenue Analytics | ✅ | Financial trends |
| Charts & Graphs | ✅ | Visual analytics |

---

## 🔐 Security & Compliance

### 31. App Lock ✅
**Screen:** `lock_screen.dart`  
**Service:** `app_lock_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| PIN Lock | ✅ | 4-6 digit PIN |
| Biometric | ✅ | Fingerprint, Face ID |
| Auto-Lock | ✅ | On app resume |
| Failed Attempts | ✅ | Lockout protection |

---

### 32. Audit Logging (HIPAA) ✅
**Screen:** `audit_log_viewer_screen.dart`  
**Service:** `audit_logging_service.dart`, `audit_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Access Logging | ✅ | Who viewed what |
| Change Tracking | ✅ | Before/after values |
| Export Logs | ✅ | Compliance reports |
| Search/Filter | ✅ | By user, date, action |

**Logged Actions:**
- Patient view/edit/delete
- Record access/modification
- Prescription creation
- Login/logout events
- Data exports
- Settings changes

---

### 33. Encryption ✅
**Service:** `encryption_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Backup Encryption | ✅ | AES encryption |
| Cloud Encryption | ✅ | Before upload |
| Key Management | ✅ | Secure storage |

---

### 34. Local Notifications ✅
**Service:** `local_notification_service.dart`

| Feature | Status | Description |
|---------|--------|-------------|
| Appointment Reminders | ✅ | Before appointments |
| Follow-up Reminders | ✅ | Scheduled alerts |
| Medication Reminders | ✅ | Refill alerts |
| Custom Scheduling | ✅ | Configurable times |

---

## 🏗️ Technical Architecture

### Technology Stack
| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.38+ |
| Language | Dart 3.10+ |
| Database | Drift ORM (SQLite) |
| State Management | Riverpod 2.6+ |
| UI Framework | Material Design 3 |
| Charts | FL Chart |
| PDF Generation | pdf, printing |
| Authentication | local_auth |
| Notifications | flutter_local_notifications |
| OCR | google_mlkit_text_recognition |
| Cloud | Google Drive API |
| Speech | speech_to_text |

### Architecture Patterns
- **Clean Architecture**: Separation of UI, business logic, and data
- **Repository Pattern**: Abstract data sources
- **Provider Pattern**: Dependency injection with Riverpod
- **Result Type**: Functional error handling

### Code Quality
- 776+ unit and widget tests
- Strict type safety enabled
- 40+ lint rules configured
- Zero analyzer errors

---

## 📊 Database Schema

### Core Tables
| Table | Purpose |
|-------|---------|
| `Patients` | Patient demographics |
| `Appointments` | Scheduling |
| `Prescriptions` | Medications |
| `MedicalRecords` | Clinical records |
| `Invoices` | Billing |

### Clinical Tables (V2)
| Table | Purpose |
|-------|---------|
| `Encounters` | Visit tracking |
| `Diagnoses` | Diagnosis codes |
| `ClinicalNotes` | SOAP notes |
| `VitalSigns` | Vital measurements |
| `TreatmentOutcomes` | Outcome tracking |

### Extended Tables (V3)
| Table | Purpose |
|-------|---------|
| `Referrals` | External referrals |
| `Immunizations` | Vaccine records |
| `FamilyMedicalHistory` | Family history |
| `PatientConsents` | Consent forms |
| `InsuranceInfo` | Insurance data |
| `LabOrders` | Lab order tracking |
| `ProblemList` | Active problems |
| `ClinicalReminders` | Screening reminders |
| `AppointmentWaitlist` | Waitlist management |
| `RecurringAppointments` | Recurring patterns |
| `ClinicalLetters` | Medical letters |

---

## 📁 File Structure

```
lib/
├── main.dart                    # App entry point
└── src/
    ├── app.dart                 # App configuration
    ├── core/                    # Core utilities
    │   ├── components/          # Reusable widgets
    │   ├── extensions/          # Dart extensions
    │   ├── mixins/              # Widget mixins
    │   ├── routing/             # Navigation
    │   ├── theme/               # Design tokens
    │   ├── utils/               # Utilities
    │   └── widgets/             # Core widgets
    ├── data/                    # Demo data
    ├── db/                      # Database
    │   ├── doctor_db.dart       # Schema
    │   └── schema_v2/           # Migrations
    ├── extensions/              # Model extensions
    ├── models/                  # Data models (19 files)
    ├── providers/               # Riverpod providers
    ├── services/                # Business logic (50 files)
    ├── theme/                   # App theme
    └── ui/
        ├── screens/             # App screens (60+ screens)
        └── widgets/             # UI widgets (30+ widgets)

test/
├── unit/                        # Unit tests
├── widget/                      # Widget tests
├── integration/                 # Integration tests
└── helpers/                     # Test utilities
```

---

## 📈 Feature Completion Summary

| Category | Total | Implemented | Percentage |
|----------|-------|-------------|------------|
| Core Modules | 5 | 5 | 100% |
| Clinical Features | 13 | 13 | 100% |
| Administrative | 6 | 6 | 100% |
| Smart Features | 6 | 6 | 100% |
| Security | 4 | 4 | 100% |
| **Total** | **34** | **34** | **100%** |

---

## 🚀 What's Next

The app is feature-complete for a single-doctor clinic. Potential future enhancements:

1. **Cloud Sync** - Real-time sync across devices
2. **Telemedicine** - Video consultations
3. **Patient Portal** - Patient-facing app
4. **AI Assistance** - Diagnostic suggestions
5. **Multi-Clinic** - Multiple location support

---

*This document was auto-generated based on the codebase analysis.*
