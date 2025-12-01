import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';

/// Screen to manage scheduled follow-ups
class FollowUpsScreen extends ConsumerStatefulWidget {
  final int? patientId;
  final String? patientName;

  const FollowUpsScreen({
    super.key,
    this.patientId,
    this.patientName,
  });

  @override
  ConsumerState<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends ConsumerState<FollowUpsScreen> with SingleTickerProviderStateMixin {
  List<ScheduledFollowUp> _followUps = [];
  Map<int, Patient> _patientMap = {};
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFollowUps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowUps() async {
    ref.read(doctorDbProvider).whenData((db) async {
      List<ScheduledFollowUp> followUps;
      
      if (widget.patientId != null) {
        followUps = await db.getScheduledFollowUpsForPatient(widget.patientId!);
      } else {
        followUps = await db.getAllScheduledFollowUps();
      }

      // Load patient info for all follow-ups
      final Map<int, Patient> patientMap = {};
      for (final followUp in followUps) {
        if (!patientMap.containsKey(followUp.patientId)) {
          final patient = await db.getPatientById(followUp.patientId);
          if (patient != null) {
            patientMap[followUp.patientId] = patient;
          }
        }
      }

      if (mounted) {
        setState(() {
          _followUps = followUps;
          _patientMap = patientMap;
          _isLoading = false;
        });
      }
    });
  }

  List<ScheduledFollowUp> get _pendingFollowUps => 
    _followUps.where((f) => f.status == 'pending').toList();

  List<ScheduledFollowUp> get _overdueFollowUps {
    final now = DateTime.now();
    return _followUps.where((f) => 
      f.status == 'pending' && f.scheduledDate.isBefore(now)).toList();
  }

  List<ScheduledFollowUp> get _upcomingFollowUps {
    final now = DateTime.now();
    return _followUps.where((f) => 
      f.status == 'pending' && !f.scheduledDate.isBefore(now)).toList();
  }

  List<ScheduledFollowUp> get _completedFollowUps => 
    _followUps.where((f) => f.status == 'completed' || f.status == 'scheduled').toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName != null 
          ? 'Follow-ups - ${widget.patientName}' 
          : 'All Follow-ups'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${_overdueFollowUps.length}'),
                isLabelVisible: _overdueFollowUps.isNotEmpty,
                backgroundColor: Colors.red,
                child: const Icon(Icons.warning_amber),
              ),
              text: 'Overdue',
            ),
            Tab(
              icon: Badge(
                label: Text('${_upcomingFollowUps.length}'),
                isLabelVisible: _upcomingFollowUps.isNotEmpty,
                child: const Icon(Icons.schedule),
              ),
              text: 'Upcoming',
            ),
            const Tab(icon: Icon(Icons.check_circle_outline), text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFollowUpsList(_overdueFollowUps, colorScheme, isOverdue: true),
                _buildFollowUpsList(_upcomingFollowUps, colorScheme),
                _buildFollowUpsList(_completedFollowUps, colorScheme, showCompleted: true),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFollowUpDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Schedule Follow-up'),
      ),
    );
  }

  Widget _buildFollowUpsList(List<ScheduledFollowUp> followUps, ColorScheme colorScheme, 
      {bool isOverdue = false, bool showCompleted = false}) {
    if (followUps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOverdue ? Icons.check_circle : (showCompleted ? Icons.history : Icons.event_available),
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isOverdue 
                ? 'No overdue follow-ups' 
                : (showCompleted ? 'No completed follow-ups' : 'No upcoming follow-ups'),
              style: TextStyle(fontSize: 18, color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    // Sort by date
    followUps.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: followUps.length,
      itemBuilder: (context, index) {
        final followUp = followUps[index];
        final patient = _patientMap[followUp.patientId];
        return _buildFollowUpCard(followUp, patient, colorScheme, isOverdue: isOverdue);
      },
    );
  }

  Widget _buildFollowUpCard(ScheduledFollowUp followUp, Patient? patient, ColorScheme colorScheme, 
      {bool isOverdue = false}) {
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');
    final now = DateTime.now();
    final daysUntil = followUp.scheduledDate.difference(now).inDays;
    
    String urgencyText;
    Color urgencyColor;
    if (followUp.status == 'completed') {
      urgencyText = 'Completed';
      urgencyColor = Colors.green;
    } else if (followUp.status == 'scheduled') {
      urgencyText = 'Scheduled';
      urgencyColor = Colors.blue;
    } else if (daysUntil < 0) {
      urgencyText = '${-daysUntil} days overdue';
      urgencyColor = Colors.red;
    } else if (daysUntil == 0) {
      urgencyText = 'Today';
      urgencyColor = Colors.orange;
    } else if (daysUntil == 1) {
      urgencyText = 'Tomorrow';
      urgencyColor = Colors.orange;
    } else if (daysUntil <= 7) {
      urgencyText = 'In $daysUntil days';
      urgencyColor = Colors.blue;
    } else {
      urgencyText = 'In $daysUntil days';
      urgencyColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isOverdue ? Colors.red.withOpacity(0.05) : null,
      child: InkWell(
        onTap: () => _showFollowUpActions(followUp, patient),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: urgencyColor.withOpacity(0.1),
                    child: Icon(
                      followUp.status == 'completed' 
                        ? Icons.check 
                        : (isOverdue ? Icons.warning : Icons.event),
                      color: urgencyColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient != null ? '${patient.firstName} ${patient.lastName}' : 'Unknown Patient',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          followUp.reason,
                          style: TextStyle(color: colorScheme.outline),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      urgencyText,
                      style: TextStyle(
                        fontSize: 12,
                        color: urgencyColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(followUp.scheduledDate),
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                  if (followUp.reminderSent) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.notifications_active, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Reminder sent',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ],
                ],
              ),
              if (followUp.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  followUp.notes,
                  style: TextStyle(fontSize: 12, color: colorScheme.outline, fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFollowUpActions(ScheduledFollowUp followUp, Patient? patient) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.person, color: colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient != null ? '${patient.firstName} ${patient.lastName}' : 'Unknown',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(followUp.reason, style: TextStyle(color: colorScheme.outline)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (followUp.status == 'pending') ...[
              ListTile(
                leading: const Icon(Icons.event_available, color: Colors.green),
                title: const Text('Convert to Appointment'),
                subtitle: const Text('Create an appointment for this follow-up'),
                onTap: () async {
                  Navigator.pop(context);
                  await _convertToAppointment(followUp, patient);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.blue),
                title: const Text('Mark as Completed'),
                subtitle: const Text('Follow-up was addressed'),
                onTap: () async {
                  Navigator.pop(context);
                  await _markAsCompleted(followUp);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_calendar, color: Colors.orange),
                title: const Text('Reschedule'),
                subtitle: const Text('Change the follow-up date'),
                onTap: () async {
                  Navigator.pop(context);
                  await _rescheduleFollowUp(followUp);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.purple),
                title: const Text('Send Reminder'),
                subtitle: Text(followUp.reminderSent ? 'Reminder already sent' : 'Send reminder to patient'),
                enabled: !followUp.reminderSent,
                onTap: followUp.reminderSent ? null : () async {
                  Navigator.pop(context);
                  await _sendReminder(followUp, patient);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Cancel Follow-up', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _cancelFollowUp(followUp);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToAppointment(ScheduledFollowUp followUp, Patient? patient) async {
    // Show time picker for the appointment
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (time != null && mounted) {
      final appointmentDateTime = DateTime(
        followUp.scheduledDate.year,
        followUp.scheduledDate.month,
        followUp.scheduledDate.day,
        time.hour,
        time.minute,
      );

      ref.read(doctorDbProvider).whenData((db) async {
        // Create appointment
        final appointmentId = await db.insertAppointment(AppointmentsCompanion.insert(
          patientId: followUp.patientId,
          appointmentDateTime: appointmentDateTime,
          reason: Value('Follow-up: ${followUp.reason}'),
          status: Value('Scheduled'),
        ));

        // Update follow-up status
        await db.updateScheduledFollowUp(ScheduledFollowUp(
          id: followUp.id,
          patientId: followUp.patientId,
          sourceAppointmentId: followUp.sourceAppointmentId,
          sourcePrescriptionId: followUp.sourcePrescriptionId,
          scheduledDate: followUp.scheduledDate,
          reason: followUp.reason,
          status: 'scheduled',
          createdAppointmentId: appointmentId,
          reminderSent: followUp.reminderSent,
          notes: followUp.notes,
          createdAt: followUp.createdAt,
        ));

        await _loadFollowUps();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment created for ${patient != null ? '${patient.firstName} ${patient.lastName}' : "patient"}'),
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  // Navigate to appointments
                },
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _markAsCompleted(ScheduledFollowUp followUp) async {
    ref.read(doctorDbProvider).whenData((db) async {
      await db.updateScheduledFollowUp(ScheduledFollowUp(
        id: followUp.id,
        patientId: followUp.patientId,
        sourceAppointmentId: followUp.sourceAppointmentId,
        sourcePrescriptionId: followUp.sourcePrescriptionId,
        scheduledDate: followUp.scheduledDate,
        reason: followUp.reason,
        status: 'completed',
        createdAppointmentId: followUp.createdAppointmentId,
        reminderSent: followUp.reminderSent,
        notes: followUp.notes,
        createdAt: followUp.createdAt,
      ));

      await _loadFollowUps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow-up marked as completed')),
        );
      }
    });
  }

  Future<void> _rescheduleFollowUp(ScheduledFollowUp followUp) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: followUp.scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate != null) {
      ref.read(doctorDbProvider).whenData((db) async {
        await db.updateScheduledFollowUp(ScheduledFollowUp(
          id: followUp.id,
          patientId: followUp.patientId,
          sourceAppointmentId: followUp.sourceAppointmentId,
          sourcePrescriptionId: followUp.sourcePrescriptionId,
          scheduledDate: newDate,
          reason: followUp.reason,
          status: followUp.status,
          createdAppointmentId: followUp.createdAppointmentId,
          reminderSent: false, // Reset reminder since date changed
          notes: followUp.notes,
          createdAt: followUp.createdAt,
        ));

        await _loadFollowUps();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Follow-up rescheduled to ${DateFormat('MMM dd, yyyy').format(newDate)}')),
          );
        }
      });
    }
  }

  Future<void> _sendReminder(ScheduledFollowUp followUp, Patient? patient) async {
    // In a real app, this would send an SMS or notification
    ref.read(doctorDbProvider).whenData((db) async {
      await db.updateScheduledFollowUp(ScheduledFollowUp(
        id: followUp.id,
        patientId: followUp.patientId,
        sourceAppointmentId: followUp.sourceAppointmentId,
        sourcePrescriptionId: followUp.sourcePrescriptionId,
        scheduledDate: followUp.scheduledDate,
        reason: followUp.reason,
        status: followUp.status,
        createdAppointmentId: followUp.createdAppointmentId,
        reminderSent: true,
        notes: followUp.notes,
        createdAt: followUp.createdAt,
      ));

      await _loadFollowUps();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder sent to ${patient != null ? '${patient.firstName} ${patient.lastName}' : "patient"}'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                ref.read(doctorDbProvider).whenData((db) async {
                  await db.updateScheduledFollowUp(ScheduledFollowUp(
                    id: followUp.id,
                    patientId: followUp.patientId,
                    sourceAppointmentId: followUp.sourceAppointmentId,
                    sourcePrescriptionId: followUp.sourcePrescriptionId,
                    scheduledDate: followUp.scheduledDate,
                    reason: followUp.reason,
                    status: followUp.status,
                    createdAppointmentId: followUp.createdAppointmentId,
                    reminderSent: false,
                    notes: followUp.notes,
                    createdAt: followUp.createdAt,
                  ));
                  await _loadFollowUps();
                });
              },
            ),
          ),
        );
      }
    });
  }

  Future<void> _cancelFollowUp(ScheduledFollowUp followUp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Follow-up'),
        content: const Text('Are you sure you want to cancel this follow-up?'),
        actions: [
          AppButton.tertiary(
            label: 'No',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton.danger(
            label: 'Yes, Cancel',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(doctorDbProvider).whenData((db) async {
        await db.deleteScheduledFollowUp(followUp.id);
        await _loadFollowUps();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Follow-up cancelled')),
          );
        }
      });
    }
  }

  void _showAddFollowUpDialog() {
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    DateTime scheduledDate = DateTime.now().add(const Duration(days: 7));
    int? selectedPatientId = widget.patientId;
    List<Patient> patients = [];

    // Load patients if not showing for a specific patient
    if (widget.patientId == null) {
      ref.read(doctorDbProvider).whenData((db) {
        db.getAllPatients().then((p) {
          patients = p;
        });
      });
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Follow-up'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.patientId == null) ...[
                  ref.read(doctorDbProvider).when(
                    data: (db) => FutureBuilder<List<Patient>>(
                      future: db.getAllPatients(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        return DropdownButtonFormField<int>(
                          value: selectedPatientId,
                          decoration: const InputDecoration(labelText: 'Patient'),
                          items: snapshot.data!.map((p) => 
                            DropdownMenuItem(value: p.id, child: Text('${p.firstName} ${p.lastName}'))
                          ).toList(),
                          onChanged: (value) => setDialogState(() => selectedPatientId = value),
                        );
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading patients'),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Follow-up',
                    hintText: 'e.g., Blood test review, Medication check',
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: scheduledDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => scheduledDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Scheduled Date'),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(DateFormat('EEE, MMM dd, yyyy').format(scheduledDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Additional notes...',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            AppButton.tertiary(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              onPressed: () async {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason')),
                  );
                  return;
                }
                if (selectedPatientId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a patient')),
                  );
                  return;
                }

                ref.read(doctorDbProvider).whenData((db) async {
                  await db.insertScheduledFollowUp(ScheduledFollowUpsCompanion.insert(
                    patientId: selectedPatientId!,
                    scheduledDate: scheduledDate,
                    reason: reasonController.text,
                    notes: Value(notesController.text),
                  ));

                  Navigator.pop(context);
                  await _loadFollowUps();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Follow-up scheduled')),
                    );
                  }
                });
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
