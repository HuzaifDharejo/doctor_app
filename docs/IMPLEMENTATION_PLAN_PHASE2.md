# Doctor App - Phase 2 Implementation Plan
## Data Integrity & Feature Completion (In Progress)

### User's Current Request
**"do it one by one"** - Implement features sequentially with clear completion status.

---

## Priority 1: Data Relationship Fixes (CRITICAL)

### Issue: Prescriptions Don't Link to Diagnoses
**Status**: 🟡 PARTIAL - Database schema ready, need UI update
**Action Items**:
1. ✅ Database: Schema has `diagnosis` and `chiefComplaint` fields
2. ⏳ UI: Update `add_prescription_screen.dart` to show associated diagnosis
3. ⏳ Feature: When adding prescription, auto-fill diagnosis from medical record

### Issue: Appointments Don't Reference Assessments
**Status**: 🟡 PARTIAL - Database schema ready
**Action Items**:
1. ✅ Database: `medicalRecordId` foreign key added to appointments
2. ⏳ UI: Update appointment detail to show linked assessment
3. ⏳ Logic: When user creates appointment, link to completed assessment

### Issue: Vital Signs Not Linked to Visits
**Status**: 🟡 PARTIAL
**Action Items**:
1. ✅ Database: `VitalSigns` table with patient link
2. ⏳ UI: Show vitals on appointment details screen
3. ⏳ Feature: Record vitals during appointment

### Issue: Billing Not Linked to Treatments
**Status**: 🟡 PARTIAL
**Action Items**:
1. ✅ Database: Invoice links to appointments, prescriptions, treatments
2. ⏳ UI: Show treatment items in billing calculation
3. ⏳ Logic: Auto-generate invoice from appointment + treatments

---

## Priority 2: Critical Safety Features (MUST HAVE)

### 1. Drug Interaction Checking
**Status**: 🟡 IN PROGRESS
**Files to Update**:
- `lib/src/services/drug_interaction_service.dart` (CREATE)
- `lib/src/ui/screens/add_prescription_screen.dart` (UPDATE)

**Features**:
- Check current medications before adding new prescription
- Alert for dangerous combinations
- Suggest alternative medications

### 2. Allergy Alert System
**Status**: 🟡 IN PROGRESS
**Files to Update**:
- `lib/src/services/allergy_service.dart` (CREATE)
- `lib/src/ui/screens/add_prescription_screen.dart` (UPDATE)

**Features**:
- Check patient allergies before prescribing
- Block prescriptions to allergic medications
- Show contraindications

### 3. Vital Signs Monitoring Dashboard
**Status**: 🟡 PARTIAL - Screen exists
**Files to Update**:
- `lib/src/ui/screens/vital_signs_screen.dart` (UPDATE)
- Add trending charts
- Add alert thresholds

### 4. Clinical Decision Support
**Status**: 🟡 NOT STARTED
**Features**:
- Evidence-based treatment suggestions
- Drug dosage calculator
- Lab result interpretation

---

## Priority 3: Treatment Tracking (IMPORTANT)

### 1. Treatment Sessions (Therapy Notes)
**Status**: 🟡 PARTIAL
**Files**:
- Create `lib/src/ui/screens/add_treatment_session_screen.dart`
- Create `lib/src/ui/screens/treatment_sessions_list_screen.dart`

### 2. Medication Response Tracking
**Status**: 🟡 PARTIAL
**Files**:
- Create `lib/src/ui/screens/medication_response_screen.dart`
- Add effectiveness scoring
- Track side effects

### 3. Treatment Goals
**Status**: 🟡 PARTIAL
**Files**:
- Create `lib/src/ui/screens/treatment_goals_screen.dart`
- Progress tracking UI
- Goal achievement celebration

---

## Phase 2 Screens to Create/Update (In Order)

### 1. Enhanced Appointment Screen with Assessment Link
**File**: `lib/src/ui/screens/add_appointment_screen.dart`
**Changes**:
- Add field to select associated medical assessment
- Show relevant vitals from assessment
- Display diagnosis context

### 2. Enhanced Prescription Screen
**File**: `lib/src/ui/screens/add_prescription_screen.dart`
**Changes**:
- Show diagnosis from linked assessment
- Drug interaction warnings
- Allergy contraindication alerts
- Previous similar prescriptions for reference

### 3. Treatment Session Recording Screen
**File**: `lib/src/ui/screens/add_treatment_session_screen.dart` (NEW)
**Features**:
- Session date and duration
- Provider type and name
- Session type (individual, group, family)
- Presenting concerns
- Session notes with rich text
- Interventions used (checklist/tag system)
- Patient mood rating
- Homework assignment tracking
- Risk assessment
- Linkage to treatment outcome

