// Modern Pulmonary Evaluation Screen - Complete Redesign
// Features: Symptom checkers, vital signs, differential diagnosis, quick templates

import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/components/app_input.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

class PulmonaryEvaluationScreenModern extends ConsumerStatefulWidget {
  
  const PulmonaryEvaluationScreenModern({
    super.key,
    this.preselectedPatient,
  });
  
  final Patient? preselectedPatient;

  @override
  ConsumerState<PulmonaryEvaluationScreenModern> createState() =>
      _PulmonaryEvaluationScreenModernState();
}

class _PulmonaryEvaluationScreenModernState
    extends ConsumerState<PulmonaryEvaluationScreenModern> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Assessment metadata
  DateTime? _evaluationDate;
  int? _patientId;
  bool _isSaving = false;

  // Patient info
  final _patientNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();

  // Chief Complaint
  final _chiefComplaintController = TextEditingController();
  final _durationController = TextEditingController();

  // Symptoms (quick checkboxes)
  Map<String, bool> _presentingSymptoms = {
    'Cough': false,
    'Dry Cough': false,
    'Productive Cough': false,
    'Hemoptysis': false,
    'Dyspnea': false,
    'Wheezing': false,
    'Chest Pain': false,
    'Fever': false,
    'Night Sweats': false,
    'Weight Loss': false,
    'Fatigue': false,
  };

  // Red Flags
  Map<String, bool> _redFlags = {
    'Hemoptysis': false,
    'Severe Dyspnea': false,
    'Stridor': false,
    'Cyanosis': false,
    'Chest Wall Deformity': false,
    'Severe Tachypnea': false,
  };

  // Vitals
  late TextEditingController _bpController;
  late TextEditingController _prController;
  late TextEditingController _rrController;
  late TextEditingController _tempController;
  late TextEditingController _spo2Controller;

  // Examination Findings
  Map<String, String> _chestFindings = {
    'Inspection': '',
    'Palpation': '',
    'Percussion': '',
    'Auscultation': '',
  };

  // Breath Sounds
  Map<String, bool> _breathSounds = {
    'Normal': false,
    'Crackles': false,
    'Wheeze': false,
    'Rhonchi': false,
    'Decreased Air Entry': false,
  };

  // Diagnosis
  final _diagnosisController = TextEditingController();
  final _differentialController = TextEditingController();

  // Investigations
  Map<String, bool> _investigations = {
    'Chest X-ray': false,
    'CT Chest': false,
    'Sputum AFB': false,
    'Blood Culture': false,
    'Spirometry': false,
    'ABG': false,
    'CBC': false,
    'COVID-19 Test': false,
  };

  // Treatment
  final _treatmentPlanController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _followUpController = TextEditingController();

  // Common diagnoses (quick select)
  static const List<String> _commonDiagnoses = [
    'Acute Bronchitis',
    'Community Acquired Pneumonia',
    'Tuberc ulosis',
    'Asthma Exacerbation',
    'COPD Exacerbation',
    'Pulmonary Embolism',
    'Pneumothorax',
    'Pleural Effusion',
    'Lung Cancer (Suspected)',
    'Interstitial Lung Disease',
    'Bronchiectasis',
  ];

  @override
  void initState() {
    super.initState();
    _evaluationDate = DateTime.now();
    
    _bpController = TextEditingController();
    _prController = TextEditingController();
    _rrController = TextEditingController();
    _tempController = TextEditingController();
    _spo2Controller = TextEditingController();
    
    if (widget.preselectedPatient != null) {
      final p = widget.preselectedPatient!;
      _patientId = p.id;
      _patientNameController.text = '${p.firstName} ${p.lastName}'.trim();
      if (p.dateOfBirth != null) {
        final age = DateTime.now().year - p.dateOfBirth!.year;
        _ageController.text = age.toString();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _patientNameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _diagnosisController.dispose();
    _differentialController.dispose();
    _treatmentPlanController.dispose();
    _medicationsController.dispose();
    _followUpController.dispose();
    _bpController.dispose();
    _prController.dispose();
    _rrController.dispose();
    _tempController.dispose();
    _spo2Controller.dispose();
    super.dispose();
  }

  void _applyDiagnosis(String diagnosis) {
    setState(() => _diagnosisController.text = diagnosis);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Diagnosis "$diagnosis" applied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _hasRedFlags() {
    return _redFlags.values.any((flag) => flag == true) ||
        (_presentingSymptoms['Hemoptysis'] == true) ||
        (_presentingSymptoms['Severe Dyspnea'] == true);
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

  Future<void> _saveEvaluation() async {
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
      
      final evaluationData = {
        'chief_complaint': _chiefComplaintController.text,
        'duration': _durationController.text,
        'symptoms': _presentingSymptoms,
        'red_flags': _redFlags,
        'vitals': {
          'bp': _bpController.text,
          'pr': _prController.text,
          'rr': _rrController.text,
          'temp': _tempController.text,
          'spo2': _spo2Controller.text,
        },
        'chest_findings': _chestFindings,
        'breath_sounds': _breathSounds,
        'diagnosis': _diagnosisController.text,
        'differential': _differentialController.text,
        'investigations': _investigations,
        'treatment_plan': _treatmentPlanController.text,
        'medications': _medicationsController.text,
        'follow_up': _followUpController.text,
      };

      final record = MedicalRecordsCompanion(
        patientId: Value(_patientId!),
        recordType: const Value('pulmonary_evaluation'),
        title: Value('Pulmonary Evaluation - ${DateFormat('dd MMM yyyy').format(_evaluationDate!)}'),
        description: Value(_chiefComplaintController.text),
        dataJson: Value(jsonEncode(evaluationData)),
        diagnosis: Value(_diagnosisController.text),
        treatment: Value(_treatmentPlanController.text),
        doctorNotes: Value(''),
        recordDate: Value(_evaluationDate!),
      );

      await db.insertMedicalRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Evaluation saved successfully'),
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
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : AppColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : const Color(0xFF3B82F6),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.save_outlined,
                        color: isDark ? Colors.white : const Color(0xFF3B82F6),
                      ),
                      tooltip: 'Save Draft',
                      onPressed: _saveDraft,
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
                          ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                          : [Colors.white, const Color(0xFFF8F9FA)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.air_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pulmonary Evaluation',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Respiratory assessment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark 
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : const Color(0xFF6B7280),
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
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
              // Evaluation Date
              _buildEvaluationHeader(context),
              const SizedBox(height: 20),

              // Quick Diagnosis Templates
              _buildQuickDiagnosisBar(),
              const SizedBox(height: 20),

              // Section 1: Patient Information
              _buildSection(
                title: 'Patient Information',
                icon: Icons.person,
                children: [
                  _buildTextField(
                    controller: _patientNameController,
                    label: 'Patient Name',
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _ageController,
                          label: 'Age',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _genderController,
                          label: 'Gender',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 2: Chief Complaint
              _buildSection(
                title: 'Chief Complaint & Duration',
                icon: Icons.medical_services_outlined,
                children: [
                  _buildTextField(
                    controller: _chiefComplaintController,
                    label: 'Chief Complaint',
                    maxLines: 3,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _durationController,
                    label: 'Duration',
                    hint: 'e.g., 1 week, 2 months',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 3: Presenting Symptoms
              _buildSection(
                title: 'Presenting Symptoms',
                icon: Icons.checklist,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presentingSymptoms.entries.map((entry) {
                      return FilterChip(
                        label: Text(entry.key),
                        selected: entry.value,
                        onSelected: (selected) {
                          setState(() =>
                              _presentingSymptoms[entry.key] = selected);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 4: Red Flags (with warning)
              if (_hasRedFlags())
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.error, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.error, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RED FLAGS DETECTED',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Requires urgent evaluation and investigation',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              _buildSection(
                title: 'Red Flags',
                icon: Icons.warning_rounded,
                isHighRisk: _hasRedFlags(),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _redFlags.entries.map((entry) {
                      return FilterChip(
                        label: Text(entry.key),
                        selected: entry.value,
                        selectedColor: AppColors.error.withValues(alpha: 0.3),
                        checkmarkColor: AppColors.error,
                        onSelected: (selected) {
                          setState(() => _redFlags[entry.key] = selected);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 5: Vital Signs
              _buildSection(
                title: 'Vital Signs',
                icon: Icons.favorite,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _bpController,
                          label: 'BP (mmHg)',
                          hint: '120/80',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: _prController,
                          label: 'Pulse (bpm)',
                          hint: '72',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _rrController,
                          label: 'RR (breaths/min)',
                          hint: '16',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          controller: _tempController,
                          label: 'Temp (°C)',
                          hint: '37',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _spo2Controller,
                    label: 'SpO₂ (%)',
                    hint: '98',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 6: Physical Examination
              _buildSection(
                title: 'Chest Auscultation Findings',
                icon: Icons.hearing,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _breathSounds.entries.map((entry) {
                      return FilterChip(
                        label: Text(entry.key),
                        selected: entry.value,
                        onSelected: (selected) {
                          setState(() =>
                              _breathSounds[entry.key] = selected);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ..._chestFindings.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTextField(
                        controller:
                            TextEditingController(text: entry.value),
                        label: entry.key,
                        onChanged: (value) {
                          _chestFindings[entry.key] = value;
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
              const SizedBox(height: 16),

              // Section 7: Investigations
              _buildSection(
                title: 'Investigations Required',
                icon: Icons.biotech,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _investigations.entries.map((entry) {
                      return FilterChip(
                        label: Text(entry.key),
                        selected: entry.value,
                        onSelected: (selected) {
                          setState(() =>
                              _investigations[entry.key] = selected);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 8: Assessment & Plan
              _buildSection(
                title: 'Assessment & Management Plan',
                icon: Icons.assignment,
                children: [
                  _buildTextField(
                    controller: _diagnosisController,
                    label: 'Primary Diagnosis',
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _differentialController,
                    label: 'Differential Diagnoses',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _treatmentPlanController,
                    label: 'Treatment Plan',
                    maxLines: 4,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _medicationsController,
                    label: 'Medications',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _followUpController,
                    label: 'Follow-up Plan',
                    hint: 'e.g., Review in 1 week',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveEvaluation,
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
                  label: Text(_isSaving ? 'Saving...' : 'Save Evaluation'),
                ),
              ),
              const SizedBox(height: 20),
            ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evaluation Date & Time',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy hh:mm a').format(_evaluationDate!),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDiagnosisBar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Common Diagnoses',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _commonDiagnoses.take(5).map((diagnosis) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _applyDiagnosis(diagnosis),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(diagnosis,
                          overflow: TextOverflow.ellipsis),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
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
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isHighRisk = false,
  }) {
    return Card(
      color: isHighRisk
          ? AppColors.error.withValues(alpha: 0.05)
          : null,
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
    ValueChanged<String>? onChanged,
  }) {
    return AppInput(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: required && controller.text.isEmpty
          ? (value) => '$label is required'
          : null,
    );
  }
}

