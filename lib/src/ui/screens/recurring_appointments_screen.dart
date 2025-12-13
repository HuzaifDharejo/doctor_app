import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/recurring_appointment_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Screen for managing recurring appointment patterns
class RecurringAppointmentsScreen extends ConsumerStatefulWidget {
  const RecurringAppointmentsScreen({super.key});

  @override
  ConsumerState<RecurringAppointmentsScreen> createState() => _RecurringAppointmentsScreenState();
}

class _RecurringAppointmentsScreenState extends ConsumerState<RecurringAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _recurringService = RecurringAppointmentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: surfaceColor,
            foregroundColor: textColor,
            elevation: 0,
            scrolledUnderElevation: 1,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.calendar_month,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    onPressed: _generateUpcomingAppointments,
                    tooltip: 'Generate appointments',
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFF8FAFC), surfaceColor],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF34D399)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.repeat,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recurring Appointments',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage regular appointment patterns',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Paused/Ended'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPatternsTab(true),
            _buildPatternsTab(false),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePatternDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Pattern'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Widget _buildPatternsTab(bool activeOnly) {
    return FutureBuilder<List<RecurringAppointmentData>>(
      future: activeOnly
          ? _recurringService.getActivePatterns()
          : _recurringService.getPausedOrEndedPatterns(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(activeOnly);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildPatternCard(snapshot.data![index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildPatternCard(RecurringAppointmentData pattern) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final frequencyColor = _getFrequencyColor(pattern.frequency);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showPatternDetails(pattern),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: frequencyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFrequencyIcon(pattern.frequency),
                      color: frequencyColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient #${pattern.patientId}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _formatFrequency(pattern.frequency),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(pattern.isActive == true),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.event,
                    'Starts: ${_formatDate(pattern.startDate)}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  if (pattern.endDate != null)
                    _buildInfoChip(
                      Icons.event_busy,
                      'Ends: ${_formatDate(pattern.endDate!)}',
                      Colors.orange,
                    ),
                ],
              ),
              if (pattern.appointmentType.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.medical_services,
                      size: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pattern.appointmentType,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    if (pattern.daysOfWeek.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.today,
                        size: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pattern.daysOfWeek,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (pattern.preferredTime.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pattern.preferredTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (pattern.isActive == true) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pausePattern(pattern.id),
                        icon: const Icon(Icons.pause, size: 16),
                        label: const Text('Pause'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _resumePattern(pattern.id),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Resume'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showGenerateDialog(pattern),
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('Generate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'PAUSED',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFrequencyColor(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return Colors.red;
      case 'weekly':
        return Colors.orange;
      case 'biweekly':
        return Colors.amber;
      case 'monthly':
        return Colors.green;
      case 'quarterly':
        return Colors.blue;
      case 'annually':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getFrequencyIcon(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.view_week;
      case 'biweekly':
        return Icons.date_range;
      case 'monthly':
        return Icons.calendar_view_month;
      case 'quarterly':
        return Icons.calendar_today;
      case 'annually':
        return Icons.event;
      default:
        return Icons.repeat;
    }
  }

  Widget _buildEmptyState(bool activeOnly) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            activeOnly ? Icons.repeat : Icons.pause_circle,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            activeOnly ? 'No active patterns' : 'No paused patterns',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          if (activeOnly) ...[
            const SizedBox(height: 8),
            Text(
              'Create a recurring appointment pattern',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPatternDetails(RecurringAppointmentData pattern) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getFrequencyColor(pattern.frequency).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFrequencyIcon(pattern.frequency),
                      color: _getFrequencyColor(pattern.frequency),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recurring Pattern',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Patient #${pattern.patientId}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(pattern.isActive == true),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Frequency', _formatFrequency(pattern.frequency)),
              if (pattern.intervalDays != null && pattern.intervalDays! > 1)
                _buildDetailRow('Interval', 'Every ${pattern.intervalDays} days'),
              _buildDetailRow('Start Date', _formatDate(pattern.startDate)),
              if (pattern.endDate != null)
                _buildDetailRow('End Date', _formatDate(pattern.endDate!)),
              if (pattern.appointmentType.isNotEmpty)
                _buildDetailRow('Appointment Type', pattern.appointmentType),
              if (pattern.daysOfWeek.isNotEmpty)
                _buildDetailRow('Preferred Days', pattern.daysOfWeek),
              if (pattern.preferredTime.isNotEmpty)
                _buildDetailRow('Preferred Time', pattern.preferredTime),
              _buildDetailRow('Duration', '${pattern.durationMinutes} minutes'),
              if (pattern.notes.isNotEmpty)
                _buildDetailRow('Notes', pattern.notes),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deletePattern(pattern.id),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditPatternDialog(pattern);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatFrequency(String frequency) {
    if (frequency.isEmpty) return 'Unknown';
    return frequency[0].toUpperCase() + frequency.substring(1).toLowerCase();
  }

  Future<void> _pausePattern(int id) async {
    await _recurringService.pausePattern(id);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pattern paused')),
      );
    }
  }

  Future<void> _resumePattern(int id) async {
    await _recurringService.resumePattern(id);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pattern resumed')),
      );
    }
  }

  Future<void> _deletePattern(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pattern'),
        content: const Text('Are you sure you want to delete this recurring pattern?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _recurringService.deletePattern(id);
      if (mounted) {
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pattern deleted')),
        );
      }
    }
  }

  void _showGenerateDialog(RecurringAppointmentData pattern) {
    int monthsAhead = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Generate Appointments'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Generate appointments for the next:'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: monthsAhead > 1
                            ? () => setDialogState(() => monthsAhead--)
                            : null,
                        icon: const Icon(Icons.remove_circle),
                      ),
                      Text(
                        '$monthsAhead month${monthsAhead > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: monthsAhead < 12
                            ? () => setDialogState(() => monthsAhead++)
                            : null,
                        icon: const Icon(Icons.add_circle),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _generateForPattern(pattern, monthsAhead);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                  child: const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _generateForPattern(RecurringAppointmentData pattern, int months) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating appointments...'),
          ],
        ),
      ),
    );

    final endDate = DateTime.now().add(Duration(days: months * 30));
    final dates = await _recurringService.generateAppointmentDates(
      pattern.id,
      endDate: endDate,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated ${dates.length} appointment slots')),
      );
    }
  }

  Future<void> _generateUpcomingAppointments() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing all patterns...'),
          ],
        ),
      ),
    );

    // Simulate processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All patterns processed')),
      );
    }
  }

  void _showCreatePatternDialog(BuildContext context) {
    _showPatternFormDialog(context, null);
  }

  void _showEditPatternDialog(RecurringAppointmentData pattern) {
    _showPatternFormDialog(context, pattern);
  }

  void _showPatternFormDialog(BuildContext context, RecurringAppointmentData? existing) {
    String selectedFrequency = existing?.frequency ?? 'weekly';
    DateTime startDate = existing?.startDate ?? DateTime.now();
    DateTime? endDate = existing?.endDate;
    final typeController = TextEditingController(text: existing?.appointmentType);
    final notesController = TextEditingController(text: existing?.notes);
    String? selectedDay = existing?.daysOfWeek;
    String? selectedTime = existing?.preferredTime;
    int duration = existing?.durationMinutes ?? 30;
    int? selectedPatientId = existing?.patientId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final frequencies = ['daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'annually'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final timeSlots = ['08:00', '09:00', '10:00', '11:00', '14:00', '15:00', '16:00'];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[600] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        existing == null ? 'Create Recurring Pattern' : 'Edit Pattern',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Patient selector
                      if (existing == null) ...[
                        FutureBuilder<List<Patient>>(
                          future: ref.read(doctorDbProvider).value?.getAllPatients() ?? Future.value([]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final patientList = snapshot.data ?? [];
                            return DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Select Patient *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              value: selectedPatientId,
                              items: patientList.map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.firstName} ${p.lastName}'),
                              )).toList(),
                              onChanged: (value) {
                                setModalState(() => selectedPatientId = value);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('Frequency'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: frequencies.map((freq) {
                          return ChoiceChip(
                            label: Text(freq[0].toUpperCase() + freq.substring(1)),
                            selected: selectedFrequency == freq,
                            selectedColor: _getFrequencyColor(freq).withValues(alpha: 0.2),
                            onSelected: (selected) {
                              setModalState(() => selectedFrequency = freq);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setModalState(() => startDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(_formatDate(startDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? startDate.add(const Duration(days: 365)),
                                  firstDate: startDate,
                                  lastDate: startDate.add(const Duration(days: 730)),
                                );
                                setModalState(() => endDate = date);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'End Date (Optional)',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: endDate != null
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () => setModalState(() => endDate = null),
                                        )
                                      : const Icon(Icons.calendar_today),
                                ),
                                child: Text(endDate != null ? _formatDate(endDate!) : 'No end date'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: typeController,
                        decoration: const InputDecoration(
                          labelText: 'Appointment Type',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Follow-up, Physical Therapy',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Preferred Day'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: weekdays.map((day) {
                          return ChoiceChip(
                            label: Text(day.substring(0, 3)),
                            selected: selectedDay == day,
                            onSelected: (selected) {
                              setModalState(() => selectedDay = selected ? day : null);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Preferred Time'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: timeSlots.map((time) {
                          return ChoiceChip(
                            label: Text(time),
                            selected: selectedTime == time,
                            onSelected: (selected) {
                              setModalState(() => selectedTime = selected ? time : null);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Duration: '),
                          Expanded(
                            child: Slider(
                              value: duration.toDouble(),
                              min: 15,
                              max: 120,
                              divisions: 7,
                              label: '$duration min',
                              onChanged: (value) {
                                setModalState(() => duration = value.round());
                              },
                            ),
                          ),
                          Text('$duration min'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (existing == null && selectedPatientId == null) ? null : () async {
                            if (existing == null) {
                              await _recurringService.createPattern(
                                patientId: selectedPatientId!,
                                frequency: selectedFrequency,
                                startDate: startDate,
                                endDate: endDate,
                                appointmentType: typeController.text.isNotEmpty ? typeController.text : null,
                                preferredDay: selectedDay,
                                preferredTime: selectedTime,
                                duration: duration,
                                notes: notesController.text.isNotEmpty ? notesController.text : null,
                              );
                            } else {
                              await _recurringService.updatePattern(
                                id: existing.id,
                                frequency: selectedFrequency,
                                startDate: startDate,
                                endDate: endDate,
                                appointmentType: typeController.text.isNotEmpty ? typeController.text : null,
                                preferredDay: selectedDay,
                                preferredTime: selectedTime,
                                duration: duration,
                                notes: notesController.text.isNotEmpty ? notesController.text : null,
                              );
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    existing == null ? 'Pattern created' : 'Pattern updated',
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(existing == null ? 'Create Pattern' : 'Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
