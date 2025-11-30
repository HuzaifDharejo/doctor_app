# 🔗 Database Connectivity Flow Diagram

**Status:** ✅ COMPLETE AND VERIFIED  
**Last Updated:** 2025-11-30

---

## 📊 HIGH-LEVEL ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APPLICATION                       │
├─────────────────────────────────────────────────────────────────┤
│                       Riverpod Providers                         │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  doctorDbProvider (FutureProvider<DoctorDatabase>)         │ │
│  │  doctorSettingsProvider (ChangeNotifierProvider)          │ │
│  │  appSettingsProvider (ChangeNotifierProvider)             │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Services Layer                                │ │
│  │  ├── AllergyCheckingService                              │ │
│  │  ├── DrugInteractionService                              │ │
│  │  ├── SeedDataService                                     │ │
│  │  ├── SearchService                                       │ │
│  │  ├── PrescriptionTemplates                               │ │
│  │  └── [14 more services]                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                           │                                      │
│                           ▼                                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              UI Layer (Screens & Widgets)                 │ │
│  │  ├── DashboardScreen                                     │ │
│  │  ├── PatientsScreen                                      │ │
│  │  ├── AppointmentsScreen                                  │ │
│  │  ├── PrescriptionsScreen                                 │ │
│  │  ├── MedicalRecordsListScreen                            │ │
│  │  ├── ClinicalDashboard                                   │ │
│  │  ├── FollowUpsScreen                                     │ │
│  │  ├── BillingScreen                                       │ │
│  │  └── [Custom widgets for each feature]                   │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │      DRIFT ORM Layer                   │
        │  (doctor_db.dart, doctor_db.g.dart)   │
        │                                        │
        │  • Type-safe queries                  │
        │  • Migration handling                 │
        │  • Lifecycle management               │
        └────────────────────────────────────────┘
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │   Platform-Specific Database           │
        ├────────────────────────────────────────┤
        │  • doctor_db_native.dart               │
        │    (iOS/Android: SQLite via sqflite)   │
        │                                        │
        │  • doctor_db_web.dart                  │
        │    (Web: IndexedDB)                    │
        └────────────────────────────────────────┘
```

---

## 🔄 DETAILED DATA FLOW

### 1. PATIENT DATA FLOW

```
┌──────────────────────────────────────────────────────────────┐
│ New Patient Creation                                         │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
                    ┌─────────────────┐
                    │ PatientsScreen  │
                    │                 │
                    │ Input Form:     │
                    │ • Name          │
                    │ • DOB           │
                    │ • Contact       │
                    │ • Allergies ◄────── AllergyCheckingService
                    │ • Medical Hx    │    (validates common allergies)
                    │ • Risk Level    │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────────────────┐
                    │ PatientModel.toJson()       │
                    │ (Serialize to Map)          │
                    └────────┬────────────────────┘
                             │
                             ▼
        ┌────────────────────────────────────┐
        │ DoctorDatabase.insertPatient()     │
        │                                    │
        │ INSERT INTO patients               │
        │ (firstName, lastName, dob,         │
        │  phone, email, address,            │
        │  medicalHistory, allergies,        │
        │  tags, riskLevel, createdAt)       │
        └────────┬───────────────────────────┘
                 │
                 ▼
        ┌────────────────────────────────────┐
        │ Patients Table                     │
        │                                    │
        │ id: INT (autoincrement)            │
        │ firstName: TEXT                    │
        │ lastName: TEXT                     │
        │ dateOfBirth: DATETIME              │
        │ phone: TEXT                        │
        │ email: TEXT                        │
        │ address: TEXT                      │
        │ medicalHistory: TEXT               │
        │ allergies: TEXT (CSV)              │
        │ tags: TEXT (CSV)                   │
        │ riskLevel: INT (0-5)               │
        │ createdAt: DATETIME                │
        └────────┬───────────────────────────┘
                 │
                 ▼
        ┌────────────────────────────────────┐
        │ Related Records Created:           │
        │                                    │
        │ ✅ Appointments (FK: patientId)    │
        │ ✅ Prescriptions (FK: patientId)   │
        │ ✅ MedicalRecords (FK: patientId)  │
        │ ✅ Invoices (FK: patientId)        │
        │ ✅ VitalSigns (FK: patientId)      │
        │ ✅ TreatmentOutcomes (FK: pat...)  │
        │ ✅ ScheduledFollowUps (FK: pat...) │
        └────────────────────────────────────┘
