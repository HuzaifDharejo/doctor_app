import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
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
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

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
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    } else {
      // Check for draft only when creating new record
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForDraft());
    }
    
    // Start auto-save timer
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) => _autoSave());
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _doctorNotesController.text = record.doctorNotes ?? '';
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
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
      } catch (_) {}
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
      final companion = MedicalRecordsCompanion.insert(
        patientId: _selectedPatientId!,
        recordType: 'general',
        title: 'General Consultation - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_chiefComplaintsController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
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
          recordType: 'general',
          title: 'General Consultation - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _chiefComplaintsController.text,
          dataJson: jsonEncode(_buildDataJson()),
          diagnosis: '',
          treatment: '',
          doctorNotes: _doctorNotesController.text,
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

      // Also save vitals to VitalSigns table for patient history tracking
      final vitals = _vitalsKey.currentState?.getData();
      if (vitals != null && _hasAnyVitals(vitals)) {
        await _saveVitalsToPatientRecord(db, vitals, recordId);
      }

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

  int _calculateCompletedSections() {
    int completed = 0;
    if (_selectedPatientId != null) completed++;
    if (_recordDate != DateTime.now()) completed++; // Date is always set
    if (_chiefComplaintsController.text.isNotEmpty) completed++;
    if (_historyController.text.isNotEmpty) completed++;
    // Vitals - check if any vital is filled
    final vitals = _vitalsKey.currentState?.getData();
    if (vitals != null && (vitals.bpSystolic != null || vitals.heartRate != null || vitals.temperature != null)) {
      completed++;
    }
    return completed;
  }

  void _applyTemplate(QuickFillTemplate template) {
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
    showTemplateAppliedSnackbar(context, template.label);
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
    const totalSections = 5; // Patient, Date, Complaints, History, Vitals

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
          const SizedBox(height: 16),

          // Quick Fill Templates
          QuickFillSection(
            templates: GeneralConsultationTemplates.templates,
            onTemplateSelected: _applyTemplate,
          ),
          const SizedBox(height: 16),

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

          // Date and Title Section
          RecordFormSection(
            title: 'Record Details',
            icon: Icons.event_note,
            accentColor: _primaryColor,
            child: DatePickerCard(
              selectedDate: _recordDate,
              onDateSelected: (date) => setState(() => _recordDate = date),
              label: 'Record Date',
              accentColor: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Chief Complaints
          RecordFormSection(
            title: 'Chief Complaints',
            icon: Icons.sick_outlined,
            accentColor: Colors.orange,
            child: SuggestionTextField(
              controller: _chiefComplaintsController,
              label: 'Chief Complaints',
              hint: 'Describe presenting complaints...',
              prefixIcon: Icons.sick_outlined,
              maxLines: 4,
              suggestions: MedicalSuggestions.chiefComplaints,
            ),
          ),
          const SizedBox(height: 16),

          // History
          RecordFormSection(
            title: 'Medical History',
            icon: Icons.history,
            accentColor: Colors.blue,
            collapsible: true,
            child: RecordTextField(
              controller: _historyController,
              hint: 'Relevant medical history...',
              maxLines: 4,
              accentColor: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),

          // Vitals Section - Using new VitalsInputSection component
          RecordFormSection(
            title: 'Vital Signs',
            icon: Icons.favorite_outline,
            accentColor: Colors.red,
            child: VitalsInputSection(
              key: _vitalsKey,
              accentColor: Colors.red,
              compact: true,
            ),
          ),
          const SizedBox(height: 16),

          // Examination
          RecordFormSection(
            title: 'Physical Examination',
            icon: Icons.accessibility_new,
            accentColor: Colors.purple,
            collapsible: true,
            child: RecordTextField(
              controller: _examinationController,
              hint: 'Physical examination findings...',
              maxLines: 4,
              accentColor: Colors.purple,
            ),
          ),
          const SizedBox(height: 16),

          // Doctor's Notes
          RecordFormSection(
            title: "Doctor's Notes",
            icon: Icons.note_alt,
            accentColor: Colors.indigo,
            collapsible: true,
            initiallyExpanded: false,
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
