import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/suggestions_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/suggestion_text_field.dart';

class EditAppointmentScreen extends ConsumerStatefulWidget {
  const EditAppointmentScreen({
    super.key,
    required this.appointment,
    this.patient,
  });
  
  final Appointment appointment;
  final Patient? patient;

  @override
  ConsumerState<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends ConsumerState<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _duration;
  late String _status;
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;
  bool _showTimeSlots = false;

  final List<int> _durations = [15, 30, 45, 60, 90, 120];
  final List<String> _statuses = ['scheduled', 'confirmed', 'completed', 'cancelled', 'no-show'];

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing appointment data
    _selectedDate = widget.appointment.appointmentDateTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.appointment.appointmentDateTime);
    _duration = widget.appointment.durationMinutes;
    _reasonController.text = widget.appointment.reason;
    _status = widget.appointment.status;
    _notesController.text = widget.appointment.notes;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildModernSliverAppBar(context, isDark),
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildFormContent(context, isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black87,
              size: 22,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () => _confirmDelete(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                  ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                  : [Colors.white, const Color(0xFFF8F9FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Edit Appointment',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.patient != null 
                              ? '${widget.patient!.firstName} ${widget.patient!.lastName}'
                              : 'Patient #${widget.appointment.patientId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Time Card
          _buildModernDateTimeCard(context, isDark),
          const SizedBox(height: 16),

          // Status Selection
          _buildModernSectionCard(
            title: 'Status',
            icon: Icons.flag_rounded,
            iconColor: const Color(0xFF8B5CF6),
            isDark: isDark,
            child: _buildStatusSelector(context, isDark),
          ),
          const SizedBox(height: 16),

          // Appointment Details
          _buildModernSectionCard(
            title: 'Visit Details',
            icon: Icons.medical_services_rounded,
            iconColor: const Color(0xFF10B981),
            isDark: isDark,
            child: Column(
              children: [
                _buildReasonSelector(context, isDark),
                const SizedBox(height: 16),
                _buildDurationSelector(context, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          _buildModernSectionCard(
            title: 'Notes',
            icon: Icons.note_alt_rounded,
            iconColor: const Color(0xFFF59E0B),
            isDark: isDark,
            child: _buildNotesField(context, isDark),
          ),
          const SizedBox(height: 24),

          // Save Button
          _buildModernSaveButton(context, isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildModernSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildModernDateTimeCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: _buildModernDateTimeItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: DateFormat('EEE, MMM d').format(_selectedDate),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showTimeSlots = !_showTimeSlots),
                    child: _buildModernDateTimeItem(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: _selectedTime.format(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showTimeSlots
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Quick Select',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildModernTimeSlotChip('9:00 AM', const TimeOfDay(hour: 9, minute: 0)),
                              _buildModernTimeSlotChip('10:00 AM', const TimeOfDay(hour: 10, minute: 0)),
                              _buildModernTimeSlotChip('11:00 AM', const TimeOfDay(hour: 11, minute: 0)),
                              _buildModernTimeSlotChip('12:00 PM', const TimeOfDay(hour: 12, minute: 0)),
                              _buildModernTimeSlotChip('2:00 PM', const TimeOfDay(hour: 14, minute: 0)),
                              _buildModernTimeSlotChip('3:00 PM', const TimeOfDay(hour: 15, minute: 0)),
                              _buildModernTimeSlotChip('4:00 PM', const TimeOfDay(hour: 16, minute: 0)),
                              _buildModernTimeSlotChip('5:00 PM', const TimeOfDay(hour: 17, minute: 0)),
                              GestureDetector(
                                onTap: () => _selectTime(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.more_time_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text('Custom', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDateTimeItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTimeSlotChip(String label, TimeOfDay time) {
    final isSelected = _selectedTime.hour == time.hour && _selectedTime.minute == time.minute;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD97706) : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSelector(BuildContext context, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statuses.map((status) {
        final isSelected = _status == status;
        Color statusColor;
        IconData statusIcon;
        
        switch (status) {
          case 'scheduled':
            statusColor = const Color(0xFF3B82F6);
            statusIcon = Icons.schedule_rounded;
          case 'confirmed':
            statusColor = const Color(0xFF10B981);
            statusIcon = Icons.check_circle_rounded;
          case 'completed':
            statusColor = const Color(0xFF8B5CF6);
            statusIcon = Icons.done_all_rounded;
          case 'cancelled':
            statusColor = const Color(0xFFEF4444);
            statusIcon = Icons.cancel_rounded;
          case 'no-show':
            statusColor = const Color(0xFFF59E0B);
            statusIcon = Icons.person_off_rounded;
          default:
            statusColor = AppColors.textSecondary;
            statusIcon = Icons.help_outline_rounded;
        }

        return GestureDetector(
          onTap: () => setState(() => _status = status),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? statusColor.withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? statusColor : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: isSelected ? statusColor : (isDark ? Colors.grey : Colors.grey[600]), size: 18),
                const SizedBox(width: 6),
                Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    color: isSelected ? statusColor : (isDark ? Colors.grey : Colors.grey[600]),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReasonSelector(BuildContext context, bool isDark) {
    return SuggestionTextField(
      controller: _reasonController,
      label: 'Reason for Visit',
      hint: 'e.g., Follow-up, Consultation',
      suggestions: AppointmentSuggestions.visitReasons,
    );
  }

  Widget _buildDurationSelector(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _durations.map((duration) {
            final isSelected = _duration == duration;
            return GestureDetector(
              onTap: () => setState(() => _duration = duration),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '$duration min',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF10B981) : (isDark ? Colors.grey : Colors.grey[600]),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField(BuildContext context, bool isDark) {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add any additional notes...',
        hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
    );
  }

  Widget _buildModernSaveButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAppointment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = await ref.read(doctorDbProvider.future);
      
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final updatedAppointment = AppointmentsCompanion(
        id: Value(widget.appointment.id),
        patientId: Value(widget.appointment.patientId),
        appointmentDateTime: Value(appointmentDateTime),
        durationMinutes: Value(_duration),
        reason: Value(_reasonController.text),
        status: Value(_status),
        notes: Value(_notesController.text),
        reminderAt: Value(widget.appointment.reminderAt),
        medicalRecordId: Value(widget.appointment.medicalRecordId),
        createdAt: Value(widget.appointment.createdAt),
      );

      await db.updateAppointment(updatedAppointment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Appointment updated successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Delete Appointment'),
          ],
        ),
        content: const Text('Are you sure you want to delete this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final db = await ref.read(doctorDbProvider.future);
        await db.deleteAppointment(widget.appointment.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Appointment deleted'),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}
