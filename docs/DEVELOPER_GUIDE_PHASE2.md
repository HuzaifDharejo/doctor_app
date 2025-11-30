# Developer Guide: Phase 2 Implementation
## Data Integrity, Safety Features & Treatment Tracking

**Status**: 🟠 Ready for Implementation  
**Mode**: One-by-one, step-by-step execution  
**Total Effort**: 15-18 hours  
**Code Quality**: Production-ready with error handling

---

## WHAT YOU HAVE NOW ✅

### 1. Complete Database Schema
All 11 tables created with proper foreign keys:
```
✅ Patients (+ allergies field)
✅ Appointments (+ medicalRecordId)
✅ Prescriptions (+ appointmentId, medicalRecordId, diagnosis)
✅ MedicalRecords (6 types)
✅ VitalSigns (+ appointment context)
✅ TreatmentOutcomes (comprehensive tracking)
✅ TreatmentSessions (therapy notes)
✅ MedicationResponses (med effectiveness)
✅ TreatmentGoals (progress tracking)
✅ ScheduledFollowUps (automation)
✅ Invoices (treatment billing)
```

### 2. Seeded Data
120 Pakistani patients with realistic data:
```
✅ 120 Patients (with medical history & allergies)
✅ 1000+ Appointments (past, today, future)
✅ 400+ Prescriptions (linked to diagnoses)
✅ 1200+ Medical Records (all types)
✅ 500+ Vital Signs (trending data)
✅ 100+ Treatment Outcomes
✅ 80+ Follow-up automations
✅ 500+ Invoices
```

### 3. Existing Screens
30+ UI screens already built:
```
✅ Dashboard (overview)
✅ Patient management (list, view, create)
✅ Appointments (schedule, view)
✅ Prescriptions (manage)
✅ Medical records (list, detail)
✅ Vital signs (tracking)
✅ Treatment outcomes (summary)
✅ Billing & invoices
✅ Follow-ups (automation)
✅ Clinical dashboard
✅ Psychiatric assessment
✅ Settings & profile
```

### 4. Services
```
✅ DrugInteractionService (20+ interactions)
✅ DoctorDatabase (complete DAOs)
✅ Logger, Settings, Theme services
```

---

## WHAT'S MISSING / INCOMPLETE 🟡

### Critical Gaps
1. **UI Integration** of drug interaction warnings
2. **UI Integration** of allergy checking
3. **Treatment session** recording screen
4. **Medication response** tracking screen
5. **Treatment goals** screen
6. **Data linking** in several screens

### Optimization Needed
1. Expand drug interaction database (20 → 50+ drugs)
2. Add vital signs trending charts
3. Add alert thresholds for vitals
4. More sophisticated allergy checking

---

## YOUR IMMEDIATE TASK

**You should:**
1. Read `STEP_BY_STEP_IMPLEMENTATION.md` (17KB - quick read)
2. Start with STEP 1.1 (Update Prescription Screen - 45 min)
3. Follow numbered steps sequentially
4. Test each change before moving to next

**Total time**: 15-18 hours split into 12 focused steps

---

## HOW TO EXECUTE STEP 1.1
## (Update Prescription Screen to Show Diagnosis)

### Open File
```
lib/src/ui/screens/add_prescription_screen.dart
```

### Find This Section
Look for the form builder or form fields section. You'll see something like:
```dart
// Current structure - prescription form
_buildPrescriptionForm()
  → medication selection
  → dosage input
  → frequency selection
  → instructions
  → save button
```

### Add This Field
Between medication and dosage, add diagnosis context:
```dart
// Add dropdown for medical record (diagnosis source)
DropdownButtonFormField<MedicalRecord>(
  decoration: InputDecoration(
    labelText: 'Diagnosis/Assessment',
    hintText: 'Select the condition being treated',
    icon: const Icon(Icons.medical_information),
  ),
  value: _selectedMedicalRecord,
  onChanged: (record) {
    setState(() => _selectedMedicalRecord = record);
  },
  items: _availableMedicalRecords.map((record) {
    return DropdownMenuItem(
      value: record,
      child: Text('${record.diagnosis} - ${record.recordDate}'),
    );
  }).toList(),
)
```

