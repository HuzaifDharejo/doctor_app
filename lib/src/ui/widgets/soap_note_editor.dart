import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/extensions/context_extensions.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../providers/encounter_provider.dart';
import '../../theme/app_theme.dart';

/// SOAP Note Editor Widget
/// Provides a structured form for entering clinical notes in SOAP format
class SOAPNoteEditor extends ConsumerStatefulWidget {
  const SOAPNoteEditor({
    super.key,
    required this.encounterId,
    required this.patientId,
    this.existingNote,
    this.onSaved,
    this.noteType = 'progress',
  });

  final int encounterId;
  final int patientId;
  final ClinicalNote? existingNote;
  final void Function(int noteId)? onSaved;
  final String noteType;

  @override
  ConsumerState<SOAPNoteEditor> createState() => _SOAPNoteEditorState();
}

class _SOAPNoteEditorState extends ConsumerState<SOAPNoteEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectiveController;
  late TextEditingController _objectiveController;
  late TextEditingController _assessmentController;
  late TextEditingController _planController;

  String _noteType = 'progress';
  String _riskLevel = 'none';
  bool _isLoading = false;
  bool _isDirty = false;

  // Expanded sections
  final Set<String> _expandedSections = {'subjective', 'objective', 'assessment', 'plan'};

  static const List<Map<String, dynamic>> _noteTypes = [
    {'value': 'progress', 'label': 'Progress Note', 'icon': Icons.trending_up},
    {'value': 'initial_assessment', 'label': 'Initial Assessment', 'icon': Icons.assignment},
    {'value': 'psychiatric_eval', 'label': 'Psychiatric Evaluation', 'icon': Icons.psychology},
    {'value': 'therapy_note', 'label': 'Therapy Note', 'icon': Icons.healing},
    {'value': 'medication_review', 'label': 'Medication Review', 'icon': Icons.medication},
    {'value': 'discharge_summary', 'label': 'Discharge Summary', 'icon': Icons.exit_to_app},
  ];

  static const List<Map<String, dynamic>> _riskLevels = [
    {'value': 'none', 'label': 'None', 'color': AppColors.success},
    {'value': 'low', 'label': 'Low', 'color': AppColors.info},
    {'value': 'moderate', 'label': 'Moderate', 'color': AppColors.warning},
    {'value': 'high', 'label': 'High', 'color': AppColors.error},
  ];

  // Quick phrases for common entries
  static const Map<String, List<String>> _quickPhrases = {
    'subjective': [
      'Patient reports feeling better',
      'Patient reports worsening symptoms',
      'Patient denies SI/HI',
      'Patient reports improved sleep',
      'Patient reports medication side effects',
      'Patient compliant with treatment',
    ],
    'objective': [
      'Alert and oriented x3',
      'Appropriate affect',
      'Good eye contact',
      'Speech normal rate and rhythm',
      'No psychomotor agitation',
      'Thought process linear and goal-directed',
    ],
    'assessment': [
      'Condition stable',
      'Condition improving',
      'Condition worsening',
      'Symptoms partially controlled',
      'Good response to treatment',
      'Medication adjustment needed',
    ],
    'plan': [
      'Continue current medications',
      'Follow up in 2 weeks',
      'Follow up in 4 weeks',
      'Labs ordered',
      'Referral placed',
      'Patient education provided',
    ],
  };

  @override
  void initState() {
    super.initState();
    _subjectiveController = TextEditingController(text: widget.existingNote?.subjective ?? '');
    _objectiveController = TextEditingController(text: widget.existingNote?.objective ?? '');
    _assessmentController = TextEditingController(text: widget.existingNote?.assessment ?? '');
    _planController = TextEditingController(text: widget.existingNote?.plan ?? '');
    _noteType = widget.existingNote?.noteType ?? widget.noteType;
    _riskLevel = widget.existingNote?.riskLevel ?? 'none';

    // Listen for changes
    _subjectiveController.addListener(_onChanged);
    _objectiveController.addListener(_onChanged);
    _assessmentController.addListener(_onChanged);
    _planController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.existingNote?.isLocked ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existingNote == null ? 'New Clinical Note' : 'Edit Note'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!isLocked && _isDirty)
            TextButton(
              onPressed: _isLoading ? null : _saveNote,
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          if (!isLocked)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'sign') _signNote();
                if (value == 'clear') _clearForm();
                if (value == 'copy_previous') _copyFromPreviousVisit();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'copy_previous',
                  child: ListTile(
                    leading: Icon(Icons.content_copy),
                    title: Text('Copy from Previous'),
                    subtitle: Text('Use last visit as template'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'sign',
                  child: ListTile(
                    leading: Icon(Icons.verified),
                    title: Text('Sign & Lock'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Clear Form'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: isLocked
          ? _buildLockedView()
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(context.responsivePadding),
                children: [
                  _buildNoteTypeSelector(),
                  const SizedBox(height: 16),
                  _buildSOAPSection('subjective', 'S', 'Subjective', _subjectiveController,
                      'Patient complaints, history, symptoms...', Icons.person),
                  const SizedBox(height: 12),
                  _buildSOAPSection('objective', 'O', 'Objective', _objectiveController,
                      'Physical exam, vital signs, observations...', Icons.visibility),
                  const SizedBox(height: 12),
                  _buildSOAPSection('assessment', 'A', 'Assessment', _assessmentController,
                      'Clinical impression, diagnosis...', Icons.analytics),
                  const SizedBox(height: 12),
                  _buildSOAPSection('plan', 'P', 'Plan', _planController,
                      'Treatment plan, medications, follow-up...', Icons.checklist),
                  const SizedBox(height: 16),
                  _buildRiskAssessment(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      floatingActionButton: !isLocked
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _saveNote,
              backgroundColor: AppColors.primary,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Note'),
            )
          : null,
    );
  }

  Widget _buildLockedView() {
    final note = widget.existingNote!;
    return ListView(
      padding: EdgeInsets.all(context.responsivePadding),
      children: [
        Container(
          padding: EdgeInsets.all(context.responsivePadding),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Note Signed & Locked',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      'Signed by ${note.signedBy}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildReadOnlySection('Subjective', note.subjective),
        _buildReadOnlySection('Objective', note.objective),
        _buildReadOnlySection('Assessment', note.assessment),
        _buildReadOnlySection('Plan', note.plan),
      ],
    );
  }

  Widget _buildReadOnlySection(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteTypeSelector() {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Note Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _noteTypes.map((type) {
              final isSelected = _noteType == type['value'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(type['label'] as String),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _noteType = type['value'] as String);
                  }
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSOAPSection(
    String key,
    String letter,
    String title,
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    final isExpanded = _expandedSections.contains(key);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSections.remove(key);
                } else {
                  _expandedSections.add(key);
                }
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: EdgeInsets.all(context.responsivePadding),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (controller.text.isNotEmpty && !isExpanded)
                          Text(
                            controller.text.length > 50
                                ? '${controller.text.substring(0, 50)}...'
                                : controller.text,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.success,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(context.responsivePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick phrases
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_quickPhrases[key] ?? []).map((phrase) {
                      return ActionChip(
                        label: Text(phrase, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          final currentText = controller.text;
                          if (currentText.isNotEmpty && !currentText.endsWith('\n')) {
                            controller.text = '$currentText\n$phrase';
                          } else {
                            controller.text = currentText + phrase;
                          }
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                        },
                        backgroundColor: AppColors.background,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: hint,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(context.responsivePadding),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskAssessment() {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 8),
              const Text(
                'Risk Assessment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: _riskLevels.map((level) {
              final isSelected = _riskLevel == level['value'];
              final color = level['color'] as Color;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _riskLevel = level['value'] as String),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: level != _riskLevels.last ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? color : color.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        level['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : color,
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

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(encounterServiceProvider);
      
      if (widget.existingNote != null) {
        // Update existing note
        await service.updateClinicalNote(ClinicalNote(
          id: widget.existingNote!.id,
          encounterId: widget.encounterId,
          patientId: widget.patientId,
          noteType: _noteType,
          subjective: _subjectiveController.text,
          objective: _objectiveController.text,
          assessment: _assessmentController.text,
          plan: _planController.text,
          mentalStatusExam: widget.existingNote!.mentalStatusExam,
          riskLevel: _riskLevel,
          riskFactors: widget.existingNote!.riskFactors,
          safetyPlan: widget.existingNote!.safetyPlan,
          signedBy: widget.existingNote!.signedBy,
          signedAt: widget.existingNote!.signedAt,
          isLocked: widget.existingNote!.isLocked,
          createdAt: widget.existingNote!.createdAt,
        ));
        widget.onSaved?.call(widget.existingNote!.id);
      } else {
        // Create new note
        final noteId = await service.addClinicalNote(
          encounterId: widget.encounterId,
          patientId: widget.patientId,
          noteType: _noteType,
          subjective: _subjectiveController.text,
          objective: _objectiveController.text,
          assessment: _assessmentController.text,
          plan: _planController.text,
          riskLevel: _riskLevel,
        );
        widget.onSaved?.call(noteId);
      }

      ref.invalidate(encounterNotesProvider(widget.encounterId));
      ref.invalidate(encounterSummaryProvider(widget.encounterId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _isDirty = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signNote() async {
    // First save the note
    await _saveNote();

    if (!mounted) return;

    final doctorName = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Sign Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Once signed, this note will be locked and cannot be edited.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'Enter your full name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.of(context).pop(controller.text);
                }
              },
              child: const Text('Sign'),
            ),
          ],
        );
      },
    );

    if (doctorName != null && doctorName.isNotEmpty && mounted) {
      try {
        final service = ref.read(encounterServiceProvider);
        await service.signClinicalNote(widget.existingNote!.id, doctorName);
        
        ref.invalidate(encounterNotesProvider(widget.encounterId));
        ref.invalidate(encounterSummaryProvider(widget.encounterId));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note signed and locked'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing note: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  /// Copy from previous visit - shows dialog to select from recent notes
  Future<void> _copyFromPreviousVisit() async {
    final db = await ref.read(doctorDbProvider.future);
    final notes = await db.getClinicalNotesForPatient(widget.patientId);
    
    // Filter out current note if editing
    final previousNotes = notes.where((n) => 
        n.id != widget.existingNote?.id && 
        n.encounterId != widget.encounterId
    ).take(10).toList();
    
    if (previousNotes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No previous clinical notes found for this patient'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }
    
    if (!mounted) return;
    
    // Show dialog to select which note to copy from
    final selectedNote = await showDialog<ClinicalNote>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.content_copy, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Copy from Previous Visit')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.separated(
            itemCount: previousNotes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final note = previousNotes[index];
              final dateStr = DateFormat('MMM d, yyyy h:mm a').format(note.createdAt);
              
              // Preview of content
              final preview = (note.subjective ?? '').isNotEmpty 
                  ? (note.subjective ?? '').substring(0, (note.subjective ?? '').length.clamp(0, 80))
                  : 'No subjective data';
              
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: _getNoteTypeColor(note.noteType).withValues(alpha: 0.2),
                  child: Icon(
                    _getNoteTypeIcon(note.noteType),
                    size: 16,
                    color: _getNoteTypeColor(note.noteType),
                  ),
                ),
                title: Text(
                  _getNoteTypeLabel(note.noteType),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.of(context).pop(note),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (selectedNote != null && mounted) {
      // Ask user what to copy
      final copyOption = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('What to Copy?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.select_all, color: AppColors.quickActionGreen),
                title: const Text('Copy All (SOAP)'),
                subtitle: const Text('Replace all fields'),
                onTap: () => Navigator.of(context).pop('all'),
              ),
              ListTile(
                leading: const Icon(Icons.merge_type, color: AppColors.primary),
                title: const Text('Merge with Existing'),
                subtitle: const Text('Add to current content'),
                onTap: () => Navigator.of(context).pop('merge'),
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined, color: AppColors.warning),
                title: const Text('Objective Only'),
                subtitle: const Text('Copy exam findings only'),
                onTap: () => Navigator.of(context).pop('objective'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (copyOption != null && mounted) {
        setState(() {
          switch (copyOption) {
            case 'all':
              _subjectiveController.text = selectedNote.subjective ?? '';
              _objectiveController.text = selectedNote.objective ?? '';
              _assessmentController.text = selectedNote.assessment ?? '';
              _planController.text = selectedNote.plan ?? '';
              _noteType = selectedNote.noteType;
              break;
            case 'merge':
              if ((selectedNote.subjective ?? '').isNotEmpty) {
                _subjectiveController.text = _subjectiveController.text.isEmpty 
                    ? selectedNote.subjective ?? ''
                    : '${_subjectiveController.text}\n\n[Previous visit:]\n${selectedNote.subjective}';
              }
              if ((selectedNote.objective ?? '').isNotEmpty) {
                _objectiveController.text = _objectiveController.text.isEmpty 
                    ? selectedNote.objective ?? ''
                    : '${_objectiveController.text}\n\n[Previous visit:]\n${selectedNote.objective}';
              }
              if ((selectedNote.assessment ?? '').isNotEmpty) {
                _assessmentController.text = _assessmentController.text.isEmpty 
                    ? selectedNote.assessment ?? ''
                    : '${_assessmentController.text}\n\n[Previous:] ${selectedNote.assessment}';
              }
              if ((selectedNote.plan ?? '').isNotEmpty) {
                _planController.text = _planController.text.isEmpty 
                    ? selectedNote.plan ?? ''
                    : '${_planController.text}\n\n[Previous plan:]\n${selectedNote.plan}';
              }
              break;
            case 'objective':
              _objectiveController.text = selectedNote.objective ?? '';
              break;
          }
          _isDirty = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied ${copyOption == 'all' ? 'all sections' : copyOption == 'objective' ? 'objective findings' : 'and merged'} from previous visit'),
            backgroundColor: AppColors.quickActionGreen,
          ),
        );
      }
    }
  }

  Color _getNoteTypeColor(String noteType) {
    switch (noteType) {
      case 'progress': return AppColors.quickActionGreen;
      case 'initial_assessment': return AppColors.primary;
      case 'psychiatric_eval': return AppColors.warning;
      case 'therapy_note': return AppColors.purple;
      case 'medication_review': return AppColors.quickActionPink;
      case 'discharge_summary': return AppColors.skyBlue;
      default: return AppColors.textSecondary;
    }
  }

  IconData _getNoteTypeIcon(String noteType) {
    switch (noteType) {
      case 'progress': return Icons.trending_up;
      case 'initial_assessment': return Icons.assignment;
      case 'psychiatric_eval': return Icons.psychology;
      case 'therapy_note': return Icons.healing;
      case 'medication_review': return Icons.medication;
      case 'discharge_summary': return Icons.exit_to_app;
      default: return Icons.note;
    }
  }

  String _getNoteTypeLabel(String noteType) {
    switch (noteType) {
      case 'progress': return 'Progress Note';
      case 'initial_assessment': return 'Initial Assessment';
      case 'psychiatric_eval': return 'Psychiatric Evaluation';
      case 'therapy_note': return 'Therapy Note';
      case 'medication_review': return 'Medication Review';
      case 'discharge_summary': return 'Discharge Summary';
      default: return 'Clinical Note';
    }
  }

  void _clearForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Form?'),
        content: const Text('This will clear all entered text.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _subjectiveController.clear();
              _objectiveController.clear();
              _assessmentController.clear();
              _planController.clear();
              setState(() {
                _riskLevel = 'none';
                _isDirty = false;
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// Show SOAP Note Editor as a full-screen modal
Future<void> showSOAPNoteEditor({
  required BuildContext context,
  required int encounterId,
  required int patientId,
  ClinicalNote? existingNote,
  String noteType = 'progress',
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => SOAPNoteEditor(
        encounterId: encounterId,
        patientId: patientId,
        existingNote: existingNote,
        noteType: noteType,
      ),
    ),
  );
}
