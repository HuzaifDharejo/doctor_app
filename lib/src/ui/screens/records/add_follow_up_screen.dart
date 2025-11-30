import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/suggestions_service.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/suggestion_text_field.dart';
import 'record_form_widgets.dart';

/// Screen for adding a Follow-up Visit medical record
class AddFollowUpScreen extends ConsumerStatefulWidget {
  const AddFollowUpScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

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
  final _titleController = TextEditingController();

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
    }
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _titleController.text = record.title;
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
    _titleController.dispose();
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
        title: _titleController.text.isNotEmpty 
            ? _titleController.text 
            : 'Follow-up Visit - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_progressNotesController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_assessmentController.text),
        treatment: Value(_planController.text),
        doctorNotes: Value(_clinicalNotesController.text),
        recordDate: _recordDate,
      );

      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'follow_up',
          title: _titleController.text.isNotEmpty 
              ? _titleController.text 
              : 'Follow-up Visit - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _progressNotesController.text,
          dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _assessmentController.text,
          treatment: _planController.text,
          doctorNotes: _clinicalNotesController.text,
          recordDate: _recordDate,
          createdAt: widget.existingRecord!.createdAt,
        );
        await db.updateMedicalRecord(updatedRecord);
      } else {
        await db.insertMedicalRecord(companion);
      }

      if (mounted) {
        RecordFormWidgets.showSuccessSnackbar(
          context, 
          widget.existingRecord != null 
              ? 'Follow-up record updated successfully!' 
              : 'Follow-up record saved successfully!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        RecordFormWidgets.showErrorSnackbar(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          controller: _scrollController,
          slivers: [
            // Gradient Header
            SliverToBoxAdapter(
              child: RecordFormWidgets.buildGradientHeader(
                context: context,
                title: widget.existingRecord != null 
                    ? 'Edit Follow-up' 
                    : 'Follow-up Visit',
                subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
                icon: Icons.event_repeat_rounded,
                gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
              ),
            ),
            // Body Content
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFormContent(context, db, isDark),
                ]),
              ),
            ),
          ],
        ),
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
          RecordFormWidgets.buildSectionHeader(
            context, 'Patient', Icons.person_outline,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildPatientSelector(
            context: context,
            db: db,
            selectedPatientId: _selectedPatientId,
            onChanged: (id) => setState(() => _selectedPatientId = id),
          ),
          const SizedBox(height: 20),

          // Date Selection
          RecordFormWidgets.buildSectionHeader(
            context, 'Visit Date', Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildDateSelector(
            context: context,
            selectedDate: _recordDate,
            onDateSelected: (date) => setState(() => _recordDate = date),
          ),
          const SizedBox(height: 20),

          // Title
          RecordFormWidgets.buildSectionHeader(context, 'Title', Icons.title),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _titleController,
            hint: 'Enter record title (optional)...',
          ),
          const SizedBox(height: 20),

          // Overall Progress
          _buildProgressSelector(isDark),
          const SizedBox(height: 20),

          // Current Symptoms
          RecordFormWidgets.buildSectionHeader(
            context, 'Current Symptoms', Icons.sick_outlined,
          ),
          const SizedBox(height: 12),
          SuggestionTextField(
            controller: _symptomsController,
            label: 'Current Symptoms',
            hint: 'Describe current symptoms...',
            prefixIcon: Icons.sick_outlined,
            maxLines: 3,
            suggestions: MedicalSuggestions.symptoms,
          ),
          const SizedBox(height: 20),

          // Vitals Section
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Vital Signs',
            icon: Icons.favorite_outline,
            accentColor: const Color(0xFF14B8A6),
            children: [
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _bpController,
                      label: 'BP',
                      unit: 'mmHg',
                      hint: '120/80',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _pulseController,
                      label: 'Pulse',
                      unit: 'bpm',
                      hint: '72',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _tempController,
                      label: 'Temp',
                      unit: '°F',
                      hint: '98.6',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildVitalField(
                      context: context,
                      controller: _spo2Controller,
                      label: 'SpO₂',
                      unit: '%',
                      hint: '98',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RecordFormWidgets.buildVitalField(
                context: context,
                controller: _weightController,
                label: 'Weight',
                unit: 'kg',
                hint: '70',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Notes
          RecordFormWidgets.buildSectionHeader(
            context, 'Progress Notes', Icons.trending_up,
          ),
          const SizedBox(height: 12),
          SuggestionTextField(
            controller: _progressNotesController,
            label: 'Progress Notes',
            hint: 'Describe patient progress since last visit...',
            prefixIcon: Icons.trending_up_outlined,
            maxLines: 5,
            suggestions: MedicalRecordSuggestions.followUpNotes,
            separator: '. ',
          ),
          const SizedBox(height: 20),

          // Medication Review
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Medication Review',
            icon: Icons.medication_outlined,
            children: [
              RecordFormWidgets.buildTextField(
                context: context,
                controller: _complianceController,
                hint: 'Medication compliance...',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              RecordFormWidgets.buildTextField(
                context: context,
                controller: _sideEffectsController,
                hint: 'Any side effects reported...',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              RecordFormWidgets.buildTextField(
                context: context,
                controller: _medicationReviewController,
                hint: 'Medication changes or adjustments...',
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Investigations
          RecordFormWidgets.buildSectionHeader(
            context, 'Investigation Results', Icons.science_outlined,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _investigationsController,
            hint: 'Recent investigation results...',
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Assessment
          RecordFormWidgets.buildSectionHeader(
            context, 'Assessment', Icons.analytics,
          ),
          const SizedBox(height: 12),
          SuggestionTextField(
            controller: _assessmentController,
            label: 'Assessment',
            hint: 'Clinical assessment...',
            prefixIcon: Icons.analytics_outlined,
            maxLines: 4,
            suggestions: MedicalSuggestions.diagnoses,
          ),
          const SizedBox(height: 20),

          // Plan
          RecordFormWidgets.buildSectionHeader(
            context, 'Plan', Icons.assignment,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _planController,
            hint: 'Treatment plan and instructions...',
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          // Next Follow-up
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Next Follow-up',
            icon: Icons.calendar_month,
            accentColor: const Color(0xFF14B8A6),
            children: [
              _buildNextFollowUpDateSelector(isDark),
              const SizedBox(height: 12),
              RecordFormWidgets.buildTextField(
                context: context,
                controller: _nextFollowUpController,
                hint: 'Notes for next follow-up...',
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Additional Notes
          RecordFormWidgets.buildSectionHeader(
            context, 'Additional Notes', Icons.note_alt,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _clinicalNotesController,
            hint: 'Additional clinical notes...',
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          // Save Button
          RecordFormWidgets.buildSaveButton(
            context: context,
            isSaving: _isSaving,
            label: widget.existingRecord != null ? 'Update Follow-up' : 'Save Follow-up',
            onPressed: () => _saveRecord(db),
            gradientColors: [const Color(0xFF14B8A6), const Color(0xFF0D9488)],
          ),
          const SizedBox(height: 40),
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

    return RecordFormWidgets.buildSectionCard(
      context: context,
      title: 'Overall Progress',
      icon: Icons.assessment_outlined,
      accentColor: const Color(0xFF14B8A6),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
      ],
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
        padding: const EdgeInsets.all(16),
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
