import 'package:doctor_app/src/db/doctor_db.dart';
import 'package:drift/drift.dart' as drift;

/// Service to seed the database with realistic clinical data
/// All data relationships are properly linked for testing
class DatabaseSeedingService {
  final DoctorDatabase db;

  DatabaseSeedingService(this.db);

  /// Seed all tables with realistic psychiatric clinic data
  Future<void> seedDatabase() async {
    // Check if already seeded
    final patientCount = await db.select(db.patients).get().then((p) => p.length);
    if (patientCount > 0) {
      return; // Already seeded
    }

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
  }

  /// Seed patient records with varied psychiatric conditions
  Future<List<int>> _seedPatients() async {
    final patients = [
      PatientsCompanion(
        firstName: const drift.Value('Ahmed'),
        lastName: const drift.Value('Khan'),
        dateOfBirth: drift.Value(DateTime(1985, 5, 15)),
        phone: const drift.Value('0300-1234567'),
        email: const drift.Value('ahmed.khan@example.com'),
        address: const drift.Value('123 Main Street, Karachi'),
        medicalHistory: const drift.Value('Depression, Anxiety, Sleep disorders'),
        allergies: const drift.Value('Penicillin, Sulfa drugs'),
        tags: const drift.Value('High risk, Follow-up required'),
        riskLevel: const drift.Value(3), // High risk
      ),
      PatientsCompanion(
        firstName: const drift.Value('Fatima'),
        lastName: const drift.Value('Ali'),
        dateOfBirth: drift.Value(DateTime(1990, 8, 22)),
        phone: const drift.Value('0321-9876543'),
        email: const drift.Value('fatima.ali@example.com'),
        address: const drift.Value('456 Oak Avenue, Lahore'),
        medicalHistory: const drift.Value('Bipolar Disorder, Hypertension'),
        allergies: const drift.Value('Aspirin'),
        tags: const drift.Value('Bipolar, Medication monitoring'),
        riskLevel: const drift.Value(2), // Medium risk
      ),
      PatientsCompanion(
        firstName: const drift.Value('Muhammad'),
        lastName: const drift.Value('Hassan'),
        dateOfBirth: drift.Value(DateTime(1988, 3, 10)),
        phone: const drift.Value('0333-5555555'),
        email: const drift.Value('m.hassan@example.com'),
        address: const drift.Value('789 Elm Street, Islamabad'),
        medicalHistory: const drift.Value('PTSD, Anxiety, Sleep disorders'),
        allergies: const drift.Value(''),
        tags: const drift.Value('PTSD, Combat veteran'),
        riskLevel: const drift.Value(2), // Medium risk
      ),
      PatientsCompanion(
        firstName: const drift.Value('Aisha'),
        lastName: const drift.Value('Ahmed'),
        dateOfBirth: drift.Value(DateTime(1995, 11, 5)),
        phone: const drift.Value('0345-2222222'),
        email: const drift.Value('aisha.ahmed@example.com'),
        address: const drift.Value('321 Pine Road, Multan'),
        medicalHistory: const drift.Value('Major Depressive Disorder, Insomnia'),
        allergies: const drift.Value('NSAIDs'),
        tags: const drift.Value('Depression, Active treatment'),
        riskLevel: const drift.Value(1), // Low risk
      ),
      PatientsCompanion(
        firstName: const drift.Value('Zainab'),
        lastName: const drift.Value('Hassan'),
        dateOfBirth: drift.Value(DateTime(1992, 7, 18)),
        phone: const drift.Value('0312-3333333'),
        email: const drift.Value('zainab.hassan@example.com'),
        address: const drift.Value('654 Maple Drive, Peshawar'),
        medicalHistory: const drift.Value('Generalized Anxiety Disorder, IBS'),
        allergies: const drift.Value('Latex'),
        tags: const drift.Value('Anxiety, Follow-up in 2 weeks'),
        riskLevel: const drift.Value(1), // Low risk
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
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[0]),
        recordType: const drift.Value('psychiatric_assessment'),
        title: const drift.Value('Depression Assessment - Follow-up'),
        diagnosis: const drift.Value('Major Depressive Disorder, Moderate'),
        treatment: const drift.Value('SSRI (Sertraline), Psychotherapy'),
        doctorNotes: const drift.Value('Patient responding well to medication. Recommend continue treatment.'),
        recordDate: drift.Value(now.subtract(Duration(days: 2))),
        dataJson: const drift.Value('{"phq9_score": 12, "gaf_score": 65, "suicidal_ideation": false}'),
      ),
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[1]),
        recordType: const drift.Value('psychiatric_assessment'),
        title: const drift.Value('Bipolar Disorder Evaluation'),
        diagnosis: const drift.Value('Bipolar I Disorder, Current Episode Stable'),
        treatment: const drift.Value('Mood stabilizer (Lithium), Antipsychotic (Haloperidol)'),
        doctorNotes: const drift.Value('Mood episodes well-controlled. Continue lithium level monitoring.'),
        recordDate: drift.Value(now.subtract(Duration(days: 1))),
        dataJson: const drift.Value('{"current_episode": "stable", "lithium_level": 0.8, "suicide_risk": 0}'),
      ),
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[2]),
        recordType: const drift.Value('psychiatric_assessment'),
        title: const drift.Value('PTSD Assessment'),
        diagnosis: const drift.Value('Post-Traumatic Stress Disorder, Moderate Severity'),
        treatment: const drift.Value('Trauma-focused CBT, SSRI'),
        doctorNotes: const drift.Value('Symptoms include nightmares and hypervigilance. Starting trauma therapy.'),
        recordDate: drift.Value(now.subtract(Duration(days: 3))),
        dataJson: const drift.Value('{"pcl5_score": 48, "trauma_type": "combat", "nightmares": true}'),
      ),
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[3]),
        recordType: const drift.Value('psychiatric_assessment'),
        title: const drift.Value('Depression Severity Assessment'),
        diagnosis: const drift.Value('Major Depressive Disorder, Moderate to Severe'),
        treatment: const drift.Value('SSRI (Fluoxetine), Cognitive Behavioral Therapy'),
        doctorNotes: const drift.Value('Patient with significant depressive symptoms. Initiated antidepressant therapy.'),
        recordDate: drift.Value(now.subtract(Duration(days: 10))),
        dataJson: const drift.Value('{"phq9_score": 18, "sleep_disturbance": true, "anhedonia": true}'),
      ),
      MedicalRecordsCompanion(
        patientId: drift.Value(patientIds[4]),
        recordType: const drift.Value('psychiatric_assessment'),
        title: const drift.Value('Anxiety Disorder Screening'),
        diagnosis: const drift.Value('Generalized Anxiety Disorder'),
        treatment: const drift.Value('SSRI (Citalopram), Relaxation techniques'),
        doctorNotes: const drift.Value('Patient with persistent anxiety. Started first-line SSRI treatment.'),
        recordDate: drift.Value(now.subtract(Duration(days: 5))),
        dataJson: const drift.Value('{"gad7_score": 16, "duration_months": 8, "worry_topics": ["health", "finances"]}'),
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
              patientId: const drift.Value(0), // Will be set from original
              appointmentDateTime: const drift.Value(DateTime(2024, 1, 1)),
              durationMinutes: const drift.Value(45),
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
}
