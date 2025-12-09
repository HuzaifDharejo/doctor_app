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
import 'components/record_components.dart';
import 'components/quick_fill_templates.dart';
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

  // Theme colors for this record type
  static const _primaryColor = Color(0xFF6366F1); // Patient Indigo
  static const _secondaryColor = Color(0xFF4F46E5);
  static const _gradientColors = [_primaryColor, _secondaryColor];

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();

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
        title: _imagingTypeController.text.isNotEmpty && _bodyPartController.text.isNotEmpty
            ? '${_imagingTypeController.text}: ${_bodyPartController.text}'
            : _imagingTypeController.text.isNotEmpty 
                ? _imagingTypeController.text
                : 'Imaging Study - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_findingsController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_impressionController.text),
        treatment: Value(_recommendationsController.text),
        doctorNotes: Value(_clinicalNotesController.text),
        recordDate: _recordDate,
      );

      MedicalRecord? resultRecord;
      
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'imaging',
          title: _imagingTypeController.text.isNotEmpty && _bodyPartController.text.isNotEmpty
              ? '${_imagingTypeController.text}: ${_bodyPartController.text}'
              : _imagingTypeController.text.isNotEmpty 
                  ? _imagingTypeController.text
                  : 'Imaging Study - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _findingsController.text,
          dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _impressionController.text,
          treatment: _recommendationsController.text,
          doctorNotes: _clinicalNotesController.text,
          recordDate: _recordDate,
          createdAt: widget.existingRecord!.createdAt,
        );
        await db.updateMedicalRecord(updatedRecord);
        resultRecord = updatedRecord;
      } else {
        final recordId = await db.insertMedicalRecord(companion);
        resultRecord = await db.getMedicalRecordById(recordId);
      }

      if (mounted) {
        RecordFormWidgets.showSuccessSnackbar(
          context, 
          widget.existingRecord != null 
              ? 'Imaging record updated successfully!' 
              : 'Imaging record saved successfully!',
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

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RecordFormScaffold(
      title: widget.existingRecord != null 
          ? 'Edit Imaging' 
          : 'Imaging / Radiology',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.image_rounded,
      gradientColors: _gradientColors,
      scrollController: _scrollController,
      body: dbAsync.when(
        data: (db) => _buildFormContent(context, db, isDark),
        loading: () => const Center(
          child: CircularProgressIndicator(color: _primaryColor),
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
          RecordFormSection(
            title: 'Patient Information',
            icon: Icons.person_outline,
            accentColor: _primaryColor,
            child: PatientSelectorCard(
              db: db,
              selectedPatientId: _selectedPatientId,
              onPatientSelected: (patient) {
                setState(() => _selectedPatientId = patient?.id);
              },
              label: 'Select Patient',
            ),
          ),
          const SizedBox(height: 16),

          // Quick Fill Templates Section
          _buildQuickFillSection(context, isDark),
          const SizedBox(height: 16),

          // Date and Title Section
          RecordFormSection(
            title: 'Record Details',
            icon: Icons.event_note,
            accentColor: _primaryColor,
            child: DatePickerCard(
              selectedDate: _recordDate,
              onDateSelected: (date) => setState(() => _recordDate = date),
              label: 'Study Date',
              accentColor: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Study Information Section
          RecordFormSection(
            title: 'Study Information',
            icon: Icons.camera_alt_outlined,
            accentColor: const Color(0xFF7C3AED),
            child: Column(
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
                RecordTextField(
                  controller: _indicationController,
                  hint: 'Clinical indication for study...',
                  maxLines: 2,
                  accentColor: const Color(0xFF7C3AED),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildUrgencySelector(isDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ToggleOptionRow(
                        label: 'Contrast Used',
                        value: _contrastUsed,
                        onChanged: (v) => setState(() => _contrastUsed = v),
                        icon: Icons.opacity,
                        accentColor: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Technique
          RecordFormSection(
            title: 'Technique',
            icon: Icons.settings_outlined,
            accentColor: Colors.orange,
            collapsible: true,
            child: RecordTextField(
              controller: _techniqueController,
              hint: 'Describe imaging technique used...',
              maxLines: 3,
              accentColor: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),

          // Findings
          RecordFormSection(
            title: 'Findings',
            icon: Icons.find_in_page,
            accentColor: Colors.teal,
            child: SuggestionTextField(
              controller: _findingsController,
              label: 'Findings',
              hint: 'Describe imaging findings in detail...',
              prefixIcon: Icons.find_in_page_outlined,
              maxLines: 6,
              suggestions: MedicalRecordSuggestions.imagingFindings,
              separator: '. ',
            ),
          ),
          const SizedBox(height: 16),

          // Impression
          RecordFormSection(
            title: 'Impression / Diagnosis',
            icon: Icons.analytics,
            accentColor: Colors.purple,
            child: RecordTextField(
              controller: _impressionController,
              hint: 'Radiological impression and diagnosis...',
              maxLines: 4,
              accentColor: Colors.purple,
            ),
          ),
          const SizedBox(height: 16),

          // Recommendations
          RecordFormSection(
            title: 'Recommendations',
            icon: Icons.recommend,
            accentColor: _primaryColor,
            collapsible: true,
            child: RecordTextField(
              controller: _recommendationsController,
              hint: 'Follow-up recommendations...',
              maxLines: 3,
              accentColor: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Reporting Details
          RecordFormSection(
            title: 'Reporting Details',
            icon: Icons.person_outline,
            accentColor: Colors.blueGrey,
            collapsible: true,
            initiallyExpanded: false,
            child: RecordFieldGrid(
              children: [
                CompactTextField(
                  controller: _radiologistController,
                  label: 'Radiologist',
                  hint: 'Name...',
                  accentColor: Colors.blueGrey,
                ),
                CompactTextField(
                  controller: _facilityController,
                  label: 'Facility',
                  hint: 'Name...',
                  accentColor: Colors.blueGrey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Clinical Notes
          RecordFormSection(
            title: 'Clinical Notes',
            icon: Icons.note_alt,
            accentColor: Colors.indigo,
            collapsible: true,
            initiallyExpanded: false,
            child: RecordNotesField(
              controller: _clinicalNotesController,
              label: '',
              hint: 'Additional clinical notes...',
              accentColor: Colors.indigo,
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          RecordActionButtons(
            onSave: () => _saveRecord(db),
            onCancel: () => Navigator.pop(context),
            saveLabel: widget.existingRecord != null ? 'Update Imaging Record' : 'Save Imaging Record',
            isLoading: _isSaving,
            canSave: _selectedPatientId != null,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuickFillSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                color: Colors.amber.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Fill Templates',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ImagingTemplates.templates.map((template) {
              return _buildQuickFillChip(
                label: template.label,
                icon: template.icon,
                color: template.color,
                onTap: () => _applyTemplate(template),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFillChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _applyTemplate(QuickFillTemplate template) {
    final data = template.data;
    
    _imagingTypeController.text = (data['imaging_type'] as String?) ?? '';
    _bodyPartController.text = (data['body_part'] as String?) ?? '';
    _indicationController.text = (data['indication'] as String?) ?? '';
    _techniqueController.text = (data['technique'] as String?) ?? '';
    _findingsController.text = (data['findings'] as String?) ?? '';
    _impressionController.text = (data['impression'] as String?) ?? '';
    _recommendationsController.text = (data['recommendations'] as String?) ?? '';
    
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('${template.label} template applied'),
          ],
        ),
        backgroundColor: template.color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
}