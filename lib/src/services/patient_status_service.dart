import 'package:drift/drift.dart';
import '../db/doctor_db.dart';
import 'lab_order_service.dart';

/// Patient status types for visual indicators
enum PatientStatus {
  inRoom,        // 🔴 Checked in, waiting
  consulted,     // 🟢 Visit completed
  labPending,    // 🟡 Lab results pending
  followUpDue,   // 🔵 Follow-up scheduled/due
  highRisk,      // ⚠️ High risk level
  none,          // No special status
}

/// Service to determine patient status for visual indicators
class PatientStatusService {
  final DoctorDatabase db;
  late final LabOrderService _labOrderService;

  PatientStatusService({required this.db}) {
    _labOrderService = LabOrderService(db: db);
  }

  /// Get all statuses for a patient (can have multiple)
  Future<List<PatientStatus>> getPatientStatuses({
    required Patient patient,
    Appointment? appointment,
  }) async {
    final statuses = <PatientStatus>[];

    // Check appointment status (In Room)
    if (appointment != null) {
      if (appointment.status == 'checked_in' || appointment.status == 'in_progress') {
        statuses.add(PatientStatus.inRoom);
      } else if (appointment.status == 'completed') {
        statuses.add(PatientStatus.consulted);
      }
    }

    // Check for lab orders pending
    final hasPendingLabs = await _hasPendingLabOrders(patient.id);
    if (hasPendingLabs) {
      statuses.add(PatientStatus.labPending);
    }

    // Check for follow-ups due
    final hasFollowUpDue = await _hasFollowUpDue(patient.id);
    if (hasFollowUpDue) {
      statuses.add(PatientStatus.followUpDue);
    }

    // Check risk level (High Risk)
    if (patient.riskLevel >= 4) {
      statuses.add(PatientStatus.highRisk);
    }

    // If no statuses, return none
    if (statuses.isEmpty) {
      statuses.add(PatientStatus.none);
    }

    return statuses;
  }

  /// Get primary status (most important one)
  Future<PatientStatus> getPrimaryStatus({
    required Patient patient,
    Appointment? appointment,
  }) async {
    final statuses = await getPatientStatuses(
      patient: patient,
      appointment: appointment,
    );

    // Priority order: In Room > High Risk > Lab Pending > Follow-up Due > Consulted > None
    if (statuses.contains(PatientStatus.inRoom)) return PatientStatus.inRoom;
    if (statuses.contains(PatientStatus.highRisk)) return PatientStatus.highRisk;
    if (statuses.contains(PatientStatus.labPending)) return PatientStatus.labPending;
    if (statuses.contains(PatientStatus.followUpDue)) return PatientStatus.followUpDue;
    if (statuses.contains(PatientStatus.consulted)) return PatientStatus.consulted;
    return PatientStatus.none;
  }

  /// Check if patient has pending lab orders
  Future<bool> _hasPendingLabOrders(int patientId) async {
    try {
      final labOrders = await _labOrderService.getLabOrdersForPatient(patientId);
      return labOrders.any((order) => 
        order.status == 'pending' || 
        order.status == 'ordered' ||
        order.status == 'in_progress'
      );
    } catch (e) {
      return false;
    }
  }

  /// Check if patient has follow-ups due
  Future<bool> _hasFollowUpDue(int patientId) async {
    try {
      final followUps = await db.getPendingFollowUpsForPatient(patientId);
      final now = DateTime.now();
      return followUps.any((followUp) => 
        followUp.scheduledDate.isBefore(now.add(const Duration(days: 7))));
    } catch (e) {
      return false;
    }
  }
}

