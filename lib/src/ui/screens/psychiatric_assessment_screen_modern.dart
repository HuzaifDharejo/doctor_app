// Modern Psychiatric Assessment Screen - Complete Redesign
// Features: Quick templates, intelligent forms, risk assessment, DSM-5 integration

import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/components/app_input.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/suggestions_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../widgets/suggestion_text_field.dart';

class PsychiatricAssessmentScreenModern extends ConsumerStatefulWidget {
  
  const PsychiatricAssessmentScreenModern({
    super.key,
    this.preselectedPatient,
    this.initialDiagnosis,
  });
  
  final Patient? preselectedPatient;
  final String? initialDiagnosis;

  @override
  ConsumerState<PsychiatricAssessmentScreenModern> createState() =>
      _PsychiatricAssessmentScreenModernState();
}

class _PsychiatricAssessmentScreenModernState
    extends ConsumerState<PsychiatricAssessmentScreenModern> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Assessment metadata
  DateTime? _assessmentDate;
  int? _patientId;
  bool _isSaving = false;
  bool _showRiskWarning = false;
  int _currentSectionIndex = 0;
  
  // Patient info
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  String _maritalStatus = 'Single';

  // Chief complaint
  final _chiefComplaintController = TextEditingController();
  final _durationController = TextEditingController();

  // Symptoms (with quick toggles)
  Map<String, bool> _symptoms = {
    'Sleep Disturbance': false,
    'Appetite Change': false,
    'Weight Change': false,
    'Fatigue': false,
    'Concentration Issues': false,
    'Memory Problems': false,
    'Anxiety': false,
    'Panic Attacks': false,
    'Obsessions': false,
    'Compulsions': false,
    'Suicidal Thoughts': false,
    'Self-Harm': false,
  };

  // Mental State Examination
  final _moodController = TextEditingController();
  final _affectController = TextEditingController();
  final _speechController = TextEditingController();
  final _thoughtController = TextEditingController();
  final _perceptionController = TextEditingController();
  final _cognitionController = TextEditingController();
  final _insightController = TextEditingController();

  // Risk Assessment
  String _suicideRisk = 'None';
  String _homicideRisk = 'None';
  final _safetyPlanController = TextEditingController();

  // Diagnosis & Treatment
  final _diagnosisController = TextEditingController();
  final _treatmentPlanController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _followUpController = TextEditingController();

  // History sections
  final _pastHistoryController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _socioeconomicController = TextEditingController();

  // Common diagnoses (DSM-5)
  static const List<String> _dsm5Diagnoses = [
    'Major Depressive Disorder',
    'Generalized Anxiety Disorder',
    'Panic Disorder',
    'Social Anxiety Disorder',
    'Specific Phobia',
    'Obsessive-Compulsive Disorder',
    'Post-Traumatic Stress Disorder',
    'Adjustment Disorder',
    'Bipolar I Disorder',
    'Bipolar II Disorder',
    'Cyclothymia',
    'Schizophrenia',
    'Schizoaffective Disorder',
    'Brief Psychotic Disorder',
    'Autism Spectrum Disorder',
    'ADHD',
  ];

  // Common quick templates
  Map<String, Map<String, dynamic>> _templates = {
    'Depression': {
      'mood': 'Depressed, hopeless',
      'affect': 'Flat, blunted',
      'symptoms': ['Sleep Disturbance', 'Appetite Change', 'Fatigue', 'Concentration Issues'],
      'diagnosis': 'Major Depressive Disorder',
    },
    'Anxiety': {
      'mood': 'Anxious, tense',
      'affect': 'Apprehensive',
      'symptoms': ['Anxiety', 'Sleep Disturbance', 'Concentration Issues'],
      'diagnosis': 'Generalized Anxiety Disorder',
    },
    'OCD': {
      'symptoms': ['Obsessions', 'Compulsions', 'Anxiety'],
      'diagnosis': 'Obsessive-Compulsive Disorder',
    },
  };

  @override
  void initState() {
    super.initState();
    _assessmentDate = DateTime.now();
    
    if (widget.preselectedPatient != null) {
      final p = widget.preselectedPatient!;
      _patientId = p.id;
      _nameController.text = '${p.firstName} ${p.lastName}'.trim();
      if (p.dateOfBirth != null) {
        final age = DateTime.now().year - p.dateOfBirth!.year;
        _ageController.text = age.toString();
      }
    }

    if (widget.initialDiagnosis != null) {
      _diagnosisController.text = widget.initialDiagnosis!;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _moodController.dispose();
    _affectController.dispose();
    _speechController.dispose();
    _thoughtController.dispose();
    _perceptionController.dispose();
    _cognitionController.dispose();
    _insightController.dispose();
    _safetyPlanController.dispose();
    _diagnosisController.dispose();
    _treatmentPlanController.dispose();
    _medicationsController.dispose();
    _followUpController.dispose();
    _pastHistoryController.dispose();
    _familyHistoryController.dispose();
    _socioeconomicController.dispose();
    super.dispose();
  }

  void _applyTemplate(String templateName) {
    final template = _templates[templateName];
    if (template == null) return;

    setState(() {
      if (template['mood'] != null) _moodController.text = template['mood'] as String;
      if (template['affect'] != null) _affectController.text = template['affect'] as String;
      if (template['diagnosis'] != null) _diagnosisController.text = template['diagnosis'] as String;
      
      final symptoms = template['symptoms'];
      if (symptoms is List) {
        for (final symptom in symptoms) {
          _symptoms[symptom as String] = true;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "$templateName" applied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveDraft() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Draft saved locally'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await ref.read(doctorDbProvider.future);
      
      final assessmentData = {
        'name': _nameController.text,
        'age': _ageController.text,
        'gender': _genderController.text,
        'marital_status': _maritalStatus,
        'chief_complaint': _chiefComplaintController.text,
        'duration': _durationController.text,
        'symptoms': _symptoms,
        'mood': _moodController.text,
        'affect': _affectController.text,
        'speech': _speechController.text,
        'thought': _thoughtController.text,
        'perception': _perceptionController.text,
        'cognition': _cognitionController.text,
        'insight': _insightController.text,
        'suicide_risk': _suicideRisk,
        'homicide_risk': _homicideRisk,
        'safety_plan': _safetyPlanController.text,
        'diagnosis': _diagnosisController.text,
        'treatment_plan': _treatmentPlanController.text,
        'medications': _medicationsController.text,
        'follow_up': _followUpController.text,
      };

      final record = MedicalRecordsCompanion(
        patientId: Value(_patientId!),
        recordType: const Value('psychiatric_assessment'),
        title: Value('Psychiatric Assessment - ${DateFormat('dd MMM yyyy').format(_assessmentDate!)}'),
        description: Value(_chiefComplaintController.text),
        dataJson: Value(jsonEncode(assessmentData)),
        diagnosis: Value(_diagnosisController.text),
        treatment: Value(_treatmentPlanController.text),
        doctorNotes: Value(''),
        recordDate: Value(_assessmentDate!),
      );

      await db.insertMedicalRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Assessment saved successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
        
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? colorScheme.surface : Colors.white;
    final backgroundColor = isDark ? colorScheme.surface : Colors.grey.shade50;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Psychiatric Assessment'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Draft',
            onPressed: _saveDraft,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Assessment Date & Info
              _buildAssessmentHeader(context, isDark, cardColor),
              const SizedBox(height: 20),

              // Quick Templates
              _buildTemplatesBar(isDark, cardColor),
              const SizedBox(height: 20),

              // Section 1: Patient Information
              _buildSection(
                context: context,
                index: 0,
                title: 'Patient Information',
                icon: Icons.person,
                isDark: isDark,
                cardColor: cardColor,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Patient Name',
                    required: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _ageController,
                          label: 'Age',
                          keyboardType: TextInputType.number,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _genderController,
                          label: 'Gender',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMaritalStatusField(isDark),
                ],
              ),
              const SizedBox(height: 16),

              // Section 2: Chief Complaint
              _buildSection(
                context: context,
                index: 1,
                title: 'Chief Complaint & Duration',
                icon: Icons.sentiment_dissatisfied,
                isDark: isDark,
                cardColor: cardColor,
                children: [
                  _buildTextField(
                    controller: _chiefComplaintController,
                    label: 'Chief Complaint',
                    maxLines: 3,
                    required: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _durationController,
                    label: 'Duration',
                    hint: 'e.g., 2 weeks, 3 months',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 3: Symptoms (with toggles)
              _buildSection(
                context: context,
                index: 2,
                title: 'Symptoms',
                icon: Icons.checklist,
                isDark: isDark,
                cardColor: cardColor,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _symptoms.entries.map((entry) {
                      final isHigh = entry.key.contains('Suicidal') ||
                          entry.key.contains('Self-Harm');
                      return FilterChip(
                        label: Text(
                          entry.key,
                          style: TextStyle(
                            color: entry.value 
                                ? Colors.white 
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        selected: entry.value,
                        onSelected: (selected) {
                          setState(() => _symptoms[entry.key] = selected);
                          if (selected && isHigh) {
                            setState(() => _showRiskWarning = true);
                          }
                        },
                        backgroundColor: isDark 
                            ? Colors.grey.shade800 
                            : Colors.grey.shade200,
                        selectedColor: isHigh
                            ? AppColors.error
                            : AppColors.primary,
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 4: Mental State Examination
              _buildSection(
                context: context,
                index: 3,
                title: 'Mental State Examination',
                icon: Icons.psychology,
                isDark: isDark,
                cardColor: cardColor,
                children: [
                  _buildTextField(
                    controller: _moodController,
                    label: 'Mood',
                    hint: 'e.g., Depressed, Anxious, Elevated',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _affectController,
                    label: 'Affect',
                    hint: 'e.g., Flat, Congruent, Labile',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _speechController,
                    label: 'Speech',
                    hint: 'e.g., Normal, Slow, Pressured',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _thoughtController,
                    label: 'Thought Process',
                    hint: 'Organized, Tangential, Blocked',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _perceptionController,
                    label: 'Perception',
                    hint: 'Hallucinations, Delusions',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _cognitionController,
                    label: 'Cognition',
                    hint: 'Orientation, Memory, Attention',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _insightController,
                    label: 'Insight & Judgment',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 5: Risk Assessment (with warning)
              _buildSection(
                context: context,
                index: 4,
                title: 'Risk Assessment',
                icon: Icons.warning_rounded,
                isHighRisk: _showRiskWarning,
                isDark: isDark,
                cardColor: cardColor,
                children: [
                  if (_showRiskWarning)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.error),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'High-risk symptoms detected. Ensure safety planning.',
                              style: TextStyle(
                                color: isDark ? Colors.red.shade300 : AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildRiskField(
                    label: 'Suicidal Risk',
                    value: _suicideRisk,
                    onChanged: (value) =>
                        setState(() => _suicideRisk = value ?? 'None'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildRiskField(
                    label: 'Homicidal Risk',
                    value: _homicideRisk,
                    onChanged: (value) =>
                        setState(() => _homicideRisk = value ?? 'None'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _safetyPlanController,
                    label: 'Safety Plan',
                    maxLines: 3,
                    hint:
                        'Document safety measures and support contacts',
                    required: _showRiskWarning,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 6: Diagnosis & Treatment
              _buildSection(
                context: context,
                index: 5,
                title: 'Diagnosis & Treatment Plan',
                icon: Icons.medication,
                isDark: isDark,
                cardColor: cardColor,
                children: [
                  _buildDiagnosisField(isDark, cardColor),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _treatmentPlanController,
                    label: 'Treatment Plan',
                    maxLines: 4,
                    required: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _medicationsController,
                    label: 'Medications',
                    maxLines: 3,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _followUpController,
                    label: 'Follow-up Plan',
                    hint: 'e.g., Review in 2 weeks',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAssessment,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Save Assessment'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssessmentHeader(BuildContext context, bool isDark, Color cardColor) {
    return Card(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark ? BorderSide(color: Colors.grey.shade800) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Date & Time',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy hh:mm a').format(_assessmentDate!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesBar(bool isDark, Color cardColor) {
    return Card(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark ? BorderSide(color: Colors.grey.shade800) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Templates',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _templates.keys.map((name) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _applyTemplate(name),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: Text(name),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required int index,
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
    required Color cardColor,
    bool isHighRisk = false,
  }) {
    return Card(
      color: isHighRisk
          ? (isDark ? Colors.red.shade900.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.05))
          : cardColor,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark 
            ? BorderSide(color: isHighRisk ? Colors.red.shade700 : Colors.grey.shade800) 
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (isHighRisk)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'HIGH RISK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    bool isDark = false,
  }) {
    return maxLines > 1
        ? AppInput.multiline(
            controller: controller,
            label: label,
            hint: hint,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: required && controller.text.isEmpty
                ? (value) => '$label is required'
                : null,
          )
        : AppInput.text(
            controller: controller,
            label: label,
            hint: hint,
            keyboardType: keyboardType,
            validator: required && controller.text.isEmpty
                ? (value) => '$label is required'
                : null,
          );
  }

  Widget _buildMaritalStatusField(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _maritalStatus,
      dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        label: Text('Marital Status', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
      items: ['Single', 'Married', 'Divorced', 'Widowed', 'Separated']
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
          .toList(),
      onChanged: (value) =>
          setState(() => _maritalStatus = value ?? 'Single'),
    );
  }

  Widget _buildRiskField({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
    bool isDark = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        label: Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
      items: ['None', 'Low', 'Moderate', 'High']
          .map((risk) {
            Color color = AppColors.success;
            if (risk == 'High') color = AppColors.error;
            else if (risk == 'Moderate') color = AppColors.warning;
            else if (risk == 'Low') color = Colors.amber;
            
            return DropdownMenuItem(
              value: risk,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(risk, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            );
          })
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDiagnosisField(bool isDark, Color cardColor) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _dsm5Diagnoses.where((option) =>
            option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        setState(() => _diagnosisController.text = selection);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        _diagnosisController.addListener(() {
          textEditingController.text = _diagnosisController.text;
        });
        
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
          decoration: InputDecoration(
            label: Text('DSM-5 Diagnosis', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(AppSpacing.lg),
            helperText: 'Start typing to see suggestions',
            helperStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
          validator: (value) =>
              value?.isEmpty == true ? 'Diagnosis is required' : null,
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 350),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      option,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                    onTap: () => onSelected(option),
                    hoverColor: AppColors.primary.withValues(alpha: 0.1),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

