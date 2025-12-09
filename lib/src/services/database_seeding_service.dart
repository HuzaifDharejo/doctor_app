import 'package:doctor_app/src/db/doctor_db.dart';
import 'package:drift/drift.dart' as drift;

/// Service to seed the database with realistic clinical data
/// All data relationships are properly linked for testing
class DatabaseSeedingService {
  final DoctorDatabase db;

  DatabaseSeedingService(this.db);

  /// Clear all data and reseed with fresh demo data
  Future<void> resetAndSeedDatabase() async {
    // Clear all tables in reverse dependency order
    await db.delete(db.treatmentGoals).go();
    await db.delete(db.medicationResponses).go();
    await db.delete(db.treatmentSessions).go();
    await db.delete(db.treatmentOutcomes).go();
    await db.delete(db.scheduledFollowUps).go();
    await db.delete(db.clinicalNotes).go();
    await db.delete(db.diagnoses).go();
    await db.delete(db.encounters).go();
    await db.delete(db.invoices).go();
    await db.delete(db.prescriptions).go();
    await db.delete(db.vitalSigns).go();
    await db.delete(db.medicalRecords).go();
    await db.delete(db.appointments).go();
    await db.delete(db.patients).go();

    // Now seed with fresh data
    await _seedAllData();
  }

  /// Seed all tables with realistic psychiatric clinic data
  Future<void> seedDatabase() async {
    // Check if already seeded
    final patientCount = await db.select(db.patients).get().then((p) => p.length);
    if (patientCount > 0) {
      return; // Already seeded
    }

    await _seedAllData();
  }

  /// Internal method to seed all data
  Future<void> _seedAllData() async {
    // Seed patients
    final patientIds = await _seedPatients();

    // Seed appointments
    final appointmentIds = await _seedAppointments(patientIds);

    // Seed medical records (assessments)
    final medicalRecordIds = await _seedMedicalRecords(patientIds, appointmentIds);

    // Link appointments to medical records
    await _linkAppointmentsToRecords(appointmentIds, medicalRecordIds);

    // Seed vital signs linked to appointments
    await _seedVitalSigns(patientIds, appointmentIds);

    // Seed prescriptions linked to diagnoses and appointments
    await _seedPrescriptions(patientIds, appointmentIds, medicalRecordIds);

    // Seed treatment outcomes
    final treatmentOutcomeIds = await _seedTreatmentOutcomes(patientIds);

    // Seed treatment sessions
    await _seedTreatmentSessions(
      patientIds,
      appointmentIds,
      medicalRecordIds,
      treatmentOutcomeIds,
    );

    // Seed medication responses
    await _seedMedicationResponses(patientIds, treatmentOutcomeIds);

    // Seed treatment goals
    await _seedTreatmentGoals(patientIds, treatmentOutcomeIds);

    // Seed scheduled follow-ups
    await _seedScheduledFollowUps(patientIds, appointmentIds);

    // Seed invoices
    await _seedInvoices(patientIds, appointmentIds);

    // Seed encounters, diagnoses, and clinical notes
    await _seedEncounters(patientIds, appointmentIds);
  }

  /// Seed patient records with varied psychiatric conditions
  Future<List<int>> _seedPatients() async {
    final patients = [
      PatientsCompanion(
        firstName: const drift.Value('Ahmed'),
        lastName: const drift.Value('Khan'),
        age: const drift.Value(40),
        gender: const drift.Value('Male'),
        bloodType: const drift.Value('B+'),
        phone: const drift.Value('0300-1234567'),
        email: const drift.Value('ahmed.khan@example.com'),
        address: const drift.Value('123 Main Street, Karachi'),
        medicalHistory: const drift.Value('Depression, Anxiety, Sleep disorders'),
        allergies: const drift.Value('Penicillin, Sulfa drugs'),
        tags: const drift.Value('High risk, Follow-up required'),
        riskLevel: const drift.Value(3),
        chronicConditions: const drift.Value('Major Depressive Disorder'),
        emergencyContactName: const drift.Value('Sara Khan'),
        emergencyContactPhone: const drift.Value('0300-1234568'),
      ),
      PatientsCompanion(
        firstName: const drift.Value('Fatima'),
        lastName: const drift.Value('Ali'),
        age: const drift.Value(35),
        gender: const drift.Value('Female'),
        bloodType: const drift.Value('A+'),
        phone: const drift.Value('0321-9876543'),
        email: const drift.Value('fatima.ali@example.com'),
        address: const drift.Value('456 Oak Avenue, Lahore'),
        medicalHistory: const drift.Value('Bipolar Disorder, Hypertension'),
        allergies: const drift.Value('Aspirin'),
        tags: const drift.Value('Bipolar, Medication monitoring'),
        riskLevel: const drift.Value(2),
        chronicConditions: const drift.Value('Bipolar I Disorder'),
        emergencyContactName: const drift.Value('Ali Hassan'),
        emergencyContactPhone: const drift.Value('0321-9876544'),
      ),
      PatientsCompanion(
        firstName: const drift.Value('Muhammad'),
        lastName: const drift.Value('Hassan'),
        age: const drift.Value(55),
        gender: const drift.Value('Male'),
        bloodType: const drift.Value('O+'),
        phone: const drift.Value('0333-5555555'),
        email: const drift.Value('m.hassan@example.com'),
        address: const drift.Value('789 Elm Street, Islamabad'),
        medicalHistory: const drift.Value('COPD, Smoking history 30 pack years'),
        allergies: const drift.Value(''),
        tags: const drift.Value('COPD, Pulmonary'),
        riskLevel: const drift.Value(3),
        chronicConditions: const drift.Value('COPD Gold Stage III'),
        emergencyContactName: const drift.Value('Ayesha Hassan'),
        emergencyContactPhone: const drift.Value('0333-5555556'),
      ),
      PatientsCompanion(
        firstName: const drift.Value('Aisha'),
        lastName: const drift.Value('Ahmed'),
        age: const drift.Value(28),
        gender: const drift.Value('Female'),
        bloodType: const drift.Value('AB+'),
        phone: const drift.Value('0345-2222222'),
        email: const drift.Value('aisha.ahmed@example.com'),
        address: const drift.Value('321 Pine Road, Multan'),
        medicalHistory: const drift.Value('Asthma since childhood'),
        allergies: const drift.Value('NSAIDs, Dust mites'),
        tags: const drift.Value('Asthma, Active treatment'),
        riskLevel: const drift.Value(1),
        chronicConditions: const drift.Value('Bronchial Asthma'),
        emergencyContactName: const drift.Value('Bilal Ahmed'),
        emergencyContactPhone: const drift.Value('0345-2222223'),
      ),
      PatientsCompanion(
        firstName: const drift.Value('Zainab'),
        lastName: const drift.Value('Hassan'),
        age: const drift.Value(33),
        gender: const drift.Value('Female'),
        bloodType: const drift.Value('B-'),
        phone: const drift.Value('0312-3333333'),
        email: const drift.Value('zainab.hassan@example.com'),
        address: const drift.Value('654 Maple Drive, Peshawar'),
        medicalHistory: const drift.Value('Generalized Anxiety Disorder, IBS'),
        allergies: const drift.Value('Latex'),
        tags: const drift.Value('Anxiety, Follow-up in 2 weeks'),
        riskLevel: const drift.Value(1),
        chronicConditions: const drift.Value('GAD'),
        emergencyContactName: const drift.Value('Usman Hassan'),
        emergencyContactPhone: const drift.Value('0312-3333334'),
      ),
    ];

    final ids = <int>[];
    for (final patient in patients) {
      final id = await db.into(db.patients).insert(patient);
      ids.add(id);
    }
    return ids;
  }

