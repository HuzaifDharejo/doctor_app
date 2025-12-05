import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../db/doctor_db.dart';
import '../../services/encounter_service.dart';
import '../../theme/app_theme.dart';

/// Quick Check-In Dialog
/// 
/// Allows fast patient check-in for scheduled appointments with optional
/// auto-encounter creation. Streamlines the check-in workflow.
class QuickCheckInDialog extends StatefulWidget {
  const QuickCheckInDialog({
    super.key,
    required this.appointment,
    required this.patient,
    required this.db,
  });

  final Appointment appointment;
  final Patient patient;
  final DoctorDatabase db;

  @override
  State<QuickCheckInDialog> createState() => _QuickCheckInDialogState();
}

class _QuickCheckInDialogState extends State<QuickCheckInDialog> {
  bool _autoCreateEncounter = true;
  bool _isLoading = false;
  String _notes = '';

  Future<void> _checkIn() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // Update appointment status to checked_in
      await widget.db.updateAppointmentStatus(widget.appointment.id, 'checked_in');

      int? encounterId;
      if (_autoCreateEncounter) {
        // Create encounter automatically
        final encounterService = EncounterService(db: widget.db);
        encounterId = await encounterService.startEncounter(
          patientId: widget.patient.id,
          appointmentId: widget.appointment.id,
          chiefComplaint: widget.appointment.reason,
          encounterType: 'outpatient',
        );

        // Update appointment notes if any
        if (_notes.isNotEmpty) {
          await widget.db.updateAppointment(AppointmentsCompanion(
            id: Value(widget.appointment.id),
            patientId: Value(widget.appointment.patientId),
            appointmentDateTime: Value(widget.appointment.appointmentDateTime),
            notes: Value(_notes),
          ));
        }
      }

      if (mounted) {
        Navigator.pop(context, CheckInResult(
          success: true,
          encounterId: encounterId,
          message: _autoCreateEncounter 
              ? 'Patient checked in and encounter started'
              : 'Patient checked in',
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Check-in failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFormat = DateFormat('h:mm a');
    final patientName = '${widget.patient.firstName} ${widget.patient.lastName}';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.15),
                    const Color(0xFF059669).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.how_to_reg_rounded,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Check-In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mark patient as arrived',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            // Patient Info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.05) 
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          child: Text(
                            '${widget.patient.firstName[0]}${widget.patient.lastName.isNotEmpty ? widget.patient.lastName[0] : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: isDark ? Colors.white54 : Colors.black45,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Scheduled: ${timeFormat.format(widget.appointment.appointmentDateTime)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reason for visit
                  if (widget.appointment.reason.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.medical_services_outlined,
                            size: 18,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.appointment.reason,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Auto-create encounter toggle
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _autoCreateEncounter
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : (isDark 
                              ? Colors.white.withValues(alpha: 0.05) 
                              : Colors.grey.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _autoCreateEncounter
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flash_on_rounded,
                          color: _autoCreateEncounter
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.white54 : Colors.black45),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Auto-start encounter',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create encounter record on check-in',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _autoCreateEncounter,
                          onChanged: (v) => setState(() => _autoCreateEncounter = v),
                          activeColor: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick notes
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add check-in notes (optional)',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? Colors.white.withValues(alpha: 0.05) 
                          : Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      prefixIcon: Icon(
                        Icons.notes_rounded,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    onChanged: (v) => _notes = v,
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _checkIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(_autoCreateEncounter ? 'Check-In & Start' : 'Check-In'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result of check-in operation
class CheckInResult {
  CheckInResult({
    required this.success,
    this.encounterId,
    this.message,
  });

  final bool success;
  final int? encounterId;
  final String? message;
}

/// Show the quick check-in dialog
Future<CheckInResult?> showQuickCheckInDialog(
  BuildContext context,
  DoctorDatabase db,
  Appointment appointment,
  Patient patient,
) {
  return showDialog<CheckInResult>(
    context: context,
    builder: (context) => QuickCheckInDialog(
      appointment: appointment,
      patient: patient,
      db: db,
    ),
  );
}
