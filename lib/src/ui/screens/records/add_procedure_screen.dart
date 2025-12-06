import 'dart:async';
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
import 'record_form_widgets.dart';

/// Screen for adding a Procedure medical record
class AddProcedureScreen extends ConsumerStatefulWidget {
  const AddProcedureScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddProcedureScreen> createState() => _AddProcedureScreenState();
}

class _AddProcedureScreenState extends ConsumerState<AddProcedureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;

  // Auto-save state
  Timer? _autoSaveTimer;
  DateTime? _lastSaved;
  bool _isAutoSaving = false;
  static const _autoSaveInterval = Duration(seconds: 30);

  // Theme colors for this record type
  static const _primaryColor = Color(0xFFEC4899); // Medication Pink
  static const _secondaryColor = Color(0xFFDB2777);
  static const _gradientColors = [_primaryColor, _secondaryColor];

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();

  // Procedure specific fields
  final _procedureNameController = TextEditingController();
  final _procedureCodeController = TextEditingController();
  final _indicationController = TextEditingController();
  final _anesthesiaController = TextEditingController();
  final _procedureNotesController = TextEditingController();
  final _findingsController = TextEditingController();
  final _complicationsController = TextEditingController();
  final _specimenController = TextEditingController();
  final _postOpInstructionsController = TextEditingController();
  final _performedByController = TextEditingController();
  final _assistedByController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  // Vitals
  final _bpPreController = TextEditingController();
  final _pulsePreController = TextEditingController();
  final _spo2PreController = TextEditingController();
  final _bpPostController = TextEditingController();
  final _pulsePostController = TextEditingController();
  final _spo2PostController = TextEditingController();

  String _procedureStatus = 'Completed';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForDraft());
    }
    
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) => _autoSave());
  }

  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _clinicalNotesController.text = record.doctorNotes ?? '';
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
        _procedureNameController.text = (data['procedure_name'] as String?) ?? '';
        _procedureCodeController.text = (data['procedure_code'] as String?) ?? '';
        _indicationController.text = (data['indication'] as String?) ?? '';
        _anesthesiaController.text = (data['anesthesia'] as String?) ?? '';
        _procedureNotesController.text = (data['procedure_notes'] as String?) ?? '';
        _findingsController.text = (data['findings'] as String?) ?? '';
        _complicationsController.text = (data['complications'] as String?) ?? '';
        _specimenController.text = (data['specimen'] as String?) ?? '';
        _postOpInstructionsController.text = (data['post_op_instructions'] as String?) ?? '';
        _performedByController.text = (data['performed_by'] as String?) ?? '';
        _assistedByController.text = (data['assisted_by'] as String?) ?? '';
        _procedureStatus = (data['procedure_status'] as String?) ?? 'Completed';
        
        final vitals = data['vitals'] as Map<String, dynamic>?;
        if (vitals != null) {
          _bpPreController.text = (vitals['bp_pre'] as String?) ?? '';
          _pulsePreController.text = (vitals['pulse_pre'] as String?) ?? '';
          _spo2PreController.text = (vitals['spo2_pre'] as String?) ?? '';
          _bpPostController.text = (vitals['bp_post'] as String?) ?? '';
          _pulsePostController.text = (vitals['pulse_post'] as String?) ?? '';
          _spo2PostController.text = (vitals['spo2_post'] as String?) ?? '';
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _scrollController.dispose();
    _procedureNameController.dispose();
    _procedureCodeController.dispose();
    _indicationController.dispose();
    _anesthesiaController.dispose();
    _procedureNotesController.dispose();
    _findingsController.dispose();
    _complicationsController.dispose();
    _specimenController.dispose();
    _postOpInstructionsController.dispose();
    _performedByController.dispose();
    _assistedByController.dispose();
    _clinicalNotesController.dispose();
    _bpPreController.dispose();
    _pulsePreController.dispose();
    _spo2PreController.dispose();
    _bpPostController.dispose();
    _pulsePostController.dispose();
    _spo2PostController.dispose();
    super.dispose();
  }

  // Auto-save methods
  Future<void> _checkForDraft() async {
    final draft = await FormDraftService.loadDraft(formType: 'procedure', patientId: _selectedPatientId);
    if (draft != null && mounted) _showRestoreDraftDialog(draft);
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
              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(10)),
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
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text('Saved ${draft.timeAgo}', style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); FormDraftService.clearDraft(formType: 'procedure', patientId: _selectedPatientId); },
            child: Text('Discard', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _restoreFromDraft(draft.data); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _restoreFromDraft(Map<String, dynamic> data) {
    setState(() {
      _procedureNameController.text = (data['procedure_name'] as String?) ?? '';
      _procedureCodeController.text = (data['procedure_code'] as String?) ?? '';
      _indicationController.text = (data['indication'] as String?) ?? '';
      _anesthesiaController.text = (data['anesthesia'] as String?) ?? '';
      _procedureNotesController.text = (data['procedure_notes'] as String?) ?? '';
      _findingsController.text = (data['findings'] as String?) ?? '';
      _complicationsController.text = (data['complications'] as String?) ?? '';
      _specimenController.text = (data['specimen'] as String?) ?? '';
      _postOpInstructionsController.text = (data['post_op_instructions'] as String?) ?? '';
      _performedByController.text = (data['performed_by'] as String?) ?? '';
      _assistedByController.text = (data['assisted_by'] as String?) ?? '';
      _clinicalNotesController.text = (data['clinical_notes'] as String?) ?? '';
      _procedureStatus = (data['procedure_status'] as String?) ?? 'Completed';
      if (data['record_date'] != null) _recordDate = DateTime.parse(data['record_date'] as String);
      
      final vitals = data['vitals'] as Map<String, dynamic>?;
      if (vitals != null) {
        _bpPreController.text = (vitals['bp_pre'] as String?) ?? '';
        _pulsePreController.text = (vitals['pulse_pre'] as String?) ?? '';
        _spo2PreController.text = (vitals['spo2_pre'] as String?) ?? '';
        _bpPostController.text = (vitals['bp_post'] as String?) ?? '';
        _pulsePostController.text = (vitals['pulse_post'] as String?) ?? '';
        _spo2PostController.text = (vitals['spo2_post'] as String?) ?? '';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Draft restored')]),
      backgroundColor: Colors.green.shade600, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 2),
    ));
  }

  Map<String, dynamic> _buildDraftData() => {
    'procedure_name': _procedureNameController.text,
    'procedure_code': _procedureCodeController.text,
    'indication': _indicationController.text,
    'anesthesia': _anesthesiaController.text,
    'procedure_notes': _procedureNotesController.text,
    'findings': _findingsController.text,
    'complications': _complicationsController.text,
    'specimen': _specimenController.text,
    'post_op_instructions': _postOpInstructionsController.text,
    'performed_by': _performedByController.text,
    'assisted_by': _assistedByController.text,
    'clinical_notes': _clinicalNotesController.text,
    'procedure_status': _procedureStatus,
    'record_date': _recordDate.toIso8601String(),
    'vitals': {
      'bp_pre': _bpPreController.text, 'pulse_pre': _pulsePreController.text, 'spo2_pre': _spo2PreController.text,
      'bp_post': _bpPostController.text, 'pulse_post': _pulsePostController.text, 'spo2_post': _spo2PostController.text,
    },
  };

  bool _hasAnyContent() =>
    _procedureNameController.text.isNotEmpty || _indicationController.text.isNotEmpty ||
    _procedureNotesController.text.isNotEmpty || _findingsController.text.isNotEmpty;

  Future<void> _autoSave() async {
    if (!mounted || !_hasAnyContent()) return;
    setState(() => _isAutoSaving = true);
    try {
      await FormDraftService.saveDraft(formType: 'procedure', patientId: _selectedPatientId, data: _buildDraftData());
      if (mounted) setState(() { _lastSaved = DateTime.now(); _isAutoSaving = false; });
    } catch (_) { if (mounted) setState(() => _isAutoSaving = false); }
  }

  Future<void> _clearDraftOnSuccess() async {
    await FormDraftService.clearDraft(formType: 'procedure', patientId: _selectedPatientId);
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'procedure_name': _procedureNameController.text.isNotEmpty ? _procedureNameController.text : null,
      'procedure_code': _procedureCodeController.text.isNotEmpty ? _procedureCodeController.text : null,
      'indication': _indicationController.text.isNotEmpty ? _indicationController.text : null,
      'anesthesia': _anesthesiaController.text.isNotEmpty ? _anesthesiaController.text : null,
      'procedure_notes': _procedureNotesController.text.isNotEmpty ? _procedureNotesController.text : null,
      'findings': _findingsController.text.isNotEmpty ? _findingsController.text : null,
      'complications': _complicationsController.text.isNotEmpty ? _complicationsController.text : null,
      'specimen': _specimenController.text.isNotEmpty ? _specimenController.text : null,
      'post_op_instructions': _postOpInstructionsController.text.isNotEmpty ? _postOpInstructionsController.text : null,
      'performed_by': _performedByController.text.isNotEmpty ? _performedByController.text : null,
      'assisted_by': _assistedByController.text.isNotEmpty ? _assistedByController.text : null,
      'procedure_status': _procedureStatus,
      'start_time': _startTime != null ? '${_startTime!.hour}:${_startTime!.minute}' : null,
      'end_time': _endTime != null ? '${_endTime!.hour}:${_endTime!.minute}' : null,
      'vitals': {
        'bp_pre': _bpPreController.text.isNotEmpty ? _bpPreController.text : null,
        'pulse_pre': _pulsePreController.text.isNotEmpty ? _pulsePreController.text : null,
        'spo2_pre': _spo2PreController.text.isNotEmpty ? _spo2PreController.text : null,
        'bp_post': _bpPostController.text.isNotEmpty ? _bpPostController.text : null,
        'pulse_post': _pulsePostController.text.isNotEmpty ? _pulsePostController.text : null,
        'spo2_post': _spo2PostController.text.isNotEmpty ? _spo2PostController.text : null,
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
        recordType: 'procedure',
        title: _procedureNameController.text.isNotEmpty 
            ? 'Procedure: ${_procedureNameController.text}'
            : 'Medical Procedure - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_procedureNotesController.text),
        dataJson: Value(jsonEncode(_buildDataJson())),
        diagnosis: Value(_findingsController.text),
        treatment: Value(_postOpInstructionsController.text),
        doctorNotes: Value(_clinicalNotesController.text),
        recordDate: _recordDate,
      );

      MedicalRecord? resultRecord;
      int? recordId;
      
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'procedure',
          title: _procedureNameController.text.isNotEmpty 
              ? 'Procedure: ${_procedureNameController.text}'
              : 'Medical Procedure - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _procedureNotesController.text,
          dataJson: jsonEncode(_buildDataJson()),
          diagnosis: _findingsController.text,
          treatment: _postOpInstructionsController.text,
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

      // Save pre-procedure vitals to VitalSigns table
      if (_hasPreVitals()) {
        await _savePreVitals(db);
      }

      // Save post-procedure vitals to VitalSigns table
      if (_hasPostVitals()) {
        await _savePostVitals(db);
      }

      // Create TreatmentOutcome for procedure
      await _saveProcedureTreatmentOutcome(db, recordId);

      if (mounted) {
        await _clearDraftOnSuccess();
        RecordFormWidgets.showSuccessSnackbar(
          context, 
          widget.existingRecord != null 
              ? 'Procedure record updated successfully!' 
              : 'Procedure record saved successfully!',
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

  bool _hasPreVitals() {
    return _bpPreController.text.isNotEmpty ||
        _pulsePreController.text.isNotEmpty ||
        _spo2PreController.text.isNotEmpty;
  }

  bool _hasPostVitals() {
    return _bpPostController.text.isNotEmpty ||
        _pulsePostController.text.isNotEmpty ||
        _spo2PostController.text.isNotEmpty;
  }

  Future<void> _savePreVitals(DoctorDatabase db) async {
    double? systolic;
    double? diastolic;
    if (_bpPreController.text.isNotEmpty) {
      final bpParts = _bpPreController.text.split('/');
      if (bpParts.isNotEmpty) systolic = double.tryParse(bpParts[0].trim());
      if (bpParts.length > 1) diastolic = double.tryParse(bpParts[1].trim());
    }

    await db.insertVitalSigns(VitalSignsCompanion.insert(
      patientId: _selectedPatientId!,
      recordedAt: _recordDate,
      systolicBp: Value(systolic),
      diastolicBp: Value(diastolic),
      heartRate: Value(_pulsePreController.text.isNotEmpty 
          ? int.tryParse(_pulsePreController.text) 
          : null),
      oxygenSaturation: Value(_spo2PreController.text.isNotEmpty 
          ? double.tryParse(_spo2PreController.text) 
          : null),
      notes: Value('Pre-procedure vitals: ${_procedureNameController.text}'),
    ));
  }

  Future<void> _savePostVitals(DoctorDatabase db) async {
    double? systolic;
    double? diastolic;
    if (_bpPostController.text.isNotEmpty) {
      final bpParts = _bpPostController.text.split('/');
      if (bpParts.isNotEmpty) systolic = double.tryParse(bpParts[0].trim());
      if (bpParts.length > 1) diastolic = double.tryParse(bpParts[1].trim());
    }

    // Post-procedure vitals recorded 30 minutes after the procedure
    final postTime = _recordDate.add(const Duration(minutes: 30));

    await db.insertVitalSigns(VitalSignsCompanion.insert(
      patientId: _selectedPatientId!,
      recordedAt: postTime,
      systolicBp: Value(systolic),
      diastolicBp: Value(diastolic),
      heartRate: Value(_pulsePostController.text.isNotEmpty 
          ? int.tryParse(_pulsePostController.text) 
          : null),
      oxygenSaturation: Value(_spo2PostController.text.isNotEmpty 
          ? double.tryParse(_spo2PostController.text) 
          : null),
      notes: Value('Post-procedure vitals: ${_procedureNameController.text}'),
    ));
  }

  Future<void> _saveProcedureTreatmentOutcome(DoctorDatabase db, int? recordId) async {
    final outcome = _procedureStatus == 'Completed' ? 'improved' 
        : _procedureStatus == 'Scheduled' ? 'ongoing'
        : _procedureStatus == 'Cancelled' ? 'ongoing'
        : 'ongoing';

    await db.insertTreatmentOutcome(TreatmentOutcomesCompanion.insert(
      patientId: _selectedPatientId!,
      medicalRecordId: Value(recordId),
      treatmentType: 'procedure',
      treatmentDescription: _procedureNameController.text.isNotEmpty 
          ? _procedureNameController.text 
          : 'Medical procedure',
      providerType: const Value('primary_care'),
      providerName: Value(_performedByController.text),
      diagnosis: Value(_indicationController.text),
      startDate: _recordDate,
      endDate: _procedureStatus == 'Completed' ? Value(_recordDate) : const Value(null),
      outcome: Value(outcome),
      sideEffects: Value(_complicationsController.text),
      notes: Value(_findingsController.text.isNotEmpty 
          ? 'Findings: ${_findingsController.text}' 
          : _clinicalNotesController.text),
    ));
  }

  int _calculateCompletedSections() {
    int completed = 0;
    if (_selectedPatientId != null) completed++;
    if (_procedureNameController.text.isNotEmpty) completed++;
    if (_indicationController.text.isNotEmpty) completed++;
    if (_procedureNotesController.text.isNotEmpty) completed++;
    if (_postOpInstructionsController.text.isNotEmpty) completed++;
    return completed;
  }

  void _applyTemplate(QuickFillTemplate template) {
    final data = template.data;
    setState(() {
      if (data['procedure_name'] != null) {
        _procedureNameController.text = data['procedure_name'] as String;
      }
      if (data['indication'] != null) {
        _indicationController.text = data['indication'] as String;
      }
      if (data['anesthesia'] != null) {
        _anesthesiaController.text = data['anesthesia'] as String;
      }
      if (data['procedure_notes'] != null) {
        _procedureNotesController.text = data['procedure_notes'] as String;
      }
      if (data['post_op_instructions'] != null) {
        _postOpInstructionsController.text = data['post_op_instructions'] as String;
      }
      if (data['specimen'] != null) {
        _specimenController.text = data['specimen'] as String;
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
          ? 'Edit Procedure' 
          : 'Medical Procedure',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.healing_rounded,
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
    const totalSections = 5; // Patient, Procedure Name, Indication, Notes, Post-op

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
            title: 'Common Procedures',
            templates: ProcedureTemplates.templates,
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
              label: 'Procedure Date',
              accentColor: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Procedure Information
          RecordFormSection(
            title: 'Procedure Information',
            icon: Icons.healing_outlined,
            accentColor: _primaryColor,
            child: Column(
              children: [
                SuggestionTextField(
                  controller: _procedureNameController,
                  label: 'Procedure Name',
                  hint: 'e.g., Wound Debridement, Biopsy...',
                  prefixIcon: Icons.healing_outlined,
                  suggestions: MedicalRecordSuggestions.procedureNames,
                ),
                const SizedBox(height: 12),
                RecordFieldGrid(
                  children: [
                    CompactTextField(
                      controller: _procedureCodeController,
                      label: 'Procedure Code',
                      hint: 'CPT/ICD...',
                      accentColor: _primaryColor,
                    ),
                    _buildStatusDropdown(isDark),
                  ],
                ),
                const SizedBox(height: 12),
                RecordTextField(
                  controller: _indicationController,
                  hint: 'Clinical indication for procedure...',
                  maxLines: 2,
                  accentColor: _primaryColor,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTimeSelector('Start', _startTime, (t) => setState(() => _startTime = t), isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeSelector('End', _endTime, (t) => setState(() => _endTime = t), isDark)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Anesthesia
          RecordFormSection(
            title: 'Anesthesia',
            icon: Icons.airline_seat_flat,
            accentColor: Colors.purple,
            collapsible: true,
            child: SuggestionTextField(
              controller: _anesthesiaController,
              label: 'Anesthesia Type',
              hint: 'e.g., Local, General, Regional...',
              prefixIcon: Icons.airline_seat_flat_outlined,
              suggestions: const [
                'None',
                'Local anesthesia',
                'Topical anesthesia',
                'Regional block',
                'Spinal anesthesia',
                'Epidural anesthesia',
                'General anesthesia',
                'Conscious sedation',
                'Monitored anesthesia care (MAC)',
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pre-Procedure Vitals
          RecordFormSection(
            title: 'Pre-Procedure Vitals',
            icon: Icons.favorite_outline,
            accentColor: Colors.red,
            collapsible: true,
            child: RecordFieldGrid(
              crossAxisCount: 3,
              children: [
                CompactTextField(
                  controller: _bpPreController,
                  label: 'BP',
                  hint: '120/80',
                  unit: 'mmHg',
                  accentColor: Colors.red,
                ),
                CompactTextField(
                  controller: _pulsePreController,
                  label: 'Pulse',
                  hint: '72',
                  unit: 'bpm',
                  keyboardType: TextInputType.number,
                  accentColor: Colors.red,
                ),
                CompactTextField(
                  controller: _spo2PreController,
                  label: 'SpO₂',
                  hint: '98',
                  unit: '%',
                  keyboardType: TextInputType.number,
                  accentColor: Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Procedure Notes
          RecordFormSection(
            title: 'Procedure Notes',
            icon: Icons.note_alt,
            accentColor: Colors.teal,
            child: SuggestionTextField(
              controller: _procedureNotesController,
              label: 'Procedure Details',
              hint: 'Describe the procedure performed...',
              prefixIcon: Icons.note_alt_outlined,
              maxLines: 6,
              suggestions: MedicalRecordSuggestions.procedureNotes,
              separator: '. ',
            ),
          ),
          const SizedBox(height: 16),

          // Findings
          RecordFormSection(
            title: 'Intra-operative Findings',
            icon: Icons.search,
            accentColor: Colors.blue,
            collapsible: true,
            child: RecordTextField(
              controller: _findingsController,
              hint: 'Findings during procedure...',
              maxLines: 4,
              accentColor: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),

          // Specimen & Complications
          RecordFormSection(
            title: 'Specimen & Complications',
            icon: Icons.science_outlined,
            accentColor: Colors.orange,
            collapsible: true,
            child: Column(
              children: [
                RecordTextField(
                  controller: _specimenController,
                  label: 'Specimen Collected',
                  hint: 'Specimen collected (if any)...',
                  maxLines: 2,
                  accentColor: Colors.orange,
                ),
                const SizedBox(height: 12),
                RecordTextField(
                  controller: _complicationsController,
                  label: 'Complications',
                  hint: 'Any complications during/after procedure...',
                  maxLines: 3,
                  prefixIcon: Icons.warning_amber_outlined,
                  accentColor: AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Post-Procedure Vitals
          RecordFormSection(
            title: 'Post-Procedure Vitals',
            icon: Icons.monitor_heart_outlined,
            accentColor: Colors.green,
            collapsible: true,
            child: RecordFieldGrid(
              crossAxisCount: 3,
              children: [
                CompactTextField(
                  controller: _bpPostController,
                  label: 'BP',
                  hint: '120/80',
                  unit: 'mmHg',
                  accentColor: Colors.green,
                ),
                CompactTextField(
                  controller: _pulsePostController,
                  label: 'Pulse',
                  hint: '72',
                  unit: 'bpm',
                  keyboardType: TextInputType.number,
                  accentColor: Colors.green,
                ),
                CompactTextField(
                  controller: _spo2PostController,
                  label: 'SpO₂',
                  hint: '98',
                  unit: '%',
                  keyboardType: TextInputType.number,
                  accentColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Post-Op Instructions
          RecordFormSection(
            title: 'Post-Op Instructions',
            icon: Icons.assignment_outlined,
            accentColor: _primaryColor,
            child: RecordTextField(
              controller: _postOpInstructionsController,
              hint: 'Post-procedure care instructions...',
              maxLines: 4,
              accentColor: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Personnel
          RecordFormSection(
            title: 'Personnel',
            icon: Icons.people_outline,
            accentColor: Colors.blueGrey,
            collapsible: true,
            initiallyExpanded: false,
            child: RecordFieldGrid(
              children: [
                CompactTextField(
                  controller: _performedByController,
                  label: 'Performed By',
                  hint: 'Name...',
                  accentColor: Colors.blueGrey,
                ),
                CompactTextField(
                  controller: _assistedByController,
                  label: 'Assisted By',
                  hint: 'Name...',
                  accentColor: Colors.blueGrey,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Additional Notes
          RecordFormSection(
            title: 'Additional Notes',
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
            saveLabel: widget.existingRecord != null ? 'Update Procedure' : 'Save Procedure',
            isLoading: _isSaving,
            canSave: _selectedPatientId != null,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          child: DropdownButton<String>(
            value: _procedureStatus,
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
            items: ['Completed', 'Cancelled', 'Partial', 'Aborted'].map((s) {
              return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: (v) => setState(() => _procedureStatus = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay? time, ValueChanged<TimeOfDay> onChanged, bool isDark) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  time != null ? time.format(context) : '--:--',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

