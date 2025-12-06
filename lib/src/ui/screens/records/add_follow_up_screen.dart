import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/suggestions_service.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../widgets/suggestion_text_field.dart';
import 'record_form_widgets.dart';
import 'components/record_components.dart';

/// Screen for adding a Follow-up Visit medical record
class AddFollowUpScreen extends ConsumerStatefulWidget {
  const AddFollowUpScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
    this.encounterId,
    this.diagnosis,
    this.treatmentPlan,
    this.reason,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;
  /// Associated encounter ID from workflow
  final int? encounterId;
  /// Diagnosis context from workflow
  final String? diagnosis;
  /// Treatment plan context from workflow
  final String? treatmentPlan;
  /// Reason for follow-up
  final String? reason;

  @override
  ConsumerState<AddFollowUpScreen> createState() => _AddFollowUpScreenState();
}

class _AddFollowUpScreenState extends ConsumerState<AddFollowUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();

  // Follow-up specific fields
  final _progressNotesController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _complianceController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _medicationReviewController = TextEditingController();
  final _investigationsController = TextEditingController();
  final _assessmentController = TextEditingController();
  final _planController = TextEditingController();
  final _nextFollowUpController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  // Vitals
  final _bpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _spo2Controller = TextEditingController();

  String _overallProgress = 'Improving';
  DateTime? _nextFollowUpDate;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    } else {
      // Initialize from workflow context
      if (widget.diagnosis != null && widget.diagnosis!.isNotEmpty) {
        _assessmentController.text = widget.diagnosis!;
      }
      if (widget.treatmentPlan != null && widget.treatmentPlan!.isNotEmpty) {
        _planController.text = widget.treatmentPlan!;
      }
    }
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _clinicalNotesController.text = record.doctorNotes ?? '';
    _assessmentController.text = record.diagnosis ?? '';
    _planController.text = record.treatment ?? '';
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
        _progressNotesController.text = (data['progress_notes'] as String?) ?? (data['follow_up_notes'] as String?) ?? '';
        _symptomsController.text = (data['symptoms'] as String?) ?? '';
        _complianceController.text = (data['compliance'] as String?) ?? '';
        _sideEffectsController.text = (data['side_effects'] as String?) ?? '';
        _medicationReviewController.text = (data['medication_review'] as String?) ?? '';
        _investigationsController.text = (data['investigations'] as String?) ?? '';
        _nextFollowUpController.text = (data['next_follow_up_notes'] as String?) ?? '';
        _overallProgress = (data['overall_progress'] as String?) ?? 'Improving';
        
        if (data['next_follow_up_date'] != null) {
          _nextFollowUpDate = DateTime.tryParse(data['next_follow_up_date'] as String);
        }
        
        final vitals = data['vitals'] as Map<String, dynamic>?;
        if (vitals != null) {
          _bpController.text = (vitals['bp'] as String?) ?? '';
          _pulseController.text = (vitals['pulse'] as String?) ?? '';
          _tempController.text = (vitals['temperature'] as String?) ?? '';
          _weightController.text = (vitals['weight'] as String?) ?? '';
          _spo2Controller.text = (vitals['spo2'] as String?) ?? '';
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _progressNotesController.dispose();
    _symptomsController.dispose();
    _complianceController.dispose();
    _sideEffectsController.dispose();
    _medicationReviewController.dispose();
    _investigationsController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    _nextFollowUpController.dispose();
    _clinicalNotesController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _spo2Controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'progress_notes': _progressNotesController.text.isNotEmpty ? _progressNotesController.text : null,
      'symptoms': _symptomsController.text.isNotEmpty ? _symptomsController.text : null,
      'compliance': _complianceController.text.isNotEmpty ? _complianceController.text : null,
      'side_effects': _sideEffectsController.text.isNotEmpty ? _sideEffectsController.text : null,
      'medication_review': _medicationReviewController.text.isNotEmpty ? _medicationReviewController.text : null,
      'investigations': _investigationsController.text.isNotEmpty ? _investigationsController.text : null,
      'next_follow_up_notes': _nextFollowUpController.text.isNotEmpty ? _nextFollowUpController.text : null,
      'overall_progress': _overallProgress,
      'next_follow_up_date': _nextFollowUpDate?.toIso8601String(),
      'vitals': {
        'bp': _bpController.text.isNotEmpty ? _bpController.text : null,
        'pulse': _pulseController.text.isNotEmpty ? _pulseController.text : null,
        'temperature': _tempController.text.isNotEmpty ? _tempController.text : null,
        'weight': _weightController.text.isNotEmpty ? _weightController.text : null,
        'spo2': _spo2Controller.text.isNotEmpty ? _spo2Controller.text : null,
      },
    };
  }

  Future<void> _saveRecord(DoctorDatabase db) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      RecordFormWidgets.showErrorSnackbar(context, 'Please select a patient');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final companion = MedicalRecordsCompanion.insert(
        patientId: _selectedPatientId!,
        recordType: 'follow_up',
        title: 'Follow-up Visit - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_progressNotesController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_assessmentController.text),
        treatment: Value(_planController.text),
        doctorNotes: Value(_clinicalNotesController.text),
        recordDate: _recordDate,
      );

      MedicalRecord? resultRecord;
      int? recordId;
      
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'follow_up',
          title: 'Follow-up Visit - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _progressNotesController.text,
          dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _assessmentController.text,
          treatment: _planController.text,
          doctorNotes: _clinicalNotesController.text,
          recordDate: _recordDate,
          createdAt: widget.existingRecord!.createdAt,
        );
        await db.updateMedicalRecord(updatedRecord);
        resultRecord = updatedRecord;
        recordId = widget.existingRecord!.id;
      } else {
        recordId = await db.insertMedicalRecord(companion);
        resultRecord = await db.getMedicalRecordById(recordId);
      }

      // Save vitals to VitalSigns table for patient history
      if (_hasAnyVitals()) {
        await _saveVitalsToPatientRecord(db);
      }

      // Create ScheduledFollowUp if next follow-up date is set
      if (_nextFollowUpDate != null) {
        await _createScheduledFollowUp(db, recordId);
      }

      if (mounted) {
        RecordFormWidgets.showSuccessSnackbar(
          context, 
          widget.existingRecord != null 
              ? 'Follow-up record updated successfully!' 
              : 'Follow-up record saved successfully!',
        );
        Navigator.pop(context, resultRecord);
      }
    } catch (e) {
      if (mounted) {
        RecordFormWidgets.showErrorSnackbar(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _hasAnyVitals() {
    return _bpController.text.isNotEmpty ||
        _pulseController.text.isNotEmpty ||
        _tempController.text.isNotEmpty ||
        _weightController.text.isNotEmpty ||
        _spo2Controller.text.isNotEmpty;
  }

  Future<void> _saveVitalsToPatientRecord(DoctorDatabase db) async {
    // Parse BP if provided (format: "120/80")
    double? systolic;
    double? diastolic;
    if (_bpController.text.isNotEmpty) {
      final bpParts = _bpController.text.split('/');
      if (bpParts.isNotEmpty) systolic = double.tryParse(bpParts[0].trim());
      if (bpParts.length > 1) diastolic = double.tryParse(bpParts[1].trim());
    }

    double? weight = _weightController.text.isNotEmpty 
        ? double.tryParse(_weightController.text) 
        : null;

    await db.insertVitalSigns(VitalSignsCompanion.insert(
      patientId: _selectedPatientId!,
      recordedAt: _recordDate,
      systolicBp: Value(systolic),
      diastolicBp: Value(diastolic),
      heartRate: Value(_pulseController.text.isNotEmpty 
          ? int.tryParse(_pulseController.text) 
          : null),
      temperature: Value(_tempController.text.isNotEmpty 
          ? double.tryParse(_tempController.text) 
          : null),
      oxygenSaturation: Value(_spo2Controller.text.isNotEmpty 
          ? double.tryParse(_spo2Controller.text) 
          : null),
      weight: Value(weight),
      notes: Value('Recorded during follow-up visit'),
    ));
  }

  Future<void> _createScheduledFollowUp(DoctorDatabase db, int? sourceRecordId) async {
    // Check if there's already a scheduled follow-up for this date
    final existingFollowUps = await db.getScheduledFollowUpsForPatient(_selectedPatientId!);
    final alreadyScheduled = existingFollowUps.any((f) => 
        f.scheduledDate.year == _nextFollowUpDate!.year &&
        f.scheduledDate.month == _nextFollowUpDate!.month &&
        f.scheduledDate.day == _nextFollowUpDate!.day);
    
    if (!alreadyScheduled) {
      await db.insertScheduledFollowUp(ScheduledFollowUpsCompanion.insert(
        patientId: _selectedPatientId!,
        scheduledDate: _nextFollowUpDate!,
        reason: _nextFollowUpController.text.isNotEmpty 
            ? _nextFollowUpController.text 
            : 'Follow-up as per treatment plan',
        status: const Value('pending'),
        notes: Value('Progress: $_overallProgress. ${_planController.text}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RecordFormScaffold(
      title: widget.existingRecord != null 
          ? 'Edit Follow-up' 
          : 'Follow-up Visit',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.event_repeat_rounded,
      gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Notes Amber
      scrollController: _scrollController,
      body: dbAsync.when(
        data: (db) => _buildFormContent(context, db, isDark),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Selection
          PatientSelectorCard(
            db: db,
            selectedPatientId: _selectedPatientId,
            onChanged: (id) => setState(() => _selectedPatientId = id),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Date Selection
          DatePickerCard(
            label: 'Visit Date',
            selectedDate: _recordDate,
            onDateSelected: (date) => setState(() => _recordDate = date),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Overall Progress
          _buildProgressSelector(isDark),
          const SizedBox(height: AppSpacing.lg),

          // Current Symptoms
          RecordFormSection(
            title: 'Current Symptoms',
            icon: Icons.sick_outlined,
            child: SuggestionTextField(
              controller: _symptomsController,
              label: 'Current Symptoms',
              hint: 'Describe current symptoms...',
              prefixIcon: Icons.sick_outlined,
              maxLines: 3,
              suggestions: MedicalSuggestions.symptoms,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Vitals Section
          RecordFormSection(
            title: 'Vital Signs',
            icon: Icons.favorite_outline,
            accentColor: const Color(0xFF14B8A6),
            child: Column(
              children: [
                RecordFieldGrid(
                  children: [
                    CompactTextField(
                      controller: _bpController,
                      label: 'BP',
                      hint: '120/80',
                      suffix: 'mmHg',
                    ),
                    CompactTextField(
                      controller: _pulseController,
                      label: 'Pulse',
                      hint: '72',
                      suffix: 'bpm',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                RecordFieldGrid(
                  children: [
                    CompactTextField(
                      controller: _tempController,
                      label: 'Temp',
                      hint: '98.6',
                      suffix: '°F',
                    ),
                    CompactTextField(
                      controller: _spo2Controller,
                      label: 'SpO₂',
                      hint: '98',
                      suffix: '%',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                CompactTextField(
                  controller: _weightController,
                  label: 'Weight',
                  hint: '70',
                  suffix: 'kg',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Progress Notes
          RecordFormSection(
            title: 'Progress Notes',
            icon: Icons.trending_up,
            child: SuggestionTextField(
              controller: _progressNotesController,
              label: 'Progress Notes',
              hint: 'Describe patient progress since last visit...',
              prefixIcon: Icons.trending_up_outlined,
              maxLines: 5,
              suggestions: MedicalRecordSuggestions.followUpNotes,
              separator: '. ',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Medication Review
          RecordFormSection(
            title: 'Medication Review',
            icon: Icons.medication_outlined,
            child: Column(
              children: [
                RecordTextField(
                  controller: _complianceController,
                  hint: 'Medication compliance...',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(
                  controller: _sideEffectsController,
                  hint: 'Any side effects reported...',
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(
                  controller: _medicationReviewController,
                  hint: 'Medication changes or adjustments...',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Investigations
          RecordFormSection(
            title: 'Investigation Results',
            icon: Icons.science_outlined,
            child: RecordTextField(
              controller: _investigationsController,
              hint: 'Recent investigation results...',
              maxLines: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Assessment
          RecordFormSection(
            title: 'Assessment',
            icon: Icons.analytics,
            child: SuggestionTextField(
              controller: _assessmentController,
              label: 'Assessment',
              hint: 'Clinical assessment...',
              prefixIcon: Icons.analytics_outlined,
              maxLines: 4,
              suggestions: MedicalSuggestions.diagnoses,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Plan
          RecordFormSection(
            title: 'Plan',
            icon: Icons.assignment,
            child: RecordNotesField(
              controller: _planController,
              hint: 'Treatment plan and instructions...',
              maxLines: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Next Follow-up
          RecordFormSection(
            title: 'Next Follow-up',
            icon: Icons.calendar_month,
            accentColor: const Color(0xFF14B8A6),
            child: Column(
              children: [
                _buildNextFollowUpDateSelector(isDark),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(
                  controller: _nextFollowUpController,
                  hint: 'Notes for next follow-up...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Additional Notes
          RecordFormSection(
            title: 'Additional Notes',
            icon: Icons.note_alt,
            child: RecordNotesField(
              controller: _clinicalNotesController,
              hint: 'Additional clinical notes...',
              maxLines: 4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save Button
          RecordSaveButton(
            isSaving: _isSaving,
            label: widget.existingRecord != null ? 'Update Follow-up' : 'Save Follow-up',
            onPressed: () => _saveRecord(db),
            gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Notes Amber
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildProgressSelector(bool isDark) {
    final options = [
      ('Improving', Icons.trending_up, AppColors.success),
      ('Stable', Icons.trending_flat, AppColors.info),
      ('Worsening', Icons.trending_down, AppColors.error),
      ('Resolved', Icons.check_circle_outline, AppColors.accent),
    ];

    return RecordFormSection(
      title: 'Overall Progress',
      icon: Icons.assessment_outlined,
      accentColor: const Color(0xFF14B8A6),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: options.map((option) {
          final isSelected = _overallProgress == option.$1;
          return ChoiceChip(
            avatar: Icon(
              option.$2,
              size: 16,
              color: isSelected ? Colors.white : option.$3,
            ),
            label: Text(option.$1),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _overallProgress = option.$1);
            },
            selectedColor: option.$3,
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? option.$3 : (isDark ? AppColors.darkDivider : AppColors.divider),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNextFollowUpDateSelector(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _nextFollowUpDate ?? DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _nextFollowUpDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event,
              color: const Color(0xFF14B8A6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Appointment',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _nextFollowUpDate != null 
                        ? DateFormat('EEEE, MMMM d, yyyy').format(_nextFollowUpDate!)
                        : 'Tap to select date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _nextFollowUpDate != null 
                          ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                          : (isDark ? AppColors.darkTextHint : AppColors.textHint),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit,
              size: 18,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

