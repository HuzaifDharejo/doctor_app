import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/doctor_db.dart';
import 'audit_service.dart';
import 'logger_service.dart';

enum DoctorRole { doctor, staff, admin }

class DoctorAuthState {
  final String? doctorEmail;
  final String? doctorName;
  final DoctorRole role;
  final DateTime? loginTime;
  final bool isAuthenticated;

  DoctorAuthState({
    this.doctorEmail,
    this.doctorName,
    this.role = DoctorRole.doctor,
    this.loginTime,
    this.isAuthenticated = false,
  });

  DoctorAuthState copyWith({
    String? doctorEmail,
    String? doctorName,
    DoctorRole? role,
    DateTime? loginTime,
    bool? isAuthenticated,
  }) {
    return DoctorAuthState(
      doctorEmail: doctorEmail ?? this.doctorEmail,
      doctorName: doctorName ?? this.doctorName,
      role: role ?? this.role,
      loginTime: loginTime ?? this.loginTime,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class DoctorAuthService extends StateNotifier<DoctorAuthState> {
  DoctorAuthService({DoctorDatabase? database}) 
      : _database = database,
        super(DoctorAuthState());
  
  final DoctorDatabase? _database;
  AuditService? _auditService;
  
  /// Initialize audit service with database
  void initAuditService(DoctorDatabase db) {
    _auditService = AuditService(db);
  }

  // Simple in-memory credentials (replace with database later)
  final Map<String, Map<String, dynamic>> _doctors = {
    'doctor@clinic.com': {
      'password': 'doctor123',
      'name': 'Dr. Ahmed Hassan',
      'role': DoctorRole.doctor,
    },
    'staff@clinic.com': {
      'password': 'staff123',
      'name': 'Staff Member',
      'role': DoctorRole.staff,
    },
    'admin@clinic.com': {
      'password': 'admin123',
      'name': 'Admin User',
      'role': DoctorRole.admin,
    },
  };

  /// Login doctor with email and password
  /// Returns true if login successful, false otherwise
  Future<bool> login(String email, String password) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      if (_doctors.containsKey(email)) {
        final doctorData = _doctors[email]!;
        if (doctorData['password'] == password) {
          state = state.copyWith(
            doctorEmail: email,
            doctorName: doctorData['name'] as String?,
            role: doctorData['role'] as DoctorRole?,
            loginTime: DateTime.now(),
            isAuthenticated: true,
          );

          // Log successful login in audit system
          if (_auditService != null) {
            _auditService!.setCurrentDoctor(
              doctorData['name'] as String? ?? 'Unknown',
              role: (doctorData['role'] as DoctorRole?)?.name ?? 'doctor',
            );
            await _auditService!.logLogin(
              result: AuditResult.success,
              notes: 'Login from ${DateTime.now().toIso8601String()}',
            );
          }
          return true;
        }
      }
      // Log failed login attempt
      if (_auditService != null) {
        await _auditService!.logLogin(
          result: AuditResult.failure,
          notes: 'Failed login attempt for email: $email',
        );
      }
      return false;
    } catch (e) {
      log.e('AUTH', 'Login error', error: e);
      // Log login error
      if (_auditService != null) {
        await _auditService!.logLogin(
          result: AuditResult.failure,
          notes: 'Login error: $e',
        );
      }
      return false;
    }
  }

  /// Logout doctor
  Future<void> logout() async {
    try {
      // Log logout in audit system before clearing state
      if (_auditService != null) {
        await _auditService!.logLogout();
      }
      state = DoctorAuthState();
    } catch (e) {
      log.e('AUTH', 'Logout error', error: e);
    }
  }

  /// Check if session is still valid (not expired)
  bool isSessionValid() {
    if (!state.isAuthenticated || state.loginTime == null) return false;

    // Session expires after 8 hours
    final sessionDuration = DateTime.now().difference(state.loginTime!);
    return sessionDuration.inHours < 8;
  }

  /// Get doctor's display name
  String getDisplayName() {
    return state.doctorName ?? 'Unknown Doctor';
  }

  /// Check if doctor has permission for action
  bool hasPermission(String action) {
    // Admin can do everything
    if (state.role == DoctorRole.admin) return true;

    // Doctor can do most things
    if (state.role == DoctorRole.doctor) {
      // Restrict certain admin actions
      if (action == 'manage_users' || action == 'system_settings') {
        return false;
      }
      return true;
    }

    // Staff has limited permissions
    if (state.role == DoctorRole.staff) {
      if (action == 'prescribe' || action == 'diagnose') {
        return false; // Staff cannot prescribe or diagnose
      }
      return true;
    }

    return false;
  }
}

// Create the provider
final doctorAuthProvider =
    StateNotifierProvider<DoctorAuthService, DoctorAuthState>((ref) {
  final authService = DoctorAuthService();
  return authService;
});

/// Provider that initializes DoctorAuthService with database for audit logging
final doctorAuthWithAuditProvider = Provider<DoctorAuthService>((ref) {
  final authService = ref.watch(doctorAuthProvider.notifier);
  // Database will be initialized by the caller when available
  return authService;
});
