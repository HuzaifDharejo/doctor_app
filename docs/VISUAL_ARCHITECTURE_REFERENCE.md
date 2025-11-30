# 📊 VISUAL ARCHITECTURE & FEATURE REFERENCE
## Doctor App Phase 2 - Complete System Overview

**Date**: November 30, 2024

---

## 🏗️ SYSTEM ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────┐
│                        DOCTOR APP V2.0                       │
├─────────────────────────────────────────────────────────────┤
│                        UI SCREENS                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Patient View            Clinical Dashboard                 │
│  ├─ Risk Summary Card    ├─ Critical Alerts                │
│  ├─ Allergy Display      ├─ Patient Stats                  │
│  ├─ Recent Meds          ├─ Today's Appointments           │
│  └─ Vital Signs          └─ Pending Invoices               │
│                                                              │
│  Prescription Screen     Vital Signs Screen                 │
│  ├─ Allergy Check        ├─ Abnormality Alerts            │
│  ├─ Drug Interaction     ├─ Threshold Warnings            │
│  ├─ Warnings             └─ Trend Charts                   │
│  └─ Save with Checks                                        │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                      SERVICES LAYER                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Allergy Service         Drug Interaction Service           │
│  ├─ Check Contraindications    ├─ Check Interactions       │
│  ├─ Get Severity                ├─ Get Severity             │
│  ├─ Education                   └─ Recommendations          │
│  └─ Risk Level                                               │
│                                                              │
│  Vital Signs Service     Comprehensive Risk Service        │
│  ├─ Check Thresholds     ├─ Assess Patient                │
│  ├─ Abnormality Alert    ├─ Multi-Factor Analysis         │
│  ├─ Normal Ranges        ├─ Overall Risk Level            │
│  └─ Recommendations      └─ Critical Alerts Generation    │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                      DATABASE LAYER                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Patients ──────┬────────────→ Appointments                │
│                 │              ├─→ MedicalRecords          │
│                 │              └─→ Invoices                │
│                 │                                            │
│                 ├────────────→ Prescriptions               │
│                 │              ├─→ Diagnosis Context       │
│                 │              └─→ Vitals Context          │
│                 │                                            │
│                 ├────────────→ VitalSigns                  │
│                 │              └─→ Appointment Reference   │
│                 │                                            │
│                 ├────────────→ TreatmentSessions           │
│                 │              ├─→ Appointments            │
│                 │              └─→ MedicalRecords          │
│                 │                                            │
│                 ├────────────→ TreatmentOutcomes           │
│                 │              └─→ Effectiveness Tracking  │
│                 │                                            │
│                 ├────────────→ MedicationResponses         │
│                 │              └─→ Side Effects            │
│                 │                                            │
│                 └────────────→ TreatmentGoals              │
│                                └─→ Progress Tracking       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 ALLERGY CHECKING FLOW

```
┌─────────────────────────┐
│ Doctor Prescribes Drug  │
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ Get Patient Allergies              │
│ e.g., "Penicillin, Aspirin"        │
└────────────┬────────────────────────┘
             │
             ▼
┌─────────────────────────────────────┐
│ AllergyCheckingService              │
│ .checkDrugSafety()                  │
│                                     │
│ Lookup contraindications database   │
│ for "Penicillin"                    │
│                                     │
│ Check if Proposed Drug in list?     │
│ e.g., Amoxicillin in [amoxicillin, │
│        ampicillin, cephalexin...]   │
└────────────┬────────────────────────┘
             │
             ├─── YES ──────────────────┐
             │                          │
             ▼                          ▼
         MATCH            ┌─────────────────────────┐
                          │ Return AllergyCheckResult │
                          │ - hasConcern: true      │
                          │ - severity: SEVERE      │
                          │ - message: Risk of      │
                          │   anaphylaxis           │
                          │ - recommendation: Use   │
                          │   fluoroquinolone       │
                          └────────────┬────────────┘
                                       │
                                       ▼
                          ┌──────────────────────────┐
                          │ Show Warning Dialog      │
                          │                          │
                          │ ⚠️ ALLERGY ALERT         │
                          │ Patient allergic to:     │
                          │ Penicillin (SEVERE)      │
                          │                          │
                          │ Proposed: Amoxicillin    │
                          │ ❌ CONTRAINDICATED       │
                          │                          │
                          │ [Use Alternative] [Ack] │
                          └──────────────────────────┘
             │
             └─── NO ───────────────────┐
                                        │
                                        ▼
                          ┌──────────────────────────┐
                          │ Return AllergyCheckResult │
                          │ - hasConcern: false      │
                          │ - severity: NONE         │
                          │ - message: Drug appears  │
                          │   safe based on allergies│
                          └──────────────────────────┘
                                        │
                                        ▼
                          ┌──────────────────────────┐
                          │ Continue with Prescription│
                          │ Allow save without warning│
                          └──────────────────────────┘
```

