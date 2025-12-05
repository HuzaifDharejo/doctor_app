import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/doctor_db.dart';
import '../services/audit_service.dart';

/// Provider for the database instance
final databaseProvider = Provider<DoctorDatabase>((ref) {
  return DoctorDatabase();
});

/// Provider for the audit service
final auditServiceProvider = Provider<AuditService>((ref) {
  final db = ref.watch(databaseProvider);
  return AuditService(db);
});
