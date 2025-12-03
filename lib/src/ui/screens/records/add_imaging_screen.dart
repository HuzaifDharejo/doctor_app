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

/// Screen for adding an Imaging/Radiology medical record
class AddImagingScreen extends ConsumerStatefulWidget {
  const AddImagingScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddImagingScreen> createState() => _AddImagingScreenState();
}

class _AddImagingScreenState extends ConsumerState<AddImagingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();
  final _titleController = TextEditingController();

  // Imaging specific fields
  final _imagingTypeController = TextEditingController();
  final _bodyPartController = TextEditingController();
  final _indicationController = TextEditingController();
  final _techniqueController = TextEditingController();
  final _findingsController = TextEditingController();
  final _impressionController = TextEditingController();
  final _recommendationsController = TextEditingController();
  final _radiologistController = TextEditingController();
  final _facilityController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  bool _contrastUsed = false;
  String _urgency = 'Routine';

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
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
        _imagingTypeController.text = (data['imaging_type'] as String?) ?? '';
        _bodyPartController.text = (data['body_part'] as String?) ?? '';
        _indicationController.text = (data['indication'] as String?) ?? '';
        _techniqueController.text = (data['technique'] as String?) ?? '';
        _findingsController.text = (data['findings'] as String?) ?? '';
        _impressionController.text = (data['impression'] as String?) ?? '';
        _recommendationsController.text = (data['recommendations'] as String?) ?? '';
        _radiologistController.text = (data['radiologist'] as String?) ?? '';
        _facilityController.text = (data['facility'] as String?) ?? '';
        _contrastUsed = (data['contrast_used'] as bool?) ?? false;
        _urgency = (data['urgency'] as String?) ?? 'Routine';
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _imagingTypeController.dispose();
    _bodyPartController.dispose();
    _indicationController.dispose();
    _techniqueController.dispose();
    _findingsController.dispose();
    _impressionController.dispose();
    _recommendationsController.dispose();
    _radiologistController.dispose();
    _facilityController.dispose();
    _clinicalNotesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'imaging_type': _imagingTypeController.text.isNotEmpty ? _imagingTypeController.text : null,
      'body_part': _bodyPartController.text.isNotEmpty ? _bodyPartController.text : null,
      'indication': _indicationController.text.isNotEmpty ? _indicationController.text : null,
      'technique': _techniqueController.text.isNotEmpty ? _techniqueController.text : null,
      'findings': _findingsController.text.isNotEmpty ? _findingsController.text : null,
      'impression': _impressionController.text.isNotEmpty ? _impressionController.text : null,
      'recommendations': _recommendationsController.text.isNotEmpty ? _recommendationsController.text : null,
      'radiologist': _radiologistController.text.isNotEmpty ? _radiologistController.text : null,
      'facility': _facilityController.text.isNotEmpty ? _facilityController.text : null,
      'contrast_used': _contrastUsed,
      'urgency': _urgency,
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
        recordType: 'imaging',
        title: _titleController.text.isNotEmpty 
            ? _titleController.text 
            : _imagingTypeController.text.isNotEmpty 
                ? '${_imagingTypeController.text} - ${_bodyPartController.text}'
                : 'Imaging Study',
        description: Value(_findingsController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_impressionController.text),
        treatment: Value(_recommendationsController.text),
        doctorNotes: Value(_clinicalNotesController.text),
        recordDate: _recordDate,
      );

      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'imaging',
          title: _titleController.text.isNotEmpty 
              ? _titleController.text 
              : _imagingTypeController.text.isNotEmpty 
                  ? '${_imagingTypeController.text} - ${_bodyPartController.text}'
                  : 'Imaging Study',
          description: _findingsController.text,
          dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _impressionController.text,
          treatment: _recommendationsController.text,
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
              ? 'Imaging record updated successfully!' 
              : 'Imaging record saved successfully!',
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
                    ? 'Edit Imaging Record' 
                    : 'Imaging / Radiology',
                subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
                icon: Icons.image_rounded,
                gradientColors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)], // Patient Indigo
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
            context, 'Study Date', Icons.calendar_today,
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

          // Study Information Section
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Study Information',
            icon: Icons.camera_alt_outlined,
            accentColor: const Color(0xFF7C3AED),
            children: [
              SuggestionTextField(
                controller: _imagingTypeController,
                label: 'Imaging Type',
                hint: 'e.g., X-Ray, CT Scan, MRI...',
                prefixIcon: Icons.image_outlined,
                suggestions: MedicalRecordSuggestions.imagingTypes,
              ),
              const SizedBox(height: 12),
              SuggestionTextField(
                controller: _bodyPartController,
                label: 'Body Part / Region',
                hint: 'e.g., Chest, Abdomen, Brain...',
                prefixIcon: Icons.accessibility_new_outlined,
                suggestions: const [
                  'Chest',
                  'Abdomen',
                  'Pelvis',
                  'Head / Brain',
                  'Spine - Cervical',
                  'Spine - Thoracic',
                  'Spine - Lumbar',
                  'Upper Extremity',
                  'Lower Extremity',
                  'Neck',
                  'Knee',
                  'Shoulder',
                  'Hip',
                  'Hand/Wrist',
                  'Foot/Ankle',
                  'Whole Body',
                ],
              ),
              const SizedBox(height: 12),
              RecordFormWidgets.buildTextField(
                context: context,
                controller: _indicationController,
                hint: 'Clinical indication for study...',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildUrgencySelector(isDark),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildContrastToggle(isDark),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Technique
          RecordFormWidgets.buildSectionHeader(
            context, 'Technique', Icons.settings_outlined,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _techniqueController,
            hint: 'Describe imaging technique used...',
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Findings
          RecordFormWidgets.buildSectionHeader(
            context, 'Findings', Icons.find_in_page,
          ),
          const SizedBox(height: 12),
          SuggestionTextField(
            controller: _findingsController,
            label: 'Findings',
            hint: 'Describe imaging findings in detail...',
            prefixIcon: Icons.find_in_page_outlined,
            maxLines: 6,
            suggestions: MedicalRecordSuggestions.imagingFindings,
            separator: '. ',
          ),
          const SizedBox(height: 20),

          // Impression
          RecordFormWidgets.buildSectionHeader(
            context, 'Impression / Diagnosis', Icons.analytics,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _impressionController,
            hint: 'Radiological impression and diagnosis...',
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          // Recommendations
          RecordFormWidgets.buildSectionHeader(
            context, 'Recommendations', Icons.recommend,
          ),
          const SizedBox(height: 12),
          RecordFormWidgets.buildTextField(
            context: context,
            controller: _recommendationsController,
            hint: 'Follow-up recommendations...',
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Reporting Details
          RecordFormWidgets.buildSectionCard(
            context: context,
            title: 'Reporting Details',
            icon: Icons.person_outline,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RecordFormWidgets.buildTextField(
                      context: context,
                      controller: _radiologistController,
                      hint: 'Radiologist name...',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RecordFormWidgets.buildTextField(
                      context: context,
                      controller: _facilityController,
                      hint: 'Facility name...',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Clinical Notes
          RecordFormWidgets.buildSectionHeader(
            context, 'Clinical Notes', Icons.note_alt,
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
            label: widget.existingRecord != null ? 'Update Imaging Record' : 'Save Imaging Record',
            onPressed: () => _saveRecord(db),
            gradientColors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)], // Patient Indigo
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildUrgencySelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urgency',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
          ),
          child: DropdownButton<String>(
            value: _urgency,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
            items: ['Routine', 'Urgent', 'Emergency'].map((s) {
              Color color;
              switch (s) {
                case 'Emergency':
                  color = AppColors.error;
                case 'Urgent':
                  color = AppColors.warning;
                default:
                  color = AppColors.success;
              }
              return DropdownMenuItem(
                value: s,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(s),
                  ],
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _urgency = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildContrastToggle(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contrast Used',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                _contrastUsed ? Icons.check_circle : Icons.circle_outlined,
                color: _contrastUsed ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _contrastUsed ? 'Yes' : 'No',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _contrastUsed,
                onChanged: (v) => setState(() => _contrastUsed = v),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

