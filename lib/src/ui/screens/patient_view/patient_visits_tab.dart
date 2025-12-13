// Patient View - Unified Visits Tab
// Combines Appointments + Encounters into a single "Visit" concept
import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/components/app_button.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../theme/app_theme.dart';
import '../add_appointment_screen.dart';
import '../add_prescription_screen.dart';
import '../edit_appointment_screen.dart';
import '../workflow_wizard_screen.dart';
import '../../widgets/quick_checkin_dialog.dart';

/// Unified Visit model that combines Appointment + Encounter + Records + Prescriptions
class PatientVisit {
  final Appointment appointment;
  final Encounter? encounter;
  final VitalSign? vitals;
  final List<Diagnose> diagnoses;
  final List<ClinicalNote> notes;
  final List<Prescription> prescriptions;
  final List<MedicalRecord> records;

  PatientVisit({
    required this.appointment,
    this.encounter,
    this.vitals,
    this.diagnoses = const [],
    this.notes = const [],
    this.prescriptions = const [],
    this.records = const [],
  });

  bool get hasClinicData => encounter != null || vitals != null || diagnoses.isNotEmpty || prescriptions.isNotEmpty || records.isNotEmpty;
  
  String get displayStatus {
    if (appointment.status == 'completed') return 'Completed';
    if (appointment.status == 'cancelled') return 'Cancelled';
    if (appointment.status == 'checked_in') return 'In Progress';
    if (appointment.appointmentDateTime.isBefore(DateTime.now())) {
      return appointment.status == 'scheduled' ? 'Missed' : appointment.status;
    }
    return 'Scheduled';
  }
}

class PatientVisitsTab extends ConsumerStatefulWidget {
  const PatientVisitsTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  ConsumerState<PatientVisitsTab> createState() => _PatientVisitsTabState();
}

class _PatientVisitsTabState extends ConsumerState<PatientVisitsTab> {
  String _filter = 'all'; // 'all', 'upcoming', 'past', 'completed'
  List<PatientVisit>? _visits;
  bool _isLoading = true;
  String? _error;
  int _refreshKey = 0; // Used to force refresh

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(PatientVisitsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient.id != widget.patient.id) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = await ref.read(doctorDbProvider.future);
      final visits = await _loadVisits(db);
      
