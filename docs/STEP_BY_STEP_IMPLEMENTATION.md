# Step-by-Step Implementation Guide - Phase 2
## Data Integrity & Safety Features

**Status**: Ready to implement  
**Estimated Time**: 14-18 hours total  
**User**: "do it one by one"

---

## BLOCK 1: DATA INTEGRITY FIXES (3-4 hours)

### STEP 1.1: Update Prescription Screen to Show Diagnosis ⏳
**File**: `lib/src/ui/screens/add_prescription_screen.dart`  
**Time**: 45 mins  
**Difficulty**: Easy

**Changes Required**:
1. Add field to select/view linked medical record (diagnosis source)
2. Auto-populate diagnosis dropdown from recent medical records
3. Display chief complaint and diagnosis on the screen
4. Update save logic to capture `medicalRecordId`

**Code Location**: 
- Form submission → Save prescription with `medicalRecordId`
- Look for: `_savePrescription()` method
- Add: Diagnosis context from `selectedMedicalRecord`

**Testing**:
- Create prescription with linked diagnosis
- Verify diagnosis appears in prescription list
- Check database shows correct `medicalRecordId`

---

### STEP 1.2: Update Appointment Screen to Link Assessment ⏳
**File**: `lib/src/ui/screens/add_appointment_screen.dart`  
**Time**: 45 mins  
**Difficulty**: Easy

**Changes Required**:
1. Add optional field to select completed assessment/medical record
2. Show list of recent assessments for the patient
3. Display selected assessment details
4. Update save logic to capture `medicalRecordId`

**Code Location**:
- Form initialization → Load patient's recent medical records
- Look for: `_initializeForm()` or `build()` method
- Add: Dropdown for medical record selection
- Update: `_saveAppointment()` to save `medicalRecordId`

**Testing**:
- Create appointment linked to assessment
- View appointment and see linked assessment
- Check database shows correct relationship

---

### STEP 1.3: Update Vital Signs Screen for Appointment Context ⏳
**File**: `lib/src/ui/screens/vital_signs_screen.dart`  
**Time**: 1 hour  
**Difficulty**: Medium

**Changes Required**:
1. Add button to "Record Vitals" for current appointment
2. Show vital signs from specific appointment
3. Display trending charts (weight, BP over time)
4. Link vital sign recording to appointment

**Code Location**:
- Look for: Vital signs list display
- Add: Context showing which appointment vitals are from
- Add: Button to record vitals with appointment pre-selected
- Update: Charts to show time-series data

**Visual Changes**:
- Add checkbox to link vital recording to appointment
- Show appointment date next to vital signs
- Add trend line on charts

**Testing**:
- Record vitals with appointment link
- View vitals with appointment context
- Check trending charts display properly

---

### STEP 1.4: Verify All Data Relationships ⏳
**File**: `lib/src/db/doctor_db.dart`  
**Time**: 30 mins  
**Difficulty**: Easy

**Verification Checklist**:
- [ ] `Appointments.medicalRecordId` → `MedicalRecords.id` (FK)
- [ ] `Prescriptions.medicalRecordId` → `MedicalRecords.id` (FK)
- [ ] `Prescriptions.appointmentId` → `Appointments.id` (FK)
- [ ] `Invoices.appointmentId` → `Appointments.id` (FK)
- [ ] `Invoices.prescriptionId` → `Prescriptions.id` (FK)
- [ ] `Invoices.treatmentSessionId` → `TreatmentSessions.id` (FK)

**Code Check**:
```dart
// Look for this pattern in doctor_db.dart:
Future<Prescription> getPrescriptionWithContext(int id) async {
  final rx = await (select(prescriptions)
    ..where((p) => p.id.equals(id)))
    .getSingle();
  // This shows prescription has all context
  return rx;
}
```

---

## BLOCK 2: SAFETY FEATURES INTEGRATION (4-5 hours)

