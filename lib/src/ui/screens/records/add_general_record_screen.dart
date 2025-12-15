import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/dynamic_suggestions_service.dart';
import '../../../services/suggestions_service.dart';
import '../../widgets/suggestion_text_field.dart';
import 'components/record_components.dart';
import 'record_form_widgets.dart';

/// Screen for adding a General Consultation medical record
/// Refactored to use reusable components for cleaner, more maintainable code
class AddGeneralRecordScreen extends ConsumerStatefulWidget {
  const AddGeneralRecordScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
    this.encounterId,
    this.appointmentId,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;
  /// Associated encounter ID from workflow - links the record to a visit
  final int? encounterId;
  /// Associated appointment ID from workflow
  final int? appointmentId;

  @override
  ConsumerState<AddGeneralRecordScreen> createState() => _AddGeneralRecordScreenState();
}

class _AddGeneralRecordScreenState extends ConsumerState<AddGeneralRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _vitalsKey = GlobalKey<VitalsInputSectionState>();
  bool _isSaving = false;

  // Auto-save state
  Timer? _autoSaveTimer;
  DateTime? _lastSaved;
  bool _isAutoSaving = false;
  static const _autoSaveInterval = Duration(seconds: 30);

  // Theme colors for this record type
  static const _primaryColor = Color(0xFF10B981); // Clinical Green
  static const _secondaryColor = Color(0xFF059669);
  static const _gradientColors = [_primaryColor, _secondaryColor];

  // Section navigation keys and expansion state
  final Map<String, GlobalKey> _sectionKeys = {
    'patient': GlobalKey(),
    'details': GlobalKey(),
    'complaints': GlobalKey(),
    'history': GlobalKey(),
    'vitals': GlobalKey(),
    'examination': GlobalKey(),
    'notes': GlobalKey(),
  };
  final Map<String, bool> _expandedSections = {
    'patient': true,
    'details': true,
    'complaints': true,
    'history': true,
    'vitals': true,
    'examination': false,
    'notes': false,
  };

  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();

  // General consultation specific fields
  final _chiefComplaintsController = TextEditingController();
  final _historyController = TextEditingController();
  final _examinationController = TextEditingController();
  final _doctorNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    
    // Initialize general consultation templates
    _templates = [
      QuickFillTemplateItem(
        label: 'General Consultation',
        icon: Icons.medical_services_rounded,
        color: _primaryColor,
        description: 'Standard general consultation template',
        data: {
          'chief_complaints': 'Patient presents for general consultation.',
          'history': 'No significant past medical history.',
          'examination': 'General examination unremarkable. Patient appears well.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Follow-up Visit',
        icon: Icons.event_repeat_rounded,
        color: Colors.amber,
        description: 'Routine follow-up visit template',
        data: {
          'chief_complaints': 'Patient returns for follow-up as scheduled.',
          'history': 'Previous treatment reviewed. Compliance confirmed.',
          'examination': 'Examination shows improvement from previous visit.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Sick Visit',
        icon: Icons.sick_rounded,
        color: Colors.orange,
        description: 'Acute illness visit template',
        data: {
          'chief_complaints': 'Patient presents with acute symptoms.',
          'history': 'Onset of symptoms noted. Duration and severity assessed.',
          'examination': 'Focused examination performed based on presenting complaint.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Preventive Check',
        icon: Icons.health_and_safety_rounded,
        color: Colors.blue,
        description: 'Preventive health check template',
        data: {
          'chief_complaints': 'Patient presents for routine preventive health check.',
          'history': 'Complete medical history reviewed. Family history updated.',
          'examination': 'Comprehensive physical examination performed. Age-appropriate screening discussed.',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal Exam',
        icon: Icons.check_circle_rounded,
        color: Colors.teal,
        description: 'Normal examination findings template',
        data: {
          'chief_complaints': 'Patient presents for evaluation.',
          'history': 'No acute concerns. General health maintained.',
          'examination': 'Vital signs within normal limits. General examination unremarkable. No abnormalities detected.',
        },
      ),
    ];
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    } else {
      // Check for draft only when creating new record
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForDraft());
    }
    
    // Start auto-save timer
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) => _autoSave());
  }

  void _loadExistingRecord() async {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _doctorNotesController.text = record.doctorNotes ?? '';
    
    // V6: Use normalized fields with fallback to dataJson
    final db = await ref.read(doctorDbProvider.future);
    final data = await db.getMedicalRecordFieldsCompat(record.id);
    if (data.isNotEmpty && mounted) {
      setState(() {
        _chiefComplaintsController.text = (data['chief_complaints'] as String?) ?? '';
        _historyController.text = (data['history'] as String?) ?? '';
        _examinationController.text = (data['examination'] as String?) ?? '';
        
        // Load vitals after build using the new component
        final vitals = data['vitals'] as Map<String, dynamic>?;
        if (vitals != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final bp = vitals['bp']?.toString() ?? '';
            final bpParts = bp.split('/');
            _vitalsKey.currentState?.setData(VitalsData(
              bpSystolic: bpParts.isNotEmpty && bpParts[0].isNotEmpty ? bpParts[0] : null,
              bpDiastolic: bpParts.length > 1 && bpParts[1].isNotEmpty ? bpParts[1] : null,
              heartRate: vitals['pulse']?.toString(),
              temperature: vitals['temperature']?.toString(),
              weight: vitals['weight']?.toString(),
              height: vitals['height']?.toString(),
              spO2: vitals['spo2']?.toString(),
              respiratoryRate: vitals['respiratory_rate']?.toString(),
            ));
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _scrollController.dispose();
    _chiefComplaintsController.dispose();
    _historyController.dispose();
    _examinationController.dispose();
    _doctorNotesController.dispose();
    super.dispose();
  }

  // Auto-save methods
  Future<void> _checkForDraft() async {
    final draft = await FormDraftService.loadDraft(
      formType: 'general_consultation',
      patientId: _selectedPatientId,
    );
    
    if (draft != null && mounted) {
      _showRestoreDraftDialog(draft);
    }
  }

  void _showRestoreDraftDialog(FormDraft draft) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.restore, color: Colors.amber.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Restore Draft?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A previous draft was found for this form.'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Saved ${draft.timeAgo}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FormDraftService.clearDraft(
                formType: 'general_consultation',
                patientId: _selectedPatientId,
              );
            },
            child: Text(
              'Discard',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreFromDraft(draft.data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _restoreFromDraft(Map<String, dynamic> data) {
    setState(() {
      _chiefComplaintsController.text = (data['chief_complaints'] as String?) ?? '';
      _historyController.text = (data['history'] as String?) ?? '';
      _examinationController.text = (data['examination'] as String?) ?? '';
      _doctorNotesController.text = (data['doctor_notes'] as String?) ?? '';
      
      if (data['record_date'] != null) {
        _recordDate = DateTime.parse(data['record_date'] as String);
      }
      
      // Restore vitals
      final vitals = data['vitals'] as Map<String, dynamic>?;
      if (vitals != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _vitalsKey.currentState?.setData(VitalsData(
            bpSystolic: vitals['bp_systolic'] as String?,
            bpDiastolic: vitals['bp_diastolic'] as String?,
            heartRate: vitals['heart_rate'] as String?,
            temperature: vitals['temperature'] as String?,
            weight: vitals['weight'] as String?,
            height: vitals['height'] as String?,
            spO2: vitals['spo2'] as String?,
            respiratoryRate: vitals['respiratory_rate'] as String?,
          ));
        });
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Draft restored'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Map<String, dynamic> _buildDraftData() {
    final vitals = _vitalsKey.currentState?.getData();
    return {
      'chief_complaints': _chiefComplaintsController.text,
      'history': _historyController.text,
      'examination': _examinationController.text,
      'doctor_notes': _doctorNotesController.text,
      'record_date': _recordDate.toIso8601String(),
      'vitals': vitals != null ? {
        'bp_systolic': vitals.bpSystolic,
        'bp_diastolic': vitals.bpDiastolic,
        'heart_rate': vitals.heartRate,
        'temperature': vitals.temperature,
        'weight': vitals.weight,
        'height': vitals.height,
        'spo2': vitals.spO2,
        'respiratory_rate': vitals.respiratoryRate,
      } : null,
    };
  }

  bool _hasAnyContent() {
    return _chiefComplaintsController.text.isNotEmpty ||
        _historyController.text.isNotEmpty ||
        _examinationController.text.isNotEmpty ||
        _doctorNotesController.text.isNotEmpty;
  }

  Future<void> _autoSave() async {
    if (!mounted || !_hasAnyContent()) return;
    
    setState(() => _isAutoSaving = true);
    
    try {
      await FormDraftService.saveDraft(
        formType: 'general_consultation',
        patientId: _selectedPatientId,
        data: _buildDraftData(),
      );
      if (mounted) {
        setState(() {
          _lastSaved = DateTime.now();
          _isAutoSaving = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isAutoSaving = false);
    }
  }

  Future<void> _clearDraftOnSuccess() async {
    await FormDraftService.clearDraft(
      formType: 'general_consultation',
      patientId: _selectedPatientId,
    );
  }

  Map<String, dynamic> _buildDataJson() {
    final vitals = _vitalsKey.currentState?.getData();
    return {
      'chief_complaints': _chiefComplaintsController.text,
      'history': _historyController.text,
      'examination': _examinationController.text,
      'vitals': {
        'bp': vitals?.formattedBP,
        'pulse': vitals?.heartRate,
        'temperature': vitals?.temperature,
        'weight': vitals?.weight,
        'height': vitals?.height,
        'spo2': vitals?.spO2,
        'respiratory_rate': vitals?.respiratoryRate,
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
      // V6: Build data for normalized storage
      final recordData = _buildDataJson();
      
      final companion = MedicalRecordsCompanion.insert(
        patientId: _selectedPatientId!,
        encounterId: Value(widget.encounterId),
        recordType: 'general',
        title: 'General Consultation - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_chiefComplaintsController.text),
        dataJson: const Value('{}'), // V6: Empty - using MedicalRecordFields
        doctorNotes: Value(_doctorNotesController.text),
        recordDate: _recordDate,
      );

      MedicalRecord? resultRecord;
      int? recordId;
      
      if (widget.existingRecord != null) {
        // Create a full record with the existing ID for update
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          encounterId: widget.encounterId ?? widget.existingRecord!.encounterId,
          recordType: 'general',
          title: 'General Consultation - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _chiefComplaintsController.text,
          dataJson: '{}', // V6: Empty - using MedicalRecordFields
          diagnosis: '',
          treatment: '',
          doctorNotes: _doctorNotesController.text,
          recordDate: _recordDate,
          createdAt: widget.existingRecord!.createdAt,
        );
        await db.updateMedicalRecord(updatedRecord);
        // V6: Delete old fields and re-insert
        await db.deleteFieldsForMedicalRecord(widget.existingRecord!.id);
        await db.insertMedicalRecordFieldsBatch(widget.existingRecord!.id, _selectedPatientId!, recordData);
        resultRecord = updatedRecord;
        recordId = widget.existingRecord!.id;
      } else {
        recordId = await db.insertMedicalRecord(companion);
        // V6: Save fields to normalized table
        await db.insertMedicalRecordFieldsBatch(recordId, _selectedPatientId!, recordData);
        resultRecord = await db.getMedicalRecordById(recordId);
      }

      // Also save vitals to VitalSigns table for patient history tracking
      final vitals = _vitalsKey.currentState?.getData();
      if (vitals != null && _hasAnyVitals(vitals)) {
        await _saveVitalsToPatientRecord(db, vitals, recordId);
      }

      // Save user inputs as suggestions for future autocomplete
      await _saveSuggestionsFromForm();

      if (mounted) {
        // Clear draft on successful save
        await _clearDraftOnSuccess();
        
        RecordFormWidgets.showSuccessSnackbar(
          context, 
          widget.existingRecord != null 
              ? 'Record updated successfully!' 
              : 'Record saved successfully!',
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

  /// Save user inputs as suggestions for future autocomplete
  Future<void> _saveSuggestionsFromForm() async {
    try {
      final service = await ref.read(dynamicSuggestionsProvider.future);
      
      // Save chief complaint
      if (_chiefComplaintsController.text.trim().isNotEmpty) {
        await service.addOrUpdateSuggestion(
          SuggestionCategory.chiefComplaint, 
          _chiefComplaintsController.text.trim(),
        );
      }
      
      // Save examination findings
      if (_examinationController.text.trim().isNotEmpty) {
        await service.addOrUpdateSuggestion(
          SuggestionCategory.examinationFindings, 
          _examinationController.text.trim(),
        );
      }
      
      // Save clinical notes
      if (_doctorNotesController.text.trim().isNotEmpty) {
        await service.addOrUpdateSuggestion(
          SuggestionCategory.clinicalNotes, 
          _doctorNotesController.text.trim(),
        );
      }
    } catch (e) {
      // Silently ignore - suggestions are enhancement, not critical
      debugPrint('Error saving suggestions: $e');
    }
  }

  bool _hasAnyVitals(VitalsData vitals) {
    return vitals.bpSystolic != null ||
        vitals.bpDiastolic != null ||
        vitals.heartRate != null ||
        vitals.temperature != null ||
        vitals.weight != null ||
        vitals.height != null ||
        vitals.spO2 != null ||
        vitals.respiratoryRate != null;
  }

  Future<void> _saveVitalsToPatientRecord(DoctorDatabase db, VitalsData vitals, int? recordId) async {
    double? weight = vitals.weight != null ? double.tryParse(vitals.weight!) : null;
    double? height = vitals.height != null ? double.tryParse(vitals.height!) : null;
    double? bmi;
    if (weight != null && height != null && height > 0) {
      bmi = weight / ((height / 100) * (height / 100));
    }

    await db.insertVitalSigns(VitalSignsCompanion.insert(
      patientId: _selectedPatientId!,
      recordedAt: _recordDate,
      systolicBp: Value(vitals.bpSystolic != null ? double.tryParse(vitals.bpSystolic!) : null),
      diastolicBp: Value(vitals.bpDiastolic != null ? double.tryParse(vitals.bpDiastolic!) : null),
      heartRate: Value(vitals.heartRate != null ? int.tryParse(vitals.heartRate!) : null),
      temperature: Value(vitals.temperature != null ? double.tryParse(vitals.temperature!) : null),
      respiratoryRate: Value(vitals.respiratoryRate != null ? int.tryParse(vitals.respiratoryRate!) : null),
      oxygenSaturation: Value(vitals.spO2 != null ? double.tryParse(vitals.spO2!) : null),
      weight: Value(weight),
      height: Value(height),
      bmi: Value(bmi),
      notes: Value('Recorded during general consultation'),
    ));
  }

  bool _hasVitalsData() {
    final vitals = _vitalsKey.currentState?.getData();
    if (vitals == null) return false;
    return vitals.bpSystolic != null ||
        vitals.heartRate != null ||
        vitals.temperature != null;
  }

  int _calculateCompletedSections() {
    int completed = 0;
    if (_selectedPatientId != null) completed++;
    if (_recordDate != DateTime.now()) completed++; // Date is always set
    if (_chiefComplaintsController.text.isNotEmpty) completed++;
    if (_historyController.text.isNotEmpty) completed++;
    // Vitals - check if any vital is filled
    if (_hasVitalsData()) {
      completed++;
    }
    if (_examinationController.text.isNotEmpty) completed++;
    if (_doctorNotesController.text.isNotEmpty) completed++;
    return completed;
  }

  void _scrollToSection(String sectionKey) {
    final key = _sectionKeys[sectionKey];
    if (key == null) return;
    final context = key.currentContext;
    if (context != null) {
      setState(() => _expandedSections[sectionKey] = true);
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  List<SectionInfo> get _sections => [
    SectionInfo(
      key: 'patient',
      title: 'Patient',
      icon: Icons.person_outline,
      isComplete: _selectedPatientId != null || widget.preselectedPatient != null,
      isExpanded: _expandedSections['patient'] ?? true,
    ),
    SectionInfo(
      key: 'details',
      title: 'Details',
      icon: Icons.event_note,
      isComplete: true, // Date is always set
      isExpanded: _expandedSections['details'] ?? true,
    ),
    SectionInfo(
      key: 'complaints',
      title: 'Complaints',
      icon: Icons.sick_outlined,
      isComplete: _chiefComplaintsController.text.isNotEmpty,
      isExpanded: _expandedSections['complaints'] ?? true,
    ),
    SectionInfo(
      key: 'history',
      title: 'History',
      icon: Icons.history,
      isComplete: _historyController.text.isNotEmpty,
      isExpanded: _expandedSections['history'] ?? true,
    ),
    SectionInfo(
      key: 'vitals',
      title: 'Vitals',
      icon: Icons.favorite_outline,
      isComplete: _hasVitalsData(),
      isExpanded: _expandedSections['vitals'] ?? true,
    ),
    SectionInfo(
      key: 'examination',
      title: 'Exam',
      icon: Icons.accessibility_new,
      isComplete: _examinationController.text.isNotEmpty,
      isExpanded: _expandedSections['examination'] ?? false,
    ),
    SectionInfo(
      key: 'notes',
      title: 'Notes',
      icon: Icons.note_alt,
      isComplete: _doctorNotesController.text.isNotEmpty,
      isExpanded: _expandedSections['notes'] ?? false,
    ),
  ];

  void _applyTemplate(QuickFillTemplateItem template) {
    final data = template.data;
    setState(() {
      if (data['chief_complaints'] != null) {
        _chiefComplaintsController.text = data['chief_complaints'] as String;
      }
      if (data['history'] != null) {
        _historyController.text = data['history'] as String;
      }
      if (data['examination'] != null) {
        _examinationController.text = data['examination'] as String;
      }
      // Apply vitals if present
      if (data['vitals'] != null) {
        final vitals = data['vitals'] as Map<String, dynamic>;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _vitalsKey.currentState?.setData(VitalsData(
            bpSystolic: vitals['bp_systolic'] as String?,
            bpDiastolic: vitals['bp_diastolic'] as String?,
            heartRate: vitals['heart_rate'] as String?,
            temperature: vitals['temperature'] as String?,
            weight: vitals['weight'] as String?,
          ));
        });
      }
    });
    showTemplateAppliedSnackbar(context, template.label, color: template.color);
  }

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RecordFormScaffold(
      title: widget.existingRecord != null 
          ? 'Edit Record' 
          : 'General Consultation',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.medical_services_rounded,
      gradientColors: _gradientColors,
      scrollController: _scrollController,
      trailing: AutoSaveIndicator(
        isSaving: _isAutoSaving,
        lastSaved: _lastSaved,
      ),
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
    // Calculate form completion
    final completedSections = _calculateCompletedSections();
    const totalSections = 7; // Patient, Details, Complaints, History, Vitals, Examination, Notes

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Indicator
          FormProgressIndicator(
            completedSections: completedSections,
            totalSections: totalSections,
            accentColor: _primaryColor,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Section Navigation Bar
          SectionNavigationBar(
            sections: _sections,
            onSectionTap: _scrollToSection,
            accentColor: _primaryColor,
          ),
          const SizedBox(height: AppSpacing.md),

          // Quick Fill Templates (using new QuickFillTemplateBar)
          QuickFillTemplateBar(
            templates: _templates,
            onTemplateSelected: _applyTemplate,
            title: 'General Consultation Templates',
            collapsible: true,
            initiallyExpanded: false,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Patient Selection / Info Card
          if (widget.preselectedPatient != null)
            PatientInfoCard(
              patient: widget.preselectedPatient!,
              gradientColors: _gradientColors,
              icon: Icons.medical_services_rounded,
            )
          else
            RecordFormSection(
              sectionKey: _sectionKeys['patient'],
              title: 'Patient Information',
              icon: Icons.person_outline,
              accentColor: _primaryColor,
              collapsible: true,
              initiallyExpanded: _expandedSections['patient'] ?? true,
              onToggle: (expanded) => setState(() => _expandedSections['patient'] = expanded),
              child: PatientSelectorCard(
                db: db,
                selectedPatientId: _selectedPatientId,
                onPatientSelected: (patient) {
                  setState(() => _selectedPatientId = patient?.id);
                },
                label: 'Select Patient',
              ),
            ),
          const SizedBox(height: AppSpacing.lg),

          // Date and Title Section
          RecordFormSection(
            sectionKey: _sectionKeys['details'],
            title: 'Record Details',
            icon: Icons.event_note,
            accentColor: _primaryColor,
            collapsible: true,
            initiallyExpanded: _expandedSections['details'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['details'] = expanded),
            child: DatePickerCard(
              selectedDate: _recordDate,
              onDateSelected: (date) => setState(() => _recordDate = date),
              label: 'Record Date',
              accentColor: _primaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chief Complaints
          RecordFormSection(
            sectionKey: _sectionKeys['complaints'],
            title: 'Chief Complaints',
            icon: Icons.sick_outlined,
            accentColor: Colors.orange,
            collapsible: true,
            initiallyExpanded: _expandedSections['complaints'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['complaints'] = expanded),
            completionSummary: _chiefComplaintsController.text.isNotEmpty
                ? _chiefComplaintsController.text
                : null,
            child: SuggestionTextField(
              controller: _chiefComplaintsController,
              label: 'Chief Complaints',
              hint: 'Describe presenting complaints...',
              prefixIcon: Icons.sick_outlined,
              maxLines: 4,
              suggestions: MedicalSuggestions.chiefComplaints,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // History
          RecordFormSection(
            sectionKey: _sectionKeys['history'],
            title: 'Medical History',
            icon: Icons.history,
            accentColor: Colors.blue,
            collapsible: true,
            initiallyExpanded: _expandedSections['history'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['history'] = expanded),
            completionSummary: _historyController.text.isNotEmpty
                ? _historyController.text
                : null,
            child: RecordTextField(
              controller: _historyController,
              hint: 'Relevant medical history...',
              maxLines: 4,
              accentColor: Colors.blue,
              enableVoice: true,
              suggestions: clinicalNotesSuggestions,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Vitals Section - Using new VitalsInputSection component
          RecordFormSection(
            sectionKey: _sectionKeys['vitals'],
            title: 'Vital Signs',
            icon: Icons.favorite_outline,
            accentColor: Colors.red,
            collapsible: true,
            initiallyExpanded: _expandedSections['vitals'] ?? true,
            onToggle: (expanded) => setState(() => _expandedSections['vitals'] = expanded),
            child: VitalsInputSection(
              key: _vitalsKey,
              accentColor: Colors.red,
              compact: true,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Examination
          RecordFormSection(
            sectionKey: _sectionKeys['examination'],
            title: 'Physical Examination',
            icon: Icons.accessibility_new,
            accentColor: Colors.purple,
            collapsible: true,
            initiallyExpanded: _expandedSections['examination'] ?? false,
            onToggle: (expanded) => setState(() => _expandedSections['examination'] = expanded),
            completionSummary: _examinationController.text.isNotEmpty
                ? _examinationController.text
                : null,
            child: RecordTextField(
              controller: _examinationController,
              hint: 'Physical examination findings...',
              maxLines: 4,
              accentColor: Colors.purple,
              enableVoice: true,
              suggestions: examinationFindingsSuggestions,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Doctor's Notes
          RecordFormSection(
            sectionKey: _sectionKeys['notes'],
            title: "Doctor's Notes",
            icon: Icons.note_alt,
            accentColor: Colors.indigo,
            collapsible: true,
            initiallyExpanded: _expandedSections['notes'] ?? false,
            onToggle: (expanded) => setState(() => _expandedSections['notes'] = expanded),
            completionSummary: _doctorNotesController.text.isNotEmpty
                ? _doctorNotesController.text
                : null,
            child: RecordNotesField(
              controller: _doctorNotesController,
              label: '',
              hint: 'Additional notes, observations, follow-up instructions...',
              accentColor: Colors.indigo,
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons - Using new component
          RecordActionButtons(
            onSave: () => _saveRecord(db),
            onCancel: () => Navigator.pop(context),
            saveLabel: widget.existingRecord != null ? 'Update Record' : 'Save Record',
            isLoading: _isSaving,
            canSave: _selectedPatientId != null,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