```

---

### 2. PRESCRIPTION WITH SAFETY CHECKS FLOW

```
┌──────────────────────────────────────────────────────────┐
│ Create/Update Prescription                               │
└──────────────────────────────────────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────────┐
        │ PrescriptionsScreen         │
        │                             │
        │ Input:                      │
        │ • Select Patient ────────┐  │
        │ • Select Medications     │  │
        │ • Set Dosage             │  │
        │ • Set Frequency          │  │
        │ • Set Duration           │  │
        │ • Instructions           │  │
        └─────────┬─────────────────┘  │
                  │                     │
                  ▼                     │
    ┌──────────────────────────────┐   │
    │ Get Patient Data             │◄──┘
    │ (allergies, current meds)    │
    └──────────┬───────────────────┘
               │
        ┌──────┴──────┐
        │             │
        ▼             ▼
  ┌──────────────┐  ┌──────────────────────┐
  │ Allergy      │  │ Drug Interaction     │
  │ Check        │  │ Check                │
  │              │  │                      │
  │ Algorithm:   │  │ Algorithm:           │
  │ 1. Extract   │  │ 1. Get all current   │
  │    patient   │  │    medications       │
  │    allergies │  │ 2. Check each new    │
  │ 2. Check     │  │    medication        │
  │    each new  │  │    against current   │
  │    drug      │  │ 3. Cross-reference   │
  │ 3. Map to    │  │    interaction DB    │
  │    known     │  │ 4. Flag severity     │
  │    allergies │  │ 5. Suggest           │
  │ 4. Flag      │  │    alternatives      │
  │    severity  │  │                      │
  │ 5. Suggest   │  │ Database Used:       │
  │    alter.    │  │ • prescriptions      │
  │              │  │   .itemsJson         │
  │ Result:      │  │ • patients.allergies │
  │ • ✅ Clear  │  │                      │
  │ • ⚠️ Warning│  │ Result:              │
  │ • 🛑 Block  │  │ • ✅ Safe            │
  │              │  │ • ⚠️ Monitor         │
  └──────┬───────┘  │ • 🛑 Contraindicated│
         │          └──────┬──────────────┘
         │                 │
         └────────┬────────┘
                  │
                  ▼
    ┌─────────────────────────────────────┐
    │ Decision: Allow/Block/Warn?         │
    │                                     │
    │ IF blocked: Show error & abort      │
    │ IF warned: Show confirmation        │
    │ IF safe: Continue                   │
    └────────┬────────────────────────────┘
             │
             ▼
    ┌─────────────────────────────────────┐
    │ Create PrescriptionModel            │
    │                                     │
    │ • patientId                         │
    │ • itemsJson (serialized)            │
    │ • instructions                      │
    │ • isRefillable                      │
    │ • createdAt                         │
    └────────┬────────────────────────────┘
             │
             ▼
    ┌─────────────────────────────────────┐
    │ DoctorDatabase.insertPrescription() │
    │                                     │
    │ INSERT INTO prescriptions           │
    │ (patientId, itemsJson,              │
    │  instructions, isRefillable,        │
    │  createdAt)                         │
    └────────┬────────────────────────────┘
             │
             ▼
    ┌─────────────────────────────────────┐
    │ Prescriptions Table Updated         │
    │                                     │
    │ id: 42                              │
    │ patientId: 1                        │
    │ itemsJson: [{                       │
    │   "medication": "Metformin",        │
    │   "dosage": "500mg",                │
    │   "frequency": "Twice daily"        │
    │ }]                                  │
    │ createdAt: 2025-11-30T...           │
    └─────────────────────────────────────┘
