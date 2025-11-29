import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:doctor_app/src/db/doctor_db.dart';
export 'package:doctor_app/src/db/doctor_db.dart';

/// Creates an in-memory database for testing.
/// 
/// Each call creates a fresh, isolated database instance that is
/// fully functional and matches the production database schema.
/// 
/// Example usage:
/// ```dart
/// late TestDoctorDatabase db;
/// 
/// setUp(() {
///   db = createTestDatabase();
/// });
/// 
/// tearDown(() async {
///   await db.close();
/// });
/// 
/// test('should insert patient', () async {
///   final id = await db.insertPatient(
///     PatientsCompanion.insert(firstName: 'John'),
///   );
///   expect(id, greaterThan(0));
/// });
/// ```
TestDoctorDatabase createTestDatabase() {
  return TestDoctorDatabase();
}

/// In-memory database for testing.
/// 
/// Uses SQLite in-memory mode for fast, isolated tests.
/// This class extends the main DoctorDatabase functionality
/// with additional test-specific methods.
class TestDoctorDatabase extends DoctorDatabase {
  /// Creates a new in-memory database instance for testing.
  TestDoctorDatabase() : super.forTesting(NativeDatabase.memory());

  /// Clears all data from all tables.
  /// Useful for resetting state between tests.
  Future<void> clearAllTables() async {
    await transaction(() async {
      await delete(invoices).go();
      await delete(prescriptions).go();
      await delete(medicalRecords).go();
      await delete(appointments).go();
      await delete(patients).go();
    });
  }

  /// Gets the count of patients in the database.
  Future<int> getPatientCount() async {
    final result = await customSelect('SELECT COUNT(*) as count FROM patients')
        .getSingle();
    return result.read<int>('count');
  }

  /// Gets the count of appointments in the database.
  Future<int> getAppointmentCount() async {
    final result =
        await customSelect('SELECT COUNT(*) as count FROM appointments')
            .getSingle();
    return result.read<int>('count');
  }

  /// Gets the count of prescriptions in the database.
  Future<int> getPrescriptionCount() async {
    final result =
        await customSelect('SELECT COUNT(*) as count FROM prescriptions')
            .getSingle();
    return result.read<int>('count');
  }

  /// Gets the count of medical records in the database.
  Future<int> getMedicalRecordCount() async {
    final result =
        await customSelect('SELECT COUNT(*) as count FROM medical_records')
            .getSingle();
    return result.read<int>('count');
  }

  /// Gets the count of invoices in the database.
  Future<int> getInvoiceCount() async {
    final result =
        await customSelect('SELECT COUNT(*) as count FROM invoices').getSingle();
    return result.read<int>('count');
  }

  /// Search patients by name (first or last name contains query).
  Future<List<Patient>> searchPatients(String query) {
    final lowerQuery = '%${query.toLowerCase()}%';
    return (select(patients)
          ..where((p) =>
              p.firstName.lower().like(lowerQuery) |
              p.lastName.lower().like(lowerQuery)))
        .get();
  }

  /// Get appointments for a patient.
  Future<List<Appointment>> getAppointmentsForPatient(int patientId) {
    return (select(appointments)
          ..where((a) => a.patientId.equals(patientId))
          ..orderBy([(a) => OrderingTerm.desc(a.appointmentDateTime)]))
        .get();
  }

