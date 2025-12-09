import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart' hide Column;

import '../db/doctor_db.dart';
import 'logger_service.dart';

/// Seed sample data into the database for testing and demo purposes.
/// This version checks if data exists first and skips if not empty.
Future<void> seedSampleData(DoctorDatabase db) async {
  // Check if patients already exist to avoid duplicates
  final existingPatients = await db.getAllPatients();
  if (existingPatients.isNotEmpty) {
    return; // Data already seeded
  }

  await _insertSampleData(db);
}

/// Force seed sample data - always adds data regardless of existing records.
/// Use this for demo/testing purposes when user explicitly requests it.
/// Clears ALL existing data first.
Future<void> seedSampleDataForce(DoctorDatabase db) async {
  log.i('SEED', '═══════════════════════════════════════════════════════════');
  log.i('SEED', '  CLEARING ALL EXISTING DATA...');
  log.i('SEED', '═══════════════════════════════════════════════════════════');
  
  // Clear all data in proper order (child tables first due to foreign keys)
  await (db.delete(db.clinicalNotes)).go();
  await (db.delete(db.encounterDiagnoses)).go();
  await (db.delete(db.diagnoses)).go();
  await (db.delete(db.encounters)).go();
  await (db.delete(db.treatmentGoals)).go();
  await (db.delete(db.medicationResponses)).go();
  await (db.delete(db.treatmentSessions)).go();
  await (db.delete(db.treatmentOutcomes)).go();
  await (db.delete(db.scheduledFollowUps)).go();
  await (db.delete(db.auditLogs)).go();
  await (db.delete(db.vitalSigns)).go();
  await (db.delete(db.medicalRecords)).go();
  await (db.delete(db.prescriptions)).go();
  await (db.delete(db.invoices)).go();
  await (db.delete(db.appointments)).go();
  await (db.delete(db.patients)).go();
  
  log.i('SEED', '  ✓ All existing data cleared');
  log.i('SEED', '');
  
  await _insertSampleData(db);
}

