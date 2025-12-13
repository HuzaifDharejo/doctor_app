import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/clinical_reminder_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Screen for managing clinical reminders and preventive care alerts
class ClinicalRemindersScreen extends ConsumerStatefulWidget {
  final int? patientId;
  
  const ClinicalRemindersScreen({super.key, this.patientId});

  @override
  ConsumerState<ClinicalRemindersScreen> createState() => _ClinicalRemindersScreenState();
}

class _ClinicalRemindersScreenState extends ConsumerState<ClinicalRemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _reminderService = ClinicalReminderService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
                              colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active,
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
                                'Clinical Reminders',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Preventive care & follow-up alerts',
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
              isScrollable: true,
              tabs: const [
                Tab(text: 'Due Now'),
                Tab(text: 'Upcoming'),
                Tab(text: 'All Active'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRemindersList('due'),
            _buildRemindersList('upcoming'),
            _buildRemindersList('active'),
            _buildRemindersList('completed'),
          ],
        ),
      ),
      floatingActionButton: widget.patientId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateReminderDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New Reminder'),
              backgroundColor: const Color(0xFF14B8A6),
            )
          : null,
    );
  }

  Widget _buildRemindersList(String filter) {
    if (widget.patientId == null) {
      return _buildSelectPatientState();
    }

    return FutureBuilder<List<ClinicalReminderData>>(
      future: _fetchReminders(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(filter);
        }

        final reminders = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              return _buildReminderCard(reminders[index]);
            },
          ),
        );
      },
    );
  }

  Future<List<ClinicalReminderData>> _fetchReminders(String filter) async {
    if (widget.patientId == null) return [];
    
    switch (filter) {
      case 'due':
        return _reminderService.getDueReminders(widget.patientId!);
      case 'upcoming':
        return _reminderService.getUpcomingReminders(widget.patientId!, daysAhead: 30);
      case 'active':
        return _reminderService.getActiveReminders(widget.patientId!);
      case 'completed':
        return _reminderService.getCompletedReminders(widget.patientId!);
      default:
        return _reminderService.getRemindersForPatient(widget.patientId!);
    }
  }

  Widget _buildReminderCard(ClinicalReminderData reminder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _reminderService.toModel(reminder);
    final priorityColor = _getPriorityColor(reminder.priority);
    final isOverdue = reminder.dueDate.isBefore(DateTime.now()) && 
        reminder.status != 'completed' && reminder.status != 'cancelled';
    final daysUntilDue = reminder.dueDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: isOverdue 
            ? BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 2)
            : BorderSide.none,
      ),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        onTap: () => _showReminderDetails(reminder),
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
                      color: (isOverdue ? Colors.red : priorityColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getReminderIcon(reminder.reminderType),
                      color: isOverdue ? Colors.red : priorityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          model.reminderType.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDueBadge(daysUntilDue, isOverdue, reminder.status == 'completed'),
                ],
              ),
              if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  reminder.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.flag,
                    _getPriorityLabel(model.priority),
                    priorityColor,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.calendar_today,
                    _formatDate(reminder.dueDate),
                    isOverdue ? Colors.red : Colors.grey,
                  ),
                  const Spacer(),
                  if (reminder.status != 'completed')
                    TextButton.icon(
                      onPressed: () => _completeReminder(reminder.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Done'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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

  Widget _buildDueBadge(int daysUntilDue, bool isOverdue, bool isCompleted) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            const Text(
              'DONE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }

    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, size: 14, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              '${-daysUntilDue}d OVERDUE',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    final color = daysUntilDue <= 7 ? Colors.orange : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        daysUntilDue == 0 ? 'TODAY' : 'In $daysUntilDue days',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
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

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 3:
        return 'High';
      case 2:
        return 'Medium';
      case 1:
        return 'Low';
      default:
        return 'Normal';
    }
  }

  IconData _getReminderIcon(String reminderType) {
    switch (reminderType.toLowerCase()) {
      case 'vaccination':
        return Icons.vaccines;
      case 'screening':
        return Icons.search;
      case 'follow_up':
        return Icons.event_repeat;
      case 'medication_review':
        return Icons.medication;
      case 'lab_work':
        return Icons.science;
      case 'preventive_care':
        return Icons.health_and_safety;
      case 'chronic_care':
        return Icons.monitor_heart;
      case 'annual_exam':
        return Icons.calendar_month;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState(String filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String message;
    IconData icon;
    Color? iconColor;

    switch (filter) {
      case 'due':
        message = 'No reminders due';
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'upcoming':
        message = 'No upcoming reminders';
        icon = Icons.event_available;
        iconColor = Colors.blue;
        break;
      case 'completed':
        message = 'No completed reminders';
        icon = Icons.task_alt;
        break;
      default:
        message = 'No active reminders';
        icon = Icons.notifications_off;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: iconColor ?? (isDark ? Colors.grey[600] : Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a reminder to track care tasks',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectPatientState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a patient',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeReminder(int id) async {
    await _reminderService.completeReminder(id: id);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder completed')),
      );
    }
  }

  void _showReminderDetails(ClinicalReminderData reminder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = _reminderService.toModel(reminder);

    showModalBottomSheet(
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
                    color: Colors.grey[300],
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
                      color: _getPriorityColor(reminder.priority).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getReminderIcon(reminder.reminderType),
                      color: _getPriorityColor(reminder.priority),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          model.reminderType.label,
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
              const SizedBox(height: 24),
              _buildDetailRow('Due Date', _formatDate(reminder.dueDate)),
              _buildDetailRow('Priority', _getPriorityLabel(model.priority)),
              _buildDetailRow('Status', model.status.label),
              if (reminder.description.isNotEmpty)
                _buildDetailRow('Description', reminder.description),
              if (reminder.frequency.isNotEmpty)
                _buildDetailRow('Frequency', reminder.frequency),
              if (reminder.lastCompletedDate != null)
                _buildDetailRow('Completed', _formatDate(reminder.lastCompletedDate!)),
              const SizedBox(height: 24),
              if (reminder.status != 'completed')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _snoozeReminder(reminder.id),
                        icon: const Icon(Icons.snooze),
                        label: const Text('Snooze'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _completeReminder(reminder.id);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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
            width: 100,
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

  Future<void> _snoozeReminder(int id) async {
    final newDate = DateTime.now().add(const Duration(days: 7));
    await _reminderService.snoozeReminder(id: id, newDueDate: newDate);
    if (mounted) {
      Navigator.pop(context);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder snoozed for 7 days')),
      );
    }
  }

  void _showCreateReminderDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'follow_up';
    String selectedPriority = 'medium';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    final reminderTypes = [
      'vaccination', 'screening', 'follow_up', 'medication_review',
      'lab_work', 'preventive_care', 'chronic_care', 'annual_exam', 'other'
    ];

    showModalBottomSheet(
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
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'New Clinical Reminder',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          hintText: 'e.g., Annual flu vaccination',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Reminder Type',
                          border: OutlineInputBorder(),
                        ),
                        items: reminderTypes.map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.replaceAll('_', ' ').split(' ').map((w) => 
                            w[0].toUpperCase() + w.substring(1)).join(' ')),
                        )).toList(),
                        onChanged: (value) {
                          setModalState(() => selectedType = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                );
                                if (date != null) {
                                  setModalState(() => dueDate = date);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Due Date *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(_formatDate(dueDate)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedPriority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(),
                              ),
                              items: ['low', 'medium', 'high'].map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p[0].toUpperCase() + p.substring(1)),
                              )).toList(),
                              onChanged: (value) {
                                setModalState(() => selectedPriority = value!);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a title')),
                              );
                              return;
                            }

                            if (widget.patientId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a patient first')),
                              );
                              return;
                            }

                            await _reminderService.createReminder(
                              patientId: widget.patientId!,
                              title: titleController.text,
                              reminderType: selectedType,
                              dueDate: dueDate,
                              priority: selectedPriority == 'high' ? 3 : (selectedPriority == 'medium' ? 2 : 1),
                              description: descriptionController.text.isNotEmpty 
                                  ? descriptionController.text 
                                  : null,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reminder created successfully')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Create Reminder'),
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