---

## ⚙️ DRUG INTERACTION CHECKING FLOW

```
┌──────────────────────────────┐
│ Doctor Proposes New Drug     │
│ e.g., Sertraline (SSRI)      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Get Patient's Current Meds   │
│ e.g., Phenelzine (MAOI)      │
│       Lithium                │
│       Aspirin                │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ DrugInteractionService       │
│ .checkInteractions()         │
│                              │
│ For each current medication: │
│   Check if [drug1, drug2]    │
│   in interactions database   │
└──────────────┬───────────────┘
               │
         ┌─────┴──────┐
         │            │
         ▼            ▼
    MATCH      NO MATCH
     [1]         [2]
     │           │
     ▼           ▼
  ┌────────────────────────────┐
  │ DrugInteraction Found:     │
  │ - drug1: SSRI              │
  │ - drug2: MAOI              │
  │ - severity: SEVERE         │
  │ - description: Risk of     │
  │   serotonin syndrome       │
  │ - recommendation: Wait 14  │
  │   days after MAOI          │
  └────────┬───────────────────┘
           │
           ▼
  ┌────────────────────────────┐
  │ Show Interaction Dialog    │
  │                            │
  │ ⚠️ DRUG INTERACTION ALERT  │
  │ SSRI + MAOI (SEVERE)       │
  │                            │
  │ Risk: Serotonin Syndrome   │
  │ Recommendation: Wait 14 d  │
  │                            │
  │ [Review] [Acknowledge]     │
  └────────────────────────────┘
           │
           ▼
  ┌────────────────────────────┐
  │ Doctor Makes Decision      │
  │ ✓ Use Alternative          │
  │ ✓ Acknowledge & Continue   │
  └────────────────────────────┘

[2] No match with other meds
    → Continue checking others
    → If all safe → Allow prescription
```

---

## 🎯 RISK ASSESSMENT FLOW