  /// Get appointment by ID.
  Future<Appointment?> getAppointmentById(int id) {
    return (select(appointments)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// Update an appointment.
  Future<bool> updateAppointment(Insertable<Appointment> appointment) {
    return update(appointments).replace(appointment);
  }

  /// Get prescription by ID.
  Future<Prescription?> getPrescriptionById(int id) {
    return (select(prescriptions)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get upcoming appointments (from now).
  Future<List<Appointment>> getUpcomingAppointments({int limit = 10}) {
    final now = DateTime.now();
    return (select(appointments)
          ..where((a) => a.appointmentDateTime.isBiggerOrEqualValue(now))
          ..orderBy([(a) => OrderingTerm.asc(a.appointmentDateTime)])
          ..limit(limit))
        .get();
  }

  /// Get past appointments (before now).
  Future<List<Appointment>> getPastAppointments({int limit = 10}) {
    final now = DateTime.now();
    return (select(appointments)
          ..where((a) => a.appointmentDateTime.isSmallerThanValue(now))
          ..orderBy([(a) => OrderingTerm.desc(a.appointmentDateTime)])
          ..limit(limit))
        .get();
  }
}

/// Test data factory for creating sample data in tests.
class TestDataFactory {
  TestDataFactory._();

  /// Creates a patient companion with minimal required data.
  static PatientsCompanion createPatient({
    String firstName = 'Test',
    String? lastName,
    DateTime? dateOfBirth,
    String? phone,
    String? email,
    String? address,
    String? medicalHistory,
    String? tags,
    int? riskLevel,
  }) {
    return PatientsCompanion.insert(
      firstName: firstName,
      lastName: Value(lastName ?? ''),
      dateOfBirth: Value(dateOfBirth),
      phone: Value(phone ?? ''),
      email: Value(email ?? ''),
      address: Value(address ?? ''),
      medicalHistory: Value(medicalHistory ?? ''),
      tags: Value(tags ?? ''),
      riskLevel: Value(riskLevel ?? 0),
    );
  }

  /// Creates an appointment companion with minimal required data.
  static AppointmentsCompanion createAppointment({
    required int patientId,
    DateTime? appointmentDateTime,
    int? durationMinutes,
    String? reason,
    String? status,
    DateTime? reminderAt,
    String? notes,
  }) {
    return AppointmentsCompanion.insert(
      patientId: patientId,
      appointmentDateTime: appointmentDateTime ?? DateTime.now(),
      durationMinutes: Value(durationMinutes ?? 15),
      reason: Value(reason ?? ''),
      status: Value(status ?? 'scheduled'),
      reminderAt: Value(reminderAt),
      notes: Value(notes ?? ''),
    );
  }

  /// Creates a prescription companion with minimal required data.
  static PrescriptionsCompanion createPrescription({
    required int patientId,
    String? itemsJson,
    String? instructions,
    bool? isRefillable,
  }) {
    return PrescriptionsCompanion.insert(
      patientId: patientId,
      itemsJson: itemsJson ?? '[]',
      instructions: Value(instructions ?? ''),
      isRefillable: Value(isRefillable ?? false),
    );
  }

  /// Creates a medical record companion with minimal required data.
  static MedicalRecordsCompanion createMedicalRecord({
    required int patientId,
    String? recordType,
    String? title,
    String? description,
    String? dataJson,
    String? diagnosis,
    String? treatment,
    String? doctorNotes,
    DateTime? recordDate,
  }) {
    return MedicalRecordsCompanion.insert(
      patientId: patientId,
      recordType: recordType ?? 'general',
      title: title ?? 'Test Record',
      description: Value(description ?? ''),
      dataJson: Value(dataJson ?? '{}'),
      diagnosis: Value(diagnosis ?? ''),
      treatment: Value(treatment ?? ''),
      doctorNotes: Value(doctorNotes ?? ''),
      recordDate: recordDate ?? DateTime.now(),
    );
  }

  /// Creates an invoice companion with minimal required data.
  static InvoicesCompanion createInvoice({
    required int patientId,
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? itemsJson,
    double? subtotal,
    double? discountPercent,
    double? discountAmount,
    double? taxPercent,
    double? taxAmount,
    double? grandTotal,
    String? paymentMethod,
    String? paymentStatus,
    String? notes,
  }) {
    return InvoicesCompanion.insert(
      patientId: patientId,
      invoiceNumber: invoiceNumber ?? 'INV-001',
      invoiceDate: invoiceDate ?? DateTime.now(),
      dueDate: Value(dueDate),
      itemsJson: itemsJson ?? '[]',
      subtotal: Value(subtotal ?? 0),
      discountPercent: Value(discountPercent ?? 0),
      discountAmount: Value(discountAmount ?? 0),
      taxPercent: Value(taxPercent ?? 0),
      taxAmount: Value(taxAmount ?? 0),
      grandTotal: Value(grandTotal ?? 0),
      paymentMethod: Value(paymentMethod ?? 'Cash'),
      paymentStatus: Value(paymentStatus ?? 'Pending'),
      notes: Value(notes ?? ''),
    );
  }
}