### STEP 2.1: Expand Drug Interaction Database ⏳
**File**: `lib/src/services/drug_interaction_service.dart`  
**Time**: 1 hour  
**Difficulty**: Easy

**Current Status**: 20+ interactions  
**Target**: Add 50+ more common interactions

**Medications to Add**:
1. **Psychiatric** (depression, bipolar, anxiety):
   - SSRIs (Sertraline, Paroxetine, Fluoxetine, Escitalopram)
   - SNRIs (Venlafaxine, Duloxetine)
   - TCAs (Amitriptyline, Nortriptyline)
   - Mood stabilizers (Lithium, Valproate)
   - Antipsychotics (Haloperidol, Olanzapine)

2. **Cardiovascular** (high BP, heart):
   - ACE Inhibitors (Lisinopril, Enalapril)
   - Beta Blockers (Metoprolol, Atenolol)
   - Calcium Blockers (Amlodipine, Verapamil)
   - Statins (Atorvastatin, Simvastatin)
   - Diuretics (Furosemide, Hydrochlorothiazide)

3. **Metabolic** (diabetes, thyroid):
   - Metformin, Insulin
   - Levothyroxine, PTU
   - Sulfonylureas

4. **Antibiotics**:
   - Penicillins, Cephalosporins
   - Fluoroquinolones, Macrolides
   - Metronidazole, Trimethoprim

**Code Change**: Add to `_interactions` list in `DrugInteractionService`

**Format**:
```dart
DrugInteraction(
  drug1: 'Drug Name',
  drug2: 'Other Drug',
  severity: InteractionSeverity.critical,
  description: 'What happens when combined',
  recommendation: 'What doctor should do',
)
```

---

### STEP 2.2: Add Drug Interaction UI to Prescription Screen ⏳
**File**: `lib/src/ui/screens/add_prescription_screen.dart`  
**Time**: 1.5 hours  
**Difficulty**: Medium

**Changes Required**:
1. Get list of patient's current medications from database
2. When adding new medication, check interactions
3. Display warnings based on severity
4. Block critical interactions (or require confirmation)

**UI Elements to Add**:
- **Interaction Alert Panel**: Shows at top if interactions found
  ```
  🚨 CRITICAL: SSRI + MAOI = Serotonin Syndrome Risk
     Recommendation: Avoid this combination
  ```

- **Warning Colors**:
  - Critical (Red): `#C62828`
  - Major (Orange): `#F57C00`
  - Moderate (Yellow): `#FFB74D`

- **Action Buttons**:
  - "View Alternatives" → Show safe drugs
  - "Override" → Confirm prescribing anyway (with warning)
  - "Cancel" → Choose different medication

**Code Logic**:
```dart
1. On medication selection:
   - Get patient's current prescriptions
   - Check interactions with new medication
   - Display warnings

2. On form submission:
   - If critical interaction: Show confirmation dialog
   - Log override if doctor confirms
   - Save with warning flag

3. Visual feedback:
   - Red border on medication field if conflict
   - Show recommendation message
   - Suggest alternatives
```

---

### STEP 2.3: Add Allergy Checking to Prescription Screen ⏳
**File**: `lib/src/ui/screens/add_prescription_screen.dart`  
**Time**: 1 hour  
**Difficulty**: Medium

**Changes Required**:
1. Get patient's allergies from database
2. Check medication against allergies
3. Display allergy warnings prominently
4. Suggest non-allergenic alternatives

**Allergy Check Logic**:
```dart
// Pseudo-code
function checkAllergy(medication, patientAllergies):
  for each allergy in patientAllergies:
    if medication contains allergy OR
       medication.allergenicGroup contains allergy.allergenicGroup:
      return ALLERGY_ALERT

// Example:
Penicillin + Penicillin Allergy = BLOCK
Cephalosporin + Penicillin Allergy = WARN (10% cross-reactivity)
```

