import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../theme/app_theme.dart';
import 'components/record_components.dart';
import 'record_form_widgets.dart';

/// Screen for adding a Cardiac Examination medical record
class AddCardiacExamScreen extends ConsumerStatefulWidget {
  const AddCardiacExamScreen({
    super.key,
    this.preselectedPatient,
    this.existingRecord,
  });

  final Patient? preselectedPatient;
  final MedicalRecord? existingRecord;

  @override
  ConsumerState<AddCardiacExamScreen> createState() => _AddCardiacExamScreenState();
}

class _AddCardiacExamScreenState extends ConsumerState<AddCardiacExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isSaving = false;

  // Section keys for navigation (string-based)
  final Map<String, GlobalKey> _sectionKeys = {
    'complaint': GlobalKey(),
    'vitals': GlobalKey(),
    'sounds': GlobalKey(),
    'exam': GlobalKey(),
    'tests': GlobalKey(),
    'assessment': GlobalKey(),
    'notes': GlobalKey(),
  };
  
  // Section expansion state (string-based)
  final Map<String, bool> _expandedSections = {
    'complaint': true,
    'vitals': true,
    'sounds': false,
    'exam': false,
    'tests': false,
    'assessment': true,
    'notes': false,
  };

  // Quick fill templates
  late List<QuickFillTemplateItem> _templates;
  
  // Section info for navigation (with keys)
  static const List<Map<String, dynamic>> _sectionInfo = [
    {'key': 'complaint', 'name': 'Complaint', 'icon': Icons.report_problem_rounded},
    {'key': 'vitals', 'name': 'Vitals', 'icon': Icons.monitor_heart_rounded},
    {'key': 'sounds', 'name': 'Sounds', 'icon': Icons.hearing_rounded},
    {'key': 'exam', 'name': 'Exam', 'icon': Icons.favorite_border_rounded},
    {'key': 'tests', 'name': 'Tests', 'icon': Icons.biotech_rounded},
    {'key': 'assessment', 'name': 'Assessment', 'icon': Icons.assignment_rounded},
    {'key': 'notes', 'name': 'Notes', 'icon': Icons.note_alt},
  ];

  // Common fields
  int? _selectedPatientId;
  DateTime _recordDate = DateTime.now();

  // Chief Complaint
  final _chiefComplaintController = TextEditingController();
  final _durationController = TextEditingController();
  List<String> _selectedSymptoms = [];

  // Vital Signs
  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _spo2Controller = TextEditingController();

  // Heart Sounds
  String _s1 = 'Normal';
  String _s2 = 'Normal';
  final _s3Controller = TextEditingController();
  final _s4Controller = TextEditingController();
  List<String> _selectedMurmurs = [];
  final _murmurDetailsController = TextEditingController();

  // Cardiac Examination
  final _jvpController = TextEditingController();
  final _apexBeatController = TextEditingController();
  final _heaveController = TextEditingController();
  final _thrillController = TextEditingController();
  final _peripheralPulsesController = TextEditingController();
  final _edemaController = TextEditingController();

  // Investigations
  List<String> _selectedInvestigations = [];
  final _ecgFindingsController = TextEditingController();
  final _echoFindingsController = TextEditingController();
  final _labResultsController = TextEditingController();

  // Assessment
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _clinicalNotesController = TextEditingController();

  // Option lists
  final List<String> _symptomOptions = [
    'Chest Pain', 'Dyspnea', 'Orthopnea', 'PND', 'Palpitations',
    'Syncope', 'Fatigue', 'Leg Swelling', 'Claudication', 'Cyanosis',
  ];

  final List<String> _murmurOptions = [
    'Systolic Ejection', 'Pansystolic', 'Early Diastolic',
    'Mid-Diastolic', 'Continuous', 'Aortic Area', 'Pulmonary Area',
    'Mitral Area', 'Tricuspid Area', 'Radiation to Carotids',
  ];

  final List<String> _investigationOptions = [
    'ECG', 'Echocardiogram', 'Chest X-ray', 'Cardiac Enzymes',
    'BNP/NT-proBNP', 'Lipid Profile', 'Stress Test', 'Holter Monitor',
    'Coronary Angiography', 'CT Angiography', 'Cardiac MRI',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preselectedPatient?.id;
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    }
    
    // Initialize quick fill templates
    _templates = [
      QuickFillTemplateItem(
        label: 'MI/ACS',
        icon: Icons.warning_rounded,
        color: Colors.red,
        description: 'Myocardial infarction / Acute coronary syndrome',
        data: {
          'chief_complaint': 'Chest pain, radiating to left arm, sweating',
          'symptoms': ['Chest Pain', 'Dyspnea'],
          'investigations': ['ECG', 'Cardiac Enzymes', 'Echocardiogram'],
          'diagnosis': 'Acute Coronary Syndrome',
          'treatment': 'Dual antiplatelet, Anticoagulation, Beta-blocker, Statin, ACEi',
        },
      ),
      QuickFillTemplateItem(
        label: 'Heart Failure',
        icon: Icons.water_drop_rounded,
        color: Colors.blue,
        description: 'Congestive heart failure template',
        data: {
          'chief_complaint': 'Progressive dyspnea, orthopnea, leg swelling',
          'symptoms': ['Dyspnea', 'Orthopnea', 'PND', 'Leg Swelling'],
          'jvp': 'Elevated',
          'edema': 'Bilateral pedal edema +2',
          'investigations': ['Echocardiogram', 'BNP/NT-proBNP', 'Chest X-ray'],
          'diagnosis': 'Congestive Heart Failure',
          'treatment': 'Diuretics, ACEi/ARB, Beta-blocker, Spironolactone',
        },
      ),
      QuickFillTemplateItem(
        label: 'Arrhythmia',
        icon: Icons.timeline_rounded,
        color: Colors.purple,
        description: 'Atrial fibrillation / arrhythmia template',
        data: {
          'chief_complaint': 'Palpitations, irregular heartbeat',
          'symptoms': ['Palpitations', 'Syncope'],
          'investigations': ['ECG', 'Holter Monitor', 'Echocardiogram'],
          'diagnosis': 'Atrial Fibrillation',
          'treatment': 'Rate control, Anticoagulation, Consider rhythm control',
        },
      ),
      QuickFillTemplateItem(
        label: 'Hypertension',
        icon: Icons.speed_rounded,
        color: Colors.orange,
        description: 'Essential hypertension template',
        data: {
          'chief_complaint': 'Elevated blood pressure, occasional headache',
          'symptoms': [],
          'investigations': ['ECG', 'Lipid Profile'],
          'diagnosis': 'Essential Hypertension',
          'treatment': 'ACEi/ARB, Lifestyle modification, Salt restriction',
        },
      ),
      QuickFillTemplateItem(
        label: 'Normal Cardiac',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        description: 'Normal cardiac examination findings',
        data: {
          's1': 'Normal',
          's2': 'Normal',
          'jvp': 'Normal',
          'apex_beat': '5th ICS, MCL',
          'peripheral_pulses': 'Normal volume and character',
          'edema': 'Absent',
          'diagnosis': 'Normal Cardiac Examination',
        },
      ),
    ];
  }

  void _loadExistingRecord() async {
    final record = widget.existingRecord!;
    _recordDate = record.recordDate;
    _diagnosisController.text = record.diagnosis ?? '';
    _treatmentController.text = record.treatment ?? '';
    _clinicalNotesController.text = record.doctorNotes ?? '';
    
    // V6: Use normalized fields with fallback to dataJson
    final db = await ref.read(doctorDbProvider.future);
    final data = await db.getMedicalRecordFieldsCompat(record.id);
    if (data.isNotEmpty) {
      setState(() {
        _chiefComplaintController.text = (data['chief_complaint'] as String?) ?? '';
        _durationController.text = (data['duration'] as String?) ?? '';
        _selectedSymptoms = List<String>.from((data['symptoms'] as List?) ?? []);
        
        final vitals = data['vitals'] as Map<String, dynamic>?;
        if (vitals != null) {
          _bpSystolicController.text = (vitals['bp_systolic'] as String?) ?? '';
          _bpDiastolicController.text = (vitals['bp_diastolic'] as String?) ?? '';
          _pulseController.text = (vitals['pulse'] as String?) ?? '';
          _respiratoryRateController.text = (vitals['respiratory_rate'] as String?) ?? '';
          _spo2Controller.text = (vitals['spo2'] as String?) ?? '';
        }
        
        final sounds = data['heart_sounds'] as Map<String, dynamic>?;
        if (sounds != null) {
          _s1 = (sounds['s1'] as String?) ?? 'Normal';
          _s2 = (sounds['s2'] as String?) ?? 'Normal';
          _s3Controller.text = (sounds['s3'] as String?) ?? '';
          _s4Controller.text = (sounds['s4'] as String?) ?? '';
          _selectedMurmurs = List<String>.from((sounds['murmurs'] as List?) ?? []);
          _murmurDetailsController.text = (sounds['murmur_details'] as String?) ?? '';
        }
        
        final exam = data['examination'] as Map<String, dynamic>?;
        if (exam != null) {
          _jvpController.text = (exam['jvp'] as String?) ?? '';
          _apexBeatController.text = (exam['apex_beat'] as String?) ?? '';
          _heaveController.text = (exam['heave'] as String?) ?? '';
          _thrillController.text = (exam['thrill'] as String?) ?? '';
          _peripheralPulsesController.text = (exam['peripheral_pulses'] as String?) ?? '';
          _edemaController.text = (exam['edema'] as String?) ?? '';
        }
        
        _selectedInvestigations = List<String>.from((data['investigations'] as List?) ?? []);
        _ecgFindingsController.text = (data['ecg_findings'] as String?) ?? '';
        _echoFindingsController.text = (data['echo_findings'] as String?) ?? '';
        _labResultsController.text = (data['lab_results'] as String?) ?? '';
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _pulseController.dispose();
    _respiratoryRateController.dispose();
    _spo2Controller.dispose();
    _s3Controller.dispose();
    _s4Controller.dispose();
    _murmurDetailsController.dispose();
    _jvpController.dispose();
    _apexBeatController.dispose();
    _heaveController.dispose();
    _thrillController.dispose();
    _peripheralPulsesController.dispose();
    _edemaController.dispose();
    _ecgFindingsController.dispose();
    _echoFindingsController.dispose();
    _labResultsController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _clinicalNotesController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildDataJson() {
    return {
      'chief_complaint': _chiefComplaintController.text.isNotEmpty ? _chiefComplaintController.text : null,
      'duration': _durationController.text.isNotEmpty ? _durationController.text : null,
      'symptoms': _selectedSymptoms.isNotEmpty ? _selectedSymptoms : null,
      'vitals': {
        'bp_systolic': _bpSystolicController.text.isNotEmpty ? _bpSystolicController.text : null,
        'bp_diastolic': _bpDiastolicController.text.isNotEmpty ? _bpDiastolicController.text : null,
        'pulse': _pulseController.text.isNotEmpty ? _pulseController.text : null,
        'respiratory_rate': _respiratoryRateController.text.isNotEmpty ? _respiratoryRateController.text : null,
        'spo2': _spo2Controller.text.isNotEmpty ? _spo2Controller.text : null,
      },
      'heart_sounds': {
        's1': _s1,
        's2': _s2,
        's3': _s3Controller.text.isNotEmpty ? _s3Controller.text : null,
        's4': _s4Controller.text.isNotEmpty ? _s4Controller.text : null,
        'murmurs': _selectedMurmurs.isNotEmpty ? _selectedMurmurs : null,
        'murmur_details': _murmurDetailsController.text.isNotEmpty ? _murmurDetailsController.text : null,
      },
      'examination': {
        'jvp': _jvpController.text.isNotEmpty ? _jvpController.text : null,
        'apex_beat': _apexBeatController.text.isNotEmpty ? _apexBeatController.text : null,
        'heave': _heaveController.text.isNotEmpty ? _heaveController.text : null,
        'thrill': _thrillController.text.isNotEmpty ? _thrillController.text : null,
        'peripheral_pulses': _peripheralPulsesController.text.isNotEmpty ? _peripheralPulsesController.text : null,
        'edema': _edemaController.text.isNotEmpty ? _edemaController.text : null,
      },
      'investigations': _selectedInvestigations.isNotEmpty ? _selectedInvestigations : null,
      'ecg_findings': _ecgFindingsController.text.isNotEmpty ? _ecgFindingsController.text : null,
      'echo_findings': _echoFindingsController.text.isNotEmpty ? _echoFindingsController.text : null,
      'lab_results': _labResultsController.text.isNotEmpty ? _labResultsController.text : null,
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
        recordType: 'cardiac_examination',
        title: _diagnosisController.text.isNotEmpty 
            ? 'Cardiac: ${_diagnosisController.text}'
            : 'Cardiac Examination - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
        description: Value(_chiefComplaintController.text),
        dataJson: const Value('{}'), // V6: Empty - using MedicalRecordFields table
        diagnosis: Value(_diagnosisController.text),
        treatment: Value(_treatmentController.text),
        doctorNotes: Value(_clinicalNotesController.text),
        recordDate: _recordDate,
      );

      MedicalRecord? resultRecord;
      
      if (widget.existingRecord != null) {
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _selectedPatientId!,
          recordType: 'cardiac_examination',
          title: _diagnosisController.text.isNotEmpty 
              ? 'Cardiac: ${_diagnosisController.text}'
              : 'Cardiac Examination - ${DateFormat('MMM d, yyyy').format(_recordDate)}',
          description: _chiefComplaintController.text,
          dataJson: '{}', // V6: Empty - using MedicalRecordFields table
          diagnosis: _diagnosisController.text,
          treatment: _treatmentController.text,
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
              ? 'Cardiac examination updated successfully!' 
              : 'Cardiac examination saved successfully!',
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

  // Progress tracking
  static const int _totalSections = 8;
  
  int _calculateCompletedSections() {
    int completed = 0;
    if (_selectedPatientId != null || widget.preselectedPatient != null) completed++;
    if (_chiefComplaintController.text.isNotEmpty) completed++;
    if (_bpSystolicController.text.isNotEmpty || _pulseController.text.isNotEmpty) completed++;
    if (_selectedMurmurs.isNotEmpty || _s1 != 'Normal' || _s2 != 'Normal') completed++;
    if (_jvpController.text.isNotEmpty || _apexBeatController.text.isNotEmpty) completed++;
    if (_selectedInvestigations.isNotEmpty) completed++;
    if (_diagnosisController.text.isNotEmpty) completed++;
    if (_treatmentController.text.isNotEmpty) completed++;
    return completed;
  }

  /// Check if section is complete for navigation indicator
  bool _isSectionComplete(int index) {
    switch (index) {
      case 0: // Chief Complaint
        return _chiefComplaintController.text.isNotEmpty;
      case 1: // Vitals
        return _bpSystolicController.text.isNotEmpty || _pulseController.text.isNotEmpty;
      case 2: // Heart Sounds
        return _selectedMurmurs.isNotEmpty || _s1 != 'Normal' || _s2 != 'Normal';
      case 3: // Cardiac Exam
        return _jvpController.text.isNotEmpty || _apexBeatController.text.isNotEmpty || 
               _peripheralPulsesController.text.isNotEmpty;
      case 4: // Investigations
        return _selectedInvestigations.isNotEmpty;
      case 5: // Assessment
        return _diagnosisController.text.isNotEmpty;
      case 6: // Notes
        return _clinicalNotesController.text.isNotEmpty;
      default:
        return false;
    }
  }

  /// Scroll to a specific section (string-based)
  void _scrollToSection(String sectionKey) {
    final key = _sectionKeys[sectionKey];
    if (key?.currentContext != null) {
      setState(() => _expandedSections[sectionKey] = true);
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  /// Apply a quick fill template
  void _applyTemplate(QuickFillTemplateItem template) {
    setState(() {
      final data = template.data;
      
      if (data['chief_complaint'] != null) {
        _chiefComplaintController.text = data['chief_complaint'] as String;
      }
      if (data['symptoms'] != null) {
        _selectedSymptoms = List<String>.from(data['symptoms'] as List);
      }
      if (data['investigations'] != null) {
        _selectedInvestigations = List<String>.from(data['investigations'] as List);
      }
      if (data['s1'] != null) _s1 = data['s1'] as String;
      if (data['s2'] != null) _s2 = data['s2'] as String;
      if (data['jvp'] != null) _jvpController.text = data['jvp'] as String;
      if (data['apex_beat'] != null) _apexBeatController.text = data['apex_beat'] as String;
      if (data['peripheral_pulses'] != null) _peripheralPulsesController.text = data['peripheral_pulses'] as String;
      if (data['edema'] != null) _edemaController.text = data['edema'] as String;
      if (data['diagnosis'] != null) _diagnosisController.text = data['diagnosis'] as String;
      if (data['treatment'] != null) _treatmentController.text = data['treatment'] as String;
    });
    
    showTemplateAppliedSnackbar(context, template.label, color: template.color);
  }

  /// Check for cardiac risk indicators
  bool get _hasCardiacRisk {
    // Check for concerning symptoms
    final riskSymptoms = ['Chest Pain', 'Syncope', 'Dyspnea'];
    if (_selectedSymptoms.any((s) => riskSymptoms.contains(s))) return true;
    
    // Check for abnormal vitals
    final systolic = int.tryParse(_bpSystolicController.text) ?? 0;
    final diastolic = int.tryParse(_bpDiastolicController.text) ?? 0;
    final pulse = int.tryParse(_pulseController.text) ?? 0;
    
    if (systolic > 180 || systolic < 90) return true;
    if (diastolic > 110 || diastolic < 60) return true;
    if (pulse > 120 || pulse < 50) return true;
    
    return false;
  }

  /// Get risk level for display
  RiskLevel get _riskLevel {
    if (!_hasCardiacRisk) return RiskLevel.none;
    
    final systolic = int.tryParse(_bpSystolicController.text) ?? 0;
    final pulse = int.tryParse(_pulseController.text) ?? 0;
    
    // Critical indicators
    if (systolic > 200 || systolic < 80 || pulse > 150 || pulse < 40) {
      return RiskLevel.critical;
    }
    // High risk indicators
    if (systolic > 180 || _selectedSymptoms.contains('Chest Pain') && _selectedSymptoms.contains('Dyspnea')) {
      return RiskLevel.high;
    }
    // Moderate risk
    if (_selectedSymptoms.contains('Chest Pain') || _selectedSymptoms.contains('Syncope')) {
      return RiskLevel.moderate;
    }
    return RiskLevel.low;
  }

  /// Build section navigation info (string-based keys)
  List<SectionInfo> get _sections => _sectionInfo.map((info) {
    final sectionKey = info['key'] as String;
    final index = _sectionInfo.indexOf(info);
    return SectionInfo(
      key: sectionKey,
      title: info['name'] as String,
      icon: info['icon'] as IconData,
      isComplete: _isSectionComplete(index),
      isExpanded: _expandedSections[sectionKey] ?? true,
      isHighRisk: sectionKey == 'vitals' && _hasCardiacRisk,
    );
  }).toList();

  @override
  Widget build(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RecordFormScaffold(
      title: widget.existingRecord != null 
          ? 'Edit Cardiac Examination' 
          : 'Cardiac Examination',
      subtitle: DateFormat('EEEE, dd MMMM yyyy').format(_recordDate),
      icon: Icons.favorite_rounded,
      gradientColors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress Indicator
          FormProgressIndicator(
            completedSections: _calculateCompletedSections(),
            totalSections: _totalSections,
            accentColor: const Color(0xFFEF4444),
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Section Navigation Bar
          SectionNavigationBar(
            sections: _sections,
            onSectionTap: _scrollToSection,
            accentColor: const Color(0xFFEF4444),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Risk Indicator (if present)
          if (_hasCardiacRisk) ...[
            RiskIndicatorBadge(level: _riskLevel),
            const SizedBox(height: AppSpacing.md),
          ],
          
          // Quick Fill Templates
          QuickFillTemplateBar(
            templates: _templates,
            onTemplateSelected: _applyTemplate,
            collapsible: true,
            initiallyExpanded: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Patient Selection
          if (widget.preselectedPatient == null) ...[
            PatientSelectorCard(
              db: db,
              selectedPatientId: _selectedPatientId,
              onChanged: (id) => setState(() => _selectedPatientId = id),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Date Selection
          DatePickerCard(
            selectedDate: _recordDate,
            onDateSelected: (date) => setState(() => _recordDate = date),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chief Complaint Section
          RecordFormSection(
            sectionKey: _sectionKeys['complaint'],
            title: 'Chief Complaint',
            icon: Icons.report_problem_rounded,
            accentColor: Colors.orange,
            collapsible: true,
            initiallyExpanded: _expandedSections['complaint'] ?? true,
            completionSummary: _chiefComplaintController.text.isNotEmpty 
                ? _chiefComplaintController.text 
                : null,
            onToggle: (expanded) => setState(() => _expandedSections['complaint'] = expanded),
            child: Column(
              children: [
                RecordTextField(
                  controller: _chiefComplaintController,
                  label: 'Chief Complaint',
                  hint: 'e.g., Chest pain, shortness of breath',
                  maxLines: 2,
                  enableVoice: true,
                  suggestions: chiefComplaintSuggestions,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(
                  controller: _durationController,
                  label: 'Duration',
                  hint: 'e.g., 2 days, 1 week',
                ),
                const SizedBox(height: AppSpacing.md),
                ChipSelectorSection(
                  title: 'Associated Symptoms',
                  options: _symptomOptions,
                  selected: _selectedSymptoms,
                  onChanged: (list) => setState(() => _selectedSymptoms = list),
                  accentColor: Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Vital Signs Section
          RecordFormSection(
            sectionKey: _sectionKeys['vitals'],
            title: 'Vital Signs',
            icon: Icons.monitor_heart_rounded,
            accentColor: Colors.red,
            collapsible: true,
            initiallyExpanded: _expandedSections['vitals'] ?? true,
            isHighRisk: _hasCardiacRisk,
            riskBadgeText: _hasCardiacRisk ? _riskLevel.name.toUpperCase() : null,
            completionSummary: _bpSystolicController.text.isNotEmpty 
                ? 'BP: ${_bpSystolicController.text}/${_bpDiastolicController.text}, PR: ${_pulseController.text}'
                : null,
            onToggle: (expanded) => setState(() => _expandedSections['vitals'] = expanded),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RecordTextField(
                        controller: _bpSystolicController,
                        label: 'BP Systolic',
                        hint: 'mmHg',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('/', style: TextStyle(fontSize: 20)),
                    ),
                    Expanded(
                      child: RecordTextField(
                        controller: _bpDiastolicController,
                        label: 'BP Diastolic',
                        hint: 'mmHg',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: RecordTextField(controller: _pulseController, label: 'Pulse', hint: 'bpm', keyboardType: TextInputType.number)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: RecordTextField(controller: _respiratoryRateController, label: 'RR', hint: '/min', keyboardType: TextInputType.number)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: RecordTextField(controller: _spo2Controller, label: 'SpO2', hint: '%', keyboardType: TextInputType.number)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Heart Sounds Section
          RecordFormSection(
            sectionKey: _sectionKeys['sounds'],
            title: 'Heart Sounds',
            icon: Icons.hearing_rounded,
            accentColor: Colors.purple,
            collapsible: true,
            initiallyExpanded: _expandedSections['sounds'] ?? false,
            completionSummary: _selectedMurmurs.isNotEmpty 
                ? '${_selectedMurmurs.length} murmurs, S1: $_s1, S2: $_s2'
                : (_s1 != 'Normal' || _s2 != 'Normal' ? 'S1: $_s1, S2: $_s2' : null),
            onToggle: (expanded) => setState(() => _expandedSections['sounds'] = expanded),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown('S1', _s1, ['Normal', 'Loud', 'Soft', 'Variable'],
                        (v) => setState(() => _s1 = v!), isDark),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildDropdown('S2', _s2, ['Normal', 'Loud', 'Soft', 'Split', 'Fixed Split'],
                        (v) => setState(() => _s2 = v!), isDark),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: RecordTextField(controller: _s3Controller, label: 'S3', hint: 'Present/Absent')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: RecordTextField(controller: _s4Controller, label: 'S4', hint: 'Present/Absent')),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ChipSelectorSection(
                  title: 'Murmurs',
                  options: _murmurOptions,
                  selected: _selectedMurmurs,
                  onChanged: (list) => setState(() => _selectedMurmurs = list),
                  accentColor: Colors.purple,
                ),
                if (_selectedMurmurs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  RecordTextField(
                    controller: _murmurDetailsController,
                    label: 'Murmur Details',
                    hint: 'Grade, radiation, timing',
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Cardiac Examination Section
          RecordFormSection(
            sectionKey: _sectionKeys['exam'],
            title: 'Cardiac Examination',
            icon: Icons.favorite_border_rounded,
            accentColor: Colors.pink,
            collapsible: true,
            initiallyExpanded: _expandedSections['exam'] ?? false,
            completionSummary: _jvpController.text.isNotEmpty || _peripheralPulsesController.text.isNotEmpty
                ? 'JVP: ${_jvpController.text.isNotEmpty ? _jvpController.text : "N/A"}'
                : null,
            onToggle: (expanded) => setState(() => _expandedSections['exam'] = expanded),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: RecordTextField(controller: _jvpController, label: 'JVP', hint: 'cm H2O')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: RecordTextField(controller: _apexBeatController, label: 'Apex Beat', hint: 'Location, character')),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: RecordTextField(controller: _heaveController, label: 'Heave', hint: 'Present/Absent')),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: RecordTextField(controller: _thrillController, label: 'Thrill', hint: 'Present/Absent')),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(controller: _peripheralPulsesController, label: 'Peripheral Pulses', hint: 'Volume, character'),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(controller: _edemaController, label: 'Edema', hint: 'Pedal, sacral, pitting'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Investigations Section
          RecordFormSection(
            sectionKey: _sectionKeys['tests'],
            title: 'Investigations',
            icon: Icons.biotech_rounded,
            accentColor: Colors.cyan,
            collapsible: true,
            initiallyExpanded: _expandedSections['tests'] ?? false,
            completionSummary: _selectedInvestigations.isNotEmpty
                ? '${_selectedInvestigations.length} tests ordered'
                : null,
            onToggle: (expanded) => setState(() => _expandedSections['tests'] = expanded),
            child: Column(
              children: [
                ChipSelectorSection(
                  title: 'Tests Ordered',
                  options: _investigationOptions,
                  selected: _selectedInvestigations,
                  onChanged: (list) => setState(() => _selectedInvestigations = list),
                  accentColor: Colors.cyan,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(controller: _ecgFindingsController, label: 'ECG Findings', hint: 'Rhythm, axis, intervals, ST changes', maxLines: 2),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(controller: _echoFindingsController, label: 'Echo Findings', hint: 'EF, wall motion, valves', maxLines: 2),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(controller: _labResultsController, label: 'Lab Results', hint: 'Troponin, BNP, lipids', maxLines: 2),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Assessment Section
          RecordFormSection(
            sectionKey: _sectionKeys['assessment'],
            title: 'Assessment & Plan',
            icon: Icons.assignment_rounded,
            accentColor: Colors.green,
            collapsible: true,
            initiallyExpanded: _expandedSections['assessment'] ?? true,
            completionSummary: _diagnosisController.text.isNotEmpty
                ? _diagnosisController.text
                : null,
            onToggle: (expanded) => setState(() => _expandedSections['assessment'] = expanded),
            child: Column(
              children: [
                RecordTextField(
                  controller: _diagnosisController,
                  label: 'Diagnosis',
                  hint: 'e.g., ACS, Heart Failure, Arrhythmia',
                  maxLines: 2,
                  enableVoice: true,
                  suggestions: diagnosisSuggestions,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(
                  controller: _treatmentController,
                  label: 'Treatment Plan',
                  hint: 'Medications, interventions, follow-up',
                  maxLines: 3,
                  enableVoice: true,
                  suggestions: treatmentSuggestions,
                ),
                const SizedBox(height: AppSpacing.md),
                RecordTextField(
                  controller: _clinicalNotesController,
                  label: 'Clinical Notes',
                  hint: 'Additional observations',
                  maxLines: 3,
                  enableVoice: true,
                  suggestions: clinicalNotesSuggestions,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save Button
          RecordSaveButton(
            onPressed: () => _saveRecord(db),
            isLoading: _isSaving,
            label: widget.existingRecord != null ? 'Update Record' : 'Save Record',
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

}