```

---

### 3. APPOINTMENT WITH VITAL SIGNS FLOW

```
┌─────────────────────────────────────┐
│ Schedule Appointment                │
└─────────────────────────────────────┘
         │
         ▼
    ┌──────────────────────────────┐
    │ AppointmentsScreen           │
    │                              │
    │ • Select Patient             │
    │ • Date/Time                  │
    │ • Duration                   │
    │ • Reason                     │
    │ • Notes                      │
    └────────┬─────────────────────┘
             │
             ▼
    ┌──────────────────────────────┐
    │ DoctorDatabase               │
    │ .insertAppointment()         │
    │                              │
    │ INSERT INTO appointments     │
    │ (patientId,                  │
    │  appointmentDateTime,        │
    │  durationMinutes,            │
    │  reason, status, notes,      │
    │  createdAt)                  │
    └────────┬─────────────────────┘
             │
             ▼
         ┌───────────────────────────────────┐
         │ Appointments Table                │
         │                                   │
         │ id: 1                             │
         │ patientId: 1 (FK to Patients)    │
         │ appointmentDateTime: 2025-12-15  │
         │ durationMinutes: 30              │
         │ reason: "Diabetes Follow-up"     │
         │ status: "scheduled"              │
         │ reminderAt: [calculated]         │
         └────────┬────────────────────────┘
                  │
         ┌────────┴──────────────────┐
         │                           │
         ▼                           ▼
   ┌──────────────┐        ┌─────────────────────┐
   │ At Clinic:   │        │ ScheduledFollowUps  │
   │ Doctor       │        │ (Auto-created for   │
   │ records      │        │  follow-up needs)   │
   │ vital signs  │        │                     │
   │              │        │ IF reason suggests  │
   │ • BP         │        │ follow-up:          │
   │ • HR         │        │ • Create entry      │
   │ • Temp       │        │ • Set reminder      │
   │ • Weight     │        │ • Link to appt      │
   │ • O2 Sat     │        └────────┬────────────┘
   │ • Blood Glu  │                 │
   │ • Pain Level │                 ▼
   └────────┬─────┘        ┌──────────────────────┐
            │              │ Scheduled FollowUps  │
            ▼              │ Table                │
    ┌──────────────────┐   │                      │
    │ VitalSigns Table │   │ id: 1                │
    │                  │   │ patientId: 1         │
    │ id: 1            │   │ sourceAppointmentId: 1
    │ patientId: 1     │   │ scheduledDate: [+14] │
    │ recordedAt: now  │   │ reason: "Recheck..." │
    │ systolicBp: 138  │   │ status: "pending"    │
    │ diastolicBp: 88  │   │ reminderSent: false  │
    │ heartRate: 78    │   └──────────────────────┘
    │ weight: 82.5     │
    │ bloodGlucose: 156│
    │ createdAt: now   │
    └──────────────────┘
```

---

### 4. MEDICAL RECORD DOCUMENTATION FLOW

```
┌────────────────────────────────────────────┐
│ Document Medical Record (After Evaluation) │
└────────────────────────────────────────────┘
                    │
                    ▼
        ┌───────────────────────────────┐
        │ MedicalRecordsListScreen      │
        │                               │
        │ New Record Dialog:            │
        │ • Record Type:                │
        │   - General                   │
        │   - Psychiatric Assessment    │
        │   - Lab Result                │
        │   - Imaging                   │
        │   - Procedure                 │
        │ • Title                       │
        │ • Diagnosis                   │
        │ • Treatment Plan              │
        │ • Doctor Notes                │
        │ • Attach Files (JSON)         │
        └─────────┬──────────────────────┘
                  │
                  ▼
        ┌──────────────────────────────┐
        │ MedicalRecordModel           │
        │ .toJson() serialization      │
        │                              │
        │ • patientId                  │
        │ • recordType                 │
        │ • title                      │
        │ • description                │
        │ • dataJson (form responses)  │
        │ • diagnosis                  │
        │ • treatment                  │
        │ • doctorNotes                │
        │ • recordDate                 │
        │ • createdAt                  │
        └────────┬─────────────────────┘
                 │
                 ▼
        ┌────────────────────────────────┐
        │ DoctorDatabase                 │
        │ .insertMedicalRecord()         │
        │                                │
        │ INSERT INTO medical_records    │
        │ (patientId, recordType,        │
        │  title, description,           │
        │  dataJson, diagnosis,          │
        │  treatment, doctorNotes,       │
        │  recordDate, createdAt)        │
        └────────┬───────────────────────┘
                 │
                 ▼
        ┌────────────────────────────────┐
        │ MedicalRecords Table           │
        │                                │
        │ id: 5                          │
        │ patientId: 1 (FK)              │
        │ recordType: "psychiatric_     │
        │              assessment"       │
        │ title: "Depression Assessment" │
        │ dataJson: {                    │
        │   "mood": "sad",               │
        │   "dsm5_codes": [...]          │
        │   "symptoms": [...]            │
        │   "onset_date": "..."          │
        │ }                              │
        │ diagnosis: "Major Depressive   │
        │             Disorder"          │
        │ treatment: "SSRI therapy"      │
        │ recordDate: 2025-11-30         │
        │ createdAt: 2025-11-30          │
        └────────┬───────────────────────┘
                 │
                 ▼
        ┌────────────────────────────────┐
        │ Creates Link to:               │
        │                                │
        │ ✅ TreatmentOutcomes          │
        │    (if associated with Rx)     │
        │ ✅ ScheduledFollowUps          │
        │    (if follow-up needed)       │
        │ ✅ Appointments                │
        │    (history and recall)        │
        └────────────────────────────────┘