**UI Elements**:
- **Allergy Alert** (above interaction alert):
  ```
  ⚠️ ALLERGY: Patient allergic to Penicillin
     Medication: Amoxicillin contains Penicillin
     Action: Choose alternative antibiotic
     Alternatives: Azithromycin, Cephalexin
  ```

- **Visual Indicator**: 
  - Allergy icon (🚫) on medication field
  - Patient name section shows allergy badges
  - Red background for allergy conflicts

---

### STEP 2.4: Add Vital Signs Alert Thresholds ⏳
**File**: `lib/src/ui/screens/vital_signs_screen.dart`  
**Time**: 1 hour  
**Difficulty**: Medium

**Alert Thresholds** (suggested defaults):
```
Systolic BP:
  - Normal: < 120
  - Elevated: 120-129
  - Stage 1 HTN: 130-139
  - Stage 2 HTN: ≥ 140 ⚠️

Diastolic BP:
  - Normal: < 80
  - Elevated: < 90
  - Stage 1 HTN: 90-99
  - Stage 2 HTN: ≥ 100 ⚠️

Weight:
  - Flag if > 5% change in 1 month
  - Flag if trending up (significant medication side effect)

Blood Glucose:
  - Normal (fasting): 70-100 mg/dL
  - Pre-diabetic: 100-125 mg/dL
  - Diabetic: > 125 mg/dL ⚠️

SpO2:
  - Normal: > 95%
  - Low: 90-94% ⚠️
  - Critical: < 90% 🚨
```

**Code Changes**:
1. Add `_getVitalStatus()` function to determine if normal/warning/critical
2. Add colored indicator on vital sign display
3. Show trend indicator (↑ ↓ → )
4. Highlight abnormal values

**Visual Changes**:
- Green: Normal
- Yellow: Warning/Elevated
- Red: Critical/Abnormal
- Add sparkline charts for trends

---

## BLOCK 3: TREATMENT TRACKING FEATURES (5-6 hours)

### STEP 3.1: Create Treatment Session Screen ⏳
**File**: `lib/src/ui/screens/add_treatment_session_screen.dart` (NEW)  
**Time**: 2 hours  
**Difficulty**: Medium-Hard

**Form Fields**:
1. **Basic Info**:
   - Patient (select)
   - Session Date & Time
   - Duration (minutes)
   - Session Type (Individual, Group, Family, Couples)
   - Provider Type (Psychiatrist, Therapist, Counselor, Nurse)
   - Provider Name (text)

2. **Session Content**:
   - Presenting Concerns (text)
   - Session Notes (rich text editor)
   - Interventions Used (multi-select checklist):
     - Cognitive Restructuring
     - Behavioral Activation
     - Exposure Therapy
     - Relaxation Training
     - Mindfulness
     - Problem-Solving
     - Social Skills Training
     - Psychoeducation
     - Other (with text field)

3. **Patient Status**:
   - Patient Mood (dropdown):
     - Anxious, Depressed, Stable, Elevated, Irritable, Calm
   - Mood Rating (1-10 scale)
   - Progress Notes (text area)

4. **Homework**:
   - Homework Assigned (text)
   - Homework Review (notes on previous homework)

5. **Risk Assessment**:
   - Risk Level (dropdown):
     - None, Low, Moderate, High
   - Risk Notes (if high/moderate)

6. **Follow-up**:
   - Plan for Next Session (text)
   - Next Session Date (optional)
   - Billable (checkbox)

**Code Structure**:
```dart
class AddTreatmentSessionScreen extends ConsumerStatefulWidget {
  - Form with sections
  - Date/time pickers
  - Rich text editor for notes
  - Multi-select for interventions
  - Save to TreatmentSessions table
}
```

**Database**:
- Insert into `treatmentSessions` table
- Link to patient, appointment, medical record, treatment outcome
- Store interventions as JSON

---