```
┌─────────────────────────────┐
│ User Views Patient          │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ ComprehensiveRiskAssessmentService      │
│ .assessPatient()                        │
│                                         │
│ Load:                                   │
│  - Patient info (allergies, history)   │
│  - Recent vital signs (10 entries)      │
│  - Active prescriptions                 │
│  - Recent appointments (20 entries)     │
│  - Medical assessments (10 entries)     │
└────────────┬────────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────┐
│ Run 6 Risk Assessments in Parallel:     │
│                                          │
│  [1] Allergy Risks                      │
│       └─ Check allergies in DB          │
│                                          │
│  [2] Drug Interaction Risks             │
│       └─ Check all med combinations     │
│                                          │
│  [3] Vital Signs Risks                  │
│       └─ Compare to thresholds          │
│       └─ BP, HR, O2, Temp, etc         │
│                                          │
│  [4] Clinical Risks                     │
│       └─ Check for high-risk diagnoses  │
│       └─ Suicidal/homicidal ideation    │
│                                          │
│  [5] Appointment Compliance             │
│       └─ Count no-shows & cancellations │
│                                          │
│  [6] Medication Adherence               │
│       └─ Track adherence patterns       │
│                                          │
└────────────┬───────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────┐
│ Aggregate Risk Factors                  │
│                                          │
│ Example Result:                          │
│  - Critical: 2 factors                  │
│    ├─ Suicidal ideation                │
│    └─ Low O2 saturation (85%)           │
│                                          │
│  - High: 3 factors                      │
│    ├─ SSRI + MAOI interaction          │
│    ├─ Penicillin allergy                │
│    └─ 3 no-show appointments            │
│                                          │
│  - Medium: 1 factor                     │
│    └─ High blood pressure               │
└────────────┬───────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────┐
│ Calculate Overall Risk Level:           │
│                                          │
│ IF critical risk exists                 │
│   ├─ Overall = CRITICAL 🔴              │
│   └─ requiresFollowUp = TRUE            │
│                                          │
│ ELSE IF high risk exists                │
│   ├─ Overall = HIGH 🟠                  │
│   └─ requiresFollowUp = TRUE            │
│                                          │
│ ELSE IF medium risk exists              │
│   ├─ Overall = MEDIUM 🟡               │
│   └─ requiresFollowUp = FALSE           │
│                                          │
│ ELSE                                    │
│   ├─ Overall = LOW 🟢                   │
│   └─ requiresFollowUp = FALSE           │
└────────────┬───────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────┐
│ Return ComprehensiveRiskAssessment      │
│                                          │
│ Contains:                                │
│  - patient: Patient object              │
│  - overallRiskLevel: RiskLevel.CRITICAL │
│  - riskFactors: List<RiskFactor>        │
│  - criticalAlerts: [Alert strings]      │
│  - followUpRequired: true                │
└────────────┬───────────────────────────┘
             │
             ▼
┌──────────────────────────────────────────┐
│ Display on UI                           │
│                                          │
│ ┌─ RiskSummaryCard ────────────────┐   │
│ │ Risk Assessment: CRITICAL 🔴     │   │
│ │ 🔴 Critical: 2  🟠 High: 3       │   │
│ │ Follow-up appointment required   │   │
│ └──────────────────────────────────┘   │
│                                          │
│ ┌─ CriticalAlertsWidget ───────────┐   │
│ │ 🔴 CRITICAL ALERTS (2)           │   │
│ │                                  │   │
│ │ Active suicidal ideation         │   │
│ │ reported                         │   │
│ │                                  │   │
│ │ • Immediate safety assessment   │   │
│ │ • Consider hospitalization      │   │
│ │ • Contact emergency services    │   │
│ │                                  │   │
│ │ Low oxygen saturation: 85%       │   │
│ │ • Assess respiratory status     │   │
│ │ • Consider oxygen therapy       │   │
│ └──────────────────────────────────┘   │
│                                          │
│ [Tap for detailed view...]              │
└──────────────────────────────────────────┘
```

---

## 📈 VITAL SIGNS MONITORING THRESHOLDS

```
┌─────────────────────────────────────────┐
│         BLOOD PRESSURE (mmHg)            │
├─────────────────────────────────────────┤
│ <120/<80        🟢 Normal               │
│ 120-139/80-89   🟡 Elevated            │
│ 140-159/90-99   🟠 Stage 1 HTN         │
│ 160-179/100-119 🟠 Stage 2 HTN         │
│ ≥180/≥120       🔴 Crisis (ALERT)     │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│         HEART RATE (bpm)                │
├─────────────────────────────────────────┤
│ 60-100          🟢 Normal               │
│ 101-120         🟡 Elevated             │
│ >120            🟠 Tachycardia (ALERT) │
│ 50-59           🟡 Slightly Low        │
│ <50             🟠 Bradycardia (ALERT) │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│      OXYGEN SATURATION (SpO2)            │
├─────────────────────────────────────────┤
│ >95%            🟢 Normal               │
│ 90-95%          🟡 Mild Hypoxemia      │
│ 85-90%          🟠 Moderate (ALERT)    │
│ <85%            🔴 Critical (ALERT)    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│      TEMPERATURE (Celsius)               │
├─────────────────────────────────────────┤
│ 36.5-37.5       🟢 Normal               │
│ 37.6-38.0       🟡 Low Fever           │
│ 38.1-39.0       🟠 Fever (ALERT)       │
│ >39.0           🟠 High Fever (ALERT)  │
│ <36.5           🟡 Hypothermia         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│   RESPIRATORY RATE (breaths/min)         │
├─────────────────────────────────────────┤
│ 12-20           🟢 Normal               │
│ 20-24           🟡 Elevated             │
│ >24             🟠 Tachypnea (ALERT)   │
│ <12             🟠 Bradypnea (ALERT)   │
└─────────────────────────────────────────┘
```