```

---

## 🎯 SERVICE INTEGRATION POINTS

### Allergy Checking Service

```
AllergyCheckingService
    │
    ├─► Receives: patientAllergies (String CSV), newDrug (String)
    │
    ├─► Process:
    │   1. Parse patient allergies from DB
    │   2. Look up common allergy database
    │   3. Check contraindications
    │   4. Map severity levels
    │   5. Generate recommendations
    │
    ├─► Returns: AllergyCheckResult {
    │       hasConcern: bool
    │       allergyType: String
    │       severity: AllergySeverity (enum)
    │       message: String
    │       recommendation: String
    │   }
    │
    └─► Used By:
        • PrescriptionsScreen (before saving)
        • DrugInteractionService (cross-check)
        • Clinical Dashboard (risk assessment)
```

### Drug Interaction Service

```
DrugInteractionService
    │
    ├─► Receives: currentMedications (List), newMedication (String)
    │
    ├─► Process:
    │   1. Get all current medications from prescriptions.itemsJson
    │   2. Query internal interaction database (20+ pairs)
    │   3. Find severity levels
    │   4. Cross-reference with allergies
    │   5. Generate clinical recommendations
    │
    ├─► Returns: List<DrugInteraction> {
    │       drug1: String
    │       drug2: String
    │       severity: InteractionSeverity (enum)
    │       description: String
    │       recommendation: String
    │   }
    │
    └─► Used By:
        • PrescriptionsScreen (validation)
        • ClinicalDashboard (risk alerts)
        • PrescriptionTemplates (safe defaults)
```

### Seed Data Service

```
SeedDataService
    │
    ├─► Function: seedSampleData(DoctorDatabase db)
    │
    ├─► Process:
    │   1. Check if patients exist (non-destructive)
    │   2. Create 75 comprehensive patient records
    │   3. Populate medical histories
    │   4. Set allergies for safety testing
    │   5. Create related appointments/records
    │
    ├─► Creates:
    │   • 75 Patients (diverse conditions)
    │   • 150+ Appointments
    │   • 75+ Prescriptions
    │   • 100+ Medical Records
    │   • 200+ Vital Signs
    │   • 50+ Treatment Outcomes
    │   • 60+ Scheduled Follow-ups
    │
    └─► Called By:
        • doctorDbProvider (on app startup)
        • Manual force reseed (testing)
```

---

## 📡 REAL-TIME DATA FLOW EXAMPLES

### Example 1: Creating Prescription for Diabetic Patient

```
USER INPUT: Create prescription for patient Muhammad Ahmed Khan
    │
    ├─ Patient ID: 1
    ├─ Allergies in DB: "Penicillin (Severe), Aspirin (Moderate)"
    ├─ Current Meds: "Lisinopril, Hydrochlorothiazide"
    └─ New Medication: Metformin 500mg + Atorvastatin 20mg

STEP 1: Allergy Check
    AllergyCheckingService.check("Metformin")
    Result: ✅ Safe
    AllergyCheckingService.check("Atorvastatin")
    Result: ✅ Safe

STEP 2: Interaction Check
    DrugInteractionService.check([
        "Lisinopril",
        "Hydrochlorothiazide",
        "Metformin",
        "Atorvastatin"
    ])
    
    Checks:
    • Metformin + Lisinopril: ✅ Safe
    • Atorvastatin + Lisinopril: ✅ Safe
    • Metformin + Atorvastatin: ✅ Safe
    
    Result: ✅ All safe

STEP 3: Insert to DB
    INSERT INTO prescriptions (
        patientId: 1,
        itemsJson: [
            {medication: "Metformin", dosage: "500mg", frequency: "twice daily"},
            {medication: "Atorvastatin", dosage: "20mg", frequency: "once daily"}
        ],
        instructions: "Take with food",
        isRefillable: true
    )
    
    Result: ID 42 created

STEP 4: Create Follow-up
    INSERT INTO scheduled_follow_ups (
        patientId: 1,
        sourceAppointmentId: NULL,
        sourcePrescriptionId: 42,
        scheduledDate: 2025-12-30,
        reason: "Recheck fasting blood glucose",
        status: "pending"
    )
    
    Result: Follow-up created

