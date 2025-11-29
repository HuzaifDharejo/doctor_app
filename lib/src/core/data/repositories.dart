/// Repository pattern for data access
/// 
/// Repositories abstract the data layer from the rest of the app,
/// providing a clean API and proper error handling.
library;

import '../utils/result.dart';
import '../utils/app_exceptions.dart';
import '../../db/doctor_db.dart';
import '../../services/logger_service.dart';

/// Base repository class with common functionality
abstract class BaseRepository {
  final DoctorDatabase db;
  
  BaseRepository(this.db);
  
  /// Execute a database operation with error handling
  Future<Result<T, AppException>> execute<T>(
    Future<T> Function() operation, {
    required String tag,
    required String operationName,
  }) async {
    try {
      log.d(tag, 'Starting $operationName');
      final result = await operation();
      log.d(tag, '$operationName completed successfully');
      return Result.success(result);
    } catch (e, st) {
      log.e(tag, '$operationName failed', error: e, stackTrace: st);
      return Result.failure(
        DatabaseException(
          'Operation failed',
          operation: operationName,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}

/// Repository for Patient data operations
class PatientRepository extends BaseRepository {
  static const _tag = 'PatientRepo';
  
  PatientRepository(super.db);
  
  /// Get all patients
  Future<Result<List<Patient>, AppException>> getAll() async {
    return execute(
      () => db.getAllPatients(),
      tag: _tag,
      operationName: 'getAllPatients',
    );
  }
  
  /// Get patient by ID
  Future<Result<Patient, AppException>> getById(int id) async {
    final result = await execute(
      () => db.getPatientById(id),
      tag: _tag,
      operationName: 'getPatientById($id)',
    );
    
    return result.flatMap((patient) {
      if (patient == null) {
        return Result.failure(DatabaseException.notFound('patients', id));
      }
      return Result.success(patient);
    });
  }
  
  /// Insert a new patient
  Future<Result<int, AppException>> insert(PatientsCompanion patient) async {
    return execute(
      () => db.insertPatient(patient),
      tag: _tag,
      operationName: 'insertPatient',
    );
  }
  
  /// Update a patient
  Future<Result<bool, AppException>> update(Patient patient) async {
    return execute(
      () => db.updatePatient(patient),
      tag: _tag,
      operationName: 'updatePatient(${patient.id})',
    );
  }
  
  /// Delete a patient
  Future<Result<int, AppException>> delete(int id) async {
    return execute(
      () => db.deletePatient(id),
      tag: _tag,
      operationName: 'deletePatient($id)',
    );
  }
  
  /// Search patients by name
  Future<Result<List<Patient>, AppException>> search(String query) async {
    final result = await getAll();
    return result.map((patients) {
      final lowerQuery = query.toLowerCase();
      return patients.where((p) {
        final fullName = '${p.firstName} ${p.lastName}'.toLowerCase();
        return fullName.contains(lowerQuery);
      }).toList();
    });
  }
  
  /// Get patients by risk level
  Future<Result<List<Patient>, AppException>> getByRiskLevel(int minRisk, int maxRisk) async {
    final result = await getAll();
    return result.map((patients) {
      return patients.where((p) => p.riskLevel >= minRisk && p.riskLevel <= maxRisk).toList();
    });
  }
}

/// Repository for Appointment data operations
class AppointmentRepository extends BaseRepository {
  static const _tag = 'AppointmentRepo';
  
  AppointmentRepository(super.db);
  
  /// Get all appointments
  Future<Result<List<Appointment>, AppException>> getAll() async {
    return execute(
      () => db.getAllAppointments(),
      tag: _tag,
      operationName: 'getAllAppointments',
    );
  }
  
  /// Get appointments for a specific day
  Future<Result<List<Appointment>, AppException>> getForDay(DateTime day) async {
    return execute(
      () => db.getAppointmentsForDay(day),
      tag: _tag,
      operationName: 'getAppointmentsForDay($day)',
    );
  }
  
  /// Get today's appointments
  Future<Result<List<Appointment>, AppException>> getToday() async {
    return getForDay(DateTime.now());
  }
  
  /// Insert a new appointment
  Future<Result<int, AppException>> insert(AppointmentsCompanion appointment) async {
    return execute(
      () => db.insertAppointment(appointment),
      tag: _tag,
      operationName: 'insertAppointment',
    );
  }
  
  /// Delete an appointment
  Future<Result<int, AppException>> delete(int id) async {
    return execute(
      () => db.deleteAppointment(id),
      tag: _tag,
      operationName: 'deleteAppointment($id)',
    );
  }
  
  /// Get upcoming appointments (from now onwards)
  Future<Result<List<Appointment>, AppException>> getUpcoming() async {
    final result = await getAll();
    return result.map((appointments) {
      final now = DateTime.now();
      return appointments
          .where((a) => a.appointmentDateTime.isAfter(now) && 
                        (a.status == 'scheduled' || a.status == 'pending'))
          .toList()
        ..sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));
    });
  }
  
  /// Get pending appointments count
  Future<Result<int, AppException>> getPendingCount() async {
    final result = await getToday();
    return result.map((appointments) {
      return appointments.where((a) => 
        a.status == 'pending' || a.status == 'scheduled'
      ).length;
    });
  }
}

/// Repository for Prescription data operations
class PrescriptionRepository extends BaseRepository {
  static const _tag = 'PrescriptionRepo';
  
  PrescriptionRepository(super.db);
  
  /// Get all prescriptions
  Future<Result<List<Prescription>, AppException>> getAll() async {
    return execute(
      () => db.getAllPrescriptions(),
      tag: _tag,
      operationName: 'getAllPrescriptions',
    );
  }
  
  /// Get prescriptions for a patient
  Future<Result<List<Prescription>, AppException>> getForPatient(int patientId) async {
    return execute(
      () => db.getPrescriptionsForPatient(patientId),
      tag: _tag,
      operationName: 'getPrescriptionsForPatient($patientId)',
    );
  }
  
  /// Get last prescription for a patient
  Future<Result<Prescription?, AppException>> getLastForPatient(int patientId) async {
    return execute(
      () => db.getLastPrescriptionForPatient(patientId),
      tag: _tag,
      operationName: 'getLastPrescriptionForPatient($patientId)',
    );
  }
  
  /// Insert a new prescription
  Future<Result<int, AppException>> insert(PrescriptionsCompanion prescription) async {
    return execute(
      () => db.insertPrescription(prescription),
      tag: _tag,
      operationName: 'insertPrescription',
    );
  }
  
  /// Delete a prescription
  Future<Result<int, AppException>> delete(int id) async {
    return execute(
      () => db.deletePrescription(id),
      tag: _tag,
      operationName: 'deletePrescription($id)',
    );
  }
}

/// Repository for Medical Record data operations
class MedicalRecordRepository extends BaseRepository {
  static const _tag = 'MedicalRecordRepo';
  
  MedicalRecordRepository(super.db);
  
  /// Get all medical records
  Future<Result<List<MedicalRecord>, AppException>> getAll() async {
    return execute(
      () => db.getAllMedicalRecords(),
      tag: _tag,
      operationName: 'getAllMedicalRecords',
    );
  }
  
  /// Get all medical records with patient info
  Future<Result<List<MedicalRecordWithPatient>, AppException>> getAllWithPatients() async {
    return execute(
      () => db.getAllMedicalRecordsWithPatients(),
      tag: _tag,
      operationName: 'getAllMedicalRecordsWithPatients',
    );
  }
  
  /// Get medical records for a patient
  Future<Result<List<MedicalRecord>, AppException>> getForPatient(int patientId) async {
    return execute(
      () => db.getMedicalRecordsForPatient(patientId),
      tag: _tag,
      operationName: 'getMedicalRecordsForPatient($patientId)',
    );
  }
  
  /// Get medical record by ID
  Future<Result<MedicalRecord, AppException>> getById(int id) async {
    final result = await execute(
      () => db.getMedicalRecordById(id),
      tag: _tag,
      operationName: 'getMedicalRecordById($id)',
    );
    
    return result.flatMap((record) {
      if (record == null) {
        return Result.failure(DatabaseException.notFound('medical_records', id));
      }
      return Result.success(record);
    });
  }
  
  /// Insert a new medical record
  Future<Result<int, AppException>> insert(MedicalRecordsCompanion record) async {
    return execute(
      () => db.insertMedicalRecord(record),
      tag: _tag,
      operationName: 'insertMedicalRecord',
    );
  }
  
  /// Update a medical record
  Future<Result<bool, AppException>> update(MedicalRecord record) async {
    return execute(
      () => db.updateMedicalRecord(record),
      tag: _tag,
      operationName: 'updateMedicalRecord(${record.id})',
    );
  }
  
  /// Delete a medical record
  Future<Result<int, AppException>> delete(int id) async {
    return execute(
      () => db.deleteMedicalRecord(id),
      tag: _tag,
      operationName: 'deleteMedicalRecord($id)',
    );
  }
  
  /// Get records by type
  Future<Result<List<MedicalRecord>, AppException>> getByType(String type) async {
    final result = await getAll();
    return result.map((records) => records.where((r) => r.recordType == type).toList());
  }
}

/// Repository for Invoice data operations
class InvoiceRepository extends BaseRepository {
  static const _tag = 'InvoiceRepo';
  
  InvoiceRepository(super.db);
  
  /// Get all invoices
  Future<Result<List<Invoice>, AppException>> getAll() async {
    return execute(
      () => db.getAllInvoices(),
      tag: _tag,
      operationName: 'getAllInvoices',
    );
  }
  
  /// Insert a new invoice
  Future<Result<int, AppException>> insert(InvoicesCompanion invoice) async {
    return execute(
      () => db.insertInvoice(invoice),
      tag: _tag,
      operationName: 'insertInvoice',
    );
  }
  
  /// Get invoices by payment status
  Future<Result<List<Invoice>, AppException>> getByStatus(String status) async {
    final result = await getAll();
    return result.map((invoices) => 
      invoices.where((i) => i.paymentStatus == status).toList()
    );
  }
  
  /// Get unpaid invoices
  Future<Result<List<Invoice>, AppException>> getUnpaid() async {
    final result = await getAll();
    return result.map((invoices) => 
      invoices.where((i) => i.paymentStatus != 'Paid').toList()
    );
  }
  
  /// Get total revenue
  Future<Result<double, AppException>> getTotalRevenue() async {
    final result = await getAll();
    return result.map((invoices) {
      return invoices
          .where((i) => i.paymentStatus == 'Paid')
          .fold<double>(0, (sum, i) => sum + i.grandTotal);
    });
  }
}