### STEP 3.2: Create Medication Response Screen ⏳
**File**: `lib/src/ui/screens/medication_response_screen.dart` (NEW)  
**Time**: 1.5 hours  
**Difficulty**: Medium

**Features**:
1. **Medication Info**:
   - Medication name
   - Dosage & Frequency
   - Start date
   - End date (if discontinued)

2. **Effectiveness Tracking**:
   - Response Status (dropdown):
     - Effective, Partial, Ineffective, Monitoring, Discontinued
   - Effectiveness Score (1-10 slider)
   - Target Symptoms (multi-select + custom):
     - Depression, Anxiety, Insomnia, Pain, etc.
   - Symptom Improvement (matrix: Symptom → None/Mild/Moderate/Significant)

3. **Side Effects**:
   - Side Effects (multi-select):
     - Weight gain, Nausea, Tremor, Sexual dysfunction, Drowsiness, etc.
   - Severity (None, Mild, Moderate, Severe)
   - Side Effect Notes (text)

4. **Adherence**:
   - Patient Adherent (Yes/No)
   - Adherence Notes (why if not adherent)

5. **Monitoring**:
   - Labs Required (multi-select):
     - CBC, CMP, Lipid Panel, Blood Glucose, ECG, etc.
   - Next Lab Date
   - Last Review Date
   - Provider Notes

**UI**:
- Timeline of medication changes
- Symptom improvement chart
- Side effect severity tracker
- Lab monitoring calendar

---

### STEP 3.3: Create Treatment Goals Screen ⏳
**File**: `lib/src/ui/screens/treatment_goals_screen.dart` (NEW)  
**Time**: 1.5 hours  
**Difficulty**: Medium

**Features**:
1. **Goal Creation**:
   - Goal Category (dropdown):
     - Symptom, Functional, Behavioral, Cognitive, Interpersonal
   - Goal Description (text)
   - Target Behavior (specific measurable behavior)
   - Baseline Measure (starting point)
   - Target Measure (goal to achieve)
   - Target Date

2. **Progress Tracking**:
   - Current Measure (update with each session)
   - Progress Percent (calculated: (current-baseline)/(target-baseline) * 100)
   - Progress Notes (array of notes over time)
   - Status (Active, Achieved, Modified, Discontinued)

3. **Goal Management**:
   - Priority (High, Medium, Low)
   - Interventions (list of strategies to achieve goal)
   - Barriers (obstacles to progress)
   - Timeline visualization

**Visual Elements**:
- Progress bar showing percentage to goal
- Trend line showing progress over time
- "Achieved!" celebration when 100%
- Color indicators (red=off-track, green=on-track)

**Database**:
- Insert into `treatmentGoals` table
- Update progress with each session
- Link to treatment outcomes

---

### STEP 3.4: Update Treatment Outcomes Screen ⏳
**File**: `lib/src/ui/screens/treatment_outcomes_screen.dart`  
**Time**: 1 hour  
**Difficulty**: Easy-Medium

**Changes**:
1. Show timeline of treatment journey
2. Link sessions, goals, medications to outcome
3. Display effectiveness summary
4. Show patient feedback
5. Include provider notes

**Visual Elements**:
- **Timeline**:
  ```
  Start → Session 1 → Session 2 → Goal 1 ✓ → Session 3 → End
  ```
- **Summary Cards**:
  - Treatment phase
  - Effectiveness score
  - Sessions completed
  - Goals achieved
  - Medications tried
  - Outcomes (Improved/Stable/Worsened/Resolved)

- **Patient Feedback Section**:
  - Show patient's comments
  - Display satisfaction rating

- **Provider Notes**:
  - Treatment approach summary
  - Key insights
  - Recommendations

---

## BLOCK 4: TESTING & VALIDATION (2-3 hours)

### STEP 4.1: Test Data Integrity
**Checklist**:
- [ ] Create patient with allergy
- [ ] Create appointment linked to assessment
- [ ] Create prescription linked to diagnosis
- [ ] Verify all relationships in database
- [ ] View patient and see all linked data