### 4. Enhanced Vital Signs Screen
**File**: `lib/src/ui/screens/vital_signs_screen.dart`
**Changes**:
- Show trends over time with charts
- Alert thresholds (BP, glucose, weight)
- Link to appointments/assessments
- Export vitals data

### 5. Medication Response Tracking
**File**: `lib/src/ui/screens/medication_response_screen.dart` (NEW)
**Features**:
- Effectiveness scoring
- Side effect tracking
- Symptom improvement tracking
- Lab monitoring schedule
- Adherence notes

### 6. Treatment Goals Dashboard
**File**: `lib/src/ui/screens/treatment_goals_screen.dart` (NEW)
**Features**:
- Create/edit goals by category
- Progress tracking with percentage
- Goal status management
- Barrier identification
- Intervention tracking

### 7. Treatment Outcomes Dashboard
**File**: `lib/src/ui/screens/treatment_outcomes_screen.dart` (UPDATE)
**Changes**:
- Show treatment timeline
- Link sessions to outcomes
- Effectiveness tracking
- Patient feedback integration
- Provider notes

---

## Database/Service Classes Needed

### 1. Drug Interaction Service
**File**: `lib/src/services/drug_interaction_service.dart`
```dart
class DrugInteractionService {
  - checkInteractions(List<String> medications)
  - getSafeAlternatives(String medication)
  - getDosageInfo(String medication, String condition)
}
```

### 2. Allergy Service
**File**: `lib/src/services/allergy_service.dart`
```dart
class AllergyService {
  - checkAllergy(String medication, List<String> allergies)
  - getContraindications(String medication, List<String> conditions)
  - getSafeAlternatives(String medication, List<String> allergies)
}
```

### 3. Treatment Tracking Service
**File**: `lib/src/services/treatment_tracking_service.dart`
```dart
class TreatmentTrackingService {
  - linkPrescriptionToDiagnosis()
  - linkAppointmentToAssessment()
  - calculateTreatmentOutcome()
  - generateTreatmentSummary()
}
```

---

## Implementation Steps (One by One)

### Step 1: Create Drug Interaction Service ⏳
- [ ] List common medications and their interactions
- [ ] Implement checking logic
- [ ] Add severity levels (critical, major, moderate, minor)

### Step 2: Update Prescription Screen ⏳
- [ ] Add drug interaction warnings
- [ ] Add allergy checking
- [ ] Show linked diagnosis
- [ ] Display contraindication alerts

### Step 3: Create Treatment Session Screen ⏳
- [ ] Form fields for all session data
- [ ] Rich text editor for notes
- [ ] Interventions checklist
- [ ] Risk assessment dropdown

### Step 4: Update Vital Signs Screen ⏳
- [ ] Add trending charts
- [ ] Add alert thresholds
- [ ] Show appointment linking
- [ ] Add export functionality

### Step 5: Create Medication Response Screen ⏳
- [ ] Effectiveness scoring UI
- [ ] Side effect tracking form
- [ ] Symptom improvement matrix
- [ ] Lab monitoring calendar

### Step 6: Create Treatment Goals Screen ⏳
- [ ] Goal creation form with categories
- [ ] Progress slider/percentage
- [ ] Status management
- [ ] Barrier and intervention tracking

### Step 7: Update Treatment Outcomes Screen ⏳
- [ ] Timeline visualization
- [ ] Session linking
- [ ] Patient feedback display
- [ ] Provider notes sections

---

## Testing Checklist

- [ ] All database relationships verified
- [ ] Drug interactions prevent harmful prescriptions
- [ ] Allergies properly alert
- [ ] Treatment sessions properly tracked
- [ ] Goals progress calculates correctly
- [ ] Outcomes summarize treatment properly
- [ ] All screens navigate properly
- [ ] Seeded data loads and displays

---

## Estimated Timeline
- **Phase 2a (Data Integrity)**: 3-4 hours
- **Phase 2b (Safety Features)**: 4-5 hours  
- **Phase 2c (Treatment Tracking)**: 5-6 hours
- **Total**: 12-15 hours

---

## Success Criteria
1. ✅ No broken data relationships
2. ✅ Drug interactions properly checked
3. ✅ Allergies properly managed
4. ✅ All treatment sessions tracked
5. ✅ Treatment outcomes properly summarized
6. ✅ All new screens functional
7. ✅ App builds without errors
8. ✅ Seeded data displays properly

