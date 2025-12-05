import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
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
              },
              itemBuilder: (context) => [
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
                padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(16),
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
                      contentPadding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
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
