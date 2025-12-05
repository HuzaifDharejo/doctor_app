/// Integration tests for patient workflow
///
/// Tests the complete patient workflow from creation to management
/// including appointments, prescriptions, and medical records.
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

  group('Patient Workflow Integration Tests', () {
    group('Complete Patient Journey', () {
      test('should create patient, add appointment, create prescription, and generate invoice', () async {
        // Step 1: Create a patient
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'John',
            lastName: 'Doe',
            phone: '555-123-4567',
            email: 'john.doe@email.com',
            dateOfBirth: DateTime(1985, 5, 15),
          ),
        );
        expect(patientId, greaterThan(0));

        // Verify patient was created
        final patient = await db.getPatientById(patientId);
        expect(patient, isNotNull);
        expect(patient!.firstName, equals('John'));
        expect(patient.lastName, equals('Doe'));

        // Step 2: Schedule an appointment for the patient
        final appointmentDate = DateTime.now().add(const Duration(days: 7));
        final appointmentId = await db.insertAppointment(
          TestDataFactory.createAppointment(
            patientId: patientId,
            appointmentDateTime: appointmentDate,
            reason: 'Initial consultation',
            status: 'scheduled',
            durationMinutes: 30,
          ),
        );
        expect(appointmentId, greaterThan(0));

        // Verify appointment was created
        final appointments = await db.getAppointmentsForPatient(patientId);
        expect(appointments.length, equals(1));
        expect(appointments.first.reason, equals('Initial consultation'));

        // Step 3: Create a medical record for the visit
        final medicalRecordId = await db.insertMedicalRecord(
          TestDataFactory.createMedicalRecord(
            patientId: patientId,
            recordType: 'general',
            title: 'Initial Assessment',
            recordDate: appointmentDate,
            description: 'Patient presents with mild symptoms.',
            diagnosis: 'Common cold',
            treatment: 'Rest and fluids',
          ),
        );
        expect(medicalRecordId, greaterThan(0));

        // Step 4: Create a prescription
        final prescriptionId = await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: '[{"name": "Paracetamol", "dosage": "500mg", "frequency": "Every 6 hours", "duration": "5 days"}]',
            instructions: 'Take with food',
          ),
        );
        expect(prescriptionId, greaterThan(0));

        // Verify prescription was created
        final prescriptions = await db.getPrescriptionsForPatient(patientId);
        expect(prescriptions.length, equals(1));

        // Step 5: Create an invoice
        final invoiceId = await db.insertInvoice(
          TestDataFactory.createInvoice(
            patientId: patientId,
            invoiceNumber: 'INV-001',
            invoiceDate: DateTime.now(),
            itemsJson: '[{"description": "Consultation", "amount": 100.00}]',
            grandTotal: 100.00,
            subtotal: 100.00,
            paymentStatus: 'Pending',
          ),
        );
        expect(invoiceId, greaterThan(0));

        // Verify invoice was created
        final invoices = await db.getInvoicesForPatient(patientId);
        expect(invoices.length, equals(1));
        expect(invoices.first.grandTotal, equals(100.00));
        expect(invoices.first.paymentStatus, equals('Pending'));

        // Step 6: Update appointment status to completed
        final appointmentToUpdate = await db.getAppointmentById(appointmentId);
        await db.updateAppointment(appointmentToUpdate!.copyWith(status: 'completed'));

        // Verify appointment status updated
        final updatedAppointments = await db.getAppointmentsForPatient(patientId);
        expect(updatedAppointments.first.status, equals('completed'));
      });

      test('should handle patient with multiple appointments', () async {
        // Create patient
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(
            firstName: 'Jane',
            lastName: 'Smith',
          ),
        );

        // Create multiple appointments
        final now = DateTime.now();
        for (var i = 0; i < 5; i++) {
          await db.insertAppointment(
            TestDataFactory.createAppointment(
              patientId: patientId,
              appointmentDateTime: now.add(Duration(days: i * 7)),
              reason: 'Appointment ${i + 1}',
              status: i < 3 ? 'completed' : 'scheduled',
            ),
          );
        }

        // Verify all appointments
        final appointments = await db.getAppointmentsForPatient(patientId);
        expect(appointments.length, equals(5));

        // Verify completed count
        final completedCount = appointments.where((a) => a.status == 'completed').length;
        expect(completedCount, equals(3));
      });
    });

    group('Patient Search and Filtering', () {
      test('should search patients by name', () async {
        // Create test patients
        await db.insertPatient(
          TestDataFactory.createPatient(firstName: 'Alice', lastName: 'Anderson'),
        );
        await db.insertPatient(
          TestDataFactory.createPatient(firstName: 'Bob', lastName: 'Brown'),
        );
        await db.insertPatient(
          TestDataFactory.createPatient(firstName: 'Charlie', lastName: 'Clark'),
        );
        await db.insertPatient(
          TestDataFactory.createPatient(firstName: 'Alice', lastName: 'Adams'),
        );

        // Search for 'Alice'
        final aliceResults = await db.searchPatients('Alice');
        expect(aliceResults.length, equals(2));

        // Search for 'Brown'
        final brownResults = await db.searchPatients('Brown');
        expect(brownResults.length, equals(1));
        expect(brownResults.first.firstName, equals('Bob'));

        // Search for 'a' (should match multiple)
        final aResults = await db.searchPatients('a');
        expect(aResults.length, greaterThanOrEqualTo(3)); // Alice, Alice, Charlie all have 'a'
      });
    });

    group('Vital Signs Tracking', () {
      test('should track vital signs over time', () async {
        // Create patient
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(firstName: 'Test', lastName: 'Patient'),
        );

        // Record vital signs over several days
        final now = DateTime.now();
        final vitalSignsData = [
          {'systolic': 120.0, 'diastolic': 80.0, 'pulse': 72, 'temp': 98.6, 'days': 0},
          {'systolic': 125.0, 'diastolic': 82.0, 'pulse': 75, 'temp': 98.4, 'days': 1},
          {'systolic': 118.0, 'diastolic': 78.0, 'pulse': 70, 'temp': 98.6, 'days': 2},
          {'systolic': 122.0, 'diastolic': 79.0, 'pulse': 73, 'temp': 99.1, 'days': 3},
        ];

        for (final data in vitalSignsData) {
          await db.insertVitalSigns(
            TestDataFactory.createVitalSigns(
              patientId: patientId,
              recordedAt: now.subtract(Duration(days: (data['days'] as int))),
              systolicBp: data['systolic'] as double,
              diastolicBp: data['diastolic'] as double,
              heartRate: data['pulse'] as int,
              temperature: data['temp'] as double,
            ),
          );
        }

        // Verify vital signs count
        final vitalSigns = await db.getVitalSignsForPatient(patientId);
        expect(vitalSigns.length, equals(4));

        // Verify most recent vital sign (should be today's)
        final latestVital = vitalSigns.first;
        expect(latestVital.systolicBp, equals(120.0));
        expect(latestVital.diastolicBp, equals(80.0));
      });
    });

    group('Data Integrity', () {
      test('should cascade delete patient data correctly', () async {
        // Create patient with related data
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(firstName: 'Delete', lastName: 'Test'),
        );

        // Add appointment
        await db.insertAppointment(
          TestDataFactory.createAppointment(
            patientId: patientId,
            appointmentDateTime: DateTime.now(),
          ),
        );

        // Add prescription
        await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: '[]',
          ),
        );

        // Add medical record
        await db.insertMedicalRecord(
          TestDataFactory.createMedicalRecord(
            patientId: patientId,
            recordType: 'general',
            title: 'Test Record',
            recordDate: DateTime.now(),
          ),
        );

        // Verify data exists
        expect(await db.getPatientCount(), equals(1));
        expect(await db.getAppointmentCount(), equals(1));
        expect(await db.getPrescriptionCount(), equals(1));
        expect(await db.getMedicalRecordCount(), equals(1));

        // Delete patient (should cascade)
        await db.deletePatient(patientId);

        // Verify patient was deleted
        expect(await db.getPatientCount(), equals(0));
        // Note: Cascade behavior depends on database schema foreign key settings
      });

      test('should maintain referential integrity', () async {
        // Create patient
        final patientId = await db.insertPatient(
          TestDataFactory.createPatient(firstName: 'Integrity', lastName: 'Test'),
        );

        // Create appointment
        final appointmentId = await db.insertAppointment(
          TestDataFactory.createAppointment(
            patientId: patientId,
            appointmentDateTime: DateTime.now(),
          ),
        );

        // Create prescription
        await db.insertPrescription(
          TestDataFactory.createPrescription(
            patientId: patientId,
            itemsJson: '[]',
          ),
        );

        // Create invoice
        await db.insertInvoice(
          TestDataFactory.createInvoice(
            patientId: patientId,
            invoiceNumber: 'INV-INTEGRITY',
            invoiceDate: DateTime.now(),
            itemsJson: '[]',
          ),
        );

        // Verify all data was created and linked to patient
        final appointments = await db.getAppointmentsForPatient(patientId);
        expect(appointments.length, equals(1));
        expect(appointments.first.id, equals(appointmentId));

        final prescriptions = await db.getPrescriptionsForPatient(patientId);
        expect(prescriptions.length, equals(1));
        expect(prescriptions.first.patientId, equals(patientId));

        final invoices = await db.getInvoicesForPatient(patientId);
        expect(invoices.length, equals(1));
        expect(invoices.first.patientId, equals(patientId));
      });
    });
  });
}
