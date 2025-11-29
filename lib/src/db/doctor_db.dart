// Minimal Drift DB. Run `flutter pub run build_runner build` to generate code.
import 'package:drift/drift.dart';

// Conditional imports for platform-specific code
import 'doctor_db_native.dart' if (dart.library.html) 'doctor_db_web.dart' as impl;

part 'doctor_db.g.dart';

class Patients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get medicalHistory => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))(); // comma-separated
  IntColumn get riskLevel => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  DateTimeColumn get appointmentDateTime => dateTime()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(15))();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Prescriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get itemsJson => text()();
  TextColumn get instructions => text().withDefault(const Constant(''))();
  BoolColumn get isRefillable => boolean().withDefault(const Constant(false))();
}

class MedicalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  TextColumn get recordType => text()(); // 'general', 'psychiatric_assessment', 'lab_result', 'imaging', 'procedure'
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get dataJson => text().withDefault(const Constant('{}'))(); // Stores form data as JSON
  TextColumn get diagnosis => text().withDefault(const Constant(''))();
  TextColumn get treatment => text().withDefault(const Constant(''))();
  TextColumn get doctorNotes => text().withDefault(const Constant(''))();
  DateTimeColumn get recordDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  TextColumn get invoiceNumber => text()();
  DateTimeColumn get invoiceDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get itemsJson => text()(); // JSON array of items
  RealColumn get subtotal => real().withDefault(const Constant(0.0))();
  RealColumn get discountPercent => real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  RealColumn get taxPercent => real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0.0))();
  RealColumn get grandTotal => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();
  TextColumn get paymentStatus => text().withDefault(const Constant('Pending'))(); // 'Pending', 'Partial', 'Paid', 'Overdue'
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Patients, Appointments, Prescriptions, MedicalRecords, Invoices])
class DoctorDatabase extends _$DoctorDatabase {
  DoctorDatabase() : super(impl.openConnection());

  @override
  int get schemaVersion => 1;

  // Patient CRUD
  Future<int> insertPatient(Insertable<Patient> p) => into(patients).insert(p);
  Future<List<Patient>> getAllPatients() => select(patients).get();
  Future<Patient?> getPatientById(int id) => (select(patients)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<bool> updatePatient(Insertable<Patient> p) => update(patients).replace(p);
  Future<int> deletePatient(int id) => (delete(patients)..where((t) => t.id.equals(id))).go();

  // Appointment CRUD
  Future<int> insertAppointment(Insertable<Appointment> a) => into(appointments).insert(a);
  Future<List<Appointment>> getAllAppointments() => select(appointments).get();
  Future<List<Appointment>> getAppointmentsForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(appointments)..where((a) => a.appointmentDateTime.isBetweenValues(start, end))).get();
  }
  Future<int> deleteAppointment(int id) => (delete(appointments)..where((t) => t.id.equals(id))).go();

  // Prescription CRUD
  Future<int> insertPrescription(Insertable<Prescription> p) => into(prescriptions).insert(p);
  Future<List<Prescription>> getAllPrescriptions() => select(prescriptions).get();
  Future<List<Prescription>> getPrescriptionsForPatient(int patientId) {
    return (select(prescriptions)..where((p) => p.patientId.equals(patientId))).get();
  }
  Future<int> deletePrescription(int id) => (delete(prescriptions)..where((t) => t.id.equals(id))).go();

  // Medical Record CRUD
  Future<int> insertMedicalRecord(Insertable<MedicalRecord> r) => into(medicalRecords).insert(r);
  Future<List<MedicalRecord>> getAllMedicalRecords() => select(medicalRecords).get();
  Future<List<MedicalRecord>> getMedicalRecordsForPatient(int patientId) {
    return (select(medicalRecords)
      ..where((r) => r.patientId.equals(patientId))
      ..orderBy([(r) => OrderingTerm.desc(r.recordDate)]))
      .get();
  }
  Future<MedicalRecord?> getMedicalRecordById(int id) => 
    (select(medicalRecords)..where((r) => r.id.equals(id))).getSingleOrNull();
  Future<bool> updateMedicalRecord(Insertable<MedicalRecord> r) => update(medicalRecords).replace(r);
  Future<int> deleteMedicalRecord(int id) => (delete(medicalRecords)..where((t) => t.id.equals(id))).go();

  // Invoice CRUD
  Future<int> insertInvoice(Insertable<Invoice> i) => into(invoices).insert(i);
  Future<List<Invoice>> getAllInvoices() {
    return (select(invoices)..orderBy([(i) => OrderingTerm.desc(i.createdAt)])).get();
  }
  Future<List<Invoice>> getInvoicesForPatient(int patientId) {
    return (select(invoices)
      ..where((i) => i.patientId.equals(patientId))
      ..orderBy([(i) => OrderingTerm.desc(i.invoiceDate)]))
      .get();
  }
  Future<Invoice?> getInvoiceById(int id) =>
    (select(invoices)..where((i) => i.id.equals(id))).getSingleOrNull();
  Future<bool> updateInvoice(Insertable<Invoice> i) => update(invoices).replace(i);
  Future<int> deleteInvoice(int id) => (delete(invoices)..where((t) => t.id.equals(id))).go();
  
  // Get invoice statistics
  Future<Map<String, double>> getInvoiceStats() async {
    final allInvoices = await getAllInvoices();
    double totalRevenue = 0;
    double pending = 0;
    double paid = 0;
    int pendingCount = 0;
    
    for (final inv in allInvoices) {
      if (inv.paymentStatus == 'Paid') {
        paid += inv.grandTotal;
        totalRevenue += inv.grandTotal;
      } else {
        pending += inv.grandTotal;
        pendingCount++;
      }
    }
    
    return {
      'totalRevenue': totalRevenue,
      'pending': pending,
      'paid': paid,
      'pendingCount': pendingCount.toDouble(),
    };
  }
}
