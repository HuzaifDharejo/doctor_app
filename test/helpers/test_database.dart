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

  /// Get prescriptions for a patient.
  Future<List<Prescription>> getPrescriptionsForPatient(int patientId) {
    return (select(prescriptions)
          ..where((p) => p.patientId.equals(patientId))
          ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
        .get();
  }

  /// Update a prescription by ID using a companion.
  Future<void> updatePrescriptionById(int id, Insertable<Prescription> prescription) async {
    await (update(prescriptions)..where((p) => p.id.equals(id))).write(prescription);
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

  /// Gets the count of encounters in the database.
  Future<int> getEncounterCount() async {
    final result =
        await customSelect('SELECT COUNT(*) as count FROM encounters')
            .getSingle();
    return result.read<int>('count');
  }

  /// Gets the count of diagnoses in the database.
  Future<int> getDiagnosisCount() async {
    final result =
        await customSelect('SELECT COUNT(*) as count FROM diagnoses')
            .getSingle();
    return result.read<int>('count');
  }

  /// Gets the count of clinical notes in the database.
  Future<int> getClinicalNoteCount() async {
    final result =
        await customSelect('SELECT COUNT(*) as count FROM clinical_notes')
            .getSingle();
    return result.read<int>('count');
  }

  /// Get encounters for a patient.
  Future<List<Encounter>> getEncountersForPatient(int patientId) {
    return (select(encounters)
          ..where((e) => e.patientId.equals(patientId))
          ..orderBy([(e) => OrderingTerm.desc(e.encounterDate)]))
        .get();
  }

  /// Get diagnoses for a patient.
  Future<List<Diagnose>> getDiagnosesForPatient(int patientId) {
    return (select(diagnoses)
          ..where((d) => d.patientId.equals(patientId))
          ..orderBy([(d) => OrderingTerm.desc(d.diagnosedDate)]))
        .get();
  }

  /// Get clinical notes for an encounter.
  Future<List<ClinicalNote>> getClinicalNotesForEncounter(int encounterId) {
    return (select(clinicalNotes)
          ..where((n) => n.encounterId.equals(encounterId))
          ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
        .get();
  }

  /// Get encounter diagnoses for an encounter.
  Future<List<EncounterDiagnose>> getEncounterDiagnosesForEncounter(int encounterId) {
    return (select(encounterDiagnoses)
          ..where((ed) => ed.encounterId.equals(encounterId)))
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
    int? age,
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
      age: Value(age),
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

  /// Creates a vital signs companion with minimal required data.
  static VitalSignsCompanion createVitalSigns({
    required int patientId,
    int? encounterId,
    DateTime? recordedAt,
    double? systolicBp,
    double? diastolicBp,
    int? heartRate,
    double? temperature,
    int? respiratoryRate,
    double? oxygenSaturation,
    double? weight,
    double? height,
  }) {
    return VitalSignsCompanion.insert(
      patientId: patientId,
      encounterId: Value(encounterId),
      recordedAt: recordedAt ?? DateTime.now(),
      systolicBp: Value(systolicBp),
      diastolicBp: Value(diastolicBp),
      heartRate: Value(heartRate),
      temperature: Value(temperature),
      respiratoryRate: Value(respiratoryRate),
      oxygenSaturation: Value(oxygenSaturation),
      weight: Value(weight),
      height: Value(height),
    );
  }

  /// Creates an encounter companion with minimal required data.
  static EncountersCompanion createEncounter({
    required int patientId,
    int? appointmentId,
    DateTime? encounterDate,
    String? encounterType,
    String? status,
    String? chiefComplaint,
    String? providerName,
    String? providerType,
    DateTime? checkInTime,
    DateTime? checkOutTime,
  }) {
    return EncountersCompanion.insert(
      patientId: patientId,
      appointmentId: Value(appointmentId),
      encounterDate: encounterDate ?? DateTime.now(),
      encounterType: Value(encounterType ?? 'follow_up'),
      status: Value(status ?? 'in_progress'),
      chiefComplaint: Value(chiefComplaint ?? ''),
      providerName: Value(providerName ?? ''),
      providerType: Value(providerType ?? 'psychiatrist'),
      checkInTime: Value(checkInTime),
      checkOutTime: Value(checkOutTime),
    );
  }

  /// Creates a diagnosis companion with minimal required data.
  static DiagnosesCompanion createDiagnosis({
    required int patientId,
    int? encounterId,
    String? icdCode,
    required String description,
    String? category,
    String? severity,
    String? diagnosisStatus,
    DateTime? onsetDate,
    DateTime? diagnosedDate,
    DateTime? resolvedDate,
    bool? isPrimary,
    int? displayOrder,
    String? notes,
  }) {
    return DiagnosesCompanion.insert(
      patientId: patientId,
      encounterId: Value(encounterId),
      icdCode: Value(icdCode ?? ''),
      description: description,
      category: Value(category ?? 'psychiatric'),
      severity: Value(severity ?? 'moderate'),
      diagnosisStatus: Value(diagnosisStatus ?? 'active'),
      onsetDate: Value(onsetDate),
      diagnosedDate: diagnosedDate ?? DateTime.now(),
      resolvedDate: Value(resolvedDate),
      isPrimary: Value(isPrimary ?? false),
      displayOrder: Value(displayOrder ?? 0),
      notes: Value(notes ?? ''),
    );
  }

  /// Creates a clinical note companion with minimal required data.
  static ClinicalNotesCompanion createClinicalNote({
    required int encounterId,
    required int patientId,
    String? noteType,
    String? subjective,
    String? objective,
    String? assessment,
    String? plan,
    String? mentalStatusExam,
    String? riskLevel,
    String? riskFactors,
    String? safetyPlan,
    String? signedBy,
    DateTime? signedAt,
    bool? isLocked,
  }) {
    return ClinicalNotesCompanion.insert(
      encounterId: encounterId,
      patientId: patientId,
      noteType: Value(noteType ?? 'progress'),
      subjective: Value(subjective ?? ''),
      objective: Value(objective ?? ''),
      assessment: Value(assessment ?? ''),
      plan: Value(plan ?? ''),
      mentalStatusExam: Value(mentalStatusExam ?? '{}'),
      riskLevel: Value(riskLevel ?? 'none'),
      riskFactors: Value(riskFactors ?? ''),
      safetyPlan: Value(safetyPlan ?? ''),
      signedBy: Value(signedBy ?? ''),
      signedAt: Value(signedAt),
      isLocked: Value(isLocked ?? false),
    );
  }

  /// Creates an encounter diagnosis companion with minimal required data.
  static EncounterDiagnosesCompanion createEncounterDiagnosis({
    required int encounterId,
    required int diagnosisId,
    bool? isNewDiagnosis,
    String? encounterStatus,
    String? notes,
  }) {
    return EncounterDiagnosesCompanion.insert(
      encounterId: encounterId,
      diagnosisId: diagnosisId,
      isNewDiagnosis: Value(isNewDiagnosis ?? false),
      encounterStatus: Value(encounterStatus ?? 'addressed'),
      notes: Value(notes ?? ''),
    );
  }
}
