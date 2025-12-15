import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../db/doctor_db.dart';
import '../models/lab_order.dart';
import 'audit_service.dart';

/// Type alias for screen compatibility
typedef LabOrderData = LabOrder;

/// Service for managing lab orders
class LabOrderService {
  LabOrderService({
    DoctorDatabase? db,
    AuditService? auditService,
  })  : _db = db ?? DoctorDatabase.instance,
        _auditService = auditService ?? AuditService(DoctorDatabase.instance);

  final DoctorDatabase _db;
  final AuditService _auditService;

  /// Create lab order
  Future<int> createLabOrder({
    required int patientId,
    required String orderNumber,
    required String testCodes,
    required String testNames,
    required String orderingProvider,
    required DateTime orderedDate,
    int? encounterId,
    String? orderType,
    String? diagnosisCodes,
    String? priority,
    String? fasting,
    String? specialInstructions,
    String? labName,
    String? labAddress,
    String? labPhone,
    String? specimenType,
    String? notes,
  }) async {
    final id = await _db.into(_db.labOrders).insert(
      LabOrdersCompanion.insert(
        patientId: patientId,
        orderNumber: orderNumber,
        testCodes: testCodes,
        testNames: testNames,
        orderingProvider: orderingProvider,
        orderedDate: orderedDate,
        encounterId: Value(encounterId),
        orderType: Value(orderType ?? 'lab'),
        diagnosisCodes: Value(diagnosisCodes ?? ''),
        priority: Value(priority ?? 'routine'),
        fasting: Value(fasting ?? 'no'),
        specialInstructions: Value(specialInstructions ?? ''),
        labName: Value(labName ?? ''),
        labAddress: Value(labAddress ?? ''),
        labPhone: Value(labPhone ?? ''),
        specimenType: Value(specimenType ?? ''),
        status: const Value('pending'),
        notes: Value(notes ?? ''),
      ),
    );

    await _auditService.log(
      action: AuditAction.create,
      entityType: AuditEntityType.labOrder,
      entityId: id,
      patientId: patientId,
      afterData: {'action': 'create_lab_order', 'order_number': orderNumber},
    );

    if (kDebugMode) {
      print('[LabOrderService] Created lab order $id for patient $patientId');
    }

    return id;
  }

  /// Get all lab orders for a patient
  Future<List<LabOrder>> getLabOrdersForPatient(int patientId) async {
    return (_db.select(_db.labOrders)
          ..where((l) => l.patientId.equals(patientId))
          ..orderBy([(l) => OrderingTerm.desc(l.orderedDate)]))
        .get();
  }