/// Insert clean sample data for a single-doctor clinic
Future<void> _insertSampleData(DoctorDatabase db) async {
  log.i('SEED', 'Seeding database with sample data...');
  final random = Random();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // ============================================================================
  // PATIENTS - 20 diverse patients for a general practice clinic
  // ============================================================================
  final patients = [
    // Chronic Disease Management
    _PatientData('Muhammad', 'Ahmed', 58, 'Male', 'O+', '0300-1234567', 'ahmed@email.com', 'House 45, F-10, Islamabad', 'Type 2 Diabetes, Hypertension', 'Penicillin', 'Diabetes,Hypertension', 4),
    _PatientData('Fatima', 'Bibi', 52, 'Female', 'A+', '0321-2345678', 'fatima@email.com', '123 Gulberg III, Lahore', 'Hypothyroidism, Osteoporosis', '', 'Thyroid,Osteoporosis', 2),
    _PatientData('Ali', 'Raza', 65, 'Male', 'B+', '0333-3456789', 'ali.raza@email.com', 'DHA Phase 5, Karachi', 'Coronary Artery Disease, Hyperlipidemia', 'Aspirin', 'CAD,Hyperlipidemia', 5),
    
    // Mental Health
    _PatientData('Ayesha', 'Khan', 34, 'Female', 'AB+', '0345-4567890', 'ayesha@email.com', '78 Model Town, Lahore', 'Generalized Anxiety Disorder', '', 'Anxiety', 3),
    _PatientData('Hassan', 'Malik', 42, 'Male', 'A-', '0302-5678901', 'hassan@email.com', 'G-9, Islamabad', 'Major Depressive Disorder', 'Sulfa drugs', 'Depression', 3),
    
    // Respiratory
    _PatientData('Zainab', 'Hussain', 28, 'Female', 'O-', '0311-6789012', 'zainab@email.com', 'Satellite Town, Rawalpindi', 'Asthma', 'Dust, Pollen', 'Asthma', 2),
    _PatientData('Usman', 'Tariq', 55, 'Male', 'B-', '0322-7890123', 'usman@email.com', 'Bahria Town, Islamabad', 'COPD', 'NSAIDs', 'COPD', 4),
    
    // General Practice
    _PatientData('Maryam', 'Nawaz', 30, 'Female', 'A+', '0334-8901234', 'maryam@email.com', 'Johar Town, Lahore', 'PCOS, Iron Deficiency Anemia', '', 'PCOS,Anemia', 2),
    _PatientData('Bilal', 'Ashraf', 45, 'Male', 'O+', '0301-9012345', 'bilal@email.com', 'G-11, Islamabad', 'Chronic Back Pain', 'Tramadol', 'Back Pain', 2),
    _PatientData('Sana', 'Javed', 25, 'Female', 'AB-', '0312-0123456', 'sana@email.com', 'Gulshan, Karachi', 'Migraine', '', 'Migraine', 2),
    
    // Pediatric (parents bring children)
    _PatientData('Ahmed', 'Junior', 8, 'Male', 'B+', '0323-1234567', 'parent@email.com', 'F-8, Islamabad', 'Childhood Asthma, Allergies', 'Eggs', 'Asthma,Allergies', 2),
    _PatientData('Sara', 'Khan', 12, 'Female', 'A+', '0335-2345678', 'sara.parent@email.com', 'DHA Lahore', 'ADHD', '', 'ADHD', 2),
    
    // Elderly Care
    _PatientData('Amjad', 'Hussain', 72, 'Male', 'O+', '0303-3456789', 'amjad@email.com', 'Gulberg II, Lahore', 'Parkinson\'s Disease, Benign Prostatic Hyperplasia', 'Levodopa', 'Parkinson,BPH', 4),
    _PatientData('Nasreen', 'Begum', 68, 'Female', 'A-', '0313-4567890', 'nasreen@email.com', 'E-11, Islamabad', 'Rheumatoid Arthritis, Hypertension', 'Methotrexate', 'Arthritis,Hypertension', 3),
    
    // New/Acute Patients
    _PatientData('Farhan', 'Ahmed', 35, 'Male', 'B+', '0324-5678901', 'farhan@email.com', 'Clifton, Karachi', 'None - New patient', '', '', 1),
    _PatientData('Hira', 'Qureshi', 29, 'Female', 'O-', '0336-6789012', 'hira@email.com', 'Garden Town, Lahore', 'None - New patient', '', '', 1),
    
    // Follow-up Patients
    _PatientData('Imran', 'Shah', 48, 'Male', 'AB+', '0304-7890123', 'imran@email.com', 'Cantt, Peshawar', 'Peptic Ulcer Disease', 'Omeprazole', 'PUD', 2),
    _PatientData('Rabia', 'Butt', 38, 'Female', 'A+', '0314-8901234', 'rabia@email.com', 'Bahria Town, Rawalpindi', 'Epilepsy', '', 'Epilepsy', 3),
    
    // Sports/Active Patients
    _PatientData('Kamran', 'Akmal', 32, 'Male', 'O+', '0325-9012345', 'kamran@email.com', 'DHA Phase 2, Lahore', 'Sports Injury - Knee', '', '', 1),
    _PatientData('Nadia', 'Ali', 27, 'Female', 'B-', '0337-0123456', 'nadia@email.com', 'F-7, Islamabad', 'Muscle strain', '', '', 1),
  ];

  final patientIds = <int>[];
  for (final p in patients) {
    final id = await db.insertPatient(
      PatientsCompanion(
        firstName: Value(p.firstName),
        lastName: Value(p.lastName),
        age: Value(p.age),
        gender: Value(p.gender),
        bloodType: Value(p.bloodType),
        phone: Value(p.phone),
        email: Value(p.email),
        address: Value(p.address),
        medicalHistory: Value(p.medicalHistory),
        allergies: Value(p.allergies),
        chronicConditions: Value(p.chronicConditions),
        riskLevel: Value(p.riskLevel),
        tags: Value(p.riskLevel >= 4 ? 'priority' : (p.riskLevel == 1 ? 'new' : 'regular')),
        createdAt: Value(today.subtract(Duration(days: random.nextInt(365)))),
      ),
    );
    patientIds.add(id);
  }
  log.i('SEED', '✓ Inserted ${patientIds.length} patients');

  // ============================================================================
  // APPOINTMENTS - Realistic clinic schedule
  // ============================================================================
  final reasons = [
    'Regular checkup', 'Follow-up consultation', 'Medication review',
    'Blood pressure monitoring', 'Lab results discussion', 'New symptoms',
    'Prescription refill', 'Annual physical exam', 'Diabetes management',
    'Mental health session', 'Respiratory therapy', 'Pain management',
  ];

  int appointmentCount = 0;

  // Past appointments (last 30 days)
  for (int dayOffset = 30; dayOffset > 0; dayOffset--) {
    // Skip Sundays
    final date = today.subtract(Duration(days: dayOffset));
    if (date.weekday == DateTime.sunday) continue;
    
    // Saturday has fewer appointments
    final maxAppts = date.weekday == DateTime.saturday ? 6 : 10;
    final numAppts = 4 + random.nextInt(maxAppts - 4);
    
    for (int i = 0; i < numAppts; i++) {
      final patientIdx = random.nextInt(patientIds.length);
      final hour = 9 + random.nextInt(8); // 9 AM to 5 PM
      final minute = [0, 15, 30, 45][random.nextInt(4)];
      
      await db.insertAppointment(
        AppointmentsCompanion(
          patientId: Value(patientIds[patientIdx]),
          appointmentDateTime: Value(date.add(Duration(hours: hour, minutes: minute))),
          durationMinutes: Value([15, 20, 30][random.nextInt(3)]),
          reason: Value(reasons[random.nextInt(reasons.length)]),
          status: Value(random.nextInt(10) < 8 ? 'completed' : (random.nextBool() ? 'cancelled' : 'no-show')),
          notes: Value('Visit notes for ${patients[patientIdx].firstName}'),
          createdAt: Value(date.subtract(const Duration(days: 7))),
        ),
      );
      appointmentCount++;
    }
  }

  // Today's appointments
  final todayStatuses = ['completed', 'completed', 'completed', 'in-progress', 'checked-in', 'scheduled', 'scheduled', 'scheduled'];
  for (int i = 0; i < 8; i++) {
    final patientIdx = i % patientIds.length;
    final hour = 9 + i;
    
    await db.insertAppointment(
      AppointmentsCompanion(
        patientId: Value(patientIds[patientIdx]),
        appointmentDateTime: Value(today.add(Duration(hours: hour))),
        durationMinutes: Value(30),
        reason: Value(reasons[i % reasons.length]),
        status: Value(todayStatuses[i]),
        notes: Value('Today\'s appointment for ${patients[patientIdx].firstName}'),
        createdAt: Value(today.subtract(const Duration(days: 3))),
      ),
    );
    appointmentCount++;
  }

  // Future appointments (next 14 days)
  for (int dayOffset = 1; dayOffset <= 14; dayOffset++) {
    final date = today.add(Duration(days: dayOffset));
    if (date.weekday == DateTime.sunday) continue;
    
    final maxAppts = date.weekday == DateTime.saturday ? 5 : 8;
    final numAppts = 3 + random.nextInt(maxAppts - 3);
    
    for (int i = 0; i < numAppts; i++) {
      final patientIdx = random.nextInt(patientIds.length);
      final hour = 9 + random.nextInt(8);
      final minute = [0, 15, 30, 45][random.nextInt(4)];
      
      await db.insertAppointment(
        AppointmentsCompanion(
          patientId: Value(patientIds[patientIdx]),
          appointmentDateTime: Value(date.add(Duration(hours: hour, minutes: minute))),
          durationMinutes: Value([15, 20, 30][random.nextInt(3)]),
          reason: Value(reasons[random.nextInt(reasons.length)]),
          status: Value('scheduled'),
          reminderAt: Value(date.subtract(const Duration(hours: 24))),
          notes: Value('Upcoming appointment'),
          createdAt: Value(today),
        ),
      );
      appointmentCount++;
    }
  }
  log.i('SEED', '✓ Inserted $appointmentCount appointments');

  // ============================================================================
  // PRESCRIPTIONS - Common medications
  // ============================================================================
  final prescriptionData = [
    // Diabetes patient
    _PrescriptionData(0, [
      _MedData('Metformin', '500mg', 'Twice daily with meals', '90 tablets'),
      _MedData('Lisinopril', '10mg', 'Once daily morning', '30 tablets'),
      _MedData('Atorvastatin', '20mg', 'Once daily at bedtime', '30 tablets'),
    ], 'Monitor blood sugar before meals. Follow diabetic diet.'),
    
    // Thyroid patient
    _PrescriptionData(1, [
      _MedData('Levothyroxine', '50mcg', 'Once daily on empty stomach', '30 tablets'),
      _MedData('Calcium + Vitamin D', '500mg/400IU', 'Twice daily with meals', '60 tablets'),
    ], 'Take thyroid medication 1 hour before breakfast.'),
    
    // Cardiac patient
    _PrescriptionData(2, [
      _MedData('Aspirin', '75mg', 'Once daily after lunch', '30 tablets'),
      _MedData('Clopidogrel', '75mg', 'Once daily', '30 tablets'),
      _MedData('Rosuvastatin', '10mg', 'Once daily at bedtime', '30 tablets'),
      _MedData('Metoprolol', '25mg', 'Twice daily', '60 tablets'),
    ], 'Do not stop medications without consulting. Report any bleeding.'),
    
    // Anxiety patient
    _PrescriptionData(3, [
      _MedData('Escitalopram', '10mg', 'Once daily morning', '30 tablets'),
      _MedData('Alprazolam', '0.5mg', 'As needed for anxiety (max 2/day)', '20 tablets'),
    ], 'Avoid alcohol. May cause drowsiness initially.'),
    
    // Depression patient
    _PrescriptionData(4, [
      _MedData('Sertraline', '50mg', 'Once daily morning', '30 tablets'),
      _MedData('Mirtazapine', '15mg', 'At bedtime', '30 tablets'),
    ], 'May take 2-4 weeks to see full effect. Don\'t stop abruptly.'),
    
    // Asthma patient
    _PrescriptionData(5, [
      _MedData('Salbutamol Inhaler', '100mcg', '2 puffs as needed', '200 doses'),
      _MedData('Fluticasone Inhaler', '250mcg', '2 puffs twice daily', '120 doses'),
      _MedData('Montelukast', '10mg', 'Once daily at bedtime', '30 tablets'),
    ], 'Rinse mouth after using Fluticasone. Carry rescue inhaler always.'),
    
    // COPD patient
    _PrescriptionData(6, [
      _MedData('Tiotropium Inhaler', '18mcg', 'Once daily morning', '30 capsules'),
      _MedData('Formoterol + Budesonide', '12/400mcg', 'Twice daily', '60 doses'),
    ], 'Use Tiotropium first, then combination inhaler.'),
    
    // PCOS patient
    _PrescriptionData(7, [
      _MedData('Metformin', '500mg', 'Twice daily', '60 tablets'),
      _MedData('Ferrous Sulfate', '200mg', 'Once daily', '30 tablets'),
      _MedData('Folic Acid', '5mg', 'Once daily', '30 tablets'),
    ], 'Take iron with vitamin C for better absorption.'),
    
    // Back pain patient
    _PrescriptionData(8, [
      _MedData('Naproxen', '500mg', 'Twice daily with food', '20 tablets'),
      _MedData('Cyclobenzaprine', '10mg', 'At bedtime', '14 tablets'),
    ], 'Apply heat. Avoid lifting heavy objects. Start physiotherapy.'),
    
    // Migraine patient
    _PrescriptionData(9, [
      _MedData('Sumatriptan', '50mg', 'At onset of migraine', '12 tablets'),
      _MedData('Propranolol', '40mg', 'Once daily for prevention', '30 tablets'),
    ], 'Take Sumatriptan at first sign of headache. Max 2 doses per day.'),
  ];

  int prescriptionCount = 0;
  for (final rx in prescriptionData) {
    final medsJson = jsonEncode(rx.medications.map((m) => {
      'name': m.name,
      'dosage': m.dosage,
      'frequency': m.frequency,
      'duration': m.duration,
    }).toList());
    
    await db.insertPrescription(
      PrescriptionsCompanion(
        patientId: Value(patientIds[rx.patientIndex]),
        itemsJson: Value(medsJson),
        instructions: Value(rx.instructions),
        isRefillable: Value(true),
        createdAt: Value(today.subtract(Duration(days: random.nextInt(30)))),
      ),
    );
    prescriptionCount++;
  }
  log.i('SEED', '✓ Inserted $prescriptionCount prescriptions');

  // ============================================================================
  // MEDICAL RECORDS - Clinical documentation
  // ============================================================================
  final recordsData = [
    _RecordData(0, 'general', 'Diabetes Follow-up', 
      'Routine diabetes checkup and medication adjustment',
      'Type 2 Diabetes Mellitus - Well Controlled (E11.9)',
      'Continue current regimen. Increase Metformin to 500mg TID.',
      'HbA1c: 6.8% (improved from 7.2%). Fasting glucose: 126 mg/dL. Patient compliant with diet and exercise. No hypoglycemic episodes.'),
    
    _RecordData(2, 'general', 'Cardiac Evaluation',
      'Annual cardiac assessment post-stent placement',
      'Coronary Artery Disease - Stable (I25.10)',
      'Continue dual antiplatelet therapy. Cardiac rehab recommended.',
      'ECG: Normal sinus rhythm. No chest pain or dyspnea. Stress test negative. Ejection fraction 55%.'),
    
    _RecordData(3, 'psychiatric_assessment', 'Anxiety Assessment',
      'Follow-up for Generalized Anxiety Disorder',
      'Generalized Anxiety Disorder - Moderate (F41.1)',
      'Continue Escitalopram. CBT sessions recommended.',
      'GAD-7 Score: 12 (moderate). Sleep improved. Fewer panic episodes. PHQ-9: 6 (mild depression symptoms).'),
    
    _RecordData(4, 'psychiatric_assessment', 'Depression Follow-up',
      'Monthly mental health evaluation',
      'Major Depressive Disorder - In Partial Remission (F32.4)',
      'Continue current medications. Monthly follow-up.',
      'PHQ-9 Score: 8 (mild). Patient reports improved mood, better sleep. No suicidal ideation. Appetite improved.'),
    
    _RecordData(5, 'pulmonary_evaluation', 'Asthma Control Assessment',
      'Pulmonary function test and medication review',
      'Moderate Persistent Asthma - Partially Controlled (J45.40)',
      'Step up controller therapy. Add LABA.',
      'FEV1: 78% predicted. Peak flow variability 18%. Using rescue inhaler 3x/week. Night symptoms 2x/month.'),
    
    _RecordData(6, 'pulmonary_evaluation', 'COPD Management',
      'Comprehensive COPD evaluation with spirometry',
      'COPD - GOLD Stage II (J44.1)',
      'Continue triple inhaler therapy. Pulmonary rehabilitation.',
      'FEV1: 58% predicted. FEV1/FVC: 0.62. O2 sat: 94% on room air. 6-minute walk: 380 meters.'),
    
    _RecordData(9, 'general', 'Migraine Evaluation',
      'Assessment of migraine frequency and triggers',
      'Migraine without Aura - Frequent (G43.909)',
      'Start prophylactic Propranolol. Continue rescue medication.',
      'Headache diary review: 6 migraines/month. Triggers identified: stress, sleep deprivation, skipping meals. MIDAS score: 21.'),
    
    _RecordData(12, 'general', 'Parkinson\'s Disease Follow-up',
      'Neurological assessment and medication adjustment',
      'Parkinson\'s Disease - Moderate Stage (G20)',
      'Increase Levodopa. Add Pramipexole for motor fluctuations.',
      'UPDRS Motor Score: 28. Mild tremor bilateral. Gait stable with walker. No dyskinesias. Cognition intact.'),
    
    _RecordData(8, 'general', 'Back Pain Assessment',
      'Evaluation of chronic low back pain',
      'Chronic Low Back Pain - Lumbar Region (M54.5)',
      'NSAIDs course. Physiotherapy referral.',
      'Pain score: 6/10. No radicular symptoms. Lumbar ROM limited. SLR negative bilaterally. MRI shows L4-L5 disc bulge.'),
    
    _RecordData(17, 'general', 'Epilepsy Follow-up',
      'Seizure control assessment',
      'Epilepsy - Well Controlled (G40.909)',
      'Continue current anticonvulsant. Annual EEG.',
      'Seizure-free for 8 months. Medication levels therapeutic. No side effects reported. Driving restriction discussed.'),
  ];

  int recordCount = 0;
  for (final r in recordsData) {
    await db.insertMedicalRecord(
      MedicalRecordsCompanion(
        patientId: Value(patientIds[r.patientIndex]),
        recordType: Value(r.recordType),
        title: Value(r.title),
        description: Value(r.description),
        diagnosis: Value(r.diagnosis),
        treatment: Value(r.treatment),
        doctorNotes: Value(r.doctorNotes),
        recordDate: Value(today.subtract(Duration(days: random.nextInt(60)))),
        createdAt: Value(today.subtract(Duration(days: random.nextInt(60)))),
      ),
    );
    recordCount++;
  }
  log.i('SEED', '✓ Inserted $recordCount medical records');

  // ============================================================================
  // INVOICES - Billing records
  // ============================================================================
  final invoiceData = [
    _InvoiceData(0, [
      _InvoiceItem('Consultation Fee', 2000),
      _InvoiceItem('HbA1c Test', 1500),
      _InvoiceItem('Lipid Profile', 1200),
    ], 'Paid', 'Cash', 0, null),
    
    _InvoiceData(2, [
      _InvoiceItem('Cardiac Consultation', 3500),
      _InvoiceItem('ECG', 800),
      _InvoiceItem('Echo Review', 500),
    ], 'Paid', 'Card', 0, null),
    
    _InvoiceData(3, [
      _InvoiceItem('Psychiatric Consultation', 3000),
    ], 'Paid', 'Online', 10, null),
    
    _InvoiceData(5, [
      _InvoiceItem('Consultation Fee', 2000),
      _InvoiceItem('Spirometry', 2500),
    ], 'Paid', 'Cash', 0, null),
    
    _InvoiceData(6, [
      _InvoiceItem('Pulmonary Consultation', 3000),
      _InvoiceItem('Spirometry', 2500),
      _InvoiceItem('Pulse Oximetry', 300),
    ], 'Partial', 'Cash', 0, 'Paid Rs. 3000, balance Rs. 2800 due'),
    
    _InvoiceData(8, [
      _InvoiceItem('Consultation Fee', 2000),
      _InvoiceItem('X-Ray Review', 500),
    ], 'Pending', 'Cash', 0, null),
    
    _InvoiceData(14, [
      _InvoiceItem('New Patient Consultation', 2500),
    ], 'Paid', 'UPI', 0, null),
    
    _InvoiceData(12, [
      _InvoiceItem('Geriatric Consultation', 3000),
      _InvoiceItem('Comprehensive Blood Work', 3500),
    ], 'Paid', 'Cash', 15, null),
  ];

  int invoiceCount = 0;
  int invoiceNum = 1001;
  for (final inv in invoiceData) {
    final subtotal = inv.items.fold<double>(0, (sum, item) => sum + item.amount);
    final discount = subtotal * inv.discountPercent / 100;
    final total = subtotal - discount;
    
    final itemsJson = jsonEncode(inv.items.map((i) => {
      'description': i.description,
      'quantity': 1,
      'unitPrice': i.amount,
    }).toList());
    
    await db.insertInvoice(
      InvoicesCompanion(
        patientId: Value(patientIds[inv.patientIndex]),
        invoiceNumber: Value('INV-${DateTime.now().year}-$invoiceNum'),
        itemsJson: Value(itemsJson),
        subtotal: Value(subtotal),
        discountPercent: Value(inv.discountPercent.toDouble()),
        discountAmount: Value(discount),
        taxPercent: const Value(0),
        taxAmount: const Value(0),
        grandTotal: Value(total),
        paymentStatus: Value(inv.status),
        paymentMethod: Value(inv.method),
        notes: Value(inv.notes ?? ''),
        invoiceDate: Value(today.subtract(Duration(days: random.nextInt(30)))),
        createdAt: Value(today.subtract(Duration(days: random.nextInt(30)))),
      ),
    );
    invoiceCount++;
    invoiceNum++;
  }
  log.i('SEED', '✓ Inserted $invoiceCount invoices');

  // ============================================================================
  // VITAL SIGNS - Recent measurements for all patients
  // ============================================================================
  final vitalData = [
    // Diabetic patient - slightly elevated BP
    _VitalData(0, 142, 88, 78, 36.8, 16, 82.5, 168, 29.2, 98),
    // Thyroid patient - normal
    _VitalData(1, 118, 76, 72, 36.6, 14, 68.0, 162, 25.9, 99),
    // Cardiac patient - controlled
    _VitalData(2, 128, 78, 64, 36.7, 15, 75.0, 170, 26.0, 97),
    // Anxiety patient - slightly elevated HR
    _VitalData(3, 122, 80, 88, 36.7, 16, 58.0, 160, 22.7, 99),
    // Depression patient - normal
    _VitalData(4, 120, 78, 70, 36.6, 14, 72.0, 172, 24.3, 98),
    // Asthma patient - good O2
    _VitalData(5, 116, 74, 68, 36.5, 18, 55.0, 158, 22.0, 98),
    // COPD patient - lower O2
    _VitalData(6, 138, 86, 82, 36.9, 20, 78.0, 168, 27.6, 94),
    // PCOS patient
    _VitalData(7, 124, 80, 76, 36.7, 15, 72.0, 165, 26.4, 99),
    // Back pain patient
    _VitalData(8, 130, 84, 74, 36.8, 15, 88.0, 175, 28.7, 98),
    // Migraine patient
    _VitalData(9, 118, 76, 72, 36.6, 14, 60.0, 162, 22.9, 99),
    // Pediatric - Ahmed Junior (child)
    _VitalData(10, 100, 65, 90, 36.8, 22, 28.0, 130, 16.6, 99),
    // Pediatric - Sara Khan
    _VitalData(11, 105, 68, 85, 36.7, 20, 42.0, 150, 18.7, 99),
    // Elderly - Amjad Hussain (Parkinson's)
    _VitalData(12, 136, 82, 68, 36.5, 16, 70.0, 168, 24.8, 96),
    // Elderly - Nasreen Begum (RA)
    _VitalData(13, 144, 88, 72, 36.6, 15, 65.0, 155, 27.0, 97),
    // New patient - Farhan Ahmed
    _VitalData(14, 120, 78, 74, 36.6, 14, 78.0, 175, 25.5, 99),
    // New patient - Hira Qureshi
    _VitalData(15, 112, 72, 70, 36.5, 14, 58.0, 162, 22.1, 99),
    // PUD patient - Imran Shah
    _VitalData(16, 126, 80, 76, 36.7, 15, 82.0, 172, 27.7, 98),
    // Epilepsy patient - Rabia Butt
    _VitalData(17, 118, 76, 72, 36.6, 14, 64.0, 160, 25.0, 99),
    // Sports injury - Kamran Akmal
    _VitalData(18, 118, 74, 62, 36.5, 14, 85.0, 180, 26.2, 99),
    // Muscle strain - Nadia Ali
    _VitalData(19, 110, 70, 68, 36.5, 14, 55.0, 165, 20.2, 99),
  ];

  int vitalCount = 0;
  for (final v in vitalData) {
    // Add current vitals
    await db.insertVitalSigns(
      VitalSignsCompanion(
        patientId: Value(patientIds[v.patientIndex]),
        systolicBp: Value(v.systolic.toDouble()),
        diastolicBp: Value(v.diastolic.toDouble()),
        heartRate: Value(v.pulse),
        temperature: Value(v.temp),
        respiratoryRate: Value(v.respRate),
        weight: Value(v.weight),
        height: Value(v.height),
        bmi: Value(v.bmi),
        oxygenSaturation: Value(v.o2Sat.toDouble()),
        recordedAt: Value(today.subtract(Duration(hours: random.nextInt(48)))),
      ),
    );
    vitalCount++;
    
    // Add a couple historical vitals for trending
    for (int i = 1; i <= 2; i++) {
      final variance = random.nextInt(10) - 5;
      await db.insertVitalSigns(
        VitalSignsCompanion(
          patientId: Value(patientIds[v.patientIndex]),
          systolicBp: Value((v.systolic + variance).toDouble()),
          diastolicBp: Value((v.diastolic + (variance ~/ 2)).toDouble()),
          heartRate: Value(v.pulse + variance),
          temperature: Value(v.temp),
          respiratoryRate: Value(v.respRate),
          weight: Value(v.weight + (variance / 10)),
          height: Value(v.height),
          bmi: Value(v.bmi + (variance / 20)),
          oxygenSaturation: Value(v.o2Sat.toDouble()),
          recordedAt: Value(today.subtract(Duration(days: i * 30))),
        ),
      );
      vitalCount++;
    }
  }
  log.i('SEED', '✓ Inserted $vitalCount vital sign records');

  log.i('SEED', '═══════════════════════════════════════════════════════════');
  log.i('SEED', '  DATABASE SEEDING COMPLETE');
  log.i('SEED', '═══════════════════════════════════════════════════════════');
  log.i('SEED', '  Patients: ${patientIds.length}');
  log.i('SEED', '  Appointments: $appointmentCount');
  log.i('SEED', '  Prescriptions: $prescriptionCount');
  log.i('SEED', '  Medical Records: $recordCount');
  log.i('SEED', '  Invoices: $invoiceCount');
  log.i('SEED', '  Vital Signs: $vitalCount');
  log.i('SEED', '═══════════════════════════════════════════════════════════');
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

class _PatientData {
  final String firstName;
  final String lastName;
  final int age;
  final String gender;
  final String bloodType;
  final String phone;
  final String email;
  final String address;
  final String medicalHistory;
  final String allergies;
  final String chronicConditions;
  final int riskLevel;

  _PatientData(this.firstName, this.lastName, this.age, this.gender, this.bloodType, 
    this.phone, this.email, this.address, this.medicalHistory, this.allergies, 
    this.chronicConditions, this.riskLevel);
}

class _PrescriptionData {
  final int patientIndex;
  final List<_MedData> medications;
  final String instructions;

  _PrescriptionData(this.patientIndex, this.medications, this.instructions);
}

class _MedData {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;

  _MedData(this.name, this.dosage, this.frequency, this.duration);
}

class _RecordData {
  final int patientIndex;
  final String recordType;
  final String title;
  final String description;
  final String diagnosis;
  final String treatment;
  final String doctorNotes;

  _RecordData(this.patientIndex, this.recordType, this.title, 
    this.description, this.diagnosis, this.treatment, this.doctorNotes);
}

class _InvoiceData {
  final int patientIndex;
  final List<_InvoiceItem> items;
  final String status;
  final String method;
  final int discountPercent;
  final String? notes;

  _InvoiceData(this.patientIndex, this.items, this.status, this.method, this.discountPercent, this.notes);
}

class _InvoiceItem {
  final String description;
  final double amount;

  _InvoiceItem(this.description, this.amount);
}

class _VitalData {
  final int patientIndex;
  final int systolic;
  final int diastolic;
  final int pulse;
  final double temp;
  final int respRate;
  final double weight;
  final double height;
  final double bmi;
  final int o2Sat;

  _VitalData(this.patientIndex, this.systolic, this.diastolic, this.pulse, 
    this.temp, this.respRate, this.weight, this.height, this.bmi, this.o2Sat);
}