### STEP 4.2: Test Safety Features
**Checklist**:
- [ ] Add SSRI to patient on MAOI → See critical warning
- [ ] Try to prescribe penicillin to allergic patient → See alert
- [ ] Record abnormal BP → See alert
- [ ] Prescribe after critical interaction → See confirmation required

### STEP 4.3: Test Treatment Tracking
**Checklist**:
- [ ] Create treatment session → See in outcomes
- [ ] Track medication response → See effectiveness
- [ ] Create goal → See progress calculation
- [ ] Update goal progress → See trending

### STEP 4.4: UI/UX Testing
**Checklist**:
- [ ] All screens load without errors
- [ ] Navigation between linked records works
- [ ] Forms save data correctly
- [ ] Data displays correctly in lists
- [ ] Responsive on mobile/tablet

---

## COMPLETION ORDER (Do One by One)

```
1. ✅ STEP 1.1: Update Prescription Screen (45 min)
2. ✅ STEP 1.2: Update Appointment Screen (45 min)
3. ✅ STEP 1.3: Update Vital Signs Screen (1 hour)
4. ✅ STEP 1.4: Verify Relationships (30 min)
   └─ Total: 3.5 hours

5. ✅ STEP 2.1: Expand Drug Database (1 hour)
6. ✅ STEP 2.2: Add Interaction UI (1.5 hours)
7. ✅ STEP 2.3: Add Allergy Checking (1 hour)
8. ✅ STEP 2.4: Add Vital Alerts (1 hour)
   └─ Total: 4.5 hours

9. ✅ STEP 3.1: Treatment Session Screen (2 hours)
10. ✅ STEP 3.2: Medication Response Screen (1.5 hours)
11. ✅ STEP 3.3: Treatment Goals Screen (1.5 hours)
12. ✅ STEP 3.4: Update Treatment Outcomes (1 hour)
    └─ Total: 6 hours

13. ✅ STEP 4.1-4.4: Testing (2-3 hours)

TOTAL: 15-16 hours
```

---

## QUICK REFERENCE

### File Locations
- Screens: `lib/src/ui/screens/`
- Services: `lib/src/services/`
- Database: `lib/src/db/doctor_db.dart`
- Models: `lib/src/models/` (auto-generated from DB)
- Widgets: `lib/src/ui/widgets/`

### Key Database Tables
- `Patients`: Patient info + allergies
- `Appointments`: Scheduled visits + medicalRecordId (NEW)
- `Prescriptions`: Medications + appointmentId, medicalRecordId (NEW)
- `MedicalRecords`: Assessments + diagnoses
- `VitalSigns`: Vital measurements
- `TreatmentSessions`: Therapy notes
- `MedicationResponses`: Med tracking
- `TreatmentGoals`: Goal progress
- `TreatmentOutcomes`: Overall summary
- `ScheduledFollowUps`: Future appointments

### Common Patterns
```dart
// Load patient with all records
final patient = await db.getPatientById(id);
final records = await db.getMedicalRecordsForPatient(id);

// Load appointment with linked assessment
final appt = await db.getAppointmentById(id);
if (appt.medicalRecordId != null) {
  final record = await db.getMedicalRecordById(appt.medicalRecordId!);
}

// Check drug interactions
final current = patient.prescriptions;
final interactions = drugInteractionService.checkInteractions(current);

// Check allergies
final allergies = patient.allergies.split(',');
final contraindications = drugInteractionService.checkContraindications(newMed, allergies);
```

---

## SUCCESS METRICS

When complete, the app will:
- ✅ Prevent dangerous drug combinations
- ✅ Alert on allergy contraindications
- ✅ Link all treatment data together
- ✅ Track treatment progress
- ✅ Show clinical decision support
- ✅ Provide comprehensive patient view
- ✅ Generate outcome summaries

---

**Ready to start? Begin with STEP 1.1!**

