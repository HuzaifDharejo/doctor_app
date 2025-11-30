# 🚀 Database Quick Reference Guide

**Status:** ✅ Production Ready  
**Last Verified:** 2025-11-30

---

## 📦 What You Have

### Database Tables (8)
```
✅ Patients           - Patient demographics & medical history
✅ Appointments       - Schedule & appointment tracking  
✅ Prescriptions      - Medication management
✅ MedicalRecords     - Clinical documentation
✅ Invoices           - Billing system
✅ VitalSigns         - Health metrics (BP, HR, Weight, etc)
✅ TreatmentOutcomes  - Treatment effectiveness tracking
✅ ScheduledFollowUps - Automated follow-up reminders
```

### Safety Features (5)
```
✅ Allergy Checking       - Prevents drug allergies
✅ Drug Interactions      - Warns about incompatible medications
✅ Vital Signs Tracking   - Monitors 8 vital parameters
✅ Treatment Outcomes     - Measures therapy effectiveness  
✅ Follow-up Automation   - Creates reminders automatically
```

### Connected Services (14+)
```
✅ AllergyCheckingService
✅ DrugInteractionService
✅ SeedDataService
✅ SearchService
✅ PrescriptionTemplates
✅ GoogleCalendarService
✅ WhatsAppService
✅ PDFService
✅ PhotoService
✅ BackupService
✅ LoggerService
✅ OCRService
✅ DoctorSettingsService
✅ [+ others]
```

### Connected Screens (8+)
```
✅ DashboardScreen
✅ PatientsScreen
✅ AppointmentsScreen
✅ PrescriptionsScreen
✅ MedicalRecordsListScreen
✅ ClinicalDashboard
✅ FollowUpsScreen
✅ BillingScreen
```

---

## 🔧 How to Use

### Get All Patients
```dart
final db = ref.watch(doctorDbProvider).value;
final patients = await db.getAllPatients();
```

### Get Specific Patient
```dart
final patient = await db.getPatientById(patientId);
```

### Create New Patient
```dart
final patient = Patient(
  firstName: 'Ahmed',
  lastName: 'Khan',
  dateOfBirth: DateTime(1985, 3, 15),
  phone: '0300-1234567',
  email: 'ahmed@example.com',
  medicalHistory: 'Hypertension, Diabetes',
  allergies: 'Penicillin (Severe)', // CSV format
  tags: 'chronic,follow-up',      // CSV format
  riskLevel: 3,
);

final id = await db.insertPatient(patient);
```

### Create Appointment
```dart
final appointment = Appointment(
  patientId: 1,
  appointmentDateTime: DateTime(2025, 12, 15, 14, 0),
  durationMinutes: 30,
  reason: 'Diabetes Follow-up',
  status: 'scheduled',
);

await db.insertAppointment(appointment);
```

### Check Allergies Before Prescription
```dart
final patient = await db.getPatientById(patientId);
final result = AllergyCheckingService.check(
  patientAllergies: patient.allergies,
  newDrug: 'Amoxicillin'
);

if (result.hasConcern) {
  print('⚠️ ${result.message}');
  print('Recommendation: ${result.recommendation}');
}
```

### Check Drug Interactions
```dart
final currentMeds = await db.getPrescriptionsForPatient(patientId);
final interactions = DrugInteractionService.check(
  currentMedications: currentMeds.map((p) => p.medication).toList(),
  newMedication: 'Metformin'
);

for (final interaction in interactions) {
  print('⚠️ ${interaction.description}');
}
```

### Record Vital Signs
```dart
final vitals = VitalSign(
  patientId: 1,
  recordedAt: DateTime.now(),
  systolicBp: 138,
  diastolicBp: 88,
  heartRate: 78,
  temperature: 37.2,
  weight: 82.5,
  bloodGlucose: '156 mg/dL',
);

await db.insertVitalSigns(vitals);
```

### Track Treatment Outcome
```dart
final outcome = TreatmentOutcome(
  patientId: 1,
  prescriptionId: 42,
  treatmentType: 'medication',
  treatmentDescription: 'Metformin for diabetes',
  startDate: DateTime(2025, 11, 30),
  outcome: 'improved',
  effectivenessScore: 8,
  sideEffects: 'None',
  patientFeedback: 'Feeling better, more energy',
);

await db.insertTreatmentOutcome(outcome);
```

### Schedule Follow-up
```dart
final followUp = ScheduledFollowUp(
  patientId: 1,
  sourceAppointmentId: 1,
  scheduledDate: DateTime(2025, 12, 30),
  reason: 'Recheck blood glucose levels',
  status: 'pending',
);

await db.insertScheduledFollowUp(followUp);
```

