import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../providers/google_calendar_provider.dart';
import '../../services/suggestions_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/suggestion_text_field.dart';

class AddAppointmentScreen extends ConsumerStatefulWidget {

  const AddAppointmentScreen({
    super.key,
    this.initialDate,
    this.patientId,
    this.preselectedPatient,
  });
  final DateTime? initialDate;
  final int? patientId;
  final Patient? preselectedPatient;

  @override
  ConsumerState<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends ConsumerState<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  int _duration = 30;
  String _reason = '';
  final _notesController = TextEditingController();
  int? _selectedPatientId;
  bool _isSaving = false;
  bool _setReminder = true;
  bool _showTimeSlots = false;

  final List<int> _durations = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedPatientId = widget.patientId ?? widget.preselectedPatient?.id;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 20.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: dbAsync.when(
        data: (db) => CustomScrollView(
          slivers: [
            // Gradient Header
            SliverToBoxAdapter(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      children: [
                        // Custom App Bar
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'New Appointment',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 40), // Balance the back button
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Appointment Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Body Content
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFormContent(context, db),
                ]),
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => _buildErrorState(context),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase? db) {
    if (db == null) {
      return _buildErrorState(context);
    }

    return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Time Card
            _buildDateTimeCard(context),
            const SizedBox(height: 20),

            // Patient Selection
            _buildSectionHeader(context, 'Patient', Icons.person_outline),
            const SizedBox(height: 12),
            _buildPatientSelector(context, db),
            const SizedBox(height: 20),

            // Appointment Details
            _buildSectionHeader(context, 'Appointment Details', Icons.medical_services_outlined),
            const SizedBox(height: 12),
            _buildReasonSelector(context),
            const SizedBox(height: 16),
            _buildDurationSelector(context),
            const SizedBox(height: 20),

            // Notes
            _buildSectionHeader(context, 'Notes', Icons.notes_outlined),
            const SizedBox(height: 12),
            _buildNotesField(context),
            const SizedBox(height: 20),

            // Reminder Toggle
            _buildReminderToggle(context),
            const SizedBox(height: 32),

            // Save Button
            _buildSaveButton(context, db),
            const SizedBox(height: 40),
          ],
        ),
    );
  }

  Widget _buildDateTimeCard(BuildContext context) {
    return Column(
      children: [
        AppCard.gradient(
          padding: const EdgeInsets.all(20),
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  child: _buildDateTimeItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: DateFormat('EEE, MMM d').format(_selectedDate),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _showTimeSlots = !_showTimeSlots);
                  },
                  child: _buildDateTimeItem(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _selectedTime.format(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Quick Time Slots - shown when tapping time
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _showTimeSlots
              ? Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTimeSlotChip(context, '9:00 AM', const TimeOfDay(hour: 9, minute: 0)),
                        _buildTimeSlotChip(context, '10:00 AM', const TimeOfDay(hour: 10, minute: 0)),
                        _buildTimeSlotChip(context, '11:00 AM', const TimeOfDay(hour: 11, minute: 0)),
                        _buildTimeSlotChip(context, '12:00 PM', const TimeOfDay(hour: 12, minute: 0)),
                        _buildTimeSlotChip(context, '2:00 PM', const TimeOfDay(hour: 14, minute: 0)),
                        _buildTimeSlotChip(context, '3:00 PM', const TimeOfDay(hour: 15, minute: 0)),
                        _buildTimeSlotChip(context, '4:00 PM', const TimeOfDay(hour: 16, minute: 0)),
                        _buildTimeSlotChip(context, '5:00 PM', const TimeOfDay(hour: 17, minute: 0)),
                        _buildTimeSlotChip(context, '6:00 PM', const TimeOfDay(hour: 18, minute: 0)),
                        // Custom time picker option
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: ActionChip(
                            label: const Text('Custom', style: TextStyle(fontSize: 11)),
                            avatar: const Icon(Icons.edit, size: 14),
                            onPressed: () => _selectTime(context),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTimeSlotChip(BuildContext context, String label, TimeOfDay time) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTime.hour == time.hour && _selectedTime.minute == time.minute;
    
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : null)),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedTime = time);
          }
        },
        visualDensity: VisualDensity.compact,
        selectedColor: AppColors.primary,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        side: BorderSide(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider)),
      ),
    );
  }

  Widget _buildDateTimeItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientSelector(BuildContext context, DoctorDatabase db) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<List<Patient>>(
      future: db.getAllPatients(),
      builder: (context, snapshot) {
        final patients = snapshot.data ?? [];
        
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
          ),
          child: DropdownButtonFormField<int>(
            initialValue: _selectedPatientId,
            decoration: InputDecoration(
              hintText: 'Select a patient',
              prefixIcon: Icon(Icons.person_search_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.textHint),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: patients.map((p) => DropdownMenuItem(
              value: p.id,
              child: Text('${p.firstName} ${p.lastName}'),
            ),).toList(),
            onChanged: (value) {
              setState(() => _selectedPatientId = value);
            },
            validator: (value) => value == null ? 'Please select a patient' : null,
            dropdownColor: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        );
      },
    );
  }

  Widget _buildReasonSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Reason for Visit',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: AppointmentSuggestions.visitReasons.map((reason) {
                final isSelected = _reason == reason;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(reason),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _reason = selected ? reason : '');
                    },
                    backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.accent : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.accent : (isDark ? AppColors.darkDivider : AppColors.divider),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      borderColor: isDark ? AppColors.darkDivider : AppColors.divider,
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duration',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_duration min',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: _durations.map((duration) {
              final isSelected = _duration == duration;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _duration = duration),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.accentGradient : null,
                      color: isSelected ? null : (isDark ? AppColors.darkBackground : AppColors.background),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? null : Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                    ),
                    child: Center(
                      child: Text(
                        '$duration',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField(BuildContext context) {
    return SuggestionTextField(
      controller: _notesController,
      label: 'Notes',
      hint: 'Add any additional notes...',
      prefixIcon: Icons.notes_outlined,
      maxLines: 3,
      suggestions: AppointmentSuggestions.notes,
    );
  }

  Widget _buildReminderToggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      borderColor: isDark ? AppColors.darkDivider : AppColors.divider,
      borderWidth: 1,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Reminder',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '30 minutes before appointment',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _setReminder,
            onChanged: (value) => setState(() => _setReminder = value),
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, DoctorDatabase db) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: _isSaving ? null : AppColors.primaryGradient,
          color: _isSaving ? (isDark ? AppColors.darkTextSecondary : AppColors.textHint) : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isSaving ? null : [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : () => _saveAppointment(context, db),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Schedule Appointment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Database Not Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Cannot create appointments at this time',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveAppointment(BuildContext context, DoctorDatabase db) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a patient'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final reminderAt = _setReminder
          ? appointmentDateTime.subtract(const Duration(minutes: 30))
          : null;

      // Get patient details for calendar event
      final patient = await db.getPatientById(_selectedPatientId!);
      final patientName = patient != null 
          ? '${patient.firstName} ${patient.lastName}'
          : 'Patient';

      await db.insertAppointment(AppointmentsCompanion.insert(
        patientId: _selectedPatientId!,
        appointmentDateTime: appointmentDateTime,
        durationMinutes: Value(_duration),
        reason: Value(_reason),
        status: const Value('scheduled'),
        reminderAt: Value(reminderAt),
        notes: Value(_notesController.text),
      ),);

      // Sync with Google Calendar if connected
      final calendarState = ref.read(googleCalendarProvider);
      if (calendarState.isConnected) {
        try {
          await ref.read(googleCalendarProvider.notifier).createAppointmentEvent(
            patientName: patientName,
            startTime: appointmentDateTime,
            durationMinutes: _duration,
            reason: _reason,
            notes: _notesController.text,
            patientPhone: patient?.phone,
            patientEmail: patient?.email,
          );
        } catch (e) {
          // Don't fail the entire operation if calendar sync fails
          debugPrint('Calendar sync failed: $e');
        }
      }

      if (context.mounted) {
        final syncMessage = calendarState.isConnected 
            ? 'Appointment scheduled & synced to calendar!'
            : 'Appointment scheduled successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(syncMessage)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
