import 'package:flutter_test/flutter_test.dart';
import 'package:doctor_app/src/services/audit_service.dart';
import '../helpers/test_database.dart';

void main() {
  group('AuditService', () {
    late TestDoctorDatabase db;
    late AuditService auditService;

    setUp(() async {
      db = createTestDatabase();
      auditService = AuditService(db);
      auditService.setCurrentDoctor('Test Doctor', role: 'doctor');
    });

    tearDown(() async {
      await db.close();
    });

    test('logs patient creation', () async {
      await auditService.logPatientCreated(1, 'John Doe', data: {
        'firstName': 'John',
        'lastName': 'Doe',
      });

      final logs = await auditService.getLogsForPatient(1);
      expect(logs, isNotEmpty);
      expect(logs.first.action, 'CREATE_PATIENT');
      expect(logs.first.patientName, 'John Doe');
      expect(logs.first.doctorName, 'Test Doctor');
    });

    test('logs patient view', () async {
      await auditService.logPatientViewed(1, 'Jane Smith');

      final logs = await auditService.getLogsByAction(AuditAction.viewPatient);
      expect(logs, isNotEmpty);
      expect(logs.first.action, 'VIEW_PATIENT');
      expect(logs.first.patientName, 'Jane Smith');
    });

    test('logs patient update with before/after data', () async {
      await auditService.logPatientUpdated(
        1,
        'John Doe',
        before: {'phone': '1234567890'},
        after: {'phone': '0987654321'},
      );

      final logs = await auditService.getLogsForPatient(1);
      expect(logs, isNotEmpty);
      expect(logs.first.action, 'UPDATE_PATIENT');
      expect(logs.first.actionDetails, contains('before'));
      expect(logs.first.actionDetails, contains('after'));
    });

    test('logs appointment creation', () async {
      await auditService.logAppointmentCreated(1, 'John Doe', 100);

      final logs = await auditService.getLogsByAction(AuditAction.createAppointment);
      expect(logs, isNotEmpty);
      expect(logs.first.action, 'CREATE_APPOINTMENT');
      expect(logs.first.entityId, 100);
    });

    test('logs screen unlock', () async {
      await auditService.logScreenUnlocked();

      final logs = await auditService.getLogsByAction(AuditAction.unlockScreen);
      expect(logs, isNotEmpty);
      expect(logs.first.action, 'UNLOCK_SCREEN');
      expect(logs.first.result, 'SUCCESS');
    });

    test('logs security settings change', () async {
      await auditService.logSecuritySettingsChanged(notes: 'Enabled app lock');

      final logs = await auditService.getLogsByAction(AuditAction.changeSecuritySettings);
      expect(logs, isNotEmpty);
      expect(logs.first.notes, 'Enabled app lock');
    });

    test('retrieves recent logs with date filtering', () async {
      // Log multiple actions
      await auditService.logPatientCreated(1, 'Patient 1');
      await auditService.logPatientViewed(1, 'Patient 1');
      await auditService.logPatientViewed(2, 'Patient 2');

      final logs = await auditService.getRecentLogs(days: 1, limit: 10);
      expect(logs.length, 3);
    });

    test('retrieves logs by doctor', () async {
      auditService.setCurrentDoctor('Dr. Smith');
      await auditService.logPatientViewed(1, 'Patient A');
      
      auditService.setCurrentDoctor('Dr. Jones');
      await auditService.logPatientViewed(2, 'Patient B');

      final drSmithLogs = await auditService.getLogsByDoctor('Dr. Smith');
      expect(drSmithLogs.length, 1);
      expect(drSmithLogs.first.doctorName, 'Dr. Smith');
    });

    test('logs failed authentication', () async {
      await auditService.logScreenUnlocked(result: AuditResult.failure);

      final logs = await auditService.getLogsByAction(AuditAction.unlockScreen);
      expect(logs.first.result, 'FAILURE');
    });
  });
}