### Record Medical Record
```dart
final record = MedicalRecord(
  patientId: 1,
  recordType: 'psychiatric_assessment',
  title: 'Depression Assessment',
  diagnosis: 'Major Depressive Disorder',
  treatment: 'SSRI therapy + Psychotherapy',
  doctorNotes: 'Patient responding well to treatment',
  recordDate: DateTime.now(),
  dataJson: jsonEncode({
    'mood': 'sad',
    'symptoms': ['sleep disturbance', 'fatigue'],
    'dsm5_code': 'F32.9',
  }),
);

await db.insertMedicalRecord(record);
```

---

## 📊 Data Structure Quick View

### Patient Model
```dart
PatientModel(
  id: 1,
  firstName: 'Muhammad',
  lastName: 'Ahmed Khan',
  dateOfBirth: DateTime(1985, 3, 15),
  phone: '0300-1234567',
  email: 'ahmed@example.com',
  address: 'Islamabad, Pakistan',
  medicalHistory: 'Hypertension, Diabetes',
  allergies: 'Penicillin (Severe), Aspirin (Moderate)',
  tags: ['chronic', 'follow-up'],
  riskLevel: 3,  // 0-5 scale
  createdAt: DateTime.now(),
)
```

### Appointment Model
```dart
Appointment(
  id: 1,
  patientId: 1,
  appointmentDateTime: DateTime(2025, 12, 15, 14, 0),
  durationMinutes: 30,
  reason: 'Diabetes Follow-up',
  status: 'scheduled',  // scheduled, completed, cancelled
  reminderAt: DateTime(2025, 12, 15, 13, 45),
  notes: 'Check blood glucose levels',
  createdAt: DateTime.now(),
)
```

### Prescription Model
```dart
Prescription(
  id: 1,
  patientId: 1,
  itemsJson: '[
    {
      "medication": "Metformin",
      "dosage": "500mg",
      "frequency": "Twice daily",
      "duration": "3 months"
    }
  ]',
  instructions: 'Take with food',
  isRefillable: true,
  createdAt: DateTime.now(),
)
```

### VitalSigns Model
```dart
VitalSign(
  id: 1,
  patientId: 1,
  recordedAt: DateTime.now(),
  systolicBp: 138,          // mmHg
  diastolicBp: 88,          // mmHg
  heartRate: 78,            // bpm
  temperature: 37.2,        // Celsius
  respiratoryRate: 16,      // breaths/min
  oxygenSaturation: 98.5,   // %
  weight: 82.5,             // kg
  height: 178,              // cm
  bmi: 26.1,                // calculated
  painLevel: 0,             // 0-10 scale
  bloodGlucose: '156',      // mg/dL
  notes: 'Normal readings',
  createdAt: DateTime.now(),
)
```

---

## 🎯 Common Workflows

### Workflow 1: New Patient + First Appointment

```dart
// 1. Create patient
final patient = Patient(firstName: 'Ali', ...);
final patientId = await db.insertPatient(patient);

// 2. Create first appointment
final appointment = Appointment(
  patientId: patientId,
  appointmentDateTime: DateTime(2025, 12, 15, 14, 0),
  reason: 'Initial consultation',
);
final appointmentId = await db.insertAppointment(appointment);

// 3. After appointment - record vitals
final vitals = VitalSign(
  patientId: patientId,
  recordedAt: DateTime.now(),
  systolicBp: 140, diastolicBp: 90,
  heartRate: 80, weight: 85,
  bloodGlucose: '180',
);
await db.insertVitalSigns(vitals);

// 4. Create medical record
final record = MedicalRecord(
  patientId: patientId,
  recordType: 'general',
  title: 'Initial Assessment',
  diagnosis: 'Type 2 Diabetes',
  treatment: 'Metformin to start',
);
await db.insertMedicalRecord(record);

// 5. Create prescription with safety checks
final allergy = AllergyCheckingService.check(
  patientAllergies: patient.allergies,
  newDrug: 'Metformin'
);
if (!allergy.hasConcern) {
  final prescription = Prescription(
    patientId: patientId,
    itemsJson: '[{"medication": "Metformin", ...}]',
  );
  await db.insertPrescription(prescription);
}

// 6. Schedule follow-up
final followUp = ScheduledFollowUp(
  patientId: patientId,
  sourceAppointmentId: appointmentId,
  scheduledDate: DateTime.now().add(Duration(days: 30)),
  reason: 'Recheck glucose levels',
);
await db.insertScheduledFollowUp(followUp);
```

### Workflow 2: Update Prescription for Existing Patient