### Load Medical Records
In the form initialization method, add:
```dart
Future<void> _loadAvailableMedicalRecords() async {
  final records = await db.getMedicalRecordsForPatient(widget.patientId);
  setState(() {
    _availableMedicalRecords = records
        .where((r) => r.diagnosis.isNotEmpty)
        .toList();
  });
}
```

### Save with Diagnosis
In the save method, capture the record:
```dart
Future<void> _savePrescription() async {
  final prescription = Prescription(
    patientId: widget.patientId,
    // ... other fields ...
    medicalRecordId: _selectedMedicalRecord?.id, // ADD THIS
    diagnosis: _selectedMedicalRecord?.diagnosis ?? '', // ADD THIS
    appointmentId: widget.appointmentId,
  );
  
  await db.insertPrescription(prescription);
  // ... rest of save logic ...
}
```

### Test It
1. Create a patient
2. Add medical record with diagnosis
3. Create prescription and select the diagnosis
4. Verify diagnosis appears in prescription list
5. Check database

---

## FILE STRUCTURE YOU'LL WORK WITH

```
lib/src/
├── db/
│   ├── doctor_db.dart (main database - READ THIS FIRST)
│   ├── doctor_db.g.dart (generated - don't edit)
│   ├── doctor_db_native.dart
│   └── doctor_db_web.dart
├── services/
│   ├── drug_interaction_service.dart (EXPAND THIS)
│   └── ... other services ...
├── ui/
│   ├── screens/
│   │   ├── add_prescription_screen.dart (UPDATE)
│   │   ├── add_appointment_screen.dart (UPDATE)
│   │   ├── vital_signs_screen.dart (UPDATE)
│   │   ├── add_treatment_session_screen.dart (CREATE)
│   │   ├── medication_response_screen.dart (CREATE)
│   │   ├── treatment_goals_screen.dart (CREATE)
│   │   └── ... 20+ other screens ...
│   └── widgets/
│       └── ... reusable UI components ...
├── models/
│   └── (auto-generated from database schema)
├── providers/
│   └── (Riverpod state management)
└── theme/
    └── (styling & theming)
```

---

## KEY DATABASE PATTERNS

### Get Patient with All Context
```dart
// From DoctorDatabase class
Future<Patient?> getPatientById(int id) => 
  (select(patients)..where((t) => t.id.equals(id)))
  .getSingleOrNull();

// Then get related data
final records = await db.getMedicalRecordsForPatient(id);
final prescriptions = await db.getPrescriptionsForPatient(id);
final appointments = await (select(appointments)
  ..where((a) => a.patientId.equals(id)))
  .get();
```

### Check Drug Interactions
```dart
import 'package:doctor_app/src/services/drug_interaction_service.dart';

final currentMeds = ['Sertraline', 'Lithium'];
final newMed = 'Diuretic';
final allMeds = [...currentMeds, newMed];

final interactions = drugInteractionService.checkInteractions(allMeds);
final critical = drugInteractionService.getCriticalInteractions(allMeds);

if (critical.isNotEmpty) {
  // Show warning, block prescription, or require confirmation
}
```

### Check Patient Allergies
```dart
final patient = await db.getPatientById(patientId);
final allergies = patient.allergies.split(',').map((a) => a.trim()).toList();

// Check if new medication is allergenic
final contraindications = drugInteractionService.checkContraindications(
  medicationName,
  patient.medicalHistory.split(','),
  allergies,
);

if (contraindications.isNotEmpty) {
  // Show alert, suggest alternatives
}
```

### Load Vital Signs with Trends
```dart
final vitals = await db.getVitalSignsForPatient(patientId);
// vitals is already sorted by date (most recent first)

// Group by month for trending
final vitalsByMonth = <String, List<VitalSign>>{};
for (final v in vitals) {
  final key = '${v.recordedAt.year}-${v.recordedAt.month}';
  vitalsByMonth.putIfAbsent(key, () => []).add(v);
}
```

---

## COMMON PATTERNS IN EXISTING SCREENS

### Form with Async Data Loading
```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(doctorDbProvider).value!;
    final data = await db.someMethod();
    setState(() => _myData = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState();
          }
          if (snapshot.hasError) {
            return ErrorState.generic(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }
          return _buildContent();
        },
      ),
    );
  }
}
```