  /// Get lab order by ID
  Future<LabOrder?> getLabOrderById(int id) async {
    return (_db.select(_db.labOrders)..where((l) => l.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get pending lab orders
  Future<List<LabOrder>> getPendingLabOrders(int patientId) async {
    return (_db.select(_db.labOrders)
          ..where((l) => l.patientId.equals(patientId) & l.status.equals('pending'))
          ..orderBy([(l) => OrderingTerm.asc(l.orderedDate)]))
        .get();
  }

  /// Get lab orders by status
  Future<List<LabOrder>> getLabOrdersByStatus(int patientId, String status) async {
    return (_db.select(_db.labOrders)
          ..where((l) => l.patientId.equals(patientId) & l.status.equals(status))
          ..orderBy([(l) => OrderingTerm.desc(l.orderedDate)]))
        .get();
  }

  /// Update lab order status
  Future<bool> updateLabOrderStatus({
    required int id,
    required String status,
    DateTime? resultedDate,
    bool? hasAbnormal,
    bool? hasCritical,
    String? notes,
  }) async {
    final existing = await getLabOrderById(id);
    if (existing == null) return false;

    await (_db.update(_db.labOrders)..where((l) => l.id.equals(id)))
        .write(LabOrdersCompanion(
          status: Value(status),
          resultedDate: resultedDate != null ? Value(resultedDate) : const Value.absent(),
          hasAbnormal: hasAbnormal != null ? Value(hasAbnormal) : const Value.absent(),
          hasCritical: hasCritical != null ? Value(hasCritical) : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.labOrder,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'update_lab_order', 'status': status},
    );

    return true;
  }

  /// Mark lab order as reviewed
  Future<bool> markAsReviewed({
    required int id,
    required String reviewedBy,
  }) async {
    final existing = await getLabOrderById(id);
    if (existing == null) return false;

    await (_db.update(_db.labOrders)..where((l) => l.id.equals(id)))
        .write(LabOrdersCompanion(
          reviewed: const Value(true),
          reviewedBy: Value(reviewedBy),
          reviewedAt: Value(DateTime.now()),
        ));

    await _auditService.log(
      action: AuditAction.update,
      entityType: AuditEntityType.labOrder,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'mark_reviewed', 'reviewed_by': reviewedBy},
    );

    return true;
  }

  /// Delete lab order
  Future<bool> deleteLabOrder(int id) async {
    final existing = await getLabOrderById(id);
    if (existing == null) return false;

    await (_db.delete(_db.labOrders)..where((l) => l.id.equals(id))).go();

    await _auditService.log(
      action: AuditAction.delete,
      entityType: AuditEntityType.labOrder,
      entityId: id,
      patientId: existing.patientId,
      afterData: {'action': 'delete_lab_order'},
    );

    return true;
  }

  /// Get lab order summary
  Future<Map<String, dynamic>> getLabOrderSummary(int patientId) async {
    final orders = await getLabOrdersForPatient(patientId);
    
    return {
      'total': orders.length,
      'pending': orders.where((o) => o.status == 'pending').length,
      'completed': orders.where((o) => o.status == 'completed').length,
      'reviewed': orders.where((o) => o.reviewed).length,
      'abnormal': orders.where((o) => o.hasAbnormal).length,
      'critical': orders.where((o) => o.hasCritical).length,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // SCREEN COMPATIBILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Get display test names for a lab order (V5: from LabTestResults table)
  /// Falls back to parsing testNames JSON if no normalized data exists
  Future<String> getDisplayTestName(int labOrderId) async {
    // First try normalized LabTestResults table (V5)
    final results = await _db.getResultsForLabOrder(labOrderId);
    if (results.isNotEmpty) {
      final names = results.map((r) => r.testName).toList();
      return names.join(', ');
    }
    
    // Fallback to legacy testNames field (JSON array)
    final order = await getLabOrderById(labOrderId);
    if (order != null && order.testNames.isNotEmpty && order.testNames != '[]') {
      try {
        final parsed = (order.testNames.startsWith('[')) 
            ? (List<String>.from(jsonDecode(order.testNames) as List))
            : order.testNames.split(',').where((s) => s.trim().isNotEmpty).toList();
        if (parsed.isNotEmpty) {
          return parsed.join(', ');
        }
      } catch (_) {
        // If parsing fails, return as-is
        return order.testNames;
      }
    }
    
    return 'Lab Order';
  }

  /// Get display test code for a lab order (V5: from LabTestResults table)
  Future<String?> getDisplayTestCode(int labOrderId) async {
    final results = await _db.getResultsForLabOrder(labOrderId);
    if (results.isNotEmpty) {
      final codes = results.map((r) => r.testCode).where((c) => c.isNotEmpty).toList();
      if (codes.isNotEmpty) {
        return codes.join(', ');
      }
    }
    
    // Fallback to legacy testCodes field
    final order = await getLabOrderById(labOrderId);
    if (order != null && order.testCodes.isNotEmpty && order.testCodes != '[]') {
      try {
        final parsed = (order.testCodes.startsWith('[')) 
            ? (List<String>.from(jsonDecode(order.testCodes) as List))
            : order.testCodes.split(',').where((s) => s.trim().isNotEmpty).toList();
        if (parsed.isNotEmpty) {
          return parsed.join(', ');
        }
      } catch (_) {
        return order.testCodes;
      }
    }
    
    return null;
  }

  /// Get test results count for a lab order
  Future<int> getTestResultsCount(int labOrderId) async {
    final results = await _db.getResultsForLabOrder(labOrderId);
    return results.length;
  }

  /// Get lab orders with display names for patient
  Future<List<Map<String, dynamic>>> getLabOrdersWithDetails(int patientId, {String? statusFilter}) async {
    final orders = statusFilter != null 
        ? await getLabOrdersByStatus(patientId, statusFilter)
        : await getLabOrdersForPatient(patientId);
    
    final List<Map<String, dynamic>> ordersWithDetails = [];
    for (final order in orders) {
      final testName = await getDisplayTestName(order.id);
      final testCode = await getDisplayTestCode(order.id);
      final testCount = await getTestResultsCount(order.id);
      ordersWithDetails.add({
        'order': order,
        'displayTestName': testName,
        'displayTestCode': testCode,
        'testCount': testCount,
      });
    }
    return ordersWithDetails;
  }

  /// Cancel lab order (screen compatibility)
  Future<bool> cancelLabOrder(int id, [String? reason]) async {
    return updateLabOrderStatus(id: id, status: 'cancelled', notes: reason);
  }

  /// Enter lab results (screen compatibility)
  Future<bool> enterLabResults({
    int? id,
    int? orderId, // alias for id
    String? results,
    String? resultSummary, // alias for results
    bool? isAbnormal,
    String? notes,
  }) async {
    final ordId = id ?? orderId ?? 0;
    final resultText = results ?? resultSummary;
    return updateLabOrderStatus(
      id: ordId,
      status: 'completed',
      resultedDate: DateTime.now(),
      hasAbnormal: isAbnormal,
      notes: resultText ?? notes,
    );
  }

  /// Create lab order (screen compatibility - alias with different params)
  Future<int> createOrder({
    required int patientId,
    String? testName,
    String? testCode,
    String? urgency,
    String? specimenType,
    String? labName,
    String? clinicalIndication,
    String? notes,
  }) async {
    final labOrderId = await createLabOrder(
      patientId: patientId,
      orderNumber: 'LAB${DateTime.now().millisecondsSinceEpoch}',
      testCodes: '[]', // V5: Use LabTestResults table instead
      testNames: '[]', // V5: Use LabTestResults table instead
      orderingProvider: 'Current Provider',
      orderedDate: DateTime.now(),
      priority: urgency ?? 'routine',
      labName: labName,
      specimenType: specimenType,
      specialInstructions: clinicalIndication ?? '',
      notes: notes,
    );
    
    // V5: Save test to normalized LabTestResults table
    if (testName != null && testName.isNotEmpty) {
      await _db.insertLabTestResult(
        LabTestResultsCompanion.insert(
          labOrderId: labOrderId,
          patientId: patientId,
          testName: testName,
          testCode: Value(testCode ?? ''),
        ),
      );
    }
    
    return labOrderId;
  }

  /// Order lab (screen compatibility - alias with different params)
  Future<int> orderLab({
    required int patientId,
    String? testName,
    String? testCode,
    String? urgency,
    String? specimenType,
    String? clinicalIndication,
    String? notes,
  }) async {
    return createOrder(
      patientId: patientId,
      testName: testName,
      testCode: testCode,
      urgency: urgency,
      specimenType: specimenType,
      clinicalIndication: clinicalIndication,
      notes: notes,
    );
  }

  /// Convert to model (screen compatibility)
  LabOrderModel toModel(LabOrderData order) {
    return LabOrderModel(
      id: order.id,
      patientId: order.patientId,
      orderNumber: order.orderNumber,
      testCodes: order.testCodes.split(',').where((s) => s.isNotEmpty).toList(),
      testNames: order.testNames.split(',').where((s) => s.isNotEmpty).toList(),
      orderingProvider: order.orderingProvider,
      orderedDate: order.orderedDate,
      status: LabOrderStatus.fromValue(order.status),
      priority: LabPriority.fromValue(order.priority),
      hasAbnormal: order.hasAbnormal,
      hasCritical: order.hasCritical,
      notes: order.notes,
    );
  }
}