```dart
// 1. Get patient and current medications
final patient = await db.getPatientById(patientId);
final currentPrescriptions = await db.getPrescriptionsForPatient(patientId);

// 2. Check new medication for allergies
final allergyResult = AllergyCheckingService.check(
  patientAllergies: patient.allergies,
  newDrug: 'Lisinopril'
);

// 3. Check for drug interactions
final currentMeds = currentPrescriptions
  .map((p) => jsonDecode(p.itemsJson) as List)
  .expand((i) => i)
  .map((m) => m['medication'] as String)
  .toList();

final interactions = DrugInteractionService.check(
  currentMedications: currentMeds,
  newMedication: 'Lisinopril'
);

// 4. If safe, create prescription
if (!allergyResult.hasConcern && interactions.isEmpty) {
  final prescription = Prescription(
    patientId: patientId,
    itemsJson: '[{"medication": "Lisinopril", ...}]',
    instructions: 'Take once daily in morning',
  );
  await db.insertPrescription(prescription);
}
```

### Workflow 3: Track Treatment Effectiveness

```dart
// 1. Get patient's recent vitals
final vitals = await db.getLatestVitalSignsForPatient(patientId);

// 2. Get recent prescriptions
final prescriptions = await db.getPrescriptionsForPatient(patientId);

// 3. Compare with previous vitals (if any)
final previousVitals = await db.getVitalSignsForPatient(patientId);

// 4. Assess improvement
bool hasImproved = false;
if (previousVitals.isNotEmpty) {
  final previousBP = previousVitals.first.systolicBp ?? 0;
  final currentBP = vitals?.systolicBp ?? 0;
  hasImproved = currentBP < previousBP;
}

// 5. Record outcome
final outcome = TreatmentOutcome(
  patientId: patientId,
  prescriptionId: prescriptions.isNotEmpty ? prescriptions.first.id : null,
  treatmentType: 'medication',
  outcome: hasImproved ? 'improved' : 'stable',
  effectivenessScore: hasImproved ? 8 : 6,
  patientFeedback: 'Feeling better overall',
);
await db.insertTreatmentOutcome(outcome);
```

---

## 🔍 Query Examples

### Get Dashboard Data for Patient

```dart
final patientId = 1;

// All needed data in one view
final patient = await db.getPatientById(patientId);
final upcomingAppointments = await db.getAppointmentsForDay(DateTime.now());
final recentPrescriptions = (await db.getPrescriptionsForPatient(patientId))
  .sublist(0, min(3, prescriptions.length));
final latestVitals = await db.getLatestVitalSignsForPatient(patientId);
final pendingFollowUps = await db.getScheduledFollowUps(patientId);

// Build dashboard from this data
```

### Search Patients by Name

```dart
final allPatients = await db.getAllPatients();
final searchResults = allPatients
  .where((p) => p.firstName.toLowerCase().contains(query.toLowerCase())
    || p.lastName.toLowerCase().contains(query.toLowerCase()))
  .toList();
```

### Get High-Risk Patients

```dart
final allPatients = await db.getAllPatients();
final highRisk = allPatients.where((p) => p.riskLevel >= 3).toList();
```

### Get Appointments for Date Range

```dart
final startDate = DateTime(2025, 12, 1);
final endDate = DateTime(2025, 12, 31);

final allAppointments = await db.getAllAppointments();
final monthlyAppointments = allAppointments
  .where((a) => a.appointmentDateTime.isAfter(startDate)
    && a.appointmentDateTime.isBefore(endDate))
  .toList();
```

---

## ⚠️ Important Notes

### Allergy Format
Allergies are stored as comma-separated strings:
```
"Penicillin (Severe), Aspirin (Moderate), Sulfa (Severe)"
```

### Prescription Items
Medications stored as JSON array in `itemsJson`:
```json
[
  {
    "medication": "Metformin",
    "dosage": "500mg",
    "frequency": "Twice daily",
    "duration": "3 months"
  }
]
```

### Medical Record Data
Complex form data stored as JSON in `dataJson`:
```json
{
  "mood": "sad",
  "symptoms": ["sleep disturbance", "fatigue"],
  "dsm5_code": "F32.9",
  "treatment_plan": "SSRI + Therapy"
}
```

### Datetime Handling
All datetime fields use UTC:
```dart
final now = DateTime.now().toUtc();
```

---

## 🚨 Safety Checklist

Before prescribing medication:
```
☐ Check patient allergies
☐ Check drug interactions
☐ Check contraindications
☐ Verify patient identity
☐ Confirm dosage
☐ Plan follow-up
```

---

## 📞 File References

| Component | File |
|-----------|------|
| Database | `lib/src/db/doctor_db.dart` |
| Provider | `lib/src/providers/db_provider.dart` |
| Seeding | `lib/src/services/seed_data_service.dart` |
| Allergy Checking | `lib/src/services/allergy_checking_service.dart` |
| Drug Interactions | `lib/src/services/drug_interaction_service.dart` |
| Patient Model | `lib/src/models/patient.dart` |

---

## ✅ Status

**Database:** ✅ Ready  
**Safety Features:** ✅ Active  
**Sample Data:** ✅ Loaded  
**All Connections:** ✅ Verified

**Ready for clinical use!** 🎉