### Dropdown with Database Items
```dart
DropdownButtonFormField<MyModel>(
  decoration: InputDecoration(
    labelText: 'Select Item',
    border: OutlineInputBorder(),
  ),
  value: _selectedItem,
  onChanged: (item) {
    setState(() => _selectedItem = item);
  },
  items: _items.map((item) {
    return DropdownMenuItem(
      value: item,
      child: Text(item.displayName),
    );
  }).toList(),
  validator: (value) => value == null ? 'Required' : null,
)
```

### Alert/Warning Widget
```dart
if (interactions.isNotEmpty) {
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      border: Border.all(color: Colors.red),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚠️ Drug Interaction Alert',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        ...interactions.map((i) => Text(
          '${i.drug1} + ${i.drug2}: ${i.description}',
        )),
      ],
    ),
  )
}
```

---

## TESTING EACH STEP

After each step, verify:

1. **Build succeeds**:
   ```
   flutter clean && flutter pub get && flutter build apk
   ```

2. **No broken imports**: Check for red squiggles in VS Code

3. **Database integrity**: Check that relationships exist
   ```dart
   // In DoctorDatabase
   final appt = await db.getAppointmentById(1);
   if (appt.medicalRecordId != null) {
     final record = await db.getMedicalRecordById(appt.medicalRecordId!);
     print('Linked record: ${record.diagnosis}');
   }
   ```

4. **UI renders**: Run app and navigate to screen
   - Check for layout errors
   - Verify form fields appear
   - Test form submission

5. **Data persists**: Restart app and verify data saved

---

## WHEN STUCK

### If build fails:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Check for import errors
4. Verify all closing braces/parentheses

### If data isn't showing:
1. Check database migrations (schema version 4 required)
2. Verify seed data loaded
3. Check FutureBuilder loading states
4. Log database queries: `log.d('TAG', 'query result: $result')`

### If UI doesn't look right:
1. Check responsive design in `AppBreakpoint`
2. Verify theme colors in `app_theme.dart`
3. Check SafeArea/Padding/Margin
4. Test on different screen sizes

### Check Existing Code:
- Look at `dashboard_screen.dart` for complex patterns
- Look at `patient_view_screen.dart` for data display
- Look at `add_prescription_screen.dart` for form patterns

---

## DOCUMENTATION TO READ

**BEFORE starting**: Read in this order
1. This file (DEVELOPER_GUIDE_PHASE2.md) - 5 min ✅
2. STEP_BY_STEP_IMPLEMENTATION.md - 10 min
3. PHASE2_IMPLEMENTATION_STATUS.md - 5 min

**WHILE working**: Keep open
1. `lib/src/db/doctor_db.dart` - See all database methods
2. `lib/src/services/drug_interaction_service.dart` - See current implementation
3. Similar screen example (e.g., `add_prescription_screen.dart`)

**FOR reference**:
1. Flutter documentation (flutter.dev)
2. Drift documentation (drift.simonbinder.eu)
3. Riverpod documentation (riverpod.dev)

---

## CHECKLIST BEFORE STARTING

- [ ] You have Flutter SDK installed
- [ ] VS Code or IDE with Flutter extension
- [ ] You've read this entire guide
- [ ] You understand database schema
- [ ] You have STEP_BY_STEP_IMPLEMENTATION.md open
- [ ] You have drug_interaction_service.dart open
- [ ] You're ready to start with STEP 1.1

---

## QUICK START (TL;DR)

1. **Read**: `STEP_BY_STEP_IMPLEMENTATION.md`
2. **Start**: STEP 1.1 (Update Prescription Screen)
3. **Follow**: One step at a time
4. **Test**: Each change
5. **Done**: 15-18 hours later, you'll have:
   - ✅ All data relationships working
   - ✅ Drug interaction warnings
   - ✅ Allergy alerts
   - ✅ Treatment tracking screens
   - ✅ Vital signs monitoring
   - ✅ Safe prescribing system

---

## SUCCESS LOOKS LIKE

When you're done:
- ✅ App builds without errors
- ✅ No database integrity issues
- ✅ Drug interactions prevent harm
- ✅ Allergies are checked
- ✅ Treatment progress tracked
- ✅ All screens work properly
- ✅ Seeded data displays correctly
- ✅ Patient care is safer

---

**You're ready to start! Open STEP_BY_STEP_IMPLEMENTATION.md and begin STEP 1.1** 🚀

