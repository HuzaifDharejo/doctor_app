import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/suggestions_service.dart';
import '../../widgets/suggestion_text_field.dart';
import 'components/record_components.dart';
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
  static const int _totalSections = 6;

  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'study_info': GlobalKey(),
    'technique': GlobalKey(),
    'findings': GlobalKey(),
    'impression': GlobalKey(),
    'reporting': GlobalKey(),
    'notes': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'study_info': true,
    'technique': true,
    'findings': true,
    'impression': true,
    'reporting': false,
    'notes': false,
  };

  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

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
    
    // Initialize imaging-specific templates
    _templates = [
      const QuickFillTemplateItem(
        label: 'Normal Chest X-ray',
        icon: Icons.image_rounded,
        color: Colors.indigo,
        description: 'Normal chest radiograph template',
        data: {
          'imaging_type': 'X-Ray',
          'body_part': 'Chest PA/Lateral',
          'indication': 'Evaluation for pneumonia / respiratory symptoms',
          'technique': 'Standard PA and lateral views obtained',
          'findings': 'Heart size normal. Lungs clear bilaterally. No pleural effusion. Costophrenic angles sharp. Bony thorax intact. No mediastinal widening.',
          'impression': 'Normal chest radiograph',
          'recommendations': 'No further imaging required at this time',
        },
      ),
      const QuickFillTemplateItem(
        label: 'Normal CT Head',
        icon: Icons.psychology_rounded,
        color: Colors.blue,
        description: 'Normal CT brain template',
        data: {
          'imaging_type': 'CT Scan',
          'body_part': 'Head / Brain',
          'indication': 'Headache / trauma evaluation',
          'technique': 'Non-contrast helical CT of the head',
          'findings': 'No acute intracranial hemorrhage. No mass effect or midline shift. Ventricles and sulci normal. Gray-white matter differentiation preserved. No bony abnormality.',
          'impression': 'Normal non-contrast CT head',
          'recommendations': 'Clinical correlation. If symptoms persist, consider MRI brain.',
        },
      ),
      const QuickFillTemplateItem(
        label: 'Normal USG Abdomen',
        icon: Icons.monitor_heart_rounded,
        color: Colors.teal,
        description: 'Normal abdominal ultrasound template',
        data: {
          'imaging_type': 'Ultrasound',
          'body_part': 'Abdomen Complete',
          'indication': 'Abdominal pain evaluation',
          'technique': 'Real-time gray scale imaging with color Doppler',
          'findings': 'Liver: Normal size and echogenicity. No focal lesion. Portal vein patent.\nGallbladder: Normal wall thickness. No calculi or polyps.\nPancreas: Normal.\nSpleen: Normal size.\nKidneys: Bilateral normal size, shape, and echogenicity. No hydronephrosis or calculi.\nBladder: Adequately distended, normal wall.',
          'impression': 'Normal abdominal ultrasound',
          'recommendations': 'No further imaging required',
        },
      ),
      const QuickFillTemplateItem(
        label: 'Normal MRI',
        icon: Icons.view_in_ar_rounded,
        color: Colors.deepPurple,
        description: 'Normal MRI brain template',
        data: {
          'imaging_type': 'MRI',
          'body_part': 'Brain',
          'indication': 'Headache / neurological symptoms evaluation',
          'technique': 'Multiplanar imaging with T1, T2, FLAIR, DWI sequences',
          'findings': 'No acute infarct or hemorrhage. Ventricles normal in size. No mass lesion. Gray-white matter differentiation preserved. No abnormal enhancement.',
          'impression': 'Normal MRI brain',
          'recommendations': 'Clinical correlation. Symptomatic management as needed.',
        },
      ),
      const QuickFillTemplateItem(
        label: 'Fracture X-ray',
        icon: Icons.healing_rounded,
        color: Colors.red,
        description: 'Fracture finding template',
        data: {
          'imaging_type': 'X-Ray',
          'body_part': 'Extremity',
          'indication': 'Trauma / suspected fracture',
          'technique': 'Standard AP and lateral views obtained',
          'findings': 'Fracture line identified. Alignment and position described. Soft tissue swelling present. No other bony abnormality.',
          'impression': 'Fracture identified - specify location and type',
          'recommendations': 'Orthopedic consultation. Immobilization. Follow-up X-ray in 2-4 weeks.',
        },
      ),
    ];
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    }
  }

  void _loadExistingRecord() async {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _clinicalNotesController.text = record.doctorNotes ?? '';
    
    // V6: Use normalized fields with fallback to dataJson
    final db = await ref.read(doctorDbProvider.future);
    final data = await db.getMedicalRecordFieldsCompat(record.id);
    if (data.isNotEmpty && mounted) {
      setState(() {
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
      });
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

  // Total sections for progress calculation

  int _calculateCompletedSections() {
    int completed = 0;
    if (_selectedPatientId != null || widget.preselectedPatient != null) completed++;
    if (_imagingTypeController.text.isNotEmpty) completed++;
    if (_bodyPartController.text.isNotEmpty) completed++;
    if (_findingsController.text.isNotEmpty) completed++;
    if (_impressionController.text.isNotEmpty) completed++;
    if (_clinicalNotesController.text.isNotEmpty) completed++;
    return completed;
  }

  void _applyTemplate(QuickFillTemplateItem template) {
    final data = template.data;
    setState(() {
      if (data['imaging_type'] != null) {
        _imagingTypeController.text = data['imaging_type'] as String;
      }
      if (data['body_part'] != null) {
        _bodyPartController.text = data['body_part'] as String;
      }
      if (data['indication'] != null) {
        _indicationController.text = data['indication'] as String;
      }
      if (data['technique'] != null) {
        _techniqueController.text = data['technique'] as String;
      }
      if (data['findings'] != null) {
        _findingsController.text = data['findings'] as String;
      }
      if (data['impression'] != null) {
        _impressionController.text = data['impression'] as String;
      }
      if (data['recommendations'] != null) {
        _recommendationsController.text = data['recommendations'] as String;
      }
    });
    showTemplateAppliedSnackbar(context, template.label, color: template.color);
  }

  void _scrollToSection(String sectionKey) {
    final key = _sectionKeys[sectionKey];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  List<SectionInfo> get _sections => [
    SectionInfo(
      key: 'study_info',
      title: 'Study Info',
      icon: Icons.camera_alt_outlined,
      isComplete: _imagingTypeController.text.isNotEmpty && _bodyPartController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'technique',
      title: 'Technique',
      icon: Icons.settings_outlined,
      isComplete: _techniqueController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'findings',
      title: 'Findings',
      icon: Icons.find_in_page,
      isComplete: _findingsController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'impression',
      title: 'Impression',
      icon: Icons.analytics,
      isComplete: _impressionController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'reporting',
      title: 'Reporting',
      icon: Icons.person_outline,
      isComplete: _radiologistController.text.isNotEmpty,
    ),
    SectionInfo(
      key: 'notes',
      title: 'Notes',
      icon: Icons.note_alt,
      isComplete: _clinicalNotesController.text.isNotEmpty,
    ),
  ];

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
      // V6: Build data for normalized storage
      final recordData = _buildDataJson();
      
      final companion = MedicalRecordsCompanion.insert(
        patientId: _selectedPatientId!,
        recordType: 'imaging',
        title: _imagingTypeController.text.isNotEmpty && _bodyPartController.text.isNotEmpty
            ? '${_imagingTypeController.text}: ${_bodyPartController.text}'
            : _imagingTypeController.text.isNotEmpty 
                ? _imagingTypeController.text
                : 'Imaging Study - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_findingsController.text),
        dataJson: const Value('{}'), // V6: Empty - using MedicalRecordFields
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
          dataJson: '{}', // V6: Empty - using MedicalRecordFields
          diagnosis: _impressionController.text,
          treatment: _recommendationsController.text,
          doctorNotes: _clinicalNotesController.text,
          recordDate: _recordDate,
          createdAt: widget.existingRecord!.createdAt,
        );
        await db.updateMedicalRecord(updatedRecord);
        // V6: Delete old fields and re-insert
        await db.deleteFieldsForMedicalRecord(widget.existingRecord!.id);
        await db.insertMedicalRecordFieldsBatch(widget.existingRecord!.id, _selectedPatientId!, recordData);
        resultRecord = updatedRecord;
      } else {
        final recordId = await db.insertMedicalRecord(companion);
        // V6: Save fields to normalized table
        await db.insertMedicalRecordFieldsBatch(recordId, _selectedPatientId!, recordData);
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Patient Selection / Info Card
          if (widget.preselectedPatient != null)
            PatientInfoCard(
              patient: widget.preselectedPatient!,
              gradientColors: _gradientColors,
              icon: Icons.image_rounded,
            )
          else
            PatientSelectorCard(
              db: db,
              selectedPatientId: _selectedPatientId,
              onChanged: (id) => setState(() => _selectedPatientId = id),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Date Picker
          DatePickerCard(
            selectedDate: _recordDate,
            onDateSelected: (date) => setState(() => _recordDate = date),
            label: 'Study Date',
            accentColor: _primaryColor,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Progress Indicator
          FormProgressIndicator(
            completedSections: _calculateCompletedSections(),
            totalSections: _totalSections,
            accentColor: _primaryColor,
          ),
          const SizedBox(height: AppSpacing.md),

          // Section Navigation Bar
          SectionNavigationBar(
            sections: _sections,
            onSectionTap: _scrollToSection,
            accentColor: _primaryColor,
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick Fill Templates (using new component)
          QuickFillTemplateBar(
            templates: _templates,
            onTemplateSelected: _applyTemplate,
            title: 'Common Imaging Studies',
            collapsible: true,
            initiallyExpanded: false,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Study Information Section
          RecordFormSection(
            key: _sectionKeys['study_info'],
            title: 'Study Information',
            icon: Icons.camera_alt_outlined,
            accentColor: const Color(0xFF7C3AED),
            collapsible: true,
            initiallyExpanded: _expandedSections['study_info'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['study_info'] = expanded),
            child: Column(
              children: [
                SuggestionTextField(
                  controller: _imagingTypeController,
                  label: 'Imaging Type',
                  hint: 'e.g., X-Ray, CT Scan, MRI...',
                  prefixIcon: Icons.image_outlined,
                  suggestions: MedicalRecordSuggestions.imagingTypes,
                ),
                const SizedBox(height: AppSpacing.md),
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
                const SizedBox(height: AppSpacing.md),
                RecordTextField(
                  controller: _indicationController,
                  hint: 'Clinical indication for study...',
                  maxLines: 2,
                  accentColor: const Color(0xFF7C3AED),
                  enableVoice: true,
                  suggestions: chiefComplaintSuggestions,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordFieldGrid(
                  children: [
                    StyledDropdown(
                      label: 'Urgency',
                      value: _urgency,
                      options: const ['Routine', 'Urgent', 'Emergency'],
                      onChanged: (v) {
                        if (v != null) setState(() => _urgency = v);
                      },
                      accentColor: _primaryColor,
                    ),
                    SwitchRow(
                      label: 'Contrast Used',
                      value: _contrastUsed,
                      onChanged: (v) => setState(() => _contrastUsed = v),
                      icon: Icons.opacity,
                      activeColor: _primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Technique Section
          RecordFormSection(
            key: _sectionKeys['technique'],
            title: 'Technique',
            icon: Icons.settings_outlined,
            accentColor: Colors.orange,
            collapsible: true,
            initiallyExpanded: _expandedSections['technique'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['technique'] = expanded),
            child: RecordTextField(
              controller: _techniqueController,
              hint: 'Describe imaging technique used...',
              maxLines: 3,
              accentColor: Colors.orange,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Findings Section
          RecordFormSection(
            key: _sectionKeys['findings'],
            title: 'Findings',
            icon: Icons.find_in_page,
            accentColor: Colors.teal,
            collapsible: true,
            initiallyExpanded: _expandedSections['findings'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['findings'] = expanded),
            child: SuggestionTextField(
              controller: _findingsController,
              label: 'Findings',
              hint: 'Describe imaging findings in detail...',
              prefixIcon: Icons.find_in_page_outlined,
              maxLines: 6,
              suggestions: investigationResultsSuggestions,
              separator: '. ',
              enableVoiceDictation: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Impression Section
          RecordFormSection(
            key: _sectionKeys['impression'],
            title: 'Impression / Diagnosis',
            icon: Icons.analytics,
            accentColor: Colors.purple,
            collapsible: true,
            initiallyExpanded: _expandedSections['impression'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['impression'] = expanded),
            child: Column(
              children: [
                RecordTextField(
                  controller: _impressionController,
                  hint: 'Radiological impression and diagnosis...',
                  maxLines: 4,
                  accentColor: Colors.purple,
                  enableVoice: true,
                  suggestions: diagnosisSuggestions,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(
                  controller: _recommendationsController,
                  hint: 'Follow-up recommendations...',
                  maxLines: 3,
                  accentColor: Colors.purple,
                  enableVoice: true,
                  suggestions: treatmentSuggestions,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Reporting Details Section
          RecordFormSection(
            key: _sectionKeys['reporting'],
            title: 'Reporting Details',
            icon: Icons.person_outline,
            accentColor: Colors.blueGrey,
            collapsible: true,
            initiallyExpanded: _expandedSections['reporting'] ?? false,
            onToggle: (expanded) => setState(() => _expandedSections['reporting'] = expanded),
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
          const SizedBox(height: AppSpacing.lg),

          // Clinical Notes Section
          RecordFormSection(
            key: _sectionKeys['notes'],
            title: 'Clinical Notes',
            icon: Icons.note_alt,
            accentColor: Colors.indigo,
            collapsible: true,
            initiallyExpanded: _expandedSections['notes'] ?? false,
            onToggle: (expanded) => setState(() => _expandedSections['notes'] = expanded),
            child: RecordNotesField(
              controller: _clinicalNotesController,
              label: '',
              hint: 'Additional clinical notes...',
              accentColor: Colors.indigo,
              enableVoice: true,
              suggestions: clinicalNotesSuggestions,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Action Buttons
          RecordActionButtons(
            onSave: () => _saveRecord(db),
            onCancel: () => Navigator.pop(context),
            saveLabel: widget.existingRecord != null ? 'Update Imaging Record' : 'Save Imaging Record',
            isLoading: _isSaving,
            canSave: _selectedPatientId != null,
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