  /// Seed appointments with proper patient references
  Future<List<int>> _seedAppointments(List<int> patientIds) async {
    final now = DateTime.now();
    final appointments = [
      AppointmentsCompanion(
        patientId: drift.Value(patientIds[0]),
        appointmentDateTime: drift.Value(now.subtract(Duration(days: 2, hours: 2))),
        durationMinutes: const drift.Value(45),
        reason: const drift.Value('Follow-up on depression treatment'),
        status: const drift.Value('completed'),
        notes: const drift.Value('Patient showing improvement, continue current medication'),
      ),
      AppointmentsCompanion(
        patientId: drift.Value(patientIds[1]),
        appointmentDateTime: drift.Value(now.subtract(Duration(days: 1, hours: 3))),
        durationMinutes: const drift.Value(50),
        reason: const drift.Value('Bipolar disorder management'),
        status: const drift.Value('completed'),
        notes: const drift.Value('Mood stable, vital signs normal'),
      ),
      AppointmentsCompanion(
        patientId: drift.Value(patientIds[2]),
        appointmentDateTime: drift.Value(now.add(Duration(hours: 2))),
        durationMinutes: const drift.Value(45),
        reason: const drift.Value('PTSD assessment and therapy'),
        status: const drift.Value('scheduled'),
        notes: const drift.Value(''),
      ),
      AppointmentsCompanion(
        patientId: drift.Value(patientIds[3]),
        appointmentDateTime: drift.Value(now.add(Duration(days: 1, hours: 1))),
        durationMinutes: const drift.Value(50),
        reason: const drift.Value('Depression treatment continuation'),
        status: const drift.Value('scheduled'),
        notes: const drift.Value(''),
      ),
      AppointmentsCompanion(
        patientId: drift.Value(patientIds[4]),
        appointmentDateTime: drift.Value(now.subtract(Duration(days: 5, hours: 4))),
        durationMinutes: const drift.Value(40),
        reason: const drift.Value('Anxiety disorder evaluation'),
        status: const drift.Value('completed'),
        notes: const drift.Value('New anxiety medication prescribed'),
      ),
    ];

    final ids = <int>[];
    for (final appointment in appointments) {
      final id = await db.into(db.appointments).insert(appointment);
      ids.add(id);
    }
    return ids;
  }

