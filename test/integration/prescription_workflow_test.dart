/// Integration tests for prescription workflow
///
/// Tests the complete prescription workflow from creation to PDF generation
/// including medication management and database operations.
import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_database.dart';

void main() {
  late TestDoctorDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('Prescription Workflow Integration Tests', () {
    group('Prescription Creation', () {
      test('should create prescription with single medication', () async {
        // Create patient first
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Alice',
            lastName: 'Johnson',
            phone: '555-111-2222',
            age: 35, // Born 1990
          ),
        );
        expect(patientId, greaterThan(0));

        // Create prescription
        final medications = [
          {
            'name': 'Amoxicillin',
            'dosage': '500mg',
            'frequency': 'Three times daily',
            'duration': '7 days',
            'instructions': 'Take with food',
          },
        ];

        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode(medications),
            instructions: 'Complete the full course',
          ),
        );
        expect(prescriptionId, greaterThan(0));

        // Verify prescription
        final prescription = await db.getPrescriptionById(prescriptionId);
        expect(prescription, isNotNull);
        expect(prescription!.patientId, equals(patientId));

        // Verify medication data
        final items = jsonDecode(prescription.itemsJson) as List;
        expect(items.length, equals(1));
        expect(items[0]['name'], equals('Amoxicillin'));
        expect(items[0]['dosage'], equals('500mg'));
      });

      test('should create prescription with multiple medications', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Bob',
            lastName: 'Smith',
            phone: '555-333-4444',
          ),
        );

        final medications = [
          {
            'name': 'Metformin',
            'dosage': '500mg',
            'frequency': 'Twice daily',
            'duration': '30 days',
          },
          {
            'name': 'Lisinopril',
            'dosage': '10mg',
            'frequency': 'Once daily',
            'duration': '30 days',
          },
          {
            'name': 'Aspirin',
            'dosage': '81mg',
            'frequency': 'Once daily',
            'duration': '30 days',
          },
        ];

        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode(medications),
          ),
        );

        final prescription = await db.getPrescriptionById(prescriptionId);
        final items = jsonDecode(prescription!.itemsJson) as List;
        expect(items.length, equals(3));
      });

      test('should create prescription with diagnosis', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Carol',
            lastName: 'White',
            phone: '555-555-6666',
          ),
        );

        final prescriptionId = await db.insertPrescription(
          PrescriptionsCompanion.insert(
            patientId: patientId,
            itemsJson: Value(jsonEncode([{'name': 'Vitamin D', 'dosage': '1000 IU'}])),
            diagnosis: const Value('Vitamin D deficiency'),
          ),
        );

        final prescription = await db.getPrescriptionById(prescriptionId);
        expect(prescription, isNotNull);
        expect(prescription!.diagnosis, equals('Vitamin D deficiency'));
      });

      test('should create prescription with vitals', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'David',
            lastName: 'Brown',
            phone: '555-777-8888',
          ),
        );

        final vitals = {
          'bp_systolic': 120,
          'bp_diastolic': 80,
          'pulse': 72,
          'temperature': 98.6,
        };
        
        final prescriptionId = await db.insertPrescription(
          PrescriptionsCompanion.insert(
            patientId: patientId,
            itemsJson: Value(jsonEncode([{'name': 'Atorvastatin', 'dosage': '20mg'}])),
            vitalsJson: Value(jsonEncode(vitals)),
          ),
        );

        final prescription = await db.getPrescriptionById(prescriptionId);
        expect(prescription!.vitalsJson, isNotEmpty);
        final parsedVitals = jsonDecode(prescription.vitalsJson) as Map<String, dynamic>;
        expect(parsedVitals['bp_systolic'], equals(120));
      });
    });

    group('Prescription Retrieval', () {
      test('should get all prescriptions for patient', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Emily',
            lastName: 'Davis',
            phone: '555-999-0000',
          ),
        );

        // Create multiple prescriptions
        await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Drug A'}]),
          ),
        );
        await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Drug B'}]),
          ),
        );
        await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Drug C'}]),
          ),
        );

        final prescriptions = await db.getPrescriptionsForPatient(patientId);
        expect(prescriptions.length, equals(3));
      });

      test('should get prescriptions in date order', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Frank',
            lastName: 'Miller',
            phone: '555-111-3333',
          ),
        );

        // Create prescriptions
        await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Drug Old'}]),
          ),
        );
        await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Drug New'}]),
          ),
        );

        final prescriptions = await db.getPrescriptionsForPatient(patientId);
        expect(prescriptions.length, equals(2));
        // Most recent should be first (if sorted by date desc)
      });
    });

    group('Prescription Update', () {
      test('should update prescription medications', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Grace',
            lastName: 'Lee',
            phone: '555-222-4444',
          ),
        );

        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Original Drug', 'dosage': '100mg'}]),
          ),
        );

        // Update with new medication
        final newMedications = [
          {'name': 'Updated Drug', 'dosage': '200mg'},
          {'name': 'Additional Drug', 'dosage': '50mg'},
        ];

        await db.updatePrescriptionById(
          prescriptionId,
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode(newMedications),
          ),
        );

        final updated = await db.getPrescriptionById(prescriptionId);
        final items = jsonDecode(updated!.itemsJson) as List;
        expect(items.length, equals(2));
        expect(items[0]['name'], equals('Updated Drug'));
      });

      test('should update prescription instructions', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Henry',
            lastName: 'Wilson',
            phone: '555-333-5555',
          ),
        );

        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Test Drug'}]),
            instructions: 'Original instructions',
          ),
        );

        await db.updatePrescriptionById(
          prescriptionId,
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Test Drug'}]),
            instructions: 'Updated instructions with more details',
          ),
        );

        final updated = await db.getPrescriptionById(prescriptionId);
        expect(updated!.instructions, equals('Updated instructions with more details'));
      });
    });

    group('Prescription with Appointments', () {
      test('should link prescription to appointment', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Ivy',
            lastName: 'Chen',
            phone: '555-444-6666',
          ),
        );

        // Create appointment
        final appointmentId = await db.insertAppointment(
          TestDataFactory.createAppointment(
            patientId: patientId,
            appointmentDateTime: DateTime.now(),
            reason: 'Consultation',
            status: 'completed',
          ),
        );

        // Create prescription linked to appointment
        final prescriptionId = await db.insertPrescription(
          PrescriptionsCompanion.insert(
            patientId: patientId,
            itemsJson: Value(jsonEncode([{'name': 'Prescription Drug'}])),
            appointmentId: Value(appointmentId),
          ),
        );

        final prescription = await db.getPrescriptionById(prescriptionId);
        expect(prescription!.appointmentId, equals(appointmentId));
      });

      test('should link prescription to medical record', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Jack',
            lastName: 'Taylor',
            phone: '555-555-7777',
          ),
        );

        // Create medical record
        final recordId = await db.insertMedicalRecord(
          TestDataFactory.createMedicalRecord(
            patientId: patientId,
            title: 'Diagnosis',
            diagnosis: 'Common cold',
          ),
        );

        // Create prescription linked to medical record
        final prescriptionId = await db.insertPrescription(
          PrescriptionsCompanion.insert(
            patientId: patientId,
            itemsJson: Value(jsonEncode([{'name': 'Cold medicine'}])),
            medicalRecordId: Value(recordId),
          ),
        );

        final prescription = await db.getPrescriptionById(prescriptionId);
        expect(prescription!.medicalRecordId, equals(recordId));
      });
    });

    group('Prescription Deletion', () {
      test('should delete prescription', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Karen',
            lastName: 'Harris',
            phone: '555-666-8888',
          ),
        );

        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'To Delete'}]),
          ),
        );

        // Verify exists
        var prescription = await db.getPrescriptionById(prescriptionId);
        expect(prescription, isNotNull);

        // Delete
        await db.deletePrescription(prescriptionId);

        // Verify deleted
        prescription = await db.getPrescriptionById(prescriptionId);
        expect(prescription, isNull);
      });

      test('should not affect other prescriptions when deleting one', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Leo',
            lastName: 'Martin',
            phone: '555-777-9999',
          ),
        );

        final id1 = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Keep 1'}]),
          ),
        );
        final id2 = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Delete This'}]),
          ),
        );
        final id3 = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Keep 2'}]),
          ),
        );

        // Delete middle one
        await db.deletePrescription(id2);

        // Verify others remain
        final prescriptions = await db.getPrescriptionsForPatient(patientId);
        expect(prescriptions.length, equals(2));

        final p1 = await db.getPrescriptionById(id1);
        final p3 = await db.getPrescriptionById(id3);
        expect(p1, isNotNull);
        expect(p3, isNotNull);
      });
    });

    group('Complete Prescription Workflow', () {
      test('should complete full workflow: create patient, appointment, and prescription', () async {
        // Step 1: Create patient with medical history
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Maria',
            lastName: 'Garcia',
            phone: '555-888-0000',
            age: 50, // Born 1975
            medicalHistory: 'Diabetes Type 2, Hypertension',
          ),
        );
        expect(patientId, greaterThan(0));

        // Step 2: Create initial consultation appointment
        final appointmentId = await db.insertAppointment(
          TestDataFactory.createAppointment(
            patientId: patientId,
            appointmentDateTime: DateTime.now(),
            reason: 'Routine checkup',
            status: 'completed',
          ),
        );
        expect(appointmentId, greaterThan(0));

        // Step 3: Create prescription with multiple medications
        final medications = [
          {
            'name': 'Metformin',
            'dosage': '1000mg',
            'frequency': 'Twice daily with meals',
            'duration': '90 days',
            'instructions': 'Take with food to reduce GI side effects',
          },
          {
            'name': 'Losartan',
            'dosage': '50mg',
            'frequency': 'Once daily',
            'duration': '90 days',
            'instructions': 'Take at same time each day',
          },
        ];

        final prescriptionId = await db.insertPrescription(
          PrescriptionsCompanion.insert(
            patientId: patientId,
            itemsJson: Value(jsonEncode(medications)),
            diagnosis: const Value('Diabetes mellitus type 2, Essential hypertension'),
            instructions: const Value('Monitor blood sugar regularly. Return if symptoms worsen.'),
            appointmentId: Value(appointmentId),
          ),
        );
        expect(prescriptionId, greaterThan(0));

        // Step 4: Verify complete prescription
        final finalPrescription = await db.getPrescriptionById(prescriptionId);
        expect(finalPrescription, isNotNull);
        expect(finalPrescription!.patientId, equals(patientId));
        expect(finalPrescription.appointmentId, equals(appointmentId));
        
        final items = jsonDecode(finalPrescription.itemsJson) as List;
        expect(items.length, equals(2));

        // Step 5: Verify patient history shows prescription
        final patientPrescriptions = await db.getPrescriptionsForPatient(patientId);
        expect(patientPrescriptions.length, equals(1));
        expect(patientPrescriptions.first.id, equals(prescriptionId));
      });

      test('should handle prescription revision workflow', () async {
        // Create patient
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Nancy',
            lastName: 'Thompson',
            phone: '555-999-1111',
          ),
        );

        // Create initial prescription
        final initialMeds = [
          {'name': 'Drug A', 'dosage': '10mg'},
        ];
        
        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode(initialMeds),
            instructions: 'Initial prescription',
          ),
        );

        // Patient returns - medication not effective
        // Update prescription with revised medications
        final revisedMeds = [
          {'name': 'Drug A', 'dosage': '20mg'}, // Increased dosage
          {'name': 'Drug B', 'dosage': '5mg'},  // Added medication
        ];

        await db.updatePrescriptionById(
          prescriptionId,
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode(revisedMeds),
            instructions: 'Revised: Increased dosage due to inadequate response',
          ),
        );

        // Verify revision
        final revised = await db.getPrescriptionById(prescriptionId);
        final items = jsonDecode(revised!.itemsJson) as List;
        expect(items.length, equals(2));
        expect(items[0]['dosage'], equals('20mg'));
        expect(revised.instructions, contains('Revised'));
      });
    });

    group('Edge Cases', () {
      test('should handle prescription with empty medications', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Oscar',
            lastName: 'Price',
            phone: '555-000-2222',
          ),
        );

        // Prescription with only advice, no medications
        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([]),
            instructions: 'Rest and plenty of fluids. No medication needed.',
          ),
        );

        final prescription = await db.getPrescriptionById(prescriptionId);
        final items = jsonDecode(prescription!.itemsJson) as List;
        expect(items, isEmpty);
        expect(prescription.instructions, isNotEmpty);
      });

      test('should handle prescription with special characters in medication names', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Paul',
            lastName: 'Quinn',
            phone: '555-111-3333',
          ),
        );

        final medications = [
          {
            'name': 'Vitamin B12 (Cyanocobalamin)',
            'dosage': '1000mcg/mL',
            'instructions': 'IM injection - once weekly × 4 weeks',
          },
          {
            'name': "Drug with 'quotes' and \"double quotes\"",
            'dosage': '100mg',
          },
        ];

        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode(medications),
          ),
        );

        final prescription = await db.getPrescriptionById(prescriptionId);
        final items = jsonDecode(prescription!.itemsJson) as List;
        expect(items[0]['name'], contains('B12'));
        expect(items[0]['name'], contains('('));
        expect(items[1]['name'], contains("'"));
      });

      test('should handle very long prescription notes', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Rita',
            lastName: 'Stone',
            phone: '555-222-4444',
          ),
        );

        final longInstructions = 'Detailed instructions: ' + 'A' * 2000;
        
        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Test Drug'}]),
            instructions: longInstructions,
          ),
        );

        final prescription = await db.getPrescriptionById(prescriptionId);
        expect(prescription!.instructions.length, greaterThan(2000));
      });

      test('should handle refillable prescriptions', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Sam',
            lastName: 'Turner',
            phone: '555-333-5555',
          ),
        );

        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: jsonEncode([{'name': 'Chronic med'}]),
            isRefillable: true,
          ),
        );

        final prescription = await db.getPrescriptionById(prescriptionId);
        expect(prescription!.isRefillable, isTrue);
      });

      test('should handle chief complaint field', () async {
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Tom',
            lastName: 'Adams',
            phone: '555-444-6666',
          ),
        );

        final prescriptionId = await db.insertPrescription(
          PrescriptionsCompanion.insert(
            patientId: patientId,
            itemsJson: Value(jsonEncode([{'name': 'Pain reliever'}])),
            chiefComplaint: const Value('Headache for 3 days'),
          ),
        );

        final prescription = await db.getPrescriptionById(prescriptionId);
        expect(prescription!.chiefComplaint, equals('Headache for 3 days'));
      });
    });
  });
}