      if (mounted) {
        setState(() {
          _visits = visits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Public method to trigger refresh from parent widget
  void refresh() {
    _refreshKey++;
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    var visits = _visits ?? [];
    
    // Apply filter
    final now = DateTime.now();
    if (_filter == 'upcoming') {
      visits = visits.where((v) => v.appointment.appointmentDateTime.isAfter(now)).toList();
    } else if (_filter == 'past') {
      visits = visits.where((v) => v.appointment.appointmentDateTime.isBefore(now)).toList();
    } else if (_filter == 'completed') {
      visits = visits.where((v) => v.appointment.status == 'completed').toList();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Filter chips
          _buildFilterChips(isDark),
          
          // Visits list
          Expanded(
            child: visits.isEmpty
                ? _buildEmptyState(context, isDark)
                : ListView.builder(
                    primary: false,
                    padding: const EdgeInsets.all(16),
                    itemCount: visits.length,
                    itemBuilder: (context, index) => _VisitCard(
                      visit: visits[index],
                      isDark: isDark,
                      onTap: () => _showVisitDetails(visits[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<List<PatientVisit>> _loadVisits(DoctorDatabase db) async {
    // Get all appointments for patient
    final allAppointments = await db.getAllAppointments();
    final appointments = allAppointments
        .where((a) => a.patientId == widget.patient.id)
        .toList()
      ..sort((a, b) => b.appointmentDateTime.compareTo(a.appointmentDateTime));

    // Get all encounters for patient
    final encounters = await db.getEncountersForPatient(widget.patient.id);
    
    // Get all prescriptions for patient
    final allPrescriptions = await db.getPrescriptionsForPatient(widget.patient.id);
    
    // Get all medical records for patient
    final allRecords = await db.getMedicalRecordsForPatient(widget.patient.id);
    
    // Build visits by matching appointments with encounters, prescriptions, and records
    final visits = <PatientVisit>[];
    
    for (final apt in appointments) {
      // Find matching encounter (by appointmentId)
      Encounter? matchingEncounter;
      for (final enc in encounters) {
        if (enc.appointmentId == apt.id) {
          matchingEncounter = enc;
          break;
        }
      }
      
      VitalSign? vitals;
      List<Diagnose> diagnoses = [];
      List<ClinicalNote> notes = [];
      List<Prescription> prescriptions = [];
      List<MedicalRecord> records = [];
      
      if (matchingEncounter != null) {
        // Load encounter details
        vitals = await db.getLatestVitalSignsForEncounter(matchingEncounter.id);
        diagnoses = await db.getFullDiagnosesForEncounter(matchingEncounter.id);
        notes = await db.getClinicalNotesForEncounter(matchingEncounter.id);
        
        // Get prescriptions linked to this encounter
        prescriptions = allPrescriptions
            .where((rx) => rx.encounterId == matchingEncounter!.id || rx.appointmentId == apt.id)
            .toList();
        
        // Get medical records linked to this encounter
        records = allRecords
            .where((rec) => rec.encounterId == matchingEncounter!.id)
            .toList();
      } else {
        // No encounter, check for prescriptions/records linked by appointment ID
        prescriptions = allPrescriptions
            .where((rx) => rx.appointmentId == apt.id)
            .toList();
      }
      
      // Also check for prescriptions/records on same day (legacy data)
      if (prescriptions.isEmpty) {
        prescriptions = allPrescriptions.where((rx) {
          final rxDate = rx.createdAt;
          return rxDate.year == apt.appointmentDateTime.year &&
                 rxDate.month == apt.appointmentDateTime.month &&
                 rxDate.day == apt.appointmentDateTime.day;
        }).toList();
      }
      
      if (records.isEmpty) {
        records = allRecords.where((rec) {
          return rec.recordDate.year == apt.appointmentDateTime.year &&
                 rec.recordDate.month == apt.appointmentDateTime.month &&
                 rec.recordDate.day == apt.appointmentDateTime.day;
        }).toList();
      }
      
      visits.add(PatientVisit(
        appointment: apt,
        encounter: matchingEncounter,
        vitals: vitals,
        diagnoses: diagnoses,
        notes: notes,
        prescriptions: prescriptions,
        records: records,
      ));
    }
    
    return visits;
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      ('all', 'All', Icons.list_alt_rounded),
      ('upcoming', 'Upcoming', Icons.upcoming_rounded),
      ('past', 'Past', Icons.history_rounded),
      ('completed', 'Completed', Icons.check_circle_outline_rounded),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: filters.map((f) {
            final isSelected = _filter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        f.$3,
                        size: 16,
                        color: isSelected 
                            ? Colors.white 
                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Colors.white 
                              : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      primary: false,
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Visits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Schedule an appointment to start tracking visits',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pull down to refresh',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddAppointmentScreen(preselectedPatient: widget.patient),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Schedule Visit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVisitDetails(PatientVisit visit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VisitDetailSheet(
        visit: visit,
        isDark: isDark,
        patient: widget.patient,
        onVisitUpdated: () => _loadData(), // Refresh data when visit is updated
      ),
    );
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.isDark,
    required this.onTap,
  });

  final PatientVisit visit;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final apt = visit.appointment;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    Color statusColor;
    IconData statusIcon;
    switch (visit.displayStatus.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
      case 'in progress':
        statusColor = AppColors.warning;
        statusIcon = Icons.play_circle;
      case 'missed':
        statusColor = AppColors.error;
        statusIcon = Icons.error;
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.schedule;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: visit.hasClinicData 
                ? AppColors.success.withValues(alpha: 0.3) 
                : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Date badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM').format(apt.appointmentDateTime).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        apt.appointmentDateTime.day.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeFormat.format(apt.appointmentDateTime),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (apt.reason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          apt.reason,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        visit.displayStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Clinical data summary (if available)
            if (visit.hasClinicData) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (visit.vitals != null)
                            _buildDataChip(Icons.monitor_heart, 'Vitals', AppColors.error),
                          if (visit.diagnoses.isNotEmpty)
                            _buildDataChip(Icons.medical_information, '${visit.diagnoses.length} Dx', AppColors.primary),
                          if (visit.notes.isNotEmpty)
                            _buildDataChip(Icons.notes, 'Notes', AppColors.warning),
                          if (visit.prescriptions.isNotEmpty)
                            _buildDataChip(Icons.medication, '${visit.prescriptions.length} Rx', const Color(0xFF8B5CF6)),
                          if (visit.records.isNotEmpty)
                            _buildDataChip(Icons.folder_outlined, '${visit.records.length} Records', const Color(0xFF0EA5E9)),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _VisitDetailSheet extends ConsumerStatefulWidget {
  const _VisitDetailSheet({
    required this.visit,
    required this.isDark,
    required this.patient,
    required this.onVisitUpdated,
  });

  final PatientVisit visit;
  final bool isDark;
  final Patient patient;
  final VoidCallback onVisitUpdated;

  @override
  ConsumerState<_VisitDetailSheet> createState() => _VisitDetailSheetState();
}

class _VisitDetailSheetState extends ConsumerState<_VisitDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final apt = widget.visit.appointment;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final isUpcoming = apt.appointmentDateTime.isAfter(DateTime.now());
    final isPast = apt.appointmentDateTime.isBefore(DateTime.now());
    final isCancelled = apt.status.toLowerCase() == 'cancelled';
    final isCompleted = apt.status.toLowerCase() == 'completed';
    final isInProgress = apt.status.toLowerCase() == 'in_progress' || apt.status.toLowerCase() == 'checked_in';

    Color statusColor;
    IconData statusIcon;
    switch (widget.visit.displayStatus.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
      case 'in progress':
        statusColor = AppColors.warning;
        statusIcon = Icons.play_circle;
      case 'missed':
        statusColor = AppColors.error;
        statusIcon = Icons.error;
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.schedule;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  // Header with status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withValues(alpha: 0.2),
                              statusColor.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.calendar_today_rounded, color: statusColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visit Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: widget.isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 14, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.visit.displayStatus.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Date & Time Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.1),
                          AppColors.primary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  dateFormat.format(apt.appointmentDateTime),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: widget.isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.access_time, color: AppColors.primary, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Time',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        timeFormat.format(apt.appointmentDateTime),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: widget.isDark ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Duration',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${apt.durationMinutes} min',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: widget.isDark ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Quick Action Buttons for upcoming appointments
                  if (isUpcoming && !isCancelled) ...[
                    const SizedBox(height: 20),
                    _buildQuickActions(context, apt, isInProgress),
                  ],
                  
                  if (apt.reason.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Reason for Visit',
                      icon: Icons.assignment,
                      child: Text(apt.reason, style: TextStyle(color: widget.isDark ? Colors.white : AppColors.textPrimary)),
                    ),
                  ],
                  
                  // Vitals
                  if (widget.visit.vitals != null) ...[
                    const SizedBox(height: 20),
                    _buildVitalsSection(widget.visit.vitals!),
                  ],
                  
                  // Diagnoses
                  if (widget.visit.diagnoses.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Diagnoses',
                      icon: Icons.medical_information,
                      child: Column(
                        children: widget.visit.diagnoses.map((dx) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  dx.icdCode.isNotEmpty ? dx.icdCode : 'Dx',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dx.description,
                                  style: TextStyle(
                                    color: widget.isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                  
                  // Notes
                  if (widget.visit.notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Clinical Notes',
                      icon: Icons.notes,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.visit.notes.map((note) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.isDark ? AppColors.darkSurface : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (note.subjective.isNotEmpty) ...[
                                _buildNoteField('S', note.subjective),
                                const SizedBox(height: 8),
                              ],
                              if (note.objective.isNotEmpty) ...[
                                _buildNoteField('O', note.objective),
                                const SizedBox(height: 8),
                              ],
                              if (note.assessment.isNotEmpty) ...[
                                _buildNoteField('A', note.assessment),
                                const SizedBox(height: 8),
                              ],
                              if (note.plan.isNotEmpty)
                                _buildNoteField('P', note.plan),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                  
                  // Prescriptions
                  if (widget.visit.prescriptions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Prescriptions',
                      icon: Icons.medication,
                      child: Column(
                        children: widget.visit.prescriptions.map((rx) => _buildPrescriptionItem(rx, widget.isDark)).toList(),
                      ),
                    ),
                  ],
                  
                  // Medical Records
                  if (widget.visit.records.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Medical Records',
                      icon: Icons.folder_outlined,
                      child: Column(
                        children: widget.visit.records.map((rec) => _buildRecordItem(rec, widget.isDark)).toList(),
                      ),
                    ),
                  ],
                  
                  // Appointment notes
                  if (apt.notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSection(
                      title: 'Visit Notes',
                      icon: Icons.edit_note,
                      child: Text(
                        apt.notes,
                        style: TextStyle(color: widget.isDark ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Main Action Buttons
                  _buildMainActions(context, apt, isUpcoming, isPast, isCancelled, isCompleted, isInProgress),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Appointment apt, bool isInProgress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.patient.phone.isNotEmpty) ...[
                  _buildQuickActionButton(
                    icon: Icons.phone_rounded,
                    label: 'Call',
                    color: AppColors.success,
                    onTap: () => _callPatient(widget.patient.phone),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickActionButton(
                    icon: Icons.message_rounded,
                    label: 'SMS',
                    color: AppColors.info,
                    onTap: () => _messagePatient(widget.patient.phone),
                  ),
                  const SizedBox(width: 10),
                ],
                _buildQuickActionButton(
                  icon: Icons.edit_calendar_rounded,
                  label: 'Reschedule',
                  color: AppColors.warning,
                  onTap: () => _showRescheduleDialog(context, apt),
                ),
                const SizedBox(width: 10),
                if (!isInProgress) ...[
                  _buildQuickActionButton(
                    icon: Icons.how_to_reg_rounded,
                    label: 'Check-In',
                    color: const Color(0xFF10B981),
                    onTap: () => _quickCheckIn(context, apt),
                  ),
                  const SizedBox(width: 10),
                ],
                _buildQuickActionButton(
                  icon: Icons.play_circle_rounded,
                  label: isInProgress ? 'Continue' : 'Start',
                  color: const Color(0xFF059669),
                  onTap: () => _startConsultation(context, apt),
                ),
                const SizedBox(width: 10),
                _buildQuickActionButton(
                  icon: Icons.medication_rounded,
                  label: 'Prescribe',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _addPrescription(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActions(
    BuildContext context,
    Appointment apt,
    bool isUpcoming,
    bool isPast,
    bool isCancelled,
    bool isCompleted,
    bool isInProgress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary action button for UPCOMING and NOT cancelled
        if (isUpcoming && !isCancelled) ...[
          if (isInProgress) ...[
            ElevatedButton.icon(
              onPressed: () => _completeVisit(context, apt),
              icon: const Icon(Icons.check_circle_rounded, size: 22),
              label: const Text('Complete Visit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => _startConsultation(context, apt),
              icon: const Icon(Icons.play_circle_rounded, size: 22),
              label: const Text('Start Consultation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton.tertiary(
                  label: 'Edit',
                  icon: Icons.edit,
                  onPressed: () => _editAppointment(context, apt),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton.danger(
                  label: 'Cancel',
                  icon: Icons.cancel_outlined,
                  onPressed: () => _showCancelConfirmation(context, apt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ]
        // Past but not completed and not cancelled
        else if (isPast && !isCompleted && !isCancelled) ...[
          Row(
            children: [
              Expanded(
                child: AppButton.tertiary(
                  label: 'Edit',
                  icon: Icons.edit,
                  onPressed: () => _editAppointment(context, apt),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Complete',
                  icon: Icons.check,
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  onPressed: () => _markAsCompleted(context, apt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ]
        // Already completed - just edit option
        else if (isCompleted) ...[
          AppButton.tertiary(
            label: 'Edit',
            icon: Icons.edit,
            fullWidth: true,
            onPressed: () => _editAppointment(context, apt),
          ),
          const SizedBox(height: 12),
        ]
        // Cancelled - no edit options, just delete
        else if (isCancelled) ...[
          // Nothing here, just show delete below
        ],
        
        // Delete button - always available
        AppButton.danger(
          label: 'Delete Visit',
          icon: Icons.delete_outline,
          fullWidth: true,
          onPressed: () => _showDeleteConfirmation(context, apt),
        ),
      ],
    );
  }

  // Action methods
  Future<void> _callPatient(String phone) async {
    unawaited(HapticFeedback.lightImpact());
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
  
  Future<void> _messagePatient(String phone) async {
    unawaited(HapticFeedback.lightImpact());
    final url = Uri.parse('sms:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _startConsultation(BuildContext context, Appointment apt) async {
    HapticFeedback.mediumImpact();
    final db = ref.read(doctorDbProvider).value;
    if (db == null) return;
    
    // Update appointment status to in_progress
    await db.updateAppointmentStatus(apt.id, 'in_progress');
    
    // Navigate to workflow wizard
    if (context.mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkflowWizardScreen(
            existingPatient: widget.patient,
            existingAppointment: apt,
          ),
        ),
      );
      widget.onVisitUpdated();
    }
  }

  Future<void> _quickCheckIn(BuildContext context, Appointment apt) async {
    HapticFeedback.mediumImpact();
    final db = ref.read(doctorDbProvider).value;
    if (db == null) return;
    
    final result = await showQuickCheckInDialog(context, db, apt, widget.patient);
    if (result != null && result.success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? '${widget.patient.firstName} checked in'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
      widget.onVisitUpdated();
    }
  }

  Future<void> _showRescheduleDialog(BuildContext context, Appointment apt) async {
    HapticFeedback.lightImpact();
    final db = ref.read(doctorDbProvider).value;
    if (db == null) return;
    
    DateTime selectedDate = apt.appointmentDateTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(apt.appointmentDateTime);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reschedule Visit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current: ${DateFormat('EEE, MMM d').format(apt.appointmentDateTime)} at ${DateFormat('h:mm a').format(apt.appointmentDateTime)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('EEE, MMM d, yyyy').format(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reschedule'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final newDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      
      await db.updateAppointment(AppointmentsCompanion(
        id: Value(apt.id),
        patientId: Value(apt.patientId),
        appointmentDateTime: Value(newDateTime),
        durationMinutes: Value(apt.durationMinutes),
        reason: Value(apt.reason),
        status: const Value('rescheduled'),
        notes: Value(apt.notes),
        reminderAt: Value(apt.reminderAt),
        medicalRecordId: Value(apt.medicalRecordId),
      ));
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Visit rescheduled to ${DateFormat('EEE, MMM d').format(newDateTime)} at ${DateFormat('h:mm a').format(newDateTime)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onVisitUpdated();
      }
    }
  }

  void _addPrescription(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPrescriptionScreen(
          preselectedPatient: widget.patient,
          appointmentId: widget.visit.appointment.id,
        ),
      ),
    );
  }

  Future<void> _editAppointment(BuildContext context, Appointment apt) async {
    Navigator.pop(context);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditAppointmentScreen(
          appointment: apt,
          patient: widget.patient,
        ),
      ),
    );
    if (result == true) {
      widget.onVisitUpdated();
    }
  }

  Future<void> _completeVisit(BuildContext context, Appointment apt) async {
    final db = ref.read(doctorDbProvider).value;
    if (db == null) return;
    
    await db.updateAppointmentStatus(apt.id, 'completed');
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visit completed for ${widget.patient.firstName} ${widget.patient.lastName}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onVisitUpdated();
    }
  }

  Future<void> _markAsCompleted(BuildContext context, Appointment apt) async {
    final db = ref.read(doctorDbProvider).value;
    if (db == null) return;
    
    await db.updateAppointmentStatus(apt.id, 'completed');
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visit marked as completed'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
      widget.onVisitUpdated();
    }
  }

  Future<void> _showCancelConfirmation(BuildContext context, Appointment apt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Visit'),
        content: Text('Are you sure you want to cancel the visit with ${widget.patient.firstName} ${widget.patient.lastName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final db = ref.read(doctorDbProvider).value;
      if (db == null) return;
      
      await db.updateAppointmentStatus(apt.id, 'cancelled');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit cancelled successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        widget.onVisitUpdated();
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Appointment apt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Delete Visit'),
          ],
        ),
        content: Text('Are you sure you want to permanently delete the visit with ${widget.patient.firstName} ${widget.patient.lastName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final db = ref.read(doctorDbProvider).value;
      if (db == null) return;
      
      await db.deleteAppointment(apt.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit deleted successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        widget.onVisitUpdated();
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildVitalsSection(VitalSign vitals) {
    return _buildSection(
      title: 'Vital Signs',
      icon: Icons.monitor_heart,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : const Color(0xFFFDF2F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildVitalItem('BP', '${vitals.systolicBp?.toInt() ?? '--'}/${vitals.diastolicBp?.toInt() ?? '--'}', 'mmHg'),
            _buildVitalItem('HR', '${vitals.heartRate ?? '--'}', 'bpm'),
            _buildVitalItem('Temp', '${vitals.temperature?.toStringAsFixed(1) ?? '--'}', '°C'),
            _buildVitalItem('SpO₂', '${vitals.oxygenSaturation?.toInt() ?? '--'}', '%'),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildNoteField(String label, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: widget.isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionItem(Prescription rx, bool isDark) {
    // V5: Use FutureBuilder to load medications from normalized table
    final dbAsync = ref.read(doctorDbProvider);
    final db = dbAsync.when(
      data: (db) => db,
      loading: () => null,
      error: (_, __) => null,
    );
    
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return FutureBuilder<List<dynamic>>(
      future: db != null 
          ? db.getMedicationsForPrescriptionCompat(rx.id)
          : Future.value(<dynamic>[]),
      builder: (context, snapshot) {
        final medications = snapshot.data ?? [];
    
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.medication, size: 16, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rx #${rx.id}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          dateFormat.format(rx.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${medications.length} items',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          // Medications list
          if (medications.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...medications.take(3).map((med) {
              final m = med as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Color(0xFF8B5CF6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${m['name'] ?? 'Medication'} - ${m['dosage'] ?? ''} ${m['frequency'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (medications.length > 3)
              Text(
                '+${medications.length - 3} more',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
          ],
        ],
      ),
    );
      }, // End of FutureBuilder builder
    ); // End of FutureBuilder
  }

  Widget _buildRecordItem(MedicalRecord record, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    IconData recordIcon;
    Color recordColor;
    
    switch (record.recordType.toLowerCase()) {
      case 'lab_result':
        recordIcon = Icons.science;
        recordColor = const Color(0xFF0EA5E9);
        break;
      case 'imaging':
        recordIcon = Icons.image;
        recordColor = const Color(0xFF10B981);
        break;
      case 'procedure':
        recordIcon = Icons.medical_services;
        recordColor = const Color(0xFFF59E0B);
        break;
      case 'psychiatric_assessment':
        recordIcon = Icons.psychology;
        recordColor = const Color(0xFFEC4899);
        break;
      default:
        recordIcon = Icons.description;
        recordColor = const Color(0xFF6366F1);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: recordColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: recordColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(recordIcon, size: 20, color: recordColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: recordColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatRecordType(record.recordType),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: recordColor,
                        ),
                      ),
                    ),
                    Text(
                      dateFormat.format(record.recordDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (record.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
  
  String _formatRecordType(String type) {
    return type.replaceAll('_', ' ').split(' ').map((word) => 
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }
}
