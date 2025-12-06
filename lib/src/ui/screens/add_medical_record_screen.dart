import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/suggestions_service.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_input.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../widgets/document_data_extractor.dart';
import '../widgets/suggestion_text_field.dart';

class AddMedicalRecordScreen extends ConsumerStatefulWidget {

  const AddMedicalRecordScreen({
    super.key,
    this.preselectedPatient,
    this.initialRecordType = 'general',
  });
  final Patient? preselectedPatient;
  final String initialRecordType;

  @override
  ConsumerState<AddMedicalRecordScreen> createState() => _AddMedicalRecordScreenState();
}

class _AddMedicalRecordScreenState extends ConsumerState<AddMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;
  bool _showDataExtractor = false;

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();
  String _recordType = 'general';
  final _descriptionController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _doctorNotesController = TextEditingController();

  // Psychiatric Assessment Fields
  final _symptomsController = TextEditingController();
  final _hopiController = TextEditingController();
  
  // MSE Fields
  final _appearanceController = TextEditingController();
  final _behaviorController = TextEditingController();
  final _speechController = TextEditingController();
  final _moodController = TextEditingController();
  final _affectController = TextEditingController();
  final _thoughtContentController = TextEditingController();
  final _thoughtProcessController = TextEditingController();
  final _perceptionController = TextEditingController();
  final _cognitionController = TextEditingController();
  final _insightController = TextEditingController();
  final _judgmentController = TextEditingController();

  // Risk Assessment
  String _suicidalRisk = 'None';
  String _homicidalRisk = 'None';
  final _riskNotesController = TextEditingController();

  // Vitals
  final _bpController = TextEditingController();
  final _pulseController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  
  // Vitals focus nodes
  final _bpFocus = FocusNode();
  final _pulseFocus = FocusNode();
  final _tempFocus = FocusNode();
  final _weightFocus = FocusNode();
  bool _bpFocused = false;
  bool _pulseFocused = false;
  bool _tempFocused = false;
  bool _weightFocused = false;

  // Lab Results Fields
  final _labTestNameController = TextEditingController();
  final _labResultController = TextEditingController();
  final _referenceRangeController = TextEditingController();

  // Imaging Fields
  final _imagingTypeController = TextEditingController();
  final _imagingFindingsController = TextEditingController();

  // Procedure Fields
  final _procedureNameController = TextEditingController();
  final _procedureNotesController = TextEditingController();

  // Follow-up Fields
  final _followUpNotesController = TextEditingController();

  // Pulmonary Evaluation Fields
  final _pulmonaryChiefComplaintController = TextEditingController();
  final _pulmonaryDurationController = TextEditingController();
  final _pulmonarySymptomCharacterController = TextEditingController();
  List<String> _selectedSystemicSymptoms = [];
  List<String> _selectedRedFlags = [];
  final _pastPulmonaryHistoryController = TextEditingController();
  final _exposureHistoryController = TextEditingController();
  final _allergyHistoryController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  List<String> _selectedComorbidities = [];
  // Chest Auscultation
  final _breathSoundsController = TextEditingController();
  List<String> _selectedAddedSounds = [];
  final _rightUpperZoneController = TextEditingController();
  final _rightMiddleZoneController = TextEditingController();
  final _rightLowerZoneController = TextEditingController();
  final _leftUpperZoneController = TextEditingController();
  final _leftMiddleZoneController = TextEditingController();
  final _leftLowerZoneController = TextEditingController();
  final _additionalFindingsController = TextEditingController();
  // Pulmonary-specific vitals
  final _respiratoryRateController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _peakFlowController = TextEditingController();
  // Investigations & Plan
  List<String> _selectedInvestigations = [];
  final _followUpPlanController = TextEditingController();

  final List<String> _recordTypes = [
    'general',
    'pulmonary_evaluation',
    'psychiatric_assessment',
    'lab_result',
    'imaging',
    'procedure',
    'follow_up',
  ];

  final Map<String, String> _recordTypeLabels = {
    'general': 'General Consultation',
    'pulmonary_evaluation': 'Pulmonary Evaluation',
    'psychiatric_assessment': 'Quick Psychiatric Assessment',
    'lab_result': 'Lab Result',
    'imaging': 'Imaging/Radiology',
    'procedure': 'Procedure',
    'follow_up': 'Follow-up Visit',
  };

  final Map<String, IconData> _recordTypeIcons = {
    'general': Icons.medical_services_outlined,
    'pulmonary_evaluation': Icons.air,
    'psychiatric_assessment': Icons.psychology,
    'lab_result': Icons.science_outlined,
    'imaging': Icons.image_outlined,
    'procedure': Icons.healing_outlined,
    'follow_up': Icons.event_repeat,
  };

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    _recordType = widget.initialRecordType;
  }

  void _applyExtractedData(Map<String, String> data) {
    setState(() {
      // Apply extracted data to relevant fields
      if (data.containsKey('diagnosis')) {
        _diagnosisController.text = data['diagnosis']!;
      }
      if (data.containsKey('treatment')) {
        _treatmentController.text = data['treatment']!;
      }
      if (data.containsKey('blood_pressure')) {
        _bpController.text = data['blood_pressure']!;
      }
      if (data.containsKey('pulse')) {
        _pulseController.text = data['pulse']!;
      }
      if (data.containsKey('temperature')) {
        _tempController.text = data['temperature']!;
      }
      if (data.containsKey('weight')) {
        _weightController.text = data['weight']!;
      }
      
      // Lab result fields
      if (data.containsKey('test_name')) {
        _labTestNameController.text = data['test_name']!;
      }
      if (data.containsKey('result')) {
        _labResultController.text = data['result']!;
      }
      if (data.containsKey('reference_range')) {
        _referenceRangeController.text = data['reference_range']!;
      }

      // If full text is available and description is empty, use it
      if (data.containsKey('full_text') && _descriptionController.text.isEmpty) {
        // Don't fill with full text, it's too long
      }

      _showDataExtractor = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Data applied to form fields'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _descriptionController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _doctorNotesController.dispose();
    _symptomsController.dispose();
    _hopiController.dispose();
    _appearanceController.dispose();
    _behaviorController.dispose();
    _speechController.dispose();
    _moodController.dispose();
    _affectController.dispose();
    _thoughtContentController.dispose();
    _thoughtProcessController.dispose();
    _perceptionController.dispose();
    _cognitionController.dispose();
    _insightController.dispose();
    _judgmentController.dispose();
    _riskNotesController.dispose();
    _bpController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _bpFocus.dispose();
    _pulseFocus.dispose();
    _tempFocus.dispose();
    _weightFocus.dispose();
    _labTestNameController.dispose();
    _labResultController.dispose();
    _referenceRangeController.dispose();
    _imagingTypeController.dispose();
    _imagingFindingsController.dispose();
    _procedureNameController.dispose();
    _procedureNotesController.dispose();
    _followUpNotesController.dispose();
    // Pulmonary evaluation controllers
    _pulmonaryChiefComplaintController.dispose();
    _pulmonaryDurationController.dispose();
    _pulmonarySymptomCharacterController.dispose();
    _pastPulmonaryHistoryController.dispose();
    _exposureHistoryController.dispose();
    _allergyHistoryController.dispose();
    _currentMedicationsController.dispose();
    _breathSoundsController.dispose();
    _rightUpperZoneController.dispose();
    _rightMiddleZoneController.dispose();
    _rightLowerZoneController.dispose();
    _leftUpperZoneController.dispose();
    _leftMiddleZoneController.dispose();
    _leftLowerZoneController.dispose();
    _additionalFindingsController.dispose();
    _respiratoryRateController.dispose();
    _spo2Controller.dispose();
    _peakFlowController.dispose();
    _followUpPlanController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    switch (_recordType) {
      case 'pulmonary_evaluation':
        return {
          'chief_complaint': _pulmonaryChiefComplaintController.text,
          'duration': _pulmonaryDurationController.text,
          'symptom_character': _pulmonarySymptomCharacterController.text,
          'systemic_symptoms': _selectedSystemicSymptoms,
          'red_flags': _selectedRedFlags,
          'past_pulmonary_history': _pastPulmonaryHistoryController.text,
          'exposure_history': _exposureHistoryController.text,
          'allergy_atopy_history': _allergyHistoryController.text,
          'current_medications': _currentMedicationsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'comorbidities': _selectedComorbidities,
          'chest_auscultation': {
            'breath_sounds': _breathSoundsController.text,
            'added_sounds': _selectedAddedSounds,
            'right_upper_zone': _rightUpperZoneController.text,
            'right_middle_zone': _rightMiddleZoneController.text,
            'right_lower_zone': _rightLowerZoneController.text,
            'left_upper_zone': _leftUpperZoneController.text,
            'left_middle_zone': _leftMiddleZoneController.text,
            'left_lower_zone': _leftLowerZoneController.text,
            'additional_findings': _additionalFindingsController.text,
          },
          'investigations_required': _selectedInvestigations,
          'follow_up_plan': _followUpPlanController.text,
          'vitals': {
            'bp': _bpController.text,
            'pulse': _pulseController.text,
            'temperature': _tempController.text,
            'respiratory_rate': _respiratoryRateController.text,
            'spo2': _spo2Controller.text,
            'peak_flow_rate': _peakFlowController.text,
            'weight': _weightController.text,
          },
        };
      case 'psychiatric_assessment':
        return {
          'symptoms': _symptomsController.text,
          'hopi': _hopiController.text,
          'mse': {
            'appearance': _appearanceController.text,
            'behavior': _behaviorController.text,
            'speech': _speechController.text,
            'mood': _moodController.text,
            'affect': _affectController.text,
            'thought_content': _thoughtContentController.text,
            'thought_process': _thoughtProcessController.text,
            'perception': _perceptionController.text,
            'cognition': _cognitionController.text,
            'insight': _insightController.text,
            'judgment': _judgmentController.text,
          },
          'risk_assessment': {
            'suicidal_risk': _suicidalRisk,
            'homicidal_risk': _homicidalRisk,
            'notes': _riskNotesController.text,
          },
          'vitals': {
            'bp': _bpController.text,
            'pulse': _pulseController.text,
            'temperature': _tempController.text,
            'weight': _weightController.text,
          },
        };
      case 'lab_result':
        return {
          'test_name': _labTestNameController.text,
          'result': _labResultController.text,
          'reference_range': _referenceRangeController.text,
        };
      case 'imaging':
        return {
          'imaging_type': _imagingTypeController.text,
          'findings': _imagingFindingsController.text,
        };
      case 'procedure':
        return {
          'procedure_name': _procedureNameController.text,
          'procedure_notes': _procedureNotesController.text,
          'vitals': {
            'bp': _bpController.text,
            'pulse': _pulseController.text,
            'temperature': _tempController.text,
            'weight': _weightController.text,
          },
        };
      case 'follow_up':
        return {
          'follow_up_notes': _followUpNotesController.text,
          'vitals': {
            'bp': _bpController.text,
            'pulse': _pulseController.text,
            'temperature': _tempController.text,
            'weight': _weightController.text,
          },
        };
      default:
        return {
          'chief_complaints': _descriptionController.text,
          'vitals': {
            'bp': _bpController.text,
            'pulse': _pulseController.text,
            'temperature': _tempController.text,
            'weight': _weightController.text,
          },
        };
    }
  }

  Future<void> _saveMedicalRecord(DoctorDatabase db) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a patient'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final recordId = await db.insertMedicalRecord(MedicalRecordsCompanion.insert(
        patientId: _selectedPatientId!,
        recordType: _recordType,
        title: _diagnosisController.text.isNotEmpty 
            ? '${_recordTypeLabels[_recordType] ?? 'Record'}: ${_diagnosisController.text}'
            : '${_recordTypeLabels[_recordType] ?? 'Medical Record'} - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_descriptionController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_diagnosisController.text),
        treatment: Value(_treatmentController.text),
        doctorNotes: Value(_doctorNotesController.text),
        recordDate: _recordDate,
      ),);

      // Fetch the created medical record to return it
      final createdRecord = await db.getMedicalRecordById(recordId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Medical record saved successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, createdRecord);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      children: [
                        // Custom App Bar
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Add Medical Record',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 40), // Balance the back button
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Record Icon
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_information_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Body Content
            SliverPadding(
              padding: EdgeInsets.all(padding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFormContent(context, db),
                ]),
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, DoctorDatabase db) {
    return Form(
      key: _formKey,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Record Type Selection
            _buildRecordTypeSelector(),
            const SizedBox(height: 20),

            // Patient Selection
            _buildSectionHeader('Patient', Icons.person_outline),
            const SizedBox(height: 12),
            _buildPatientSelector(db),
            const SizedBox(height: 20),

            // Date Selection
            _buildSectionHeader('Record Date', Icons.calendar_today),
            const SizedBox(height: 12),
            _buildDateSelector(),
            const SizedBox(height: 20),

            // Document Data Extractor Toggle/Widget
            _buildExtractFromDocumentSection(),
            const SizedBox(height: 20),

            // Type-specific fields
            _buildTypeSpecificFields(),

            // Common fields
            _buildSectionHeader('Diagnosis', Icons.medical_information),
            const SizedBox(height: 12),
            SuggestionTextField(
              controller: _diagnosisController,
              label: 'Diagnosis',
              hint: 'Enter diagnosis...',
              prefixIcon: Icons.medical_information_outlined,
              maxLines: 3,
              suggestions: MedicalSuggestions.diagnoses,
            ),
            const SizedBox(height: 20),

            _buildSectionHeader('Treatment Plan', Icons.healing),
            const SizedBox(height: 12),
            SuggestionTextField(
              controller: _treatmentController,
              label: 'Treatment',
              hint: 'Enter treatment plan...',
              prefixIcon: Icons.healing_outlined,
              maxLines: 3,
              suggestions: PrescriptionSuggestions.instructions,
              separator: '\n',
            ),
            const SizedBox(height: 20),

            _buildSectionHeader("Doctor's Notes", Icons.note_alt),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _doctorNotesController,
              hint: 'Additional notes...',
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Save Button
            _buildSaveButton(db),
            const SizedBox(height: 40),
          ],
        ),
    );
  }

  Widget _buildRecordTypeSelector() {
    final appSettingsService = ref.watch(appSettingsProvider);
    final enabledTypes = appSettingsService.settings.enabledMedicalRecordTypes;
    final filteredTypes = _recordTypes.where(enabledTypes.contains).toList();
    
    // If current record type is not in enabled types, switch to first enabled type
    if (!enabledTypes.contains(_recordType) && filteredTypes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _recordType = filteredTypes.first);
      });
    }
    
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Record Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (filteredTypes.length < _recordTypes.length)
                    Text(
                      '${filteredTypes.length}/${_recordTypes.length} enabled',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filteredTypes.map((type) {
                  final isSelected = _recordType == type;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _recordTypeIcons[type],
                          size: 16,
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 6),
                        Text(_recordTypeLabels[type] ?? type),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _recordType = type);
                      }
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : (isDark ? AppColors.darkDivider : AppColors.divider),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientSelector(DoctorDatabase db) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return FutureBuilder<List<Patient>>(
          future: db.getAllPatients(),
          builder: (context, snapshot) {
            final patients = snapshot.data ?? [];
            
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
              ),
              child: DropdownButtonFormField<int>(
                initialValue: _selectedPatientId,
                decoration: InputDecoration(
                  hintText: 'Select a patient',
                  prefixIcon: Icon(Icons.person_search_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
                items: patients.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.firstName} ${p.lastName}'),
                ),).toList(),
                onChanged: (value) {
                  setState(() => _selectedPatientId = value);
                },
                validator: (value) => value == null ? 'Please select a patient' : null,
                dropdownColor: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _recordDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _recordDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_recordDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.edit, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExtractFromDocumentSection() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        if (_showDataExtractor) {
          return DocumentDataExtractor(
            onDataExtracted: _applyExtractedData,
            onClose: () => setState(() => _showDataExtractor = false),
          );
        }

        return GestureDetector(
          onTap: () => setState(() => _showDataExtractor = true),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.document_scanner,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extract from Document',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan image or PDF to auto-fill fields',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (_recordType) {
      case 'pulmonary_evaluation':
        return _buildPulmonaryEvaluationFields();
      case 'psychiatric_assessment':
        return _buildPsychiatricAssessmentFields();
      case 'lab_result':
        return _buildLabResultFields();
      case 'imaging':
        return _buildImagingFields();
      case 'procedure':
        return _buildProcedureFields();
      case 'follow_up':
        return _buildFollowUpFields();
      default:
        return _buildGeneralFields();
    }
  }

  Widget _buildPsychiatricAssessmentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Presenting Symptoms
        _buildSectionHeader('Presenting Symptoms', Icons.sick_outlined),
        const SizedBox(height: 12),
        SuggestionTextField(
          controller: _symptomsController,
          label: 'Symptoms',
          hint: 'Describe presenting symptoms and chief complaints...',
          prefixIcon: Icons.sick_outlined,
          maxLines: 4,
          suggestions: MedicalSuggestions.symptoms,
        ),
        const SizedBox(height: 20),

        // History of Present Illness
        _buildSectionHeader('History of Present Illness (HOPI)', Icons.history),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _hopiController,
          hint: 'Detailed history of the current illness...',
          maxLines: 5,
        ),
        const SizedBox(height: 20),

        // Mental State Examination
        _buildSectionCard(
          title: 'Mental State Examination (MSE)',
          icon: Icons.psychology,
          children: [
            Row(
              children: [
                Expanded(child: _buildMSEField(_appearanceController, 'Appearance', MedicalRecordSuggestions.mseAppearance)),
                const SizedBox(width: 12),
                Expanded(child: _buildMSEField(_behaviorController, 'Behavior', MedicalRecordSuggestions.mseBehavior)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMSEField(_speechController, 'Speech', MedicalRecordSuggestions.mseSpeech)),
                const SizedBox(width: 12),
                Expanded(child: _buildMSEField(_moodController, 'Mood', MedicalRecordSuggestions.mseMood)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMSEField(_affectController, 'Affect', MedicalRecordSuggestions.mseAffect)),
                const SizedBox(width: 12),
                Expanded(child: _buildMSEField(_perceptionController, 'Perception', MedicalRecordSuggestions.msePerception)),
              ],
            ),
            const SizedBox(height: 12),
            _buildMSEField(_thoughtContentController, 'Thought Content', MedicalRecordSuggestions.mseThoughtContent),
            const SizedBox(height: 12),
            _buildMSEField(_thoughtProcessController, 'Thought Process', MedicalRecordSuggestions.mseThoughtProcess),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMSEField(_cognitionController, 'Cognition', MedicalRecordSuggestions.mseCognition)),
                const SizedBox(width: 12),
                Expanded(child: _buildMSEField(_insightController, 'Insight', MedicalRecordSuggestions.mseInsight)),
              ],
            ),
            const SizedBox(height: 12),
            _buildMSEField(_judgmentController, 'Judgment', MedicalRecordSuggestions.mseJudgment),
          ],
        ),
        const SizedBox(height: 20),

        // Risk Assessment
        _buildSectionCard(
          title: 'Risk Assessment',
          icon: Icons.warning_amber_rounded,
          children: [
            _buildRiskSelector('Suicidal Risk', _suicidalRisk, (value) {
              setState(() => _suicidalRisk = value);
            }),
            const SizedBox(height: 12),
            _buildRiskSelector('Homicidal Risk', _homicidalRisk, (value) {
              setState(() => _homicidalRisk = value);
            }),
            const SizedBox(height: 12),
            _buildCompactField(_riskNotesController, 'Risk Notes'),
          ],
        ),
        const SizedBox(height: 20),

        // Vitals
        _buildVitalsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPulmonaryEvaluationFields() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chief Complaint & Duration
        _buildSectionHeader('Presenting Complaint', Icons.air),
        const SizedBox(height: 12),
        SuggestionTextField(
          controller: _pulmonaryChiefComplaintController,
          label: 'Chief Complaint',
          hint: 'Describe the main respiratory complaint...',
          prefixIcon: Icons.air,
          maxLines: 2,
          suggestions: PulmonarySuggestions.chiefComplaints,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SuggestionTextField(
                controller: _pulmonaryDurationController,
                label: 'Duration',
                hint: 'How long?',
                prefixIcon: Icons.schedule,
                suggestions: PulmonarySuggestions.durations,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SuggestionTextField(
                controller: _pulmonarySymptomCharacterController,
                label: 'Symptom Character',
                hint: 'Type of cough/symptom',
                prefixIcon: Icons.description_outlined,
                suggestions: PulmonarySuggestions.symptomCharacters,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Systemic Symptoms (Chips)
        _buildSectionHeader('Systemic Symptoms', Icons.thermostat_outlined),
        const SizedBox(height: 12),
        _buildChipSelector(
          label: 'Select systemic symptoms',
          options: PulmonarySuggestions.systemicSymptoms,
          selectedOptions: _selectedSystemicSymptoms,
          onChanged: (selected) => setState(() => _selectedSystemicSymptoms = selected),
          color: AppColors.warning,
        ),
        const SizedBox(height: 20),

        // Red Flags (Chips with red color)
        _buildSectionHeader('Red Flags', Icons.warning_amber_rounded),
        const SizedBox(height: 12),
        _buildChipSelector(
          label: 'Select any red flags present',
          options: PulmonarySuggestions.redFlags,
          selectedOptions: _selectedRedFlags,
          onChanged: (selected) => setState(() => _selectedRedFlags = selected),
          color: AppColors.error,
        ),
        const SizedBox(height: 20),

        // History Section
        _buildSectionCard(
          title: 'Clinical History',
          icon: Icons.history,
          children: [
            SuggestionTextField(
              controller: _pastPulmonaryHistoryController,
              label: 'Past Pulmonary History',
              hint: 'Previous respiratory conditions...',
              prefixIcon: Icons.history,
              maxLines: 2,
              suggestions: PulmonarySuggestions.pastPulmonaryHistory,
            ),
            const SizedBox(height: 12),
            SuggestionTextField(
              controller: _exposureHistoryController,
              label: 'Exposure History',
              hint: 'Smoking, occupational, environmental...',
              prefixIcon: Icons.smoke_free,
              maxLines: 2,
              suggestions: PulmonarySuggestions.exposureHistory,
            ),
            const SizedBox(height: 12),
            SuggestionTextField(
              controller: _allergyHistoryController,
              label: 'Allergy/Atopy History',
              hint: 'Allergies, eczema, rhinitis...',
              prefixIcon: Icons.spa_outlined,
              maxLines: 2,
              suggestions: PulmonarySuggestions.allergyHistory,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _currentMedicationsController,
              hint: 'Current medications (comma-separated)...',
              maxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Comorbidities (Chips)
        _buildSectionHeader('Comorbidities', Icons.medical_services_outlined),
        const SizedBox(height: 12),
        _buildChipSelector(
          label: 'Select comorbidities',
          options: PulmonarySuggestions.comorbidities,
          selectedOptions: _selectedComorbidities,
          onChanged: (selected) => setState(() => _selectedComorbidities = selected),
          color: AppColors.info,
        ),
        const SizedBox(height: 20),

        // Pulmonary Vitals
        _buildSectionCard(
          title: 'Vital Signs',
          icon: Icons.favorite_border,
          children: [
            Row(
              children: [
                Expanded(child: _buildVitalField(_bpController, 'BP', 'mmHg', _bpFocus, _bpFocused, (v) => setState(() => _bpFocused = v))),
                const SizedBox(width: 12),
                Expanded(child: _buildVitalField(_pulseController, 'Pulse', 'bpm', _pulseFocus, _pulseFocused, (v) => setState(() => _pulseFocused = v))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildVitalField(_tempController, 'Temp', '°F', _tempFocus, _tempFocused, (v) => setState(() => _tempFocused = v))),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSimpleVitalField(_respiratoryRateController, 'RR', '/min'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSimpleVitalField(_spo2Controller, 'SpO₂', '%'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSimpleVitalField(_peakFlowController, 'PEFR', 'L/min'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildVitalField(_weightController, 'Weight', 'kg', _weightFocus, _weightFocused, (v) => setState(() => _weightFocused = v)),
          ],
        ),
        const SizedBox(height: 20),

        // Chest Auscultation
        _buildSectionCard(
          title: 'Chest Auscultation',
          icon: Icons.hearing,
          children: [
            SuggestionTextField(
              controller: _breathSoundsController,
              label: 'Breath Sounds',
              hint: 'Type of breath sounds...',
              prefixIcon: Icons.hearing,
              suggestions: PulmonarySuggestions.breathSounds,
            ),
            const SizedBox(height: 12),
            Text(
              'Added Sounds',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildChipSelector(
              label: 'Select added sounds',
              options: PulmonarySuggestions.addedSounds,
              selectedOptions: _selectedAddedSounds,
              onChanged: (selected) => setState(() => _selectedAddedSounds = selected),
              color: AppColors.accent,
            ),
            const SizedBox(height: 16),
            Text(
              'Zone-wise Findings',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Right lung zones
            Row(
              children: [
                Expanded(
                  child: SuggestionTextField(
                    controller: _rightUpperZoneController,
                    label: 'R. Upper',
                    hint: 'Findings...',
                    suggestions: PulmonarySuggestions.zoneFindings,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SuggestionTextField(
                    controller: _leftUpperZoneController,
                    label: 'L. Upper',
                    hint: 'Findings...',
                    suggestions: PulmonarySuggestions.zoneFindings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SuggestionTextField(
                    controller: _rightMiddleZoneController,
                    label: 'R. Middle',
                    hint: 'Findings...',
                    suggestions: PulmonarySuggestions.zoneFindings,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SuggestionTextField(
                    controller: _leftMiddleZoneController,
                    label: 'L. Middle',
                    hint: 'Findings...',
                    suggestions: PulmonarySuggestions.zoneFindings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SuggestionTextField(
                    controller: _rightLowerZoneController,
                    label: 'R. Lower',
                    hint: 'Findings...',
                    suggestions: PulmonarySuggestions.zoneFindings,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SuggestionTextField(
                    controller: _leftLowerZoneController,
                    label: 'L. Lower',
                    hint: 'Findings...',
                    suggestions: PulmonarySuggestions.zoneFindings,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _additionalFindingsController,
              hint: 'Additional auscultation findings...',
              maxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Investigations Required (Chips)
        _buildSectionHeader('Investigations Required', Icons.biotech),
        const SizedBox(height: 12),
        _buildChipSelector(
          label: 'Select investigations to order',
          options: PulmonarySuggestions.investigations,
          selectedOptions: _selectedInvestigations,
          onChanged: (selected) => setState(() => _selectedInvestigations = selected),
        ),
        const SizedBox(height: 20),

        // Follow-up Plan
        _buildSectionHeader('Follow-up Plan', Icons.event_note),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _followUpPlanController,
          hint: 'Follow-up instructions and plan...',
          maxLines: 3,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChipSelector({
    required String label,
    required List<String> options,
    required List<String> selectedOptions,
    required void Function(List<String>) onChanged,
    Color color = AppColors.primary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final isSelected = selectedOptions.contains(option);
          return FilterChip(
            label: Text(
              option,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              final newList = List<String>.from(selectedOptions);
              if (selected) {
                newList.add(option);
              } else {
                newList.remove(option);
              }
              onChanged(newList);
            },
            selectedColor: color,
            checkmarkColor: Colors.white,
            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? color : Colors.transparent,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSimpleVitalField(TextEditingController controller, String label, String unit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '---',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Vital field with focus tracking for animated suggestions
  Widget _buildVitalField(
    TextEditingController controller,
    String label,
    String unit,
    FocusNode focusNode,
    bool isFocused,
    ValueChanged<bool> onFocusChange,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused 
            ? AppColors.primary.withValues(alpha: 0.5) 
            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: Focus(
        onFocusChange: onFocusChange,
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '---',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chief Complaints
        _buildSectionHeader('Chief Complaints', Icons.sick_outlined),
        const SizedBox(height: 12),
        SuggestionTextField(
          controller: _descriptionController,
          label: 'Chief Complaints',
          hint: 'Describe presenting complaints...',
          prefixIcon: Icons.sick_outlined,
          maxLines: 3,
          suggestions: MedicalSuggestions.chiefComplaints,
        ),
        const SizedBox(height: 20),

        // Vitals
        _buildVitalsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLabResultFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Lab Test Details', Icons.science),
        const SizedBox(height: 12),
        SuggestionTextField(
          controller: _labTestNameController,
          label: 'Test Name',
          hint: 'Select or type test name...',
          prefixIcon: Icons.science_outlined,
          suggestions: MedicalRecordSuggestions.labTestNames,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _labResultController,
          hint: 'Result values...',
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        SuggestionTextField(
          controller: _referenceRangeController,
          label: 'Reference Range',
          hint: 'Normal range...',
          prefixIcon: Icons.straighten_outlined,
          suggestions: MedicalRecordSuggestions.referenceRanges,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildImagingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Imaging Study', Icons.image_outlined),
        const SizedBox(height: 12),
        SuggestionTextField(
          controller: _imagingTypeController,
          label: 'Imaging Type',
          hint: 'Select or type imaging study...',
          prefixIcon: Icons.image_outlined,
          suggestions: MedicalRecordSuggestions.imagingTypes,
        ),
        const SizedBox(height: 16),
        SuggestionTextField(
          controller: _imagingFindingsController,
          label: 'Findings',
          hint: 'Describe imaging findings...',
          prefixIcon: Icons.find_in_page_outlined,
          maxLines: 5,
          suggestions: MedicalRecordSuggestions.imagingFindings,
          separator: '. ',
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProcedureFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Procedure Details', Icons.healing_outlined),
        const SizedBox(height: 12),
        SuggestionTextField(
          controller: _procedureNameController,
          label: 'Procedure Name',
          hint: 'Select or type procedure...',
          prefixIcon: Icons.healing_outlined,
          suggestions: MedicalRecordSuggestions.procedureNames,
        ),
        const SizedBox(height: 16),
        SuggestionTextField(
          controller: _procedureNotesController,
          label: 'Procedure Notes',
          hint: 'Describe the procedure and findings...',
          prefixIcon: Icons.note_alt_outlined,
          maxLines: 5,
          suggestions: MedicalRecordSuggestions.procedureNotes,
          separator: '. ',
        ),
        const SizedBox(height: 20),

        // Vitals
        _buildVitalsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFollowUpFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chief Complaints / Progress
        _buildSectionHeader('Follow-up Notes', Icons.event_repeat),
        const SizedBox(height: 12),
        SuggestionTextField(
          controller: _followUpNotesController,
          label: 'Progress & Notes',
          hint: 'Patient progress and notes...',
          prefixIcon: Icons.trending_up_outlined,
          maxLines: 5,
          suggestions: MedicalRecordSuggestions.followUpNotes,
          separator: '. ',
        ),
        const SizedBox(height: 20),

        // Vitals
        _buildVitalsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  // Temperature unit state
  bool _isCelsius = false;

  Widget _buildVitalsSection() {
    return _buildSectionCard(
      title: 'Vitals',
      icon: Icons.favorite_outline,
      children: [
        Row(
          children: [
            Expanded(child: _buildVitalFieldWithSuggestions(
              controller: _bpController,
              label: 'BP (mmHg)',
              focusNode: _bpFocus,
              isFocused: _bpFocused,
              onFocusChange: (f) => setState(() => _bpFocused = f),
              suggestions: MedicalSuggestions.bloodPressure,
            ),),
            const SizedBox(width: 12),
            Expanded(child: _buildVitalFieldWithSuggestions(
              controller: _pulseController,
              label: 'Pulse (bpm)',
              focusNode: _pulseFocus,
              isFocused: _pulseFocused,
              onFocusChange: (f) => setState(() => _pulseFocused = f),
              suggestions: MedicalSuggestions.pulseRate,
            ),),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildVitalFieldWithSuggestions(
                    controller: _tempController,
                    label: 'Temp (${_isCelsius ? '°C' : '°F'})',
                    focusNode: _tempFocus,
                    isFocused: _tempFocused,
                    onFocusChange: (f) => setState(() => _tempFocused = f),
                    suggestions: _isCelsius 
                        ? MedicalSuggestions.temperatureCelsius
                        : MedicalSuggestions.temperatureFahrenheit,
                  ),),
                  const SizedBox(width: 4),
                  // Temperature unit toggle
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _isCelsius = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: !_isCelsius ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '°F',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: !_isCelsius ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _isCelsius = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: _isCelsius ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '°C',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _isCelsius ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildVitalFieldWithSuggestions(
              controller: _weightController,
              label: 'Weight (kg)',
              focusNode: _weightFocus,
              isFocused: _weightFocused,
              onFocusChange: (f) => setState(() => _weightFocused = f),
              suggestions: MedicalSuggestions.weightKg,
            ),),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalFieldWithSuggestions({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
    required bool isFocused,
    required ValueChanged<bool> onFocusChange,
    required List<String> suggestions,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Focus(
              onFocusChange: onFocusChange,
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: label,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBackground : AppColors.background,
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: isFocused
                  ? Container(
                      margin: const EdgeInsets.only(top: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: suggestions.map((s) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                controller.text = s;
                                setState(() {});
                                Future.delayed(const Duration(milliseconds: 50), () {
                                  focusNode.requestFocus();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(s, style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                          ),).toList(),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRiskSelector(String label, String value, void Function(String) onChanged) {
    final risks = ['None', 'Low', 'Moderate', 'High'];
    
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: risks.map((risk) {
                final isSelected = value == risk;
                Color chipColor;
                switch (risk) {
                  case 'High':
                    chipColor = AppColors.error;
                  case 'Moderate':
                    chipColor = AppColors.warning;
                  case 'Low':
                    chipColor = AppColors.info;
                  default:
                    chipColor = AppColors.success;
                }
                
                return ChoiceChip(
                  label: Text(risk),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) onChanged(risk);
                  },
                  selectedColor: chipColor.withValues(alpha: 0.2),
                  backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
                  labelStyle: TextStyle(
                    color: isSelected ? chipColor : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? chipColor : (isDark ? AppColors.darkDivider : AppColors.divider),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return maxLines > 1
        ? AppInput.multiline(
            controller: controller,
            hint: hint,
            maxLines: maxLines,
          )
        : AppInput.text(
            controller: controller,
            hint: hint,
          );
  }

  Widget _buildMSEField(TextEditingController controller, String label, List<String> suggestions) {
    return SuggestionTextField(
      controller: controller,
      label: label,
      suggestions: suggestions,
      appendMode: false,
    );
  }

  Widget _buildCompactField(TextEditingController controller, String label) {
    return AppInput.text(
      controller: controller,
      label: label,
    );
  }

  Widget _buildSaveButton(DoctorDatabase db) {
    return Builder(
      builder: (context) {
        return AppButton.gradient(
          label: 'Save Medical Record',
          icon: Icons.save_outlined,
          onPressed: _isSaving ? null : () => _saveMedicalRecord(db),
          isLoading: _isSaving,
          fullWidth: true,
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
        );
      },
    );
  }
}