---

## 🎨 UI COMPONENT BREAKDOWN

```
┌─────────────────────────────────────────┐
│    CRITICAL ALERTS WIDGET               │
├─────────────────────────────────────────┤
│                                         │
│  🔴 CRITICAL ALERTS (2)     [×]        │
│  ───────────────────────────────────   │
│                                         │
│  • Active suicidal ideation            │
│    Last assessment: 2 days ago         │
│    [View Patient] [Contact]            │
│                                         │
│  • Low oxygen saturation: 85%          │
│    Recorded: Today 2:30 PM             │
│    [Assess] [Record New]               │
│                                         │
├─────────────────────────────────────────┤
│    RISK SUMMARY CARD                   │
├─────────────────────────────────────────┤
│                                         │
│  ┌─ Risk Assessment ────────────────┐  │
│  │ Level: CRITICAL 🔴              │  │
│  │                                 │  │
│  │ Critical: 2    High: 3          │  │
│  │                                 │  │
│  │ ⚠️ Follow-up appointment         │  │
│  │    is required                  │  │
│  └─────────────────────────────────┘  │
│                                         │
├─────────────────────────────────────────┤
│   RISK ASSESSMENT DETAIL (Modal)        │
├─────────────────────────────────────────┤
│                                         │
│  ⚠️ Risk Assessment: CRITICAL           │
│                                         │
│  📊 Risk Summary                        │
│  🔴 2 Critical   🟠 3 High   🟡 1 Med  │
│  ⚠️ Follow-up required                  │
│                                         │
│  ⚠️ Allergy Risks (1)                  │
│  ───────────────────────────────────  │
│  [HIGH] Patient has Penicillin allergy │
│  • Review prescriptions against list   │
│  • Ensure medical alert available      │
│                                         │
│  💊 Drug Interactions (1)               │
│  ───────────────────────────────────  │
│  [CRITICAL] SSRI + MAOI                │
│  • Risk of serotonin syndrome          │
│  • Recommendation: Use alternative     │
│                                         │
│  ❤️ Vital Signs (2)                    │
│  ───────────────────────────────────  │
│  [CRITICAL] Low O2: 85%                │
│  • Assess respiratory status           │
│  • Consider oxygen therapy             │
│                                         │
│  [CRITICAL] High BP: 180/120           │
│  • Contact patient immediately         │
│  • Consider emergency referral         │
│                                         │
│  🏥 Clinical Risks (1)                 │
│  ───────────────────────────────────  │
│  [CRITICAL] Suicidal ideation          │
│  • Immediate safety assessment         │
│  • Consider hospitalization            │
│  • Contact emergency services          │
│                                         │
│  📅 Appointment Issues (0)              │
│  ───────────────────────────────────  │
│  No appointment compliance issues      │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📊 RISK LEVEL COLOR SCHEME

```
🔴 CRITICAL
   Color: #C62828 (Red)
   Action: Immediate intervention
   Example: Suicidal ideation, critical vitals
   
🟠 HIGH  
   Color: #F57C00 (Orange)
   Action: Action needed soon
   Example: Drug interaction, high BP, allergy
   
🟡 MEDIUM
   Color: #FFB74D (Amber)
   Action: Monitor and review
   Example: Elevated vitals, compliance issue
   
🟢 LOW
   Color: #4CAF50 (Green)
   Action: Standard care
   Example: Minor risk factors
   
⚪ NONE
   Color: #2E7D32 (Dark Green)
   Action: No special monitoring
   Example: All green indicators