UI RESPONSE:
✅ "Prescription created successfully"
ℹ️  "Follow-up scheduled for December 30"
```

### Example 2: Retrieving Patient Dashboard

```
USER ACTION: Open Dashboard for Patient ID = 1

QUERIES EXECUTED:

1. Get Patient Data
   SELECT * FROM patients WHERE id = 1
   Result: Full patient record

2. Get Recent Appointments
   SELECT * FROM appointments 
   WHERE patientId = 1
   ORDER BY appointmentDateTime DESC
   LIMIT 5
   Result: 5 recent/upcoming appointments

3. Get Current Prescriptions
   SELECT * FROM prescriptions
   WHERE patientId = 1
   ORDER BY createdAt DESC
   LIMIT 3
   Result: 3 most recent prescriptions

4. Get Latest Vital Signs
   SELECT * FROM vital_signs
   WHERE patientId = 1
   ORDER BY recordedAt DESC
   LIMIT 1
   Result: Most recent vitals

5. Get Active Medical Records
   SELECT * FROM medical_records
   WHERE patientId = 1
   AND recordType IN ('psychiatric_assessment', 'lab_result')
   ORDER BY recordDate DESC
   LIMIT 3
   Result: Recent clinical records

6. Get Pending Follow-ups
   SELECT * FROM scheduled_follow_ups
   WHERE patientId = 1
   AND status = 'pending'
   ORDER BY scheduledDate ASC
   Result: Upcoming follow-ups

7. Get Treatment Outcomes
   SELECT * FROM treatment_outcomes
   WHERE patientId = 1
   ORDER BY createdAt DESC
   LIMIT 3
   Result: Recent treatment responses

UI DISPLAY:
┌─────────────────────────────────────┐
│ Muhammad Ahmed Khan                 │
│ DOB: 1985-03-15 | Age: 40           │
│ Risk Level: ⚠️  High (3/5)          │
│ Allergies: Penicillin ⚠️            │
├─────────────────────────────────────┤
│ VITALS (Latest)                     │
│ BP: 138/88 | HR: 78 | Wt: 82.5kg   │
├─────────────────────────────────────┤
│ UPCOMING (5 appointments)           │
│ Dec 15: Diabetes Follow-up          │
│ Dec 22: Lab Review                  │
│ ...                                 │
├─────────────────────────────────────┤
│ ACTIVE (3 prescriptions)            │
│ • Metformin 500mg (2x daily)        │
│ • Lisinopril 10mg (1x daily)        │
│ • Atorvastatin 20mg (1x daily)      │
├─────────────────────────────────────┤
│ FOLLOW-UPS (2 pending)              │
│ ⏰ Dec 30: Recheck glucose (from Rx)│
│ ⏰ Jan 5: Recheck BP (from appt)    │
└─────────────────────────────────────┘
```

---

## 🔐 DATA INTEGRITY VERIFICATION CHAIN

```
Data Entry
    ↓
[Type Checking via Dart]
    ↓
Model.toJson() 
    ├─ Validate required fields
    ├─ Serialize complex types
    └─ Null safety checks
    ↓
Drift ORM
    ├─ Column type validation
    ├─ Foreign key constraint
    ├─ Not-null constraint
    └─ Default value application
    ↓
Platform DB (SQLite/IndexedDB)
    ├─ Transaction wrapping
    ├─ ACID compliance
    └─ Constraint enforcement
    ↓
Data Retrieval
    ├─ Deserialization
    ├─ Type conversion
    └─ Null coalescing
    ↓
Model.fromJson()
    ├─ Field mapping
    ├─ Type casting
    └─ Null safety
    ↓
UI Display
    ├─ Consumer Widget binding
    ├─ State management
    └─ Real-time updates
```

---

## 🎯 KEY VERIFICATION POINTS

✅ **Database Initialization**
- doctorDbProvider creates single instance
- seedSampleData called on first launch
- Proper lifecycle cleanup on app close

✅ **Data Flow**
- Models ↔ Database (bidirectional sync)
- Services use DB queries
- UI watches providers for real-time updates

✅ **Foreign Keys**
- All relationships defined at schema level
- Cascade delete configured
- Orphaned records impossible

✅ **Safety Features**
- Allergy checking before prescriptions
- Drug interaction warnings
- Vital signs trend analysis
- Risk level assessment

✅ **Performance**
- Indexed queries (FK fields)
- Limit-based pagination
- Latest record optimization
- Date range queries optimized

---

**Status: ✅ ALL CONNECTIONS VERIFIED**  
**Integrity: ✅ COMPLETE AND OPERATIONAL**