  /// Seed medical records (assessments) linked to patients
  Future<List<int>> _seedMedicalRecords(
    List<int> patientIds,
    List<int> appointmentIds,
  ) async {
    final now = DateTime.now();
    final records = [
      // Psychiatric Assessment - Full data
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[0]),
        recordType: const drift.Value('psychiatric_assessment'),
        title: const drift.Value('Depression Assessment - Follow-up'),
        diagnosis: const drift.Value('Major Depressive Disorder, Moderate'),
        treatment: const drift.Value('SSRI (Sertraline), Psychotherapy'),
        doctorNotes: const drift.Value('Patient responding well to medication. Recommend continue treatment.'),
        recordDate: drift.Value(now.subtract(Duration(days: 2))),
        dataJson: const drift.Value('{"name":"Ahmed Khan","age":"40","gender":"Male","marital_status":"Married","chief_complaint":"Persistent low mood and loss of interest for 3 months","duration":"3 months","symptoms":"Depressed mood, anhedonia, fatigue, poor concentration","mood":"Depressed","affect":"Flat","speech":"Slow, low volume","thought":"Negative automatic thoughts, no delusions","perception":"No hallucinations","cognition":"Intact but slowed","insight":"Good","suicide_risk":"Low","homicide_risk":"None","safety_plan":"Family support, crisis helpline","diagnosis":"Major Depressive Disorder, Moderate, F32.1","treatment_plan":"Continue SSRI, weekly psychotherapy","medications":"Sertraline 100mg daily","follow_up":"2 weeks"}'),
      ),
      // Psychiatric Assessment - Bipolar
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[1]),
        recordType: const drift.Value('psychiatric_assessment'),
        title: const drift.Value('Bipolar Disorder Evaluation'),
        diagnosis: const drift.Value('Bipolar I Disorder, Current Episode Stable'),
        treatment: const drift.Value('Mood stabilizer (Lithium), Antipsychotic'),
        doctorNotes: const drift.Value('Mood episodes well-controlled. Continue lithium level monitoring.'),
        recordDate: drift.Value(now.subtract(Duration(days: 1))),
        dataJson: const drift.Value('{"name":"Fatima Ali","age":"35","gender":"Female","marital_status":"Single","chief_complaint":"Follow-up for bipolar disorder management","duration":"Ongoing treatment for 2 years","symptoms":"Previously had manic and depressive episodes","mood":"Euthymic","affect":"Appropriate","speech":"Normal rate and volume","thought":"Linear, goal-directed","perception":"No perceptual disturbances","cognition":"Intact","insight":"Good","suicide_risk":"None","homicide_risk":"None","safety_plan":"Established safety plan in place","diagnosis":"Bipolar I Disorder, F31.9, Currently Stable","treatment_plan":"Continue mood stabilizers, monthly lithium levels","medications":"Lithium 750mg BD, Olanzapine 5mg HS","follow_up":"1 month"}'),
      ),
      // Pulmonary Evaluation - COPD
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[2]),
        recordType: const drift.Value('pulmonary_evaluation'),
        title: const drift.Value('COPD Exacerbation Assessment'),
        diagnosis: const drift.Value('COPD Exacerbation, Moderate'),
        treatment: const drift.Value('Bronchodilators, Steroids, Antibiotics'),
        doctorNotes: const drift.Value('Patient with acute exacerbation. Increased dyspnea and productive cough.'),
        recordDate: drift.Value(now.subtract(Duration(days: 3))),
        dataJson: const drift.Value('{"chief_complaint":"Increased shortness of breath and cough for 5 days","duration":"5 days","symptoms":{"Cough":true,"Productive Cough":true,"Dyspnea":true,"Wheezing":true,"Fever":false,"Night Sweats":false,"Weight Loss":false,"Fatigue":true},"red_flags":{"Hemoptysis":false,"Severe Dyspnea":true,"Stridor":false,"Cyanosis":false},"vitals":{"bp":"140/90","pr":"95","rr":"24","temp":"37.2","spo2":"91"},"chest_findings":{"Inspection":"Barrel chest, use of accessory muscles","Palpation":"Reduced chest expansion bilaterally","Percussion":"Hyperresonant","Auscultation":"Prolonged expiration, scattered wheezes"},"breath_sounds":{"Normal":false,"Crackles":false,"Wheeze":true,"Rhonchi":true,"Decreased Air Entry":true},"diagnosis":"Acute exacerbation of COPD","differential":"Pneumonia, Heart failure","investigations":{"Chest X-ray":true,"CT Chest":false,"Sputum AFB":true,"Blood Culture":false,"Spirometry":false,"ABG":true,"CBC":true},"treatment_plan":"Nebulization, oral steroids, antibiotics if indicated","medications":"Salbutamol nebulization QID, Prednisolone 40mg OD x 5 days, Azithromycin 500mg OD x 3 days","follow_up":"3 days or earlier if worsening"}'),
      ),
      // Pulmonary Evaluation - Asthma
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[3]),
        recordType: const drift.Value('pulmonary_evaluation'),
        title: const drift.Value('Asthma Evaluation'),
        diagnosis: const drift.Value('Bronchial Asthma, Moderate Persistent'),
        treatment: const drift.Value('Inhaled corticosteroids, LABA'),
        doctorNotes: const drift.Value('Poorly controlled asthma. Step up therapy needed.'),
        recordDate: drift.Value(now.subtract(Duration(days: 10))),
        dataJson: const drift.Value('{"chief_complaint":"Recurrent wheezing and breathlessness, worse at night","duration":"2 weeks worsening","symptoms":{"Cough":true,"Dry Cough":true,"Dyspnea":true,"Wheezing":true,"Chest Pain":false,"Fever":false,"Night Sweats":true},"red_flags":{"Hemoptysis":false,"Severe Dyspnea":false,"Stridor":false,"Cyanosis":false},"vitals":{"bp":"120/80","pr":"88","rr":"20","temp":"36.8","spo2":"95"},"chest_findings":{"Inspection":"Normal","Palpation":"Normal expansion","Percussion":"Resonant","Auscultation":"Bilateral expiratory wheeze"},"breath_sounds":{"Normal":false,"Crackles":false,"Wheeze":true,"Rhonchi":false,"Decreased Air Entry":false},"diagnosis":"Bronchial Asthma - Moderate Persistent","differential":"COPD, Cardiac wheeze","investigations":{"Chest X-ray":true,"Spirometry":true,"CBC":true},"treatment_plan":"Step up to ICS/LABA combination, asthma action plan","medications":"Budesonide/Formoterol 200/6 2 puffs BD, Salbutamol MDI PRN","follow_up":"2 weeks"}'),
      ),
      // Lab Result
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[0]),
        recordType: const drift.Value('lab_result'),
        title: const drift.Value('Complete Blood Count'),
        diagnosis: const drift.Value('Normal CBC'),
        treatment: const drift.Value('No treatment required'),
        doctorNotes: const drift.Value('Routine monitoring labs - all within normal limits'),
        recordDate: drift.Value(now.subtract(Duration(days: 5))),
        dataJson: const drift.Value('{"test_name":"Complete Blood Count (CBC)","test_category":"Hematology","result":"Hb: 14.2 g/dL, WBC: 7,500/uL, Platelets: 250,000/uL","reference_range":"Hb: 13-17, WBC: 4000-11000, Plt: 150000-400000","units":"Various","specimen":"Blood","lab_name":"City Diagnostics Lab","ordering_physician":"Dr. Ahmed","interpretation":"All parameters within normal limits","result_status":"Normal"}'),
      ),
      // Lab Result - Abnormal
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[1]),
        recordType: const drift.Value('lab_result'),
        title: const drift.Value('Lithium Level'),
        diagnosis: const drift.Value('Lithium level within therapeutic range'),
        treatment: const drift.Value('Continue current dose'),
        doctorNotes: const drift.Value('Therapeutic lithium level achieved'),
        recordDate: drift.Value(now.subtract(Duration(days: 7))),
        dataJson: const drift.Value('{"test_name":"Serum Lithium Level","test_category":"Therapeutic Drug Monitoring","result":"0.82 mEq/L","reference_range":"0.6-1.2 mEq/L (therapeutic)","units":"mEq/L","specimen":"Serum","lab_name":"National Lab Services","ordering_physician":"Dr. Fatima","interpretation":"Level within therapeutic range. Continue current dosing.","result_status":"Normal"}'),
      ),
      // Imaging
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[2]),
        recordType: const drift.Value('imaging'),
        title: const drift.Value('Chest X-Ray PA View'),
        diagnosis: const drift.Value('COPD changes'),
        treatment: const drift.Value('Continue COPD management'),
        doctorNotes: const drift.Value('CXR shows hyperinflated lungs consistent with COPD'),
        recordDate: drift.Value(now.subtract(Duration(days: 3))),
        dataJson: const drift.Value('{"imaging_type":"X-Ray","body_part":"Chest PA View","indication":"Evaluation of COPD exacerbation, rule out pneumonia","technique":"Digital radiograph, PA and lateral views","findings":"Hyperinflated lungs with flattened diaphragms. No focal consolidation. No pleural effusion. Heart size normal. No pneumothorax.","impression":"Chest X-ray findings consistent with COPD. No acute pulmonary infiltrates to suggest pneumonia.","recommendations":"Clinical correlation. Follow-up as clinically indicated.","radiologist":"Dr. Hassan Imaging","facility":"City Radiology Center","contrast_used":false,"urgency":"Routine"}'),
      ),
      // Procedure
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[4]),
        recordType: const drift.Value('procedure'),
        title: const drift.Value('ECG Recording'),
        diagnosis: const drift.Value('Normal sinus rhythm'),
        treatment: const drift.Value('No cardiac intervention needed'),
        doctorNotes: const drift.Value('ECG performed for baseline assessment'),
        recordDate: drift.Value(now.subtract(Duration(days: 5))),
        dataJson: const drift.Value('{"procedure_name":"12-Lead Electrocardiogram (ECG)","procedure_code":"93000","indication":"Baseline cardiac assessment before starting SSRI","anesthesia":"None required","procedure_notes":"Standard 12-lead ECG performed. Patient cooperative.","findings":"Normal sinus rhythm at 72 bpm. Normal axis. PR interval 160ms. QRS 90ms. QTc 410ms. No ST-T changes.","complications":"None","specimen":"N/A","post_op_instructions":"No specific instructions. May resume normal activities.","performed_by":"Dr. Zainab","assisted_by":"Nurse Ayesha","procedure_status":"Completed","start_time":"10:30","end_time":"10:45","vitals":{"bp_pre":"120/78","pulse_pre":"72","spo2_pre":"98","bp_post":"118/76","pulse_post":"70","spo2_post":"99"}}'),
      ),
      // Follow-up
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[0]),
        recordType: const drift.Value('follow_up'),
        title: const drift.Value('Depression Treatment Follow-up'),
        diagnosis: const drift.Value('MDD - Improving'),
        treatment: const drift.Value('Continue current regimen'),
        doctorNotes: const drift.Value('Good progress noted'),
        recordDate: drift.Value(now.subtract(Duration(days: 14))),
        dataJson: drift.Value('{"progress_notes":"Patient reports significant improvement in mood and energy. Sleeping better. Appetite improved.","symptoms":"Mild residual fatigue, occasional low mood","compliance":"Excellent - taking medications as prescribed","side_effects":"Initial nausea resolved. No current side effects.","medication_review":"Sertraline 100mg well tolerated. Consider maintaining current dose.","investigations":"No new labs needed at this time","overall_progress":"Improved","next_follow_up_date":"${now.add(Duration(days: 14)).toIso8601String()}","next_follow_up_notes":"Review PHQ-9 scores, consider dose adjustment if plateaued","vitals":{"bp":"125/82","pulse":"74","temperature":"36.8","weight":"73","spo2":"98"}}'),
      ),
    ];

    final ids = <int>[];
    for (final record in records) {
      final id = await db.into(db.medicalRecords).insert(record);
      ids.add(id);
    }
    return ids;
  }

  /// Link appointments to their corresponding medical records
  Future<void> _linkAppointmentsToRecords(
    List<int> appointmentIds,
    List<int> recordIds,
  ) async {
    for (int i = 0; i < appointmentIds.length && i < recordIds.length; i++) {
      await db.update(db.appointments).replace(
            AppointmentsCompanion(
              id: drift.Value(appointmentIds[i]),
              medicalRecordId: drift.Value(recordIds[i]),
              patientId: drift.Value(0), // Will be set from original
              appointmentDateTime: drift.Value(DateTime(2024, 1, 1)),
              durationMinutes: drift.Value(45),
            ),
          );
    }
  }

  /// Seed vital signs data linked to appointments
  Future<void> _seedVitalSigns(List<int> patientIds, List<int> appointmentIds) async {
    final vitalSigns = [
      VitalSignsCompanion(
        patientId: drift.Value(patientIds[0]),
        recordedAt: drift.Value(DateTime.now().subtract(Duration(days: 2, hours: 1))),
        recordedByAppointmentId: drift.Value(appointmentIds[0]),
        systolicBp: const drift.Value(130),
        diastolicBp: const drift.Value(85),
        heartRate: const drift.Value(78),
        temperature: const drift.Value(37.0),
        respiratoryRate: const drift.Value(16),
        oxygenSaturation: const drift.Value(97),
        weight: const drift.Value(72.5),
        height: const drift.Value(175),
        bmi: const drift.Value(23.6),
        notes: const drift.Value('All vital signs normal'),
      ),
      VitalSignsCompanion(
        patientId: drift.Value(patientIds[1]),
        recordedAt: drift.Value(DateTime.now().subtract(Duration(days: 1, hours: 2))),
        recordedByAppointmentId: drift.Value(appointmentIds[1]),
        systolicBp: const drift.Value(128),
        diastolicBp: const drift.Value(82),
        heartRate: const drift.Value(72),
        temperature: const drift.Value(36.8),
        respiratoryRate: const drift.Value(15),
        oxygenSaturation: const drift.Value(98),
        weight: const drift.Value(68.0),
        height: const drift.Value(168),
        bmi: const drift.Value(24.1),
        notes: const drift.Value('Stable vitals on mood stabilizer'),
      ),
      VitalSignsCompanion(
        patientId: drift.Value(patientIds[2]),
        recordedAt: drift.Value(DateTime.now().subtract(Duration(days: 3, hours: 5))),
        recordedByAppointmentId: const drift.Value(null),
        systolicBp: const drift.Value(135),
        diastolicBp: const drift.Value(88),
        heartRate: const drift.Value(85), // Elevated due to anxiety
        temperature: const drift.Value(37.1),
        respiratoryRate: const drift.Value(18),
        oxygenSaturation: const drift.Value(96),
        weight: const drift.Value(80.0),
        height: const drift.Value(180),
        bmi: const drift.Value(24.7),
        notes: const drift.Value('Slightly elevated BP and HR due to PTSD symptoms'),
      ),
      VitalSignsCompanion(
        patientId: drift.Value(patientIds[3]),
        recordedAt: drift.Value(DateTime.now().subtract(Duration(days: 10, hours: 1))),
        recordedByAppointmentId: const drift.Value(null),
        systolicBp: const drift.Value(125),
        diastolicBp: const drift.Value(80),
        heartRate: const drift.Value(70),
        temperature: const drift.Value(36.9),
        respiratoryRate: const drift.Value(16),
        oxygenSaturation: const drift.Value(97),
        weight: const drift.Value(65.0),
        height: const drift.Value(162),
        bmi: const drift.Value(24.8),
        notes: const drift.Value('Baseline vitals recorded at initial assessment'),
      ),
      VitalSignsCompanion(
        patientId: drift.Value(patientIds[4]),
        recordedAt: drift.Value(DateTime.now().subtract(Duration(days: 5, hours: 2))),
        recordedByAppointmentId: drift.Value(appointmentIds[4]),
        systolicBp: const drift.Value(122),
        diastolicBp: const drift.Value(78),
        heartRate: const drift.Value(76),
        temperature: const drift.Value(37.0),
        respiratoryRate: const drift.Value(16),
        oxygenSaturation: const drift.Value(98),
        weight: const drift.Value(58.0),
        height: const drift.Value(160),
        bmi: const drift.Value(22.7),
        notes: const drift.Value('Normal vital signs'),
      ),
    ];

    for (final vs in vitalSigns) {
      await db.into(db.vitalSigns).insert(vs);
    }
  }

  /// Seed prescriptions linked to diagnoses and appointments
  Future<void> _seedPrescriptions(
    List<int> patientIds,
    List<int> appointmentIds,
    List<int> medicalRecordIds,
  ) async {
    final prescriptions = [
      PrescriptionsCompanion(
        patientId: drift.Value(patientIds[0]),
        appointmentId: drift.Value(appointmentIds[0]),
        medicalRecordId: drift.Value(medicalRecordIds[0]),
        diagnosis: const drift.Value('Major Depressive Disorder'),
        chiefComplaint: const drift.Value('Depressed mood, loss of interest'),
        itemsJson: const drift.Value('[{"medication": "Sertraline", "dosage": "100mg", "frequency": "once daily"}]'),
        instructions: const drift.Value('Take one tablet daily in the morning. May cause drowsiness.'),
        isRefillable: const drift.Value(true),
        vitalsJson: const drift.Value('{"systolicBp": 130, "diastolicBp": 85, "heartRate": 78}'),
      ),
      PrescriptionsCompanion(
        patientId: drift.Value(patientIds[1]),
        appointmentId: drift.Value(appointmentIds[1]),
        medicalRecordId: drift.Value(medicalRecordIds[1]),
        diagnosis: const drift.Value('Bipolar I Disorder'),
        chiefComplaint: const drift.Value('Mood stabilization maintenance'),
        itemsJson: const drift.Value('[{"medication": "Lithium Carbonate", "dosage": "750mg", "frequency": "twice daily"}, {"medication": "Haloperidol", "dosage": "5mg", "frequency": "once daily"}]'),
        instructions: const drift.Value('Take lithium with food. Maintain consistent fluid intake. Get lithium levels checked monthly.'),
        isRefillable: const drift.Value(true),
        vitalsJson: const drift.Value('{"systolicBp": 128, "diastolicBp": 82, "heartRate": 72}'),
      ),
      PrescriptionsCompanion(
        patientId: drift.Value(patientIds[2]),
        appointmentId: const drift.Value(null),
        medicalRecordId: drift.Value(medicalRecordIds[2]),
        diagnosis: const drift.Value('PTSD'),
        chiefComplaint: const drift.Value('Trauma-related symptoms'),
        itemsJson: const drift.Value('[{"medication": "Sertraline", "dosage": "150mg", "frequency": "once daily"}]'),
        instructions: const drift.Value('Take in morning. Therapy participation is essential for treatment success.'),
        isRefillable: const drift.Value(true),
        vitalsJson: const drift.Value('{}'),
      ),
      PrescriptionsCompanion(
        patientId: drift.Value(patientIds[3]),
        appointmentId: const drift.Value(null),
        medicalRecordId: drift.Value(medicalRecordIds[3]),
        diagnosis: const drift.Value('Major Depressive Disorder'),
        chiefComplaint: const drift.Value('Severe depression, sleep disturbance'),
        itemsJson: const drift.Value('[{"medication": "Fluoxetine", "dosage": "20mg", "frequency": "once daily"}, {"medication": "Amitriptyline", "dosage": "25mg", "frequency": "at bedtime"}]'),
        instructions: const drift.Value('Fluoxetine in morning, Amitriptyline at night. May take 4-6 weeks for full effect.'),
        isRefillable: const drift.Value(true),
        vitalsJson: const drift.Value('{}'),
      ),
      PrescriptionsCompanion(
        patientId: drift.Value(patientIds[4]),
        appointmentId: drift.Value(appointmentIds[4]),
        medicalRecordId: drift.Value(medicalRecordIds[4]),
        diagnosis: const drift.Value('Generalized Anxiety Disorder'),
        chiefComplaint: const drift.Value('Persistent anxiety, worry'),
        itemsJson: const drift.Value('[{"medication": "Citalopram", "dosage": "20mg", "frequency": "once daily"}]'),
        instructions: const drift.Value('Take once daily. Initial anxiety may increase before improving.'),
        isRefillable: const drift.Value(true),
        vitalsJson: const drift.Value('{"systolicBp": 122, "diastolicBp": 78, "heartRate": 76}'),
      ),
    ];

    for (final prescription in prescriptions) {
      await db.into(db.prescriptions).insert(prescription);
    }
  }

  /// Seed treatment outcomes
  Future<List<int>> _seedTreatmentOutcomes(List<int> patientIds) async {
    final now = DateTime.now();
    final outcomes = [
      TreatmentOutcomesCompanion(
        patientId: drift.Value(patientIds[0]),
        treatmentType: const drift.Value('medication'),
        treatmentDescription: const drift.Value('SSRI therapy for depression'),
        diagnosis: const drift.Value('Major Depressive Disorder'),
        startDate: drift.Value(now.subtract(Duration(days: 60))),
        outcome: const drift.Value('improved'),
        effectivenessScore: const drift.Value(8),
        sideEffects: const drift.Value('Minor: nausea for first week'),
        patientFeedback: const drift.Value('Feel much better, sleeping well'),
      ),
      TreatmentOutcomesCompanion(
        patientId: drift.Value(patientIds[1]),
        treatmentType: const drift.Value('medication'),
        treatmentDescription: const drift.Value('Lithium and antipsychotic combination'),
        diagnosis: const drift.Value('Bipolar I Disorder'),
        startDate: drift.Value(now.subtract(Duration(days: 120))),
        outcome: const drift.Value('stable'),
        effectivenessScore: const drift.Value(7),
        sideEffects: const drift.Value('Tremor, polyuria'),
        patientFeedback: const drift.Value('Mood is stable, continue treatment'),
      ),
      TreatmentOutcomesCompanion(
        patientId: drift.Value(patientIds[2]),
        treatmentType: const drift.Value('therapy'),
        treatmentDescription: const drift.Value('Trauma-focused CBT for PTSD'),
        diagnosis: const drift.Value('PTSD'),
        startDate: drift.Value(now.subtract(Duration(days: 45))),
        outcome: const drift.Value('ongoing'),
        effectivenessScore: const drift.Value(6),
        sideEffects: const drift.Value('Initial increase in anxiety during sessions'),
        patientFeedback: const drift.Value('Difficult but helpful'),
      ),
      TreatmentOutcomesCompanion(
        patientId: drift.Value(patientIds[3]),
        treatmentType: const drift.Value('medication'),
        treatmentDescription: const drift.Value('SSRI and tricyclic combination'),
        diagnosis: const drift.Value('Major Depressive Disorder'),
        startDate: drift.Value(now.subtract(Duration(days: 20))),
        outcome: const drift.Value('ongoing'),
        effectivenessScore: const drift.Value(5),
        sideEffects: const drift.Value('Dry mouth, drowsiness'),
        patientFeedback: const drift.Value('Some improvement in mood'),
      ),
      TreatmentOutcomesCompanion(
        patientId: drift.Value(patientIds[4]),
        treatmentType: const drift.Value('medication'),
        treatmentDescription: const drift.Value('SSRI therapy for anxiety'),
        diagnosis: const drift.Value('Generalized Anxiety Disorder'),
        startDate: drift.Value(now.subtract(Duration(days: 10))),
        outcome: const drift.Value('ongoing'),
        effectivenessScore: const drift.Value(4),
        sideEffects: const drift.Value('None reported yet'),
        patientFeedback: const drift.Value('Too early to tell'),
      ),
    ];

    final ids = <int>[];
    for (final outcome in outcomes) {
      final id = await db.into(db.treatmentOutcomes).insert(outcome);
      ids.add(id);
    }
    return ids;
  }

  /// Seed treatment sessions
  Future<void> _seedTreatmentSessions(
    List<int> patientIds,
    List<int> appointmentIds,
    List<int> medicalRecordIds,
    List<int> treatmentOutcomeIds,
  ) async {
    final sessions = [
      TreatmentSessionsCompanion(
        patientId: drift.Value(patientIds[0]),
        treatmentOutcomeId: drift.Value(treatmentOutcomeIds[0]),
        appointmentId: drift.Value(appointmentIds[0]),
        medicalRecordId: drift.Value(medicalRecordIds[0]),
        sessionDate: drift.Value(DateTime.now().subtract(Duration(days: 2))),
        providerType: const drift.Value('psychiatrist'),
        providerName: const drift.Value('Dr. Ahmed'),
        sessionType: const drift.Value('individual'),
        durationMinutes: const drift.Value(45),
        presentingConcerns: const drift.Value('Mood improvement, medication adjustment'),
        sessionNotes: const drift.Value('Patient reporting improved energy and mood. Side effects minimal.'),
        patientMood: const drift.Value('stable'),
        moodRating: const drift.Value(7),
        riskAssessment: const drift.Value('none'),
        isBillable: const drift.Value(true),
      ),
      TreatmentSessionsCompanion(
        patientId: drift.Value(patientIds[1]),
        treatmentOutcomeId: drift.Value(treatmentOutcomeIds[1]),
        appointmentId: drift.Value(appointmentIds[1]),
        medicalRecordId: drift.Value(medicalRecordIds[1]),
        sessionDate: drift.Value(DateTime.now().subtract(Duration(days: 1))),
        providerType: const drift.Value('psychiatrist'),
        providerName: const drift.Value('Dr. Fatima'),
        sessionType: const drift.Value('individual'),
        durationMinutes: const drift.Value(50),
        presentingConcerns: const drift.Value('Mood monitoring, medication compliance'),
        sessionNotes: const drift.Value('Lithium levels optimal. Patient compliant with treatment.'),
        patientMood: const drift.Value('stable'),
        moodRating: const drift.Value(8),
        riskAssessment: const drift.Value('none'),
        isBillable: const drift.Value(true),
      ),
    ];

    for (final session in sessions) {
      await db.into(db.treatmentSessions).insert(session);
    }
  }

  /// Seed medication responses
  Future<void> _seedMedicationResponses(
    List<int> patientIds,
    List<int> treatmentOutcomeIds,
  ) async {
    final responses = [
      MedicationResponsesCompanion(
        patientId: drift.Value(patientIds[0]),
        treatmentOutcomeId: drift.Value(treatmentOutcomeIds[0]),
        medicationName: const drift.Value('Sertraline'),
        dosage: const drift.Value('100mg'),
        frequency: const drift.Value('once daily'),
        startDate: drift.Value(DateTime.now().subtract(Duration(days: 60))),
        responseStatus: const drift.Value('effective'),
        effectivenessScore: const drift.Value(8),
        targetSymptoms: const drift.Value('["depressed mood", "anhedonia", "insomnia"]'),
        symptomImprovement: const drift.Value('{"depressed mood": "80%", "anhedonia": "70%", "insomnia": "85%"}'),
        sideEffects: const drift.Value('["nausea"]'),
        sideEffectSeverity: const drift.Value('mild'),
        adherent: const drift.Value(true),
      ),
      MedicationResponsesCompanion(
        patientId: drift.Value(patientIds[1]),
        treatmentOutcomeId: drift.Value(treatmentOutcomeIds[1]),
        medicationName: const drift.Value('Lithium Carbonate'),
        dosage: const drift.Value('750mg'),
        frequency: const drift.Value('twice daily'),
        startDate: drift.Value(DateTime.now().subtract(Duration(days: 120))),
        responseStatus: const drift.Value('effective'),
        effectivenessScore: const drift.Value(7),
        targetSymptoms: const drift.Value('["mood episodes", "mania", "depression"]'),
        symptomImprovement: const drift.Value('{"mood episodes": "90%", "mania": "95%", "depression": "75%"}'),
        sideEffects: const drift.Value('["tremor", "polyuria"]'),
        sideEffectSeverity: const drift.Value('mild'),
        adherent: const drift.Value(true),
        labsRequired: const drift.Value('Lithium level, TSH, Creatinine'),
        nextLabDate: drift.Value(DateTime.now().add(Duration(days: 30))),
      ),
    ];

    for (final response in responses) {
      await db.into(db.medicationResponses).insert(response);
    }
  }

  /// Seed treatment goals
  Future<void> _seedTreatmentGoals(
    List<int> patientIds,
    List<int> treatmentOutcomeIds,
  ) async {
    final goals = [
      TreatmentGoalsCompanion(
        patientId: drift.Value(patientIds[0]),
        treatmentOutcomeId: drift.Value(treatmentOutcomeIds[0]),
        goalCategory: const drift.Value('symptom'),
        goalDescription: const drift.Value('Reduce depressive symptoms'),
        targetBehavior: const drift.Value('Return to normal mood'),
        baselineMeasure: const drift.Value('PHQ-9 = 22'),
        targetMeasure: const drift.Value('PHQ-9 < 5'),
        currentMeasure: const drift.Value('PHQ-9 = 8'),
        progressPercent: const drift.Value(65),
        status: const drift.Value('active'),
        targetDate: drift.Value(DateTime.now().add(Duration(days: 60))),
        priority: const drift.Value(1),
      ),
      TreatmentGoalsCompanion(
        patientId: drift.Value(patientIds[0]),
        treatmentOutcomeId: drift.Value(treatmentOutcomeIds[0]),
        goalCategory: const drift.Value('functional'),
        goalDescription: const drift.Value('Return to work'),
        targetBehavior: const drift.Value('Work full-time'),
        baselineMeasure: const drift.Value('On medical leave'),
        targetMeasure: const drift.Value('Full-time employment'),
        currentMeasure: const drift.Value('Part-time work (20 hrs/week)'),
        progressPercent: const drift.Value(50),
        status: const drift.Value('active'),
        targetDate: drift.Value(DateTime.now().add(Duration(days: 90))),
        priority: const drift.Value(2),
      ),
      TreatmentGoalsCompanion(
        patientId: drift.Value(patientIds[1]),
        treatmentOutcomeId: drift.Value(treatmentOutcomeIds[1]),
        goalCategory: const drift.Value('symptom'),
        goalDescription: const drift.Value('Maintain mood stability'),
        targetBehavior: const drift.Value('No mood episodes'),
        baselineMeasure: const drift.Value('Episodic mood swings'),
        targetMeasure: const drift.Value('Stable mood > 6 months'),
        currentMeasure: const drift.Value('Stable mood > 4 months'),
        progressPercent: const drift.Value(75),
        status: const drift.Value('active'),
        targetDate: drift.Value(DateTime.now().add(Duration(days: 120))),
        priority: const drift.Value(1),
      ),
    ];

    for (final goal in goals) {
      await db.into(db.treatmentGoals).insert(goal);
    }
  }

  /// Seed scheduled follow-ups
  Future<void> _seedScheduledFollowUps(List<int> patientIds, List<int> appointmentIds) async {
    final now = DateTime.now();
    final followUps = [
      ScheduledFollowUpsCompanion(
        patientId: drift.Value(patientIds[0]),
        sourceAppointmentId: drift.Value(appointmentIds[0]),
        scheduledDate: drift.Value(now.add(Duration(days: 14))),
        reason: const drift.Value('Follow-up on depression treatment'),
        status: const drift.Value('pending'),
        notes: const drift.Value('Check medication response and side effects'),
      ),
      ScheduledFollowUpsCompanion(
        patientId: drift.Value(patientIds[2]),
        sourceAppointmentId: drift.Value(appointmentIds[2]),
        scheduledDate: drift.Value(now.add(Duration(days: 7))),
        reason: const drift.Value('PTSD therapy session'),
        status: const drift.Value('pending'),
        notes: const drift.Value('Continue trauma-focused CBT'),
      ),
      ScheduledFollowUpsCompanion(
        patientId: drift.Value(patientIds[4]),
        sourceAppointmentId: drift.Value(appointmentIds[4]),
        scheduledDate: drift.Value(now.add(Duration(days: 21))),
        reason: const drift.Value('Anxiety disorder follow-up'),
        status: const drift.Value('pending'),
        notes: const drift.Value('Assess anxiety medication effectiveness'),
      ),
    ];

    for (final followUp in followUps) {
      await db.into(db.scheduledFollowUps).insert(followUp);
    }
  }

  /// Seed invoices
  Future<void> _seedInvoices(List<int> patientIds, List<int> appointmentIds) async {
    final now = DateTime.now();
    final invoices = [
      InvoicesCompanion(
        patientId: drift.Value(patientIds[0]),
        appointmentId: drift.Value(appointmentIds[0]),
        invoiceNumber: const drift.Value('INV-2024-001'),
        invoiceDate: drift.Value(now.subtract(Duration(days: 2))),
        dueDate: drift.Value(now.add(Duration(days: 30))),
        itemsJson: const drift.Value('[{"description": "Psychiatric Consultation", "quantity": 1, "rate": 5000}]'),
        subtotal: const drift.Value(5000),
        taxPercent: const drift.Value(17),
        taxAmount: const drift.Value(850),
        grandTotal: const drift.Value(5850),
        paymentStatus: const drift.Value('Paid'),
      ),
      InvoicesCompanion(
        patientId: drift.Value(patientIds[1]),
        appointmentId: drift.Value(appointmentIds[1]),
        invoiceNumber: const drift.Value('INV-2024-002'),
        invoiceDate: drift.Value(now.subtract(Duration(days: 1))),
        dueDate: drift.Value(now.add(Duration(days: 30))),
        itemsJson: const drift.Value('[{"description": "Psychiatric Consultation", "quantity": 1, "rate": 5000}]'),
        subtotal: const drift.Value(5000),
        taxPercent: const drift.Value(17),
        taxAmount: const drift.Value(850),
        grandTotal: const drift.Value(5850),
        paymentStatus: const drift.Value('Pending'),
      ),
      InvoicesCompanion(
        patientId: drift.Value(patientIds[4]),
        appointmentId: drift.Value(appointmentIds[4]),
        invoiceNumber: const drift.Value('INV-2024-003'),
        invoiceDate: drift.Value(now.subtract(Duration(days: 5))),
        dueDate: drift.Value(now.add(Duration(days: 25))),
        itemsJson: const drift.Value('[{"description": "Initial Anxiety Assessment", "quantity": 1, "rate": 4500}]'),
        subtotal: const drift.Value(4500),
        taxPercent: const drift.Value(17),
        taxAmount: const drift.Value(765),
        grandTotal: const drift.Value(5265),
        paymentStatus: const drift.Value('Paid'),
      ),
    ];

    for (final invoice in invoices) {
      await db.into(db.invoices).insert(invoice);
    }
  }

  /// Seed encounters with related diagnoses and clinical notes
  Future<void> _seedEncounters(List<int> patientIds, List<int> appointmentIds) async {
    final now = DateTime.now();

    // Create encounter data with diagnoses and clinical notes
    final encounterData = [
      // Patient 1 (Ahmed Khan) - Depression and Anxiety
      {
        'encounter': EncountersCompanion(
          patientId: drift.Value(patientIds[0]),
          appointmentId: drift.Value(appointmentIds[0]),
          encounterDate: drift.Value(now.subtract(const Duration(days: 14))),
          encounterType: const drift.Value('outpatient'),
          status: const drift.Value('completed'),
          chiefComplaint: const drift.Value('Persistent sadness and difficulty sleeping for 3 weeks'),
          providerName: const drift.Value('Dr. Aisha Rahman'),
          providerType: const drift.Value('psychiatrist'),
          checkInTime: drift.Value(now.subtract(const Duration(days: 14, hours: 2))),
          checkOutTime: drift.Value(now.subtract(const Duration(days: 14, hours: 1))),
        ),
        'diagnoses': [
          {
            'icdCode': 'F32.1',
            'description': 'Major depressive disorder, single episode, moderate',
            'category': 'psychiatric',
            'severity': 'moderate',
            'isPrimary': true,
          },
          {
            'icdCode': 'F41.1',
            'description': 'Generalized anxiety disorder',
            'category': 'psychiatric',
            'severity': 'mild',
            'isPrimary': false,
          },
        ],
        'note': {
          'noteType': 'progress',
          'subjective': 'Patient reports persistent low mood, anhedonia, and difficulty sleeping for the past 3 weeks. '
              'Denies suicidal ideation. Reports increased work stress. Appetite decreased.',
          'objective': 'Appearance: Well-groomed. Behavior: Cooperative, good eye contact. '
              'Speech: Normal rate and volume. Mood: "Down". Affect: Constricted. '
              'Thought process: Linear and goal-directed. No delusions or hallucinations. '
              'Cognition: Alert and oriented x3. Insight and judgment: Fair.',
          'assessment': 'Major depressive disorder, single episode, moderate severity. '
              'Patient is exhibiting classic symptoms of depression with associated anxiety features. '
              'No immediate safety concerns.',
          'plan': '1. Start Sertraline 50mg daily\n'
              '2. Sleep hygiene counseling provided\n'
              '3. Recommend psychotherapy (CBT)\n'
              '4. Follow-up in 2 weeks to assess medication response\n'
              '5. Return sooner if symptoms worsen or suicidal thoughts develop',
          'riskLevel': 'low',
        },
      },

      // Patient 2 (Fatima Ali) - Bipolar follow-up
      {
        'encounter': EncountersCompanion(
          patientId: drift.Value(patientIds[1]),
          appointmentId: drift.Value(appointmentIds[1]),
          encounterDate: drift.Value(now.subtract(const Duration(days: 7))),
          encounterType: const drift.Value('follow_up'),
          status: const drift.Value('completed'),
          chiefComplaint: const drift.Value('Medication review and mood check'),
          providerName: const drift.Value('Dr. Aisha Rahman'),
          providerType: const drift.Value('psychiatrist'),
          checkInTime: drift.Value(now.subtract(const Duration(days: 7, hours: 3))),
          checkOutTime: drift.Value(now.subtract(const Duration(days: 7, hours: 2))),
        ),
        'diagnoses': [
          {
            'icdCode': 'F31.31',
            'description': 'Bipolar disorder, current episode depressed, mild',
            'category': 'psychiatric',
            'severity': 'mild',
            'isPrimary': true,
          },
        ],
        'note': {
          'noteType': 'medication_review',
          'subjective': 'Patient reports stable mood on current medication regimen. '
              'Sleeping well, 7-8 hours nightly. Energy levels improved. '
              'Denies any manic or hypomanic symptoms. No side effects reported.',
          'objective': 'Appearance: Appropriate dress. Behavior: Pleasant and engaged. '
              'Mood: "Good, better". Affect: Euthymic, appropriate range. '
              'Speech: Normal. Thought process: Coherent. No psychotic features.',
          'assessment': 'Bipolar disorder, currently stable on Lithium 900mg and Lamotrigine 200mg. '
              'Patient demonstrates good medication compliance and insight.',
          'plan': '1. Continue Lithium 900mg daily\n'
              '2. Continue Lamotrigine 200mg daily\n'
              '3. Lithium level to be checked in 1 month\n'
              '4. Continue mood tracking\n'
              '5. Follow-up in 4 weeks',
          'riskLevel': 'none',
        },
      },

      // Patient 3 (Muhammad Hassan) - PTSD
      {
        'encounter': EncountersCompanion(
          patientId: drift.Value(patientIds[2]),
          appointmentId: drift.Value(appointmentIds[2]),
          encounterDate: drift.Value(now.subtract(const Duration(days: 5))),
          encounterType: const drift.Value('outpatient'),
          status: const drift.Value('completed'),
          chiefComplaint: const drift.Value('Nightmares and flashbacks worsening'),
          providerName: const drift.Value('Dr. Aisha Rahman'),
          providerType: const drift.Value('psychiatrist'),
          checkInTime: drift.Value(now.subtract(const Duration(days: 5, hours: 4))),
          checkOutTime: drift.Value(now.subtract(const Duration(days: 5, hours: 3))),
        ),
        'diagnoses': [
          {
            'icdCode': 'F43.10',
            'description': 'Post-traumatic stress disorder, unspecified',
            'category': 'psychiatric',
            'severity': 'moderate',
            'isPrimary': true,
          },
          {
            'icdCode': 'G47.00',
            'description': 'Insomnia, unspecified',
            'category': 'neurological',
            'severity': 'moderate',
            'isPrimary': false,
          },
        ],
        'note': {
          'noteType': 'progress',
          'subjective': 'Patient reports increased frequency of nightmares over past 2 weeks, '
              'now occurring 4-5 times weekly (previously 1-2 times). Flashbacks triggered by loud noises. '
              'Hypervigilant in crowded places. Sleep averaging 4 hours nightly.',
          'objective': 'Appearance: Tired-appearing, but groomed. Behavior: Restless, scanning room. '
              'Mood: "On edge". Affect: Anxious, hypervigilant. '
              'Speech: Slightly pressured. No psychotic features. Insight: Good.',
          'assessment': 'PTSD with exacerbation of symptoms, likely triggered by anniversary of trauma. '
              'Associated significant sleep disruption. No active suicidal ideation.',
          'plan': '1. Increase Prazosin from 2mg to 4mg at bedtime for nightmares\n'
              '2. Continue Sertraline 100mg\n'
              '3. Refer to trauma-focused CBT therapist\n'
              '4. Grounding techniques reviewed\n'
              '5. Follow-up in 1 week to assess response',
          'riskLevel': 'moderate',
        },
      },

      // Patient 4 (Zainab Malik) - OCD
      {
        'encounter': EncountersCompanion(
          patientId: drift.Value(patientIds[3]),
          appointmentId: drift.Value(appointmentIds[3]),
          encounterDate: drift.Value(now.subtract(const Duration(days: 3))),
          encounterType: const drift.Value('follow_up'),
          status: const drift.Value('completed'),
          chiefComplaint: const drift.Value('Follow-up on OCD treatment progress'),
          providerName: const drift.Value('Dr. Aisha Rahman'),
          providerType: const drift.Value('psychiatrist'),
          checkInTime: drift.Value(now.subtract(const Duration(days: 3, hours: 2))),
          checkOutTime: drift.Value(now.subtract(const Duration(days: 3, hours: 1))),
        ),
        'diagnoses': [
          {
            'icdCode': 'F42.2',
            'description': 'Obsessive-compulsive disorder, mixed obsessional thoughts and acts',
            'category': 'psychiatric',
            'severity': 'mild',
            'isPrimary': true,
          },
        ],
        'note': {
          'noteType': 'progress',
          'subjective': 'Patient reports improvement in hand-washing compulsions. '
              'Now washing 8-10 times daily (previously 25-30 times). '
              'Contamination fears still present but more manageable. ERP therapy going well.',
          'objective': 'Appearance: Well-groomed, no visible skin irritation on hands. '
              'Behavior: Calm, less distressed when discussing contamination. '
              'Mood: "Better". Affect: Brighter than previous visits.',
          'assessment': 'OCD responding well to combined SSRI and ERP therapy. '
              'Y-BOCS score decreased from 28 to 18.',
          'plan': '1. Continue Fluvoxamine 200mg daily\n'
              '2. Continue weekly ERP sessions\n'
              '3. Encourage continued exposure homework\n'
              '4. Follow-up in 4 weeks',
          'riskLevel': 'none',
        },
      },

      // Patient 5 (Imran Shah) - Initial Assessment
      {
        'encounter': EncountersCompanion(
          patientId: drift.Value(patientIds[4]),
          appointmentId: drift.Value(appointmentIds[4]),
          encounterDate: drift.Value(now.subtract(const Duration(days: 1))),
          encounterType: const drift.Value('outpatient'),
          status: const drift.Value('completed'),
          chiefComplaint: const drift.Value('New patient: panic attacks and social anxiety'),
          providerName: const drift.Value('Dr. Aisha Rahman'),
          providerType: const drift.Value('psychiatrist'),
          checkInTime: drift.Value(now.subtract(const Duration(days: 1, hours: 3))),
          checkOutTime: drift.Value(now.subtract(const Duration(days: 1, hours: 1))),
        ),
        'diagnoses': [
          {
            'icdCode': 'F41.0',
            'description': 'Panic disorder without agoraphobia',
            'category': 'psychiatric',
            'severity': 'moderate',
            'isPrimary': true,
          },
          {
            'icdCode': 'F40.10',
            'description': 'Social anxiety disorder, unspecified',
            'category': 'psychiatric',
            'severity': 'moderate',
            'isPrimary': false,
          },
        ],
        'note': {
          'noteType': 'initial_assessment',
          'subjective': 'New patient presenting with panic attacks occurring 2-3 times weekly for past 6 months. '
              'Describes sudden onset of palpitations, chest tightness, dizziness, and fear of dying. '
              'Episodes last 10-15 minutes. Also reports significant anxiety in social situations, '
              'avoiding meetings and public speaking.',
          'objective': 'Appearance: Anxious-appearing. Behavior: Fidgeting, good eye contact when comfortable. '
              'Mood: "Anxious". Affect: Apprehensive. Speech: Slightly rapid. '
              'No psychotic features. Cardiac exam unremarkable. PHQ-9: 12. GAD-7: 16.',
          'assessment': 'Panic disorder with comorbid social anxiety disorder. '
              'No evidence of underlying cardiac pathology based on history. '
              'Symptoms significantly impacting work performance.',
          'plan': '1. Start Escitalopram 5mg daily, increase to 10mg after 1 week\n'
              '2. Educate on panic disorder and nature of panic attacks\n'
              '3. Teach breathing exercises for acute panic\n'
              '4. Consider beta-blocker PRN for performance anxiety\n'
              '5. Refer for CBT\n'
              '6. Follow-up in 2 weeks',
          'riskLevel': 'low',
        },
      },
    ];

    // Insert encounters with their diagnoses and notes
    for (final data in encounterData) {
      // Insert encounter
      final encounterId = await db.into(db.encounters).insert(
        data['encounter'] as EncountersCompanion,
      );

      // Insert diagnoses and link to encounter
      final diagnosisList = data['diagnoses'] as List<Map<String, dynamic>>;
      for (final diagData in diagnosisList) {
        final diagnosisId = await db.into(db.diagnoses).insert(
          DiagnosesCompanion(
            patientId: (data['encounter'] as EncountersCompanion).patientId,
            encounterId: drift.Value(encounterId),
            icdCode: drift.Value(diagData['icdCode'] as String),
            description: drift.Value(diagData['description'] as String),
            category: drift.Value(diagData['category'] as String),
            severity: drift.Value(diagData['severity'] as String),
            diagnosisStatus: const drift.Value('active'),
            diagnosedDate: (data['encounter'] as EncountersCompanion).encounterDate,
            isPrimary: drift.Value(diagData['isPrimary'] as bool),
          ),
        );

        // Link diagnosis to encounter
        await db.into(db.encounterDiagnoses).insert(
          EncounterDiagnosesCompanion(
            encounterId: drift.Value(encounterId),
            diagnosisId: drift.Value(diagnosisId),
            isNewDiagnosis: const drift.Value(true),
            encounterStatus: const drift.Value('addressed'),
          ),
        );
      }

      // Insert clinical note
      final noteData = data['note'] as Map<String, dynamic>;
      await db.into(db.clinicalNotes).insert(
        ClinicalNotesCompanion(
          encounterId: drift.Value(encounterId),
          patientId: (data['encounter'] as EncountersCompanion).patientId,
          noteType: drift.Value(noteData['noteType'] as String),
          subjective: drift.Value(noteData['subjective'] as String),
          objective: drift.Value(noteData['objective'] as String),
          assessment: drift.Value(noteData['assessment'] as String),
          plan: drift.Value(noteData['plan'] as String),
          riskLevel: drift.Value(noteData['riskLevel'] as String),
          signedBy: const drift.Value('Dr. Aisha Rahman'),
          signedAt: (data['encounter'] as EncountersCompanion).checkOutTime,
          isLocked: const drift.Value(true),
        ),
      );
    }
  }
}