```

---

## 🔍 DATABASE RELATIONSHIP MAP

```
Patients (PK: id)
├── Appointments (FK: patientId, medicalRecordId)
│   ├── MedicalRecords ←(link)
│   ├── Prescriptions (FK: appointmentId)
│   ├── TreatmentSessions (FK: appointmentId)
│   ├── VitalSigns (FK: recordedByAppointmentId)
│   └── Invoices (FK: appointmentId)
│
├── Prescriptions (FK: patientId, appointmentId, medicalRecordId)
│   ├── Diagnosis context (stored)
│   ├── Chief complaint (stored)
│   ├── Vitals at prescription (stored as JSON)
│   └── Invoices (FK: prescriptionId)
│
├── MedicalRecords (FK: patientId)
│   ├── Appointments ←(backref)
│   ├── Prescriptions ←(backref)
│   └── TreatmentSessions ←(backref)
│
├── VitalSigns (FK: patientId)
│   ├── Appointments ←(recordedByAppointmentId)
│   └── Risk assessment data
│
├── TreatmentSessions (FK: patientId, appointmentId, medicalRecordId)
│   ├── Therapy notes
│   ├── Interventions
│   ├── Progress tracking
│   └── Invoices (FK: treatmentSessionId)
│
├── TreatmentOutcomes (FK: patientId)
│   ├── Treatment effectiveness
│   ├── Side effects
│   ├── MedicationResponses
│   └── TreatmentGoals
│
├── MedicationResponses (FK: patientId, prescriptionId)
│   ├── Effectiveness tracking
│   ├── Side effect monitoring
│   └── Adherence tracking
│
└── TreatmentGoals (FK: patientId, treatmentOutcomeId)
    ├── Progress monitoring
    └── Goal achievement tracking

Invoices (FK: patientId, appointmentId, prescriptionId, treatmentSessionId)
└── Links billing to all clinical activities
```

---

## ✅ INTEGRATION CHECKLIST

```
PRESCRIPTION SCREEN
├─ [ ] Import risk services
├─ [ ] Add allergy checking before save
├─ [ ] Show allergy warning dialog
├─ [ ] Add drug interaction checking
├─ [ ] Show interaction warning dialog
└─ [ ] Test with allergic patient

PATIENT VIEW SCREEN
├─ [ ] Import risk widgets
├─ [ ] Add risk summary card
├─ [ ] Create _loadRiskAssessment() method
├─ [ ] Add detailed risk modal
├─ [ ] Show critical alerts section
└─ [ ] Test with high-risk patient

CLINICAL DASHBOARD
├─ [ ] Calculate alertRisks from all patients
├─ [ ] Display CriticalAlertsWidget
├─ [ ] Add navigation from alert to patient
├─ [ ] Add refresh handler
├─ [ ] Test alert display
└─ [ ] Test alert navigation

VITAL SIGNS SCREEN
├─ [ ] Add _assessVitalSignsRisks() method
├─ [ ] Display risk indicators on cards
├─ [ ] Show alerts for abnormal values
├─ [ ] Color-code by severity
├─ [ ] Test threshold alerts
└─ [ ] Test normal range display

TESTING
├─ [ ] Allergy warning on contraindicated drug
├─ [ ] Drug interaction warning
├─ [ ] Risk summary on patient view
├─ [ ] Critical alerts on dashboard
├─ [ ] Vital signs alerts display correctly
├─ [ ] Test on device (not just emulator)
├─ [ ] Test dark theme
├─ [ ] Test light theme
└─ [ ] Edge case testing

DEPLOYMENT
├─ [ ] Code review
├─ [ ] Final testing on real device
├─ [ ] Update user manual
├─ [ ] Deploy to production
└─ [ ] Monitor for issues
```

---

## 📞 SUPPORT MATRIX

| Feature | File | Contact | Status |
|---------|------|---------|--------|
| Allergy Service | allergy_checking_service.dart | Ready | ✅ Complete |
| Drug Interactions | drug_interaction_service.dart | Ready | ✅ Complete |
| Risk Assessment | comprehensive_risk_assessment_service.dart | Ready | ✅ Created |
| Risk Widgets | risk_assessment_widgets.dart | Ready | ✅ Created |
| Integration Guide | QUICK_INTEGRATION_GUIDE_ADVANCED.md | Ready | ✅ Written |
| Implementation Guide | IMPLEMENTATION_GUIDE_PHASE2.md | Ready | ✅ Written |
| Database Schema | doctor_db.dart v4 | Ready | ✅ Complete |

---

**Status**: ✅ All components created and documented  
**Next**: Integration into UI screens (2-3 hours)  
**Support**: Refer to guides for copy-paste code examples
