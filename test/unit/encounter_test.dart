import 'package:drift/drift.dart';
import 'package:doctor_app/src/db/doctor_db.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late TestDoctorDatabase db;
  late int testPatientId;
  late int testAppointmentId;

  setUp(() async {
    db = TestDoctorDatabase();
    
    // Create a test patient
    testPatientId = await db.into(db.patients).insert(TestDataFactory.createPatient(
      firstName: 'Encounter Test',
      phone: '555-ENCOUNTER',
    ));
    
    // Create a test appointment
    testAppointmentId = await db.into(db.appointments).insert(TestDataFactory.createAppointment(
      patientId: testPatientId,
      appointmentDateTime: DateTime.now(),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  group('Encounters Table Tests', () {
    test('should create an encounter', () async {
      // Act
      final encounterId = await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(
          patientId: testPatientId,
          appointmentId: testAppointmentId,
          chiefComplaint: 'Test complaint',
          encounterType: 'consultation',
        ),
      );

      // Assert
      expect(encounterId, greaterThan(0));
      final count = await db.getEncounterCount();
      expect(count, 1);
    });

    test('should retrieve encounter by id', () async {
      // Arrange
      final encounterId = await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(
          patientId: testPatientId,
          chiefComplaint: 'Headache and fatigue',
        ),
      );

      // Act
      final encounter = await (db.select(db.encounters)
            ..where((e) => e.id.equals(encounterId)))
          .getSingle();

      // Assert
      expect(encounter.patientId, testPatientId);
      expect(encounter.chiefComplaint, 'Headache and fatigue');
    });

    test('should update encounter status', () async {
      // Arrange
      final encounterId = await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(
          patientId: testPatientId,
          status: 'in_progress',
        ),
      );

      // Act
      await (db.update(db.encounters)..where((e) => e.id.equals(encounterId)))
          .write(const EncountersCompanion(status: Value('completed')));

      // Assert
      final updated = await (db.select(db.encounters)
            ..where((e) => e.id.equals(encounterId)))
          .getSingle();
      expect(updated.status, 'completed');
    });

    test('should delete encounter', () async {
      // Arrange
      final encounterId = await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(patientId: testPatientId),
      );
      expect(await db.getEncounterCount(), 1);

      // Act
      await (db.delete(db.encounters)..where((e) => e.id.equals(encounterId)))
          .go();

      // Assert
      expect(await db.getEncounterCount(), 0);
    });

    test('should get encounters for patient', () async {
      // Arrange
      await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(
          patientId: testPatientId,
          chiefComplaint: 'First visit',
        ),
      );
      await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(
          patientId: testPatientId,
          chiefComplaint: 'Second visit',
        ),
      );

      // Act
      final encounters = await db.getEncountersForPatient(testPatientId);

      // Assert
      expect(encounters.length, 2);
    });

    test('should store all encounter fields correctly', () async {
      // Arrange
      final now = DateTime.now();
      final encounterId = await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(
          patientId: testPatientId,
          appointmentId: testAppointmentId,
          encounterDate: now,
          encounterType: 'follow_up',
          status: 'in_progress',
          chiefComplaint: 'Persistent cough',
          providerName: 'Dr. Smith',
          providerType: 'psychiatrist',
        ),
      );

      // Act
      final encounter = await (db.select(db.encounters)
            ..where((e) => e.id.equals(encounterId)))
          .getSingle();

      // Assert
      expect(encounter.patientId, testPatientId);
      expect(encounter.appointmentId, testAppointmentId);
      expect(encounter.encounterType, 'follow_up');
      expect(encounter.status, 'in_progress');
      expect(encounter.chiefComplaint, 'Persistent cough');
      expect(encounter.providerName, 'Dr. Smith');
      expect(encounter.providerType, 'psychiatrist');
    });
  });

  group('Diagnoses Table Tests', () {
    test('should create a diagnosis', () async {
      // Act
      final diagnosisId = await db.into(db.diagnoses).insert(
        TestDataFactory.createDiagnosis(
          patientId: testPatientId,
          description: 'Test diagnosis',
          icdCode: 'J06.9',
        ),
      );

      // Assert
      expect(diagnosisId, greaterThan(0));
      final count = await db.getDiagnosisCount();
      expect(count, 1);
    });

    test('should retrieve diagnosis by id', () async {
      // Arrange
      final diagnosisId = await db.into(db.diagnoses).insert(
        TestDataFactory.createDiagnosis(
          patientId: testPatientId,
          description: 'Upper respiratory infection',
          icdCode: 'J06.9',
          severity: 'mild',
        ),
      );

      // Act
      final diagnosis = await (db.select(db.diagnoses)
            ..where((d) => d.id.equals(diagnosisId)))
          .getSingle();

      // Assert
      expect(diagnosis.patientId, testPatientId);
      expect(diagnosis.description, 'Upper respiratory infection');
      expect(diagnosis.icdCode, 'J06.9');
      expect(diagnosis.severity, 'mild');
    });

    test('should update diagnosis status', () async {
      // Arrange
      final diagnosisId = await db.into(db.diagnoses).insert(
        TestDataFactory.createDiagnosis(
          patientId: testPatientId,
          description: 'Acute bronchitis',
          diagnosisStatus: 'active',
        ),
      );

      // Act
      await (db.update(db.diagnoses)..where((d) => d.id.equals(diagnosisId)))
          .write(const DiagnosesCompanion(diagnosisStatus: Value('resolved')));

      // Assert
      final updated = await (db.select(db.diagnoses)
            ..where((d) => d.id.equals(diagnosisId)))
          .getSingle();
      expect(updated.diagnosisStatus, 'resolved');
    });

    test('should delete diagnosis', () async {
      // Arrange
      final diagnosisId = await db.into(db.diagnoses).insert(
        TestDataFactory.createDiagnosis(
          patientId: testPatientId,
          description: 'To be deleted',
        ),
      );
      expect(await db.getDiagnosisCount(), 1);

      // Act
      await (db.delete(db.diagnoses)..where((d) => d.id.equals(diagnosisId)))
          .go();

      // Assert
      expect(await db.getDiagnosisCount(), 0);
    });

    test('should get diagnoses for patient', () async {
      // Arrange
      await db.into(db.diagnoses).insert(
        TestDataFactory.createDiagnosis(
          patientId: testPatientId,
          description: 'Diabetes Type 2',
          category: 'Endocrine',
        ),
      );
      await db.into(db.diagnoses).insert(
        TestDataFactory.createDiagnosis(
          patientId: testPatientId,
          description: 'Hypertension',
          category: 'Cardiovascular',
        ),
      );

      // Act
      final diagnoses = await db.getDiagnosesForPatient(testPatientId);

      // Assert
      expect(diagnoses.length, 2);
    });

    test('should store all diagnosis fields correctly', () async {
      // Arrange
      final diagnosedDate = DateTime.now();
      final diagnosisId = await db.into(db.diagnoses).insert(
        TestDataFactory.createDiagnosis(
          patientId: testPatientId,
          icdCode: 'E11.9',
          description: 'Type 2 diabetes mellitus without complications',
          category: 'Endocrine',
          severity: 'moderate',
          diagnosedDate: diagnosedDate,
          diagnosisStatus: 'active',
          notes: 'Newly diagnosed, starting metformin',
        ),
      );

      // Act
      final diagnosis = await (db.select(db.diagnoses)
            ..where((d) => d.id.equals(diagnosisId)))
          .getSingle();

      // Assert
      expect(diagnosis.patientId, testPatientId);
      expect(diagnosis.icdCode, 'E11.9');
      expect(diagnosis.description, 'Type 2 diabetes mellitus without complications');
      expect(diagnosis.category, 'Endocrine');
      expect(diagnosis.severity, 'moderate');
      expect(diagnosis.diagnosisStatus, 'active');
      expect(diagnosis.notes, 'Newly diagnosed, starting metformin');
    });
  });

  group('Clinical Notes Table Tests', () {
    late int testEncounterId;

    setUp(() async {
      // Create an encounter for clinical notes
      testEncounterId = await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(
          patientId: testPatientId,
          chiefComplaint: 'Clinical note test',
        ),
      );
    });

    test('should create a clinical note', () async {
      // Act
      final noteId = await db.into(db.clinicalNotes).insert(
        TestDataFactory.createClinicalNote(
          encounterId: testEncounterId,
          patientId: testPatientId,
          subjective: 'Patient reports headache',
        ),
      );

      // Assert
      expect(noteId, greaterThan(0));
      final count = await db.getClinicalNoteCount();
      expect(count, 1);
    });

    test('should retrieve clinical note by id', () async {
      // Arrange
      final noteId = await db.into(db.clinicalNotes).insert(
        TestDataFactory.createClinicalNote(
          encounterId: testEncounterId,
          patientId: testPatientId,
          subjective: 'Severe headache for 3 days',
          objective: 'BP: 140/90, HR: 88',
        ),
      );

      // Act
      final note = await (db.select(db.clinicalNotes)
            ..where((n) => n.id.equals(noteId)))
          .getSingle();

      // Assert
      expect(note.encounterId, testEncounterId);
      expect(note.patientId, testPatientId);
      expect(note.subjective, 'Severe headache for 3 days');
      expect(note.objective, 'BP: 140/90, HR: 88');
    });

    test('should update clinical note', () async {
      // Arrange
      final noteId = await db.into(db.clinicalNotes).insert(
        TestDataFactory.createClinicalNote(
          encounterId: testEncounterId,
          patientId: testPatientId,
          assessment: 'Initial assessment',
        ),
      );

      // Act
      await (db.update(db.clinicalNotes)..where((n) => n.id.equals(noteId)))
          .write(const ClinicalNotesCompanion(
            assessment: Value('Updated assessment: Tension headache'),
          ));

      // Assert
      final updated = await (db.select(db.clinicalNotes)
            ..where((n) => n.id.equals(noteId)))
          .getSingle();
      expect(updated.assessment, 'Updated assessment: Tension headache');
    });

    test('should delete clinical note', () async {
      // Arrange
      final noteId = await db.into(db.clinicalNotes).insert(
        TestDataFactory.createClinicalNote(
          encounterId: testEncounterId,
          patientId: testPatientId,
        ),
      );
      expect(await db.getClinicalNoteCount(), 1);

      // Act
      await (db.delete(db.clinicalNotes)..where((n) => n.id.equals(noteId)))
          .go();

      // Assert
      expect(await db.getClinicalNoteCount(), 0);
    });

    test('should get clinical notes for encounter', () async {
      // Arrange
      await db.into(db.clinicalNotes).insert(
        TestDataFactory.createClinicalNote(
          encounterId: testEncounterId,
          patientId: testPatientId,
          noteType: 'soap',
        ),
      );
      await db.into(db.clinicalNotes).insert(
        TestDataFactory.createClinicalNote(
          encounterId: testEncounterId,
          patientId: testPatientId,
          noteType: 'progress',
        ),
      );

      // Act
      final notes = await db.getClinicalNotesForEncounter(testEncounterId);

      // Assert
      expect(notes.length, 2);
    });

    test('should store full SOAP note correctly', () async {
      // Arrange
      final noteId = await db.into(db.clinicalNotes).insert(
        TestDataFactory.createClinicalNote(
          encounterId: testEncounterId,
          patientId: testPatientId,
          noteType: 'soap',
          subjective: 'Patient complains of persistent cough for 5 days. Associated with mild fever and fatigue.',
          objective: 'Temp: 37.8°C, BP: 120/80, HR: 78. Lung auscultation reveals mild crackles in right lower lobe.',
          assessment: 'Likely lower respiratory tract infection. Rule out pneumonia.',
          plan: '1. Order chest X-ray\n2. Start amoxicillin 500mg TID x 7 days\n3. Return in 5 days for follow-up',
        ),
      );

      // Act
      final note = await (db.select(db.clinicalNotes)
            ..where((n) => n.id.equals(noteId)))
          .getSingle();

      // Assert
      expect(note.noteType, 'soap');
      expect(note.subjective, contains('persistent cough'));
      expect(note.objective, contains('crackles in right lower lobe'));
      expect(note.assessment, contains('pneumonia'));
      expect(note.plan, contains('amoxicillin'));
    });
  });

  group('Encounter Diagnoses Linking Table Tests', () {
    late int testEncounterId;
    late int testDiagnosisId;

    setUp(() async {
      // Create an encounter
      testEncounterId = await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(
          patientId: testPatientId,
          chiefComplaint: 'Linking test',
        ),
      );

      // Create a diagnosis
      testDiagnosisId = await db.into(db.diagnoses).insert(
        TestDataFactory.createDiagnosis(
          patientId: testPatientId,
          description: 'Test diagnosis for linking',
        ),
      );
    });

    test('should link diagnosis to encounter', () async {
      // Act
      final linkId = await db.into(db.encounterDiagnoses).insert(
        TestDataFactory.createEncounterDiagnosis(
          encounterId: testEncounterId,
          diagnosisId: testDiagnosisId,
        ),
      );

      // Assert
      expect(linkId, greaterThan(0));
    });

    test('should retrieve linked diagnoses for encounter', () async {
      // Arrange
      final diagnosisId2 = await db.into(db.diagnoses).insert(
        TestDataFactory.createDiagnosis(
          patientId: testPatientId,
          description: 'Second diagnosis',
        ),
      );

      await db.into(db.encounterDiagnoses).insert(
        TestDataFactory.createEncounterDiagnosis(
          encounterId: testEncounterId,
          diagnosisId: testDiagnosisId,
        ),
      );
      await db.into(db.encounterDiagnoses).insert(
        TestDataFactory.createEncounterDiagnosis(
          encounterId: testEncounterId,
          diagnosisId: diagnosisId2,
        ),
      );

      // Act
      final links = await db.getEncounterDiagnosesForEncounter(testEncounterId);

      // Assert
      expect(links.length, 2);
    });

    test('should store encounter diagnosis fields correctly', () async {
      // Arrange
      final linkId = await db.into(db.encounterDiagnoses).insert(
        TestDataFactory.createEncounterDiagnosis(
          encounterId: testEncounterId,
          diagnosisId: testDiagnosisId,
          isNewDiagnosis: true,
          notes: 'Primary diagnosis for this encounter',
        ),
      );

      // Act
      final link = await (db.select(db.encounterDiagnoses)
            ..where((ed) => ed.id.equals(linkId)))
          .getSingle();

      // Assert
      expect(link.encounterId, testEncounterId);
      expect(link.diagnosisId, testDiagnosisId);
      expect(link.isNewDiagnosis, true);
      expect(link.notes, 'Primary diagnosis for this encounter');
    });

    test('should delete encounter diagnosis link', () async {
      // Arrange
      final linkId = await db.into(db.encounterDiagnoses).insert(
        TestDataFactory.createEncounterDiagnosis(
          encounterId: testEncounterId,
          diagnosisId: testDiagnosisId,
        ),
      );

      // Act
      await (db.delete(db.encounterDiagnoses)
            ..where((ed) => ed.id.equals(linkId)))
          .go();

      // Assert
      final links = await db.getEncounterDiagnosesForEncounter(testEncounterId);
      expect(links, isEmpty);
    });
  });

  group('Encounter Relationships Tests', () {
    test('should create complete encounter with all related data', () async {
      // Arrange & Act: Create encounter
      final encounterId = await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(
          patientId: testPatientId,
          appointmentId: testAppointmentId,
          chiefComplaint: 'Complete encounter test',
          encounterType: 'consultation',
          status: 'in_progress',
        ),
      );

      // Add clinical note
      final noteId = await db.into(db.clinicalNotes).insert(
        TestDataFactory.createClinicalNote(
          encounterId: encounterId,
          patientId: testPatientId,
          noteType: 'soap',
          subjective: 'Patient presents with...',
          objective: 'Vitals normal...',
          assessment: 'Assessment...',
          plan: 'Treatment plan...',
        ),
      );

      // Add diagnosis
      final diagnosisId = await db.into(db.diagnoses).insert(
        TestDataFactory.createDiagnosis(
          patientId: testPatientId,
          encounterId: encounterId,
          description: 'Complete encounter diagnosis',
          icdCode: 'Z00.00',
        ),
      );

      // Link diagnosis to encounter
      await db.into(db.encounterDiagnoses).insert(
        TestDataFactory.createEncounterDiagnosis(
          encounterId: encounterId,
          diagnosisId: diagnosisId,
          isNewDiagnosis: true,
        ),
      );

      // Assert
      expect(encounterId, greaterThan(0));
      expect(noteId, greaterThan(0));
      expect(diagnosisId, greaterThan(0));

      // Verify counts
      expect(await db.getEncounterCount(), 1);
      expect(await db.getClinicalNoteCount(), 1);
      expect(await db.getDiagnosisCount(), 1);

      // Verify relationships
      final notes = await db.getClinicalNotesForEncounter(encounterId);
      expect(notes.length, 1);
      expect(notes.first.encounterId, encounterId);

      final links = await db.getEncounterDiagnosesForEncounter(encounterId);
      expect(links.length, 1);
      expect(links.first.isNewDiagnosis, true);
    });

    test('should handle multiple encounters for same patient', () async {
      // Arrange: Create 3 encounters
      for (int i = 1; i <= 3; i++) {
        await db.into(db.encounters).insert(
          TestDataFactory.createEncounter(
            patientId: testPatientId,
            chiefComplaint: 'Visit $i',
            encounterDate: DateTime.now().subtract(Duration(days: i * 7)),
          ),
        );
      }

      // Act
      final encounters = await db.getEncountersForPatient(testPatientId);

      // Assert
      expect(encounters.length, 3);
      // Should be ordered by date descending (most recent first)
      expect(encounters.first.chiefComplaint, 'Visit 1');
    });

    test('should handle multiple diagnoses per encounter', () async {
      // Arrange
      final encounterId = await db.into(db.encounters).insert(
        TestDataFactory.createEncounter(
          patientId: testPatientId,
          chiefComplaint: 'Multiple diagnoses test',
        ),
      );

      final diagnosisIds = <int>[];
      final diagnosisData = [
        ('E11.9', 'Type 2 diabetes', true),
        ('I10', 'Essential hypertension', false),
        ('E78.5', 'Hyperlipidemia', false),
      ];

      for (final (icdCode, description, isNew) in diagnosisData) {
        final diagnosisId = await db.into(db.diagnoses).insert(
          TestDataFactory.createDiagnosis(
            patientId: testPatientId,
            encounterId: encounterId,
            icdCode: icdCode,
            description: description,
          ),
        );
        diagnosisIds.add(diagnosisId);

        await db.into(db.encounterDiagnoses).insert(
          TestDataFactory.createEncounterDiagnosis(
            encounterId: encounterId,
            diagnosisId: diagnosisId,
            isNewDiagnosis: isNew,
          ),
        );
      }

      // Act
      final links = await db.getEncounterDiagnosesForEncounter(encounterId);
      final newDiagnosisLinks = links.where((l) => l.isNewDiagnosis).toList();

      // Assert
      expect(links.length, 3);
      expect(newDiagnosisLinks.length, 1);
    });
  });
}
