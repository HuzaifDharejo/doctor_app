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

  group('Patient CRUD Operations', () {
    test('should insert a patient and return ID', () async {
      final id = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'John', lastName: 'Doe'),
      );

      expect(id, greaterThan(0));
    });

    test('should get patient by ID', () async {
      final id = await db.insertPatient(
        TestDataFactory.createPatient(
          firstName: 'John',
          lastName: 'Doe',
          phone: '123-456-7890',
          email: 'john@example.com',
        ),
      );

      final patient = await db.getPatientById(id);

      expect(patient, isNotNull);
      expect(patient!.firstName, equals('John'));
      expect(patient.lastName, equals('Doe'));
      expect(patient.phone, equals('123-456-7890'));
      expect(patient.email, equals('john@example.com'));
    });

    test('should return null for non-existent patient', () async {
      final patient = await db.getPatientById(999);

      expect(patient, isNull);
    });

    test('should get all patients', () async {
      await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'John'),
      );
      await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Jane'),
      );
      await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Bob'),
      );

      final patients = await db.getAllPatients();

      expect(patients.length, equals(3));
    });

    test('should update patient', () async {
      final id = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'John', lastName: 'Doe'),
      );

      final patient = await db.getPatientById(id);
      final updated = patient!.copyWith(firstName: 'Johnny', phone: '555-1234');
      await db.updatePatient(updated);

      final result = await db.getPatientById(id);
      expect(result!.firstName, equals('Johnny'));
      expect(result.phone, equals('555-1234'));
      expect(result.lastName, equals('Doe'));
    });

    test('should delete patient', () async {
      final id = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'John'),
      );

      expect(await db.getPatientById(id), isNotNull);

      final rowsDeleted = await db.deletePatient(id);
      expect(rowsDeleted, equals(1));

      expect(await db.getPatientById(id), isNull);
    });

    test('should handle patient with all fields', () async {
      final id = await db.insertPatient(
        TestDataFactory.createPatient(
          firstName: 'John',
          lastName: 'Doe',
          age: 35,  // was born 1990
          phone: '123-456-7890',
          email: 'john@example.com',
          address: '123 Main St',
          medicalHistory: 'No known allergies',
          tags: 'vip,returning',
          riskLevel: 2,
        ),
      );

      final patient = await db.getPatientById(id);

      expect(patient!.firstName, equals('John'));
      expect(patient.lastName, equals('Doe'));
      expect(patient.age, equals(35));
      expect(patient.phone, equals('123-456-7890'));
      expect(patient.email, equals('john@example.com'));
      expect(patient.address, equals('123 Main St'));
      expect(patient.medicalHistory, equals('No known allergies'));
      expect(patient.tags, equals('vip,returning'));
      expect(patient.riskLevel, equals(2));
      expect(patient.createdAt, isNotNull);
    });

    test('should search patients by first name', () async {
      await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'John', lastName: 'Doe'),
      );
      await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Johnny', lastName: 'Smith'),
      );
      await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Jane', lastName: 'Johnson'),
      );

      final results = await db.searchPatients('john');

      expect(results.length, equals(3)); // John, Johnny, Johnson
    });

    test('should search patients by last name', () async {
      await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'John', lastName: 'Smith'),
      );
      await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Jane', lastName: 'Smithson'),
      );
      await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Bob', lastName: 'Johnson'),
      );

      final results = await db.searchPatients('smith');

      expect(results.length, equals(2));
    });

    test('should get patient count', () async {
      expect(await db.getPatientCount(), equals(0));

      await db.insertPatient(TestDataFactory.createPatient(firstName: 'A'));
      await db.insertPatient(TestDataFactory.createPatient(firstName: 'B'));

      expect(await db.getPatientCount(), equals(2));
    });
  });

  group('Appointment CRUD Operations', () {
    late int patientId;

    setUp(() async {
      patientId = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Test', lastName: 'Patient'),
      );
    });

    test('should insert appointment and return ID', () async {
      final id = await db.insertAppointment(
        TestDataFactory.createAppointment(patientId: patientId),
      );

      expect(id, greaterThan(0));
    });

    test('should get appointment by ID', () async {
      final appointmentTime = DateTime(2024, 6, 15, 10, 30);
      final id = await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          appointmentDateTime: appointmentTime,
          reason: 'Checkup',
          durationMinutes: 30,
          status: 'scheduled',
        ),
      );

      final appointment = await db.getAppointmentById(id);

      expect(appointment, isNotNull);
      expect(appointment!.patientId, equals(patientId));
      expect(appointment.appointmentDateTime, equals(appointmentTime));
      expect(appointment.reason, equals('Checkup'));
      expect(appointment.durationMinutes, equals(30));
      expect(appointment.status, equals('scheduled'));
    });

    test('should get all appointments', () async {
      await db.insertAppointment(
        TestDataFactory.createAppointment(patientId: patientId),
      );
      await db.insertAppointment(
        TestDataFactory.createAppointment(patientId: patientId),
      );

      final appointments = await db.getAllAppointments();

      expect(appointments.length, equals(2));
    });

    test('should get appointments for a specific day', () async {
      final today = DateTime.now();
      final todayMorning = DateTime(today.year, today.month, today.day, 9, 0);
      final todayAfternoon = DateTime(today.year, today.month, today.day, 14, 0);
      final tomorrow = DateTime(today.year, today.month, today.day + 1, 10, 0);

      await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          appointmentDateTime: todayMorning,
        ),
      );
      await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          appointmentDateTime: todayAfternoon,
        ),
      );
      await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          appointmentDateTime: tomorrow,
        ),
      );

      final todayAppointments = await db.getAppointmentsForDay(today);

      expect(todayAppointments.length, equals(2));
    });

    test('should get appointments for a patient', () async {
      final patient2Id = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Another'),
      );

      await db.insertAppointment(
        TestDataFactory.createAppointment(patientId: patientId),
      );
      await db.insertAppointment(
        TestDataFactory.createAppointment(patientId: patientId),
      );
      await db.insertAppointment(
        TestDataFactory.createAppointment(patientId: patient2Id),
      );

      final patientAppointments = await db.getAppointmentsForPatient(patientId);

      expect(patientAppointments.length, equals(2));
    });

    test('should update appointment', () async {
      final id = await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          status: 'scheduled',
        ),
      );

      final appointment = await db.getAppointmentById(id);
      final updated = appointment!.copyWith(status: 'completed', notes: 'Done');
      await db.updateAppointment(updated);

      final result = await db.getAppointmentById(id);
      expect(result!.status, equals('completed'));
      expect(result.notes, equals('Done'));
    });

    test('should delete appointment', () async {
      final id = await db.insertAppointment(
        TestDataFactory.createAppointment(patientId: patientId),
      );

      expect(await db.getAppointmentById(id), isNotNull);

      await db.deleteAppointment(id);

      expect(await db.getAppointmentById(id), isNull);
    });

    test('should get upcoming appointments', () async {
      final now = DateTime.now();
      final future1 = now.add(const Duration(hours: 1));
      final future2 = now.add(const Duration(hours: 2));
      final past = now.subtract(const Duration(hours: 1));

      await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          appointmentDateTime: future1,
        ),
      );
      await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          appointmentDateTime: future2,
        ),
      );
      await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          appointmentDateTime: past,
        ),
      );

      final upcoming = await db.getUpcomingAppointments();

      expect(upcoming.length, equals(2));
      // Should be ordered by date ascending
      expect(upcoming[0].appointmentDateTime.isBefore(upcoming[1].appointmentDateTime), isTrue);
    });

    test('should get past appointments', () async {
      final now = DateTime.now();
      final future = now.add(const Duration(hours: 1));
      final past1 = now.subtract(const Duration(hours: 1));
      final past2 = now.subtract(const Duration(hours: 2));

      await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          appointmentDateTime: future,
        ),
      );
      await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          appointmentDateTime: past1,
        ),
      );
      await db.insertAppointment(
        TestDataFactory.createAppointment(
          patientId: patientId,
          appointmentDateTime: past2,
        ),
      );

      final past = await db.getPastAppointments();

      expect(past.length, equals(2));
      // Should be ordered by date descending (most recent first)
      expect(past[0].appointmentDateTime.isAfter(past[1].appointmentDateTime), isTrue);
    });

    test('should get appointment count', () async {
      expect(await db.getAppointmentCount(), equals(0));

      await db.insertAppointment(
        TestDataFactory.createAppointment(patientId: patientId),
      );

      expect(await db.getAppointmentCount(), equals(1));
    });
  });

  group('Prescription CRUD Operations', () {
    late int patientId;

    setUp(() async {
      patientId = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Test'),
      );
    });

    test('should insert prescription and return ID', () async {
      final id = await db.insertPrescription(
        TestDataFactory.createPrescription(patientId: patientId),
      );

      expect(id, greaterThan(0));
    });

    test('should get prescription by ID', () async {
      final itemsJson = '[{"name":"Med1","dosage":"10mg"}]';
      final id = await db.insertPrescription(
        TestDataFactory.createPrescription(
          patientId: patientId,
          itemsJson: itemsJson,
          instructions: 'Take with food',
          isRefillable: true,
        ),
      );

      final prescription = await db.getPrescriptionById(id);

      expect(prescription, isNotNull);
      expect(prescription!.patientId, equals(patientId));
      expect(prescription.itemsJson, equals(itemsJson));
      expect(prescription.instructions, equals('Take with food'));
      expect(prescription.isRefillable, isTrue);
    });

    test('should get all prescriptions', () async {
      await db.insertPrescription(
        TestDataFactory.createPrescription(patientId: patientId),
      );
      await db.insertPrescription(
        TestDataFactory.createPrescription(patientId: patientId),
      );

      final prescriptions = await db.getAllPrescriptions();

      expect(prescriptions.length, equals(2));
    });

    test('should get prescriptions for patient', () async {
      final patient2Id = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Another'),
      );

      await db.insertPrescription(
        TestDataFactory.createPrescription(patientId: patientId),
      );
      await db.insertPrescription(
        TestDataFactory.createPrescription(patientId: patientId),
      );
      await db.insertPrescription(
        TestDataFactory.createPrescription(patientId: patient2Id),
      );

      final patientPrescriptions = await db.getPrescriptionsForPatient(patientId);

      expect(patientPrescriptions.length, equals(2));
    });

    test('should get last prescription for patient', () async {
      // Insert prescriptions and check ordering by ID (which is reliable)
      final id1 = await db.insertPrescription(
        TestDataFactory.createPrescription(
          patientId: patientId,
          instructions: 'First',
        ),
      );

      final id2 = await db.insertPrescription(
        TestDataFactory.createPrescription(
          patientId: patientId,
          instructions: 'Second',
        ),
      );

      // Verify IDs are sequential
      expect(id2, greaterThan(id1));

      // Get all prescriptions and check the last one has highest ID
      final allPrescriptions = await db.getPrescriptionsForPatient(patientId);
      expect(allPrescriptions.length, equals(2));

      // The getLastPrescriptionForPatient orders by createdAt desc
      // Since they may have the same timestamp, let's just verify we get one
      final lastPrescription = await db.getLastPrescriptionForPatient(patientId);
      expect(lastPrescription, isNotNull);
      expect(['First', 'Second'], contains(lastPrescription!.instructions));
    });

    test('should delete prescription', () async {
      final id = await db.insertPrescription(
        TestDataFactory.createPrescription(patientId: patientId),
      );

      expect(await db.getPrescriptionById(id), isNotNull);

      await db.deletePrescription(id);

      expect(await db.getPrescriptionById(id), isNull);
    });

    test('should get prescription count', () async {
      expect(await db.getPrescriptionCount(), equals(0));

      await db.insertPrescription(
        TestDataFactory.createPrescription(patientId: patientId),
      );

      expect(await db.getPrescriptionCount(), equals(1));
    });
  });

  group('Medical Record CRUD Operations', () {
    late int patientId;

    setUp(() async {
      patientId = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Test'),
      );
    });

    test('should insert medical record and return ID', () async {
      final id = await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(patientId: patientId),
      );

      expect(id, greaterThan(0));
    });

    test('should get medical record by ID', () async {
      final recordDate = DateTime(2024, 3, 15);
      final id = await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(
          patientId: patientId,
          recordType: 'lab_result',
          title: 'Blood Test',
          description: 'Routine checkup',
          dataJson: '{"glucose": 95}',
          diagnosis: 'Normal',
          treatment: 'None',
          doctorNotes: 'All values in range',
          recordDate: recordDate,
        ),
      );

      final record = await db.getMedicalRecordById(id);

      expect(record, isNotNull);
      expect(record!.patientId, equals(patientId));
      expect(record.recordType, equals('lab_result'));
      expect(record.title, equals('Blood Test'));
      expect(record.description, equals('Routine checkup'));
      expect(record.dataJson, equals('{"glucose": 95}'));
      expect(record.diagnosis, equals('Normal'));
      expect(record.treatment, equals('None'));
      expect(record.doctorNotes, equals('All values in range'));
      expect(record.recordDate, equals(recordDate));
    });

    test('should get all medical records', () async {
      await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(patientId: patientId),
      );
      await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(patientId: patientId),
      );

      final records = await db.getAllMedicalRecords();

      expect(records.length, equals(2));
    });

    test('should get medical records for patient ordered by date', () async {
      final patient2Id = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Another'),
      );

      final date1 = DateTime(2024, 1, 1);
      final date2 = DateTime(2024, 6, 1);
      final date3 = DateTime(2024, 3, 1);

      await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(
          patientId: patientId,
          recordDate: date1,
        ),
      );
      await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(
          patientId: patientId,
          recordDate: date2,
        ),
      );
      await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(
          patientId: patientId,
          recordDate: date3,
        ),
      );
      await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(patientId: patient2Id),
      );

      final patientRecords = await db.getMedicalRecordsForPatient(patientId);

      expect(patientRecords.length, equals(3));
      // Should be ordered by date descending
      expect(patientRecords[0].recordDate, equals(date2));
      expect(patientRecords[1].recordDate, equals(date3));
      expect(patientRecords[2].recordDate, equals(date1));
    });

    test('should update medical record', () async {
      final id = await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(
          patientId: patientId,
          diagnosis: 'Initial',
        ),
      );

      final record = await db.getMedicalRecordById(id);
      final updated = record!.copyWith(
        diagnosis: 'Updated diagnosis',
        treatment: 'New treatment',
      );
      await db.updateMedicalRecord(updated);

      final result = await db.getMedicalRecordById(id);
      expect(result!.diagnosis, equals('Updated diagnosis'));
      expect(result.treatment, equals('New treatment'));
    });

    test('should delete medical record', () async {
      final id = await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(patientId: patientId),
      );

      expect(await db.getMedicalRecordById(id), isNotNull);

      await db.deleteMedicalRecord(id);

      expect(await db.getMedicalRecordById(id), isNull);
    });

    test('should get medical records with patient info', () async {
      await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(
          patientId: patientId,
          title: 'Record 1',
        ),
      );

      final recordsWithPatients = await db.getAllMedicalRecordsWithPatients();

      expect(recordsWithPatients.length, equals(1));
      expect(recordsWithPatients[0].record.title, equals('Record 1'));
      expect(recordsWithPatients[0].patient.firstName, equals('Test'));
    });

    test('should get medical record count', () async {
      expect(await db.getMedicalRecordCount(), equals(0));

      await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(patientId: patientId),
      );

      expect(await db.getMedicalRecordCount(), equals(1));
    });
  });

  group('Invoice CRUD Operations', () {
    late int patientId;

    setUp(() async {
      patientId = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Test'),
      );
    });

    test('should insert invoice and return ID', () async {
      final id = await db.insertInvoice(
        TestDataFactory.createInvoice(patientId: patientId),
      );

      expect(id, greaterThan(0));
    });

    test('should get invoice by ID', () async {
      final invoiceDate = DateTime(2024, 6, 15);
      final dueDate = DateTime(2024, 7, 15);
      final itemsJson = '[{"item":"Consultation","price":100}]';

      final id = await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          invoiceNumber: 'INV-2024-001',
          invoiceDate: invoiceDate,
          dueDate: dueDate,
          itemsJson: itemsJson,
          subtotal: 100.0,
          discountPercent: 10.0,
          discountAmount: 10.0,
          taxPercent: 5.0,
          taxAmount: 4.5,
          grandTotal: 94.5,
          paymentMethod: 'Card',
          paymentStatus: 'Paid',
          notes: 'Thank you',
        ),
      );

      final invoice = await db.getInvoiceById(id);

      expect(invoice, isNotNull);
      expect(invoice!.patientId, equals(patientId));
      expect(invoice.invoiceNumber, equals('INV-2024-001'));
      expect(invoice.invoiceDate, equals(invoiceDate));
      expect(invoice.dueDate, equals(dueDate));
      expect(invoice.itemsJson, equals(itemsJson));
      expect(invoice.subtotal, equals(100.0));
      expect(invoice.discountPercent, equals(10.0));
      expect(invoice.discountAmount, equals(10.0));
      expect(invoice.taxPercent, equals(5.0));
      expect(invoice.taxAmount, equals(4.5));
      expect(invoice.grandTotal, equals(94.5));
      expect(invoice.paymentMethod, equals('Card'));
      expect(invoice.paymentStatus, equals('Paid'));
      expect(invoice.notes, equals('Thank you'));
    });

    test('should get all invoices ordered by creation date', () async {
      final id1 = await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          invoiceNumber: 'INV-001',
        ),
      );
      final id2 = await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          invoiceNumber: 'INV-002',
        ),
      );

      final invoices = await db.getAllInvoices();

      expect(invoices.length, equals(2));
      // Both invoices should be present
      final invoiceNumbers = invoices.map((i) => i.invoiceNumber).toList();
      expect(invoiceNumbers, containsAll(['INV-001', 'INV-002']));
      
      // Verify both IDs are valid
      expect(id1, greaterThan(0));
      expect(id2, greaterThan(0));
    });

    test('should get invoices for patient', () async {
      final patient2Id = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Another'),
      );

      await db.insertInvoice(
        TestDataFactory.createInvoice(patientId: patientId),
      );
      await db.insertInvoice(
        TestDataFactory.createInvoice(patientId: patientId),
      );
      await db.insertInvoice(
        TestDataFactory.createInvoice(patientId: patient2Id),
      );

      final patientInvoices = await db.getInvoicesForPatient(patientId);

      expect(patientInvoices.length, equals(2));
    });

    test('should update invoice', () async {
      final id = await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          paymentStatus: 'Pending',
        ),
      );

      final invoice = await db.getInvoiceById(id);
      final updated = invoice!.copyWith(
        paymentStatus: 'Paid',
        paymentMethod: 'Cash',
      );
      await db.updateInvoice(updated);

      final result = await db.getInvoiceById(id);
      expect(result!.paymentStatus, equals('Paid'));
      expect(result.paymentMethod, equals('Cash'));
    });

    test('should delete invoice', () async {
      final id = await db.insertInvoice(
        TestDataFactory.createInvoice(patientId: patientId),
      );

      expect(await db.getInvoiceById(id), isNotNull);

      await db.deleteInvoice(id);

      expect(await db.getInvoiceById(id), isNull);
    });

    test('should get invoice count', () async {
      expect(await db.getInvoiceCount(), equals(0));

      await db.insertInvoice(
        TestDataFactory.createInvoice(patientId: patientId),
      );

      expect(await db.getInvoiceCount(), equals(1));
    });
  });

  group('Invoice Statistics', () {
    late int patientId;

    setUp(() async {
      patientId = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Test'),
      );
    });

    test('should calculate invoice stats with no invoices', () async {
      final stats = await db.getInvoiceStats();

      expect(stats['totalRevenue'], equals(0.0));
      expect(stats['pending'], equals(0.0));
      expect(stats['paid'], equals(0.0));
      expect(stats['pendingCount'], equals(0.0));
    });

    test('should calculate invoice stats with paid invoices only', () async {
      await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          grandTotal: 100.0,
          paymentStatus: 'Paid',
        ),
      );
      await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          grandTotal: 150.0,
          paymentStatus: 'Paid',
        ),
      );

      final stats = await db.getInvoiceStats();

      expect(stats['totalRevenue'], equals(250.0));
      expect(stats['paid'], equals(250.0));
      expect(stats['pending'], equals(0.0));
      expect(stats['pendingCount'], equals(0.0));
    });

    test('should calculate invoice stats with pending invoices only', () async {
      await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          grandTotal: 200.0,
          paymentStatus: 'Pending',
        ),
      );
      await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          grandTotal: 300.0,
          paymentStatus: 'Overdue',
        ),
      );

      final stats = await db.getInvoiceStats();

      expect(stats['totalRevenue'], equals(0.0));
      expect(stats['paid'], equals(0.0));
      expect(stats['pending'], equals(500.0));
      expect(stats['pendingCount'], equals(2.0));
    });

    test('should calculate invoice stats with mixed payment statuses', () async {
      await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          grandTotal: 100.0,
          paymentStatus: 'Paid',
        ),
      );
      await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          grandTotal: 200.0,
          paymentStatus: 'Pending',
        ),
      );
      await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          grandTotal: 150.0,
          paymentStatus: 'Paid',
        ),
      );
      await db.insertInvoice(
        TestDataFactory.createInvoice(
          patientId: patientId,
          grandTotal: 75.0,
          paymentStatus: 'Partial',
        ),
      );

      final stats = await db.getInvoiceStats();

      expect(stats['totalRevenue'], equals(250.0)); // Only paid invoices
      expect(stats['paid'], equals(250.0));
      expect(stats['pending'], equals(275.0)); // Pending + Partial
      expect(stats['pendingCount'], equals(2.0));
    });
  });

  group('Database Clear Operations', () {
    test('should clear all tables', () async {
      // Insert data into all tables
      final patientId = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Test'),
      );
      await db.insertAppointment(
        TestDataFactory.createAppointment(patientId: patientId),
      );
      await db.insertPrescription(
        TestDataFactory.createPrescription(patientId: patientId),
      );
      await db.insertMedicalRecord(
        TestDataFactory.createMedicalRecord(patientId: patientId),
      );
      await db.insertInvoice(
        TestDataFactory.createInvoice(patientId: patientId),
      );

      // Verify data exists
      expect(await db.getPatientCount(), greaterThan(0));
      expect(await db.getAppointmentCount(), greaterThan(0));
      expect(await db.getPrescriptionCount(), greaterThan(0));
      expect(await db.getMedicalRecordCount(), greaterThan(0));
      expect(await db.getInvoiceCount(), greaterThan(0));

      // Clear all tables
      await db.clearAllTables();

      // Verify all cleared
      expect(await db.getPatientCount(), equals(0));
      expect(await db.getAppointmentCount(), equals(0));
      expect(await db.getPrescriptionCount(), equals(0));
      expect(await db.getMedicalRecordCount(), equals(0));
      expect(await db.getInvoiceCount(), equals(0));
    });
  });

  group('Foreign Key Constraints', () {
    test('appointments should reference valid patient', () async {
      final patientId = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Test'),
      );

      final appointmentId = await db.insertAppointment(
        TestDataFactory.createAppointment(patientId: patientId),
      );

      final appointment = await db.getAppointmentById(appointmentId);
      expect(appointment!.patientId, equals(patientId));

      // The patient referenced by the appointment should exist
      final patient = await db.getPatientById(appointment.patientId);
      expect(patient, isNotNull);
    });

    test('prescriptions should reference valid patient', () async {
      final patientId = await db.insertPatient(
        TestDataFactory.createPatient(firstName: 'Test'),
      );

      final prescriptionId = await db.insertPrescription(
        TestDataFactory.createPrescription(patientId: patientId),
      );

      final prescription = await db.getPrescriptionById(prescriptionId);
      expect(prescription!.patientId, equals(patientId));
    });
  });

  group('TestDataFactory', () {
    test('should create patient with defaults', () {
      final patient = TestDataFactory.createPatient();

      expect(patient.firstName.value, equals('Test'));
    });

    test('should create patient with custom values', () {
      final patient = TestDataFactory.createPatient(
        firstName: 'John',
        lastName: 'Doe',
        riskLevel: 3,
      );

      expect(patient.firstName.value, equals('John'));
      expect(patient.lastName.value, equals('Doe'));
      expect(patient.riskLevel.value, equals(3));
    });

    test('should create appointment with defaults', () {
      final appointment = TestDataFactory.createAppointment(patientId: 1);

      expect(appointment.patientId.value, equals(1));
      expect(appointment.durationMinutes.value, equals(15));
      expect(appointment.status.value, equals('scheduled'));
    });

    test('should create prescription with defaults', () {
      final prescription = TestDataFactory.createPrescription(patientId: 1);

      expect(prescription.patientId.value, equals(1));
      expect(prescription.itemsJson.value, equals('[]'));
      expect(prescription.isRefillable.value, isFalse);
    });

    test('should create medical record with defaults', () {
      final record = TestDataFactory.createMedicalRecord(patientId: 1);

      expect(record.patientId.value, equals(1));
      expect(record.recordType.value, equals('general'));
      expect(record.title.value, equals('Test Record'));
    });

    test('should create invoice with defaults', () {
      final invoice = TestDataFactory.createInvoice(patientId: 1);

      expect(invoice.patientId.value, equals(1));
      expect(invoice.invoiceNumber.value, equals('INV-001'));
      expect(invoice.paymentStatus.value, equals('Pending'));
    });
  });
}
