import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/components/app_button.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';

/// Screen to view and track treatment outcomes for a patient
class TreatmentOutcomesScreen extends ConsumerStatefulWidget {
  final int patientId;
  final String patientName;

  const TreatmentOutcomesScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<TreatmentOutcomesScreen> createState() => _TreatmentOutcomesScreenState();
}

class _TreatmentOutcomesScreenState extends ConsumerState<TreatmentOutcomesScreen> {
  List<TreatmentOutcome> _outcomes = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // 'all', 'ongoing', 'completed'

  @override
  void initState() {
    super.initState();
    _loadOutcomes();
  }

  Future<void> _loadOutcomes() async {
    final dbAsync = ref.read(doctorDbProvider);
    dbAsync.when(
      data: (db) async {
        final outcomes = await db.getTreatmentOutcomesForPatient(widget.patientId);
        if (mounted) {
          setState(() {
            _outcomes = outcomes;
            _isLoading = false;
          });
        }
      },
      loading: () {},
      error: (_, __) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  List<TreatmentOutcome> get _filteredOutcomes {
    if (_filterStatus == 'all') return _outcomes;
    if (_filterStatus == 'ongoing') {
      return _outcomes.where((o) => o.outcome == 'ongoing').toList();
    }
    return _outcomes.where((o) => o.outcome != 'ongoing').toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Treatment Outcomes - ${widget.patientName}'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Treatments')),
              const PopupMenuItem(value: 'ongoing', child: Text('Ongoing')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredOutcomes.isEmpty
              ? _buildEmptyState(colorScheme)
              : _buildOutcomesList(colorScheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOutcomeDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Treatment'),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'all' 
              ? 'No treatments recorded yet'
              : 'No ${_filterStatus} treatments',
            style: TextStyle(fontSize: 18, color: colorScheme.outline),
          ),
          const SizedBox(height: 8),
          const Text('Tap the button below to add a treatment'),
        ],
      ),
    );
  }

  Widget _buildOutcomesList(ColorScheme colorScheme) {
    // Group by status
    final ongoing = _filteredOutcomes.where((o) => o.outcome == 'ongoing').toList();
    final completed = _filteredOutcomes.where((o) => o.outcome != 'ongoing').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (ongoing.isNotEmpty && _filterStatus != 'completed') ...[
          _buildSectionHeader('Ongoing Treatments', Icons.hourglass_top, Colors.orange, ongoing.length),
          const SizedBox(height: 8),
          ...ongoing.map((o) => _buildOutcomeCard(o, colorScheme)),
          const SizedBox(height: 24),
        ],
        if (completed.isNotEmpty && _filterStatus != 'ongoing') ...[
          _buildSectionHeader('Completed Treatments', Icons.check_circle_outline, Colors.green, completed.length),
          const SizedBox(height: 8),
          ...completed.map((o) => _buildOutcomeCard(o, colorScheme)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildOutcomeCard(TreatmentOutcome outcome, ColorScheme colorScheme) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final outcomeInfo = _getOutcomeInfo(outcome.outcome);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOutcomeDetails(outcome),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(outcome.treatmentType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      outcome.treatmentType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(outcome.treatmentType),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: outcomeInfo.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(outcomeInfo.icon, size: 14, color: outcomeInfo.color),
                        const SizedBox(width: 4),
                        Text(
                          outcomeInfo.label,
                          style: TextStyle(fontSize: 12, color: outcomeInfo.color, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                outcome.treatmentDescription,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    'Started: ${dateFormat.format(outcome.startDate)}',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                  if (outcome.endDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.event_available, size: 14, color: colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      'Ended: ${dateFormat.format(outcome.endDate!)}',
                      style: TextStyle(fontSize: 12, color: colorScheme.outline),
                    ),
                  ],
                ],
              ),
              if (outcome.effectivenessScore != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Effectiveness: ', style: TextStyle(fontSize: 12, color: colorScheme.outline)),
                    _buildEffectivenessBar(outcome.effectivenessScore!, colorScheme),
                    const SizedBox(width: 8),
                    Text('${outcome.effectivenessScore}/10', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              if (outcome.sideEffects.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Side effects: ${outcome.sideEffects}',
                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEffectivenessBar(int score, ColorScheme colorScheme) {
    return SizedBox(
      width: 100,
      child: LinearProgressIndicator(
        value: score / 10,
        backgroundColor: colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          score >= 7 ? Colors.green : (score >= 4 ? Colors.orange : Colors.red),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'medication':
        return Colors.blue;
      case 'therapy':
        return Colors.purple;
      case 'procedure':
        return Colors.teal;
      case 'lifestyle':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  ({String label, IconData icon, Color color}) _getOutcomeInfo(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'improved':
        return (label: 'Improved', icon: Icons.trending_up, color: Colors.green);
      case 'stable':
        return (label: 'Stable', icon: Icons.horizontal_rule, color: Colors.blue);
      case 'worsened':
        return (label: 'Worsened', icon: Icons.trending_down, color: Colors.red);
      case 'resolved':
        return (label: 'Resolved', icon: Icons.check_circle, color: Colors.green);
      case 'ongoing':
        return (label: 'Ongoing', icon: Icons.hourglass_top, color: Colors.orange);
      default:
        return (label: outcome, icon: Icons.help_outline, color: Colors.grey);
    }
  }

  void _showOutcomeDetails(TreatmentOutcome outcome) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final outcomeInfo = _getOutcomeInfo(outcome.outcome);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_services, size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outcome.treatmentDescription,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTypeColor(outcome.treatmentType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            outcome.treatmentType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getTypeColor(outcome.treatmentType),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow('Status', outcomeInfo.label, icon: outcomeInfo.icon, color: outcomeInfo.color),
              _buildDetailRow('Start Date', dateFormat.format(outcome.startDate)),
              if (outcome.endDate != null)
                _buildDetailRow('End Date', dateFormat.format(outcome.endDate!)),
              if (outcome.effectivenessScore != null)
                _buildDetailRow('Effectiveness', '${outcome.effectivenessScore}/10'),
              if (outcome.sideEffects.isNotEmpty)
                _buildDetailRow('Side Effects', outcome.sideEffects, color: Colors.orange),
              if (outcome.patientFeedback.isNotEmpty)
                _buildDetailRow('Patient Feedback', outcome.patientFeedback),
              if (outcome.notes.isNotEmpty)
                _buildDetailRow('Notes', outcome.notes),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showUpdateOutcomeDialog(outcome);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Update'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteOutcome(outcome.id);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
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

  Widget _buildDetailRow(String label, String value, {IconData? icon, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ),
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOutcome(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Treatment'),
        content: const Text('Are you sure you want to delete this treatment record?'),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton.danger(
            label: 'Delete',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(doctorDbProvider).whenData((db) async {
        await db.deleteTreatmentOutcome(id);
        await _loadOutcomes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Treatment deleted')),
          );
        }
      });
    }
  }

  void _showAddOutcomeDialog() {
    _showOutcomeFormDialog();
  }

  void _showUpdateOutcomeDialog(TreatmentOutcome outcome) {
    _showOutcomeFormDialog(existing: outcome);
  }

  void _showOutcomeFormDialog({TreatmentOutcome? existing}) {
    final isEditing = existing != null;
    final descController = TextEditingController(text: existing?.treatmentDescription ?? '');
    final sideEffectsController = TextEditingController(text: existing?.sideEffects ?? '');
    final feedbackController = TextEditingController(text: existing?.patientFeedback ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final diagnosisController = TextEditingController(text: existing?.diagnosis ?? '');
    final providerNameController = TextEditingController(text: existing?.providerName ?? '');
    
    String selectedType = existing?.treatmentType ?? 'medication';
    String selectedOutcome = existing?.outcome ?? 'ongoing';
    String selectedProviderType = existing?.providerType ?? 'psychiatrist';
    String selectedPhase = existing?.treatmentPhase ?? 'initial';
    int? effectivenessScore = existing?.effectivenessScore;
    DateTime startDate = existing?.startDate ?? DateTime.now();
    DateTime? endDate = existing?.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Update Treatment' : 'Add Treatment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Treatment Type'),
                  items: const [
                    DropdownMenuItem(value: 'medication', child: Text('Medication')),
                    DropdownMenuItem(value: 'therapy', child: Text('Therapy')),
                    DropdownMenuItem(value: 'procedure', child: Text('Procedure')),
                    DropdownMenuItem(value: 'lifestyle', child: Text('Lifestyle')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedProviderType,
                  decoration: const InputDecoration(labelText: 'Provider Type'),
                  items: const [
                    DropdownMenuItem(value: 'psychiatrist', child: Text('Psychiatrist')),
                    DropdownMenuItem(value: 'therapist', child: Text('Therapist')),
                    DropdownMenuItem(value: 'counselor', child: Text('Counselor')),
                    DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
                    DropdownMenuItem(value: 'primary_care', child: Text('Primary Care')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedProviderType = value!),
                ),
                const SizedBox(height: 16),
                AppInput.text(
                  controller: providerNameController,
                  label: 'Provider Name',
                  hint: 'Dr. Smith',
                ),
                const SizedBox(height: 16),
                AppInput.text(
                  controller: diagnosisController,
                  label: 'Diagnosis',
                  hint: 'e.g., Major Depressive Disorder',
                ),
                const SizedBox(height: 16),
                AppInput.multiline(
                  controller: descController,
                  label: 'Treatment Description',
                  hint: 'e.g., Metformin 500mg twice daily',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPhase,
                  decoration: const InputDecoration(labelText: 'Treatment Phase'),
                  items: const [
                    DropdownMenuItem(value: 'initial', child: Text('Initial')),
                    DropdownMenuItem(value: 'acute', child: Text('Acute')),
                    DropdownMenuItem(value: 'continuation', child: Text('Continuation')),
                    DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                    DropdownMenuItem(value: 'tapering', child: Text('Tapering')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedPhase = value!),
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
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() => startDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Start Date'),
                          child: Text(DateFormat('MMM dd, yyyy').format(startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: startDate,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            suffixIcon: endDate != null 
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setDialogState(() => endDate = null),
                                )
                              : null,
                          ),
                          child: Text(endDate != null 
                            ? DateFormat('MMM dd, yyyy').format(endDate!) 
                            : 'Not set'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedOutcome,
                  decoration: const InputDecoration(labelText: 'Outcome'),
                  items: const [
                    DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                    DropdownMenuItem(value: 'improved', child: Text('Improved')),
                    DropdownMenuItem(value: 'stable', child: Text('Stable')),
                    DropdownMenuItem(value: 'worsened', child: Text('Worsened')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedOutcome = value!),
                ),
                const SizedBox(height: 16),
                const Text('Effectiveness (1-10):'),
                Slider(
                  value: (effectivenessScore ?? 5).toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${effectivenessScore ?? 5}',
                  onChanged: (value) => setDialogState(() => effectivenessScore = value.toInt()),
                ),
                const SizedBox(height: 8),
                AppInput.text(
                  controller: sideEffectsController,
                  label: 'Side Effects',
                  hint: 'Any observed side effects...',
                ),
                const SizedBox(height: 16),
                AppInput.text(
                  controller: feedbackController,
                  label: 'Patient Feedback',
                  hint: 'What does the patient say...',
                ),
                const SizedBox(height: 16),
                AppInput.multiline(
                  controller: notesController,
                  label: 'Notes',
                  hint: 'Additional notes...',
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
                if (descController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a treatment description')),
                  );
                  return;
                }

                ref.read(doctorDbProvider).whenData((db) async {
                  if (isEditing) {
                    await db.updateTreatmentOutcome(TreatmentOutcome(
                      id: existing.id,
                      patientId: widget.patientId,
                      prescriptionId: existing.prescriptionId,
                      medicalRecordId: existing.medicalRecordId,
                      treatmentType: selectedType,
                      treatmentDescription: descController.text,
                      providerType: selectedProviderType,
                      providerName: providerNameController.text,
                      diagnosis: diagnosisController.text,
                      startDate: startDate,
                      endDate: endDate,
                      outcome: selectedOutcome,
                      effectivenessScore: effectivenessScore,
                      sideEffects: sideEffectsController.text,
                      patientFeedback: feedbackController.text,
                      treatmentPhase: selectedPhase,
                      notes: notesController.text,
                      createdAt: existing.createdAt,
                    ));
                  } else {
                    await db.insertTreatmentOutcome(TreatmentOutcomesCompanion.insert(
                      patientId: widget.patientId,
                      treatmentType: selectedType,
                      treatmentDescription: descController.text,
                      providerType: Value(selectedProviderType),
                      providerName: Value(providerNameController.text),
                      diagnosis: Value(diagnosisController.text),
                      startDate: startDate,
                      endDate: Value(endDate),
                      outcome: Value(selectedOutcome),
                      effectivenessScore: Value(effectivenessScore),
                      sideEffects: Value(sideEffectsController.text),
                      patientFeedback: Value(feedbackController.text),
                      treatmentPhase: Value(selectedPhase),
                      notes: Value(notesController.text),
                    ));
                  }

                  Navigator.pop(context);
                  await _loadOutcomes();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Treatment updated' : 'Treatment added')),
                    );
                  }
                });
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
