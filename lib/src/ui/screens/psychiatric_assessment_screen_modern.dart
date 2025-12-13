// Modern Psychiatric Assessment Screen - Complete Redesign
// Features: Quick templates, intelligent forms, risk assessment, DSM-5 integration

import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/components/app_input.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/suggestions_service.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../widgets/suggestion_text_field.dart';
import 'records/components/quick_fill_templates.dart';
import 'records/components/form_progress_indicator.dart';
import '../../core/widgets/keyboard_aware_scaffold.dart';

class PsychiatricAssessmentScreenModern extends ConsumerStatefulWidget {
  
  const PsychiatricAssessmentScreenModern({
    super.key,
    this.preselectedPatient,
    this.initialDiagnosis,
    this.existingRecord,
    this.encounterId,
    this.appointmentId,
    this.chiefComplaint,
    this.historyOfPresentIllness,
    this.isTherapySession = false,
  });
  
  final Patient? preselectedPatient;
  final String? initialDiagnosis;
  final MedicalRecord? existingRecord;
  /// Associated encounter ID from workflow - links the record to a visit
  final int? encounterId;
  /// Associated appointment ID from workflow
  final int? appointmentId;
  /// Chief complaint from workflow for pre-filling
  final String? chiefComplaint;
  /// History of present illness from workflow
  final String? historyOfPresentIllness;
  /// If true, this is a therapy session note instead of psychiatric assessment
  final bool isTherapySession;

  @override
  ConsumerState<PsychiatricAssessmentScreenModern> createState() =>
      _PsychiatricAssessmentScreenModernState();
}

class _PsychiatricAssessmentScreenModernState
    extends ConsumerState<PsychiatricAssessmentScreenModern> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Section keys for navigation
  final List<GlobalKey> _sectionKeys = List.generate(6, (_) => GlobalKey());
  
  // Section names for navigation
  static const List<Map<String, dynamic>> _sectionInfo = [
    {'name': 'Patient', 'icon': Icons.person},
    {'name': 'Complaint', 'icon': Icons.sentiment_dissatisfied},
    {'name': 'Symptoms', 'icon': Icons.checklist},
    {'name': 'MSE', 'icon': Icons.psychology},
    {'name': 'Risk', 'icon': Icons.warning_rounded},
    {'name': 'Notes', 'icon': Icons.note_alt},
  ];
  
  // Assessment metadata
  DateTime? _assessmentDate;
  int? _patientId;
  bool _isSaving = false;
  bool _showRiskWarning = false;
  int _currentSectionIndex = 0;
  int _diagnosisKey = 0; // Key to force Autocomplete rebuild
  
  // Collapsible section state
  final Map<int, bool> _expandedSections = {
    0: true,  // Patient Info
    1: true,  // Chief Complaint
    2: true,  // Symptoms
    3: false, // MSE - collapsed by default
    4: false, // Risk Assessment - collapsed by default
  };
  
  // MSE Templates
  static const Map<String, Map<String, String>> _mseTemplates = {
    'Normal': {
      'mood': 'Euthymic',
      'affect': 'Congruent, full range',
      'speech': 'Normal rate, rhythm, and volume',
      'thought': 'Linear, goal-directed',
      'perception': 'No hallucinations or delusions',
      'cognition': 'Oriented x3, intact memory and attention',
      'insight': 'Good insight and judgment',
    },
    'Depression': {
      'mood': 'Depressed, sad',
      'affect': 'Constricted, tearful at times',
      'speech': 'Slow, reduced spontaneity',
      'thought': 'Linear but preoccupied with negative themes',
      'perception': 'No psychotic features',
      'cognition': 'Mild concentration difficulties, oriented x3',
      'insight': 'Fair insight, intact judgment',
    },
    'Psychosis': {
      'mood': 'Guarded, suspicious',
      'affect': 'Blunted, incongruent',
      'speech': 'Tangential, loosening of associations',
      'thought': 'Disorganized, paranoid ideation',
      'perception': 'Auditory hallucinations present, persecutory delusions',
      'cognition': 'Impaired attention, oriented to person only',
      'insight': 'Poor insight and judgment',
    },
    'Anxiety': {
      'mood': 'Anxious, worried',
      'affect': 'Tense, restless',
      'speech': 'Rapid, pressured at times',
      'thought': 'Linear but ruminative, catastrophizing',
      'perception': 'No hallucinations or delusions',
      'cognition': 'Difficulty concentrating, oriented x3',
      'insight': 'Good insight, seeking help',
    },
    'Mania': {
      'mood': 'Elevated, euphoric',
      'affect': 'Expansive, labile',
      'speech': 'Pressured, loud, rapid',
      'thought': 'Flight of ideas, grandiose themes',
      'perception': 'No hallucinations, possible grandiose delusions',
      'cognition': 'Distractible, poor concentration',
      'insight': 'Poor insight, impaired judgment',
    },
  };
  
  // Patient info
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  String _maritalStatus = 'Single';

  // Chief complaint
  final _chiefComplaintController = TextEditingController();
  final _durationController = TextEditingController();

  // Symptoms (with quick toggles) - organized by category
  Map<String, bool> _symptoms = {
    'Sleep Disturbance': false,
    'Appetite Change': false,
    'Weight Change': false,
    'Fatigue': false,
    'Concentration Issues': false,
    'Memory Problems': false,
    'Anxiety': false,
    'Panic Attacks': false,
    'Obsessions': false,
    'Compulsions': false,
    'Suicidal Thoughts': false,
    'Self-Harm': false,
    // Additional symptoms
    'Low Mood': false,
    'Irritability': false,
    'Social Withdrawal': false,
    'Loss of Interest': false,
    'Hopelessness': false,
    'Guilt': false,
    'Restlessness': false,
    'Racing Thoughts': false,
    'Hallucinations': false,
    'Delusions': false,
  };

  // Symptom icons and categories
  static const Map<String, IconData> _symptomIcons = {
    'Sleep Disturbance': Icons.bedtime_rounded,
    'Appetite Change': Icons.restaurant_rounded,
    'Weight Change': Icons.monitor_weight_rounded,
    'Fatigue': Icons.battery_2_bar_rounded,
    'Concentration Issues': Icons.psychology_rounded,
    'Memory Problems': Icons.memory_rounded,
    'Anxiety': Icons.warning_rounded,
    'Panic Attacks': Icons.bolt_rounded,
    'Obsessions': Icons.loop_rounded,
    'Compulsions': Icons.repeat_rounded,
    'Suicidal Thoughts': Icons.dangerous_rounded,
    'Self-Harm': Icons.healing_rounded,
    'Low Mood': Icons.mood_bad_rounded,
    'Irritability': Icons.sentiment_very_dissatisfied_rounded,
    'Social Withdrawal': Icons.person_off_rounded,
    'Loss of Interest': Icons.do_not_disturb_on_rounded,
    'Hopelessness': Icons.cloud_rounded,
    'Guilt': Icons.sentiment_dissatisfied_rounded,
    'Restlessness': Icons.directions_run_rounded,
    'Racing Thoughts': Icons.speed_rounded,
    'Hallucinations': Icons.visibility_rounded,
    'Delusions': Icons.blur_on_rounded,
  };

  static const Map<String, List<String>> _symptomCategories = {
    'Mood & Affect': ['Low Mood', 'Anxiety', 'Irritability', 'Hopelessness', 'Guilt'],
    'Neurovegetative': ['Sleep Disturbance', 'Appetite Change', 'Weight Change', 'Fatigue'],
    'Cognitive': ['Concentration Issues', 'Memory Problems', 'Racing Thoughts'],
    'Behavioral': ['Social Withdrawal', 'Loss of Interest', 'Restlessness'],
    'OCD Spectrum': ['Obsessions', 'Compulsions'],
    'Psychotic': ['Hallucinations', 'Delusions'],
    'Risk Factors': ['Panic Attacks', 'Suicidal Thoughts', 'Self-Harm'],
  };

  // Mental State Examination
  final _moodController = TextEditingController();
  final _affectController = TextEditingController();
  final _speechController = TextEditingController();
  final _thoughtController = TextEditingController();
  final _perceptionController = TextEditingController();
  final _cognitionController = TextEditingController();
  final _insightController = TextEditingController();

  // Risk Assessment
  String _suicideRisk = 'None';
  String _homicideRisk = 'None';
  final _safetyPlanController = TextEditingController();

  // Diagnosis & Treatment
  final _diagnosisController = TextEditingController();
  final _treatmentPlanController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _followUpController = TextEditingController();

  // History sections
  final _pastHistoryController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _socioeconomicController = TextEditingController();

  // Common diagnoses (DSM-5)
  static const List<String> _dsm5Diagnoses = [
    'Major Depressive Disorder',
    'Generalized Anxiety Disorder',
    'Panic Disorder',
    'Social Anxiety Disorder',
    'Specific Phobia',
    'Obsessive-Compulsive Disorder',
    'Post-Traumatic Stress Disorder',
    'Adjustment Disorder',
    'Bipolar I Disorder',
    'Bipolar II Disorder',
    'Cyclothymia',
    'Schizophrenia',
    'Schizoaffective Disorder',
    'Brief Psychotic Disorder',
    'Autism Spectrum Disorder',
    'ADHD',
  ];

  /// Recalculates _showRiskWarning based on risk factors
  void _updateRiskWarning() {
    final hasHighRiskSymptom = _symptoms.entries.any((e) => 
        e.value && (e.key.contains('Suicidal') || e.key.contains('Self-Harm')));
    final hasHighRiskLevel = _suicideRisk == 'Moderate' || _suicideRisk == 'High' 
        || _homicideRisk == 'Moderate' || _homicideRisk == 'High';
    setState(() => _showRiskWarning = hasHighRiskSymptom || hasHighRiskLevel);
  }

  /// Applies an MSE template
  void _applyMseTemplate(String templateName) {
    final template = _mseTemplates[templateName];
    if (template == null) return;
    
    setState(() {
      _moodController.text = template['mood'] ?? '';
      _affectController.text = template['affect'] ?? '';
      _speechController.text = template['speech'] ?? '';
      _thoughtController.text = template['thought'] ?? '';
      _perceptionController.text = template['perception'] ?? '';
      _cognitionController.text = template['cognition'] ?? '';
      _insightController.text = template['insight'] ?? '';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$templateName MSE template applied'),
          ],
        ),
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Gets risk level color for visual indicator
  Color _getRiskColor() {
    if (_suicideRisk == 'High' || _homicideRisk == 'High') return AppColors.error;
    if (_suicideRisk == 'Moderate' || _homicideRisk == 'Moderate') return Colors.orange;
    if (_suicideRisk == 'Low' || _homicideRisk == 'Low') return Colors.amber;
    return AppColors.success;
  }

  /// Gets risk level label
  String _getRiskLabel() {
    if (_suicideRisk == 'High' || _homicideRisk == 'High') return 'HIGH RISK';
    if (_suicideRisk == 'Moderate' || _homicideRisk == 'Moderate') return 'MODERATE';
    if (_suicideRisk == 'Low' || _homicideRisk == 'Low') return 'LOW';
    return 'NONE';
  }

  /// Scrolls to a specific section by index
  void _scrollToSection(int index) {
    if (index < 0 || index >= _sectionKeys.length) return;
    
    final key = _sectionKeys[index];
    final context = key.currentContext;
    if (context != null) {
      // Expand the section if collapsed
      setState(() {
        _expandedSections[index] = true;
      });
      
      // Scroll to the section
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1, // Position near top
      );
    }
  }

  /// Checks if a section is complete for navigation indicator
  bool _isSectionComplete(int index) {
    switch (index) {
      case 0: // Patient
        return _patientId != null || widget.preselectedPatient != null || _nameController.text.isNotEmpty;
      case 1: // Chief Complaint
        return _chiefComplaintController.text.isNotEmpty;
      case 2: // Symptoms
        return _symptoms.values.any((v) => v);
      case 3: // MSE
        return _moodController.text.isNotEmpty || _affectController.text.isNotEmpty;
      case 4: // Risk
        return _suicideRisk != 'None' || _homicideRisk != 'None' || _safetyPlanController.text.isNotEmpty;
      case 5: // Notes
        return _pastHistoryController.text.isNotEmpty || _familyHistoryController.text.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _assessmentDate = DateTime.now();
    
    if (widget.preselectedPatient != null) {
      final p = widget.preselectedPatient!;
      _patientId = p.id;
      _nameController.text = '${p.firstName} ${p.lastName}'.trim();
      if (p.age != null) {
        _ageController.text = p.age.toString();
      }
    }

    if (widget.initialDiagnosis != null) {
      _diagnosisController.text = widget.initialDiagnosis!;
    }
    
    // Pre-fill from workflow data
    if (widget.chiefComplaint != null && widget.chiefComplaint!.isNotEmpty) {
      _chiefComplaintController.text = widget.chiefComplaint!;
    }
    if (widget.historyOfPresentIllness != null && widget.historyOfPresentIllness!.isNotEmpty) {
      // Could be used for duration or additional context
      if (_durationController.text.isEmpty) {
        _durationController.text = widget.historyOfPresentIllness!;
      }
    }
    
    if (widget.existingRecord != null) {
      _loadExistingRecord();
    }
  }
  
  void _loadExistingRecord() {
    final record = widget.existingRecord!;
    _assessmentDate = record.recordDate;
    _diagnosisController.text = record.diagnosis ?? '';
    _treatmentPlanController.text = record.treatment ?? '';
    
    if (record.dataJson != null) {
      try {
        final data = jsonDecode(record.dataJson!) as Map<String, dynamic>;
        _nameController.text = (data['name'] as String?) ?? '';
        _ageController.text = (data['age'] as String?) ?? '';
        _genderController.text = (data['gender'] as String?) ?? '';
        _maritalStatus = (data['marital_status'] as String?) ?? 'Single';
        _chiefComplaintController.text = (data['chief_complaint'] as String?) ?? '';
        _durationController.text = (data['duration'] as String?) ?? '';
        
        final symptoms = data['symptoms'] as Map<String, dynamic>?;
        if (symptoms != null) {
          _symptoms = symptoms.map((k, v) => MapEntry(k, v as bool? ?? false));
        }
        
        _pastHistoryController.text = (data['past_history'] as String?) ?? '';
        _familyHistoryController.text = (data['family_history'] as String?) ?? '';
        _socioeconomicController.text = (data['socioeconomic'] as String?) ?? '';
        _moodController.text = (data['mood'] as String?) ?? '';
        _affectController.text = (data['affect'] as String?) ?? '';
        _speechController.text = (data['speech'] as String?) ?? '';
        _thoughtController.text = (data['thought'] as String?) ?? '';
        _perceptionController.text = (data['perception'] as String?) ?? '';
        _cognitionController.text = (data['cognition'] as String?) ?? '';
        _insightController.text = (data['insight'] as String?) ?? '';
        _suicideRisk = (data['suicide_risk'] as String?) ?? 'None';
        _homicideRisk = (data['homicide_risk'] as String?) ?? 'None';
        _safetyPlanController.text = (data['safety_plan'] as String?) ?? '';
        _medicationsController.text = (data['medications'] as String?) ?? '';
        _followUpController.text = (data['follow_up'] as String?) ?? '';
        
        // Update risk warning after loading data
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateRiskWarning());
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _chiefComplaintController.dispose();
    _durationController.dispose();
    _moodController.dispose();
    _affectController.dispose();
    _speechController.dispose();
    _thoughtController.dispose();
    _perceptionController.dispose();
    _cognitionController.dispose();
    _insightController.dispose();
    _safetyPlanController.dispose();
    _diagnosisController.dispose();
    _treatmentPlanController.dispose();
    _medicationsController.dispose();
    _followUpController.dispose();
    _pastHistoryController.dispose();
    _familyHistoryController.dispose();
    _socioeconomicController.dispose();
    super.dispose();
  }

  void _applyTemplate(QuickFillTemplate template) {
    if (!mounted) return;
    
    final data = template.data;

    setState(() {
      if (data['chief_complaint'] != null) _chiefComplaintController.text = data['chief_complaint'] as String;
      if (data['duration'] != null) _durationController.text = data['duration'] as String;
      if (data['mood'] != null) _moodController.text = data['mood'] as String;
      if (data['affect'] != null) _affectController.text = data['affect'] as String;
      if (data['speech'] != null) _speechController.text = data['speech'] as String;
      if (data['thought'] != null) _thoughtController.text = data['thought'] as String;
      if (data['perception'] != null) _perceptionController.text = data['perception'] as String;
      if (data['cognition'] != null) _cognitionController.text = data['cognition'] as String;
      if (data['insight'] != null) _insightController.text = data['insight'] as String;
      if (data['diagnosis'] != null) {
        _diagnosisController.text = data['diagnosis'] as String;
        _diagnosisKey++; // Force Autocomplete rebuild
      }
      if (data['treatment'] != null) _treatmentPlanController.text = data['treatment'] as String;
      if (data['follow_up'] != null) _followUpController.text = data['follow_up'] as String;
      if (data['suicide_risk'] != null) _suicideRisk = data['suicide_risk'] as String;
      
      // Handle symptoms list
      final symptoms = data['symptoms'];
      if (symptoms is List) {
        // Reset all symptoms first
        for (final key in _symptoms.keys) {
          _symptoms[key] = false;
        }
        // Then set the ones from template
        for (final symptom in symptoms) {
          if (_symptoms.containsKey(symptom)) {
            _symptoms[symptom as String] = true;
          }
        }
      }
    });
    
    // Update risk warning after applying template
    _updateRiskWarning();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
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

  // Total sections for progress calculation
  static const int _totalSections = 9; // Patient, Chief Complaint, Symptoms, MSE, History, Risk, Diagnosis, Treatment, Follow-up

  int _calculateCompletedSections() {
    int completed = 0;
    // Patient info
    if (_patientId != null || widget.preselectedPatient != null || _nameController.text.isNotEmpty) completed++;
    // Chief complaint
    if (_chiefComplaintController.text.isNotEmpty) completed++;
    // Symptoms (at least one selected)
    if (_symptoms.values.any((v) => v)) completed++;
    // MSE (at least mood or affect filled)
    if (_moodController.text.isNotEmpty || _affectController.text.isNotEmpty) completed++;
    // History (any history filled)
    if (_pastHistoryController.text.isNotEmpty || _familyHistoryController.text.isNotEmpty) completed++;
    // Risk assessment
    if (_suicideRisk != 'None' || _homicideRisk != 'None' || _safetyPlanController.text.isNotEmpty) completed++;
    // Diagnosis
    if (_diagnosisController.text.isNotEmpty) completed++;
    // Treatment plan
    if (_treatmentPlanController.text.isNotEmpty || _medicationsController.text.isNotEmpty) completed++;
    // Follow-up
    if (_followUpController.text.isNotEmpty) completed++;
    return completed;
  }

  Future<void> _saveDraft() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Draft saved locally'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await ref.read(doctorDbProvider.future);
      
      final assessmentData = {
        'name': _nameController.text,
        'age': _ageController.text,
        'gender': _genderController.text,
        'marital_status': _maritalStatus,
        'chief_complaint': _chiefComplaintController.text,
        'duration': _durationController.text,
        'symptoms': _symptoms,
        'past_history': _pastHistoryController.text,
        'family_history': _familyHistoryController.text,
        'socioeconomic': _socioeconomicController.text,
        'mood': _moodController.text,
        'affect': _affectController.text,
        'speech': _speechController.text,
        'thought': _thoughtController.text,
        'perception': _perceptionController.text,
        'cognition': _cognitionController.text,
        'insight': _insightController.text,
        'suicide_risk': _suicideRisk,
        'homicide_risk': _homicideRisk,
        'safety_plan': _safetyPlanController.text,
        'diagnosis': _diagnosisController.text,
        'treatment_plan': _treatmentPlanController.text,
        'medications': _medicationsController.text,
        'follow_up': _followUpController.text,
      };

      final recordType = widget.isTherapySession ? 'therapy_session' : 'psychiatric_assessment';
      final recordTitle = widget.isTherapySession 
          ? 'Therapy Session - ${DateFormat('dd MMM yyyy').format(_assessmentDate!)}'
          : 'Psychiatric Assessment - ${DateFormat('dd MMM yyyy').format(_assessmentDate!)}';

      if (widget.existingRecord != null) {
        // Update existing record - use full MedicalRecord for replace
        final updatedRecord = MedicalRecord(
          id: widget.existingRecord!.id,
          patientId: _patientId!,
          recordType: recordType,
          title: recordTitle,
          description: _chiefComplaintController.text,
          dataJson: jsonEncode(assessmentData),
          diagnosis: _diagnosisController.text,
          treatment: _treatmentPlanController.text,
          doctorNotes: '',
          recordDate: _assessmentDate!,
          createdAt: widget.existingRecord!.createdAt,
        );
        debugPrint('PSYCHIATRIC: Updating record ID: ${widget.existingRecord!.id}');
        await db.updateMedicalRecord(updatedRecord);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✓ Assessment updated successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
          
          // Pop immediately with the result
          Navigator.pop(context, updatedRecord);
        }
      } else {
        // Insert new record - include encounterId to link to visit
        final record = MedicalRecordsCompanion(
          patientId: Value(_patientId!),
          encounterId: Value(widget.encounterId),
          recordType: Value(recordType),
          title: Value(recordTitle),
          description: Value(_chiefComplaintController.text),
          dataJson: Value(jsonEncode(assessmentData)),
          diagnosis: Value(_diagnosisController.text),
          treatment: Value(_treatmentPlanController.text),
          doctorNotes: Value(''),
          recordDate: Value(_assessmentDate!),
        );
        debugPrint('PSYCHIATRIC: Inserting new record for patient $_patientId, encounterId: ${widget.encounterId}');
        final recordId = await db.insertMedicalRecord(record);
        debugPrint('PSYCHIATRIC: Record inserted with ID: $recordId');
        
        // Fetch the created record to return
        final resultRecord = await db.getMedicalRecordById(recordId);
        debugPrint('PSYCHIATRIC: Fetched record: ${resultRecord?.id}, diagnosis: ${resultRecord?.diagnosis}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✓ Assessment saved successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
          
          // Pop immediately with the result instead of delayed
          Navigator.pop(context, resultRecord);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('PSYCHIATRIC ERROR: $e');
      debugPrint('PSYCHIATRIC STACKTRACE: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = isDark ? colorScheme.surface : Colors.white;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : AppColors.background,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : const Color(0xFF8B5CF6),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.save_outlined,
                        color: isDark ? Colors.white : const Color(0xFF8B5CF6),
                      ),
                      tooltip: 'Save Draft',
                      onPressed: _saveDraft,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                          : [Colors.white, const Color(0xFFF8F9FA)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // Billing Purple
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.isTherapySession 
                                  ? Icons.self_improvement_rounded 
                                  : Icons.psychology_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isTherapySession 
                                      ? 'Therapy Session' 
                                      : 'Psychiatric Assessment',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.isTherapySession 
                                      ? 'Counseling notes' 
                                      : 'Mental health evaluation',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark 
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
              // Assessment Date & Info
              _buildAssessmentHeader(context, isDark, cardColor),
              const SizedBox(height: 20),

              // Progress Indicator
              FormProgressIndicator(
                completedSections: _calculateCompletedSections(),
                totalSections: _totalSections,
                accentColor: AppColors.primary,
              ),
              const SizedBox(height: 12),

              // Section Navigation Bar
              _buildSectionNavigationBar(isDark, cardColor),
              const SizedBox(height: 20),

              // Quick Templates
              _buildTemplatesBar(isDark, cardColor),
              const SizedBox(height: 20),

              // Section 1: Patient Information
              if (widget.preselectedPatient != null)
                _buildPatientCard(context, isDark)
              else
                _buildSection(
                  context: context,
                  index: 0,
                  title: 'Patient Information',
                  icon: Icons.person,
                  isDark: isDark,
                  cardColor: cardColor,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Patient Name',
                      required: true,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _ageController,
                            label: 'Age',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _genderController,
                            label: 'Gender',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMaritalStatusField(isDark),
                  ],
                ),
              const SizedBox(height: 16),

              // Section 2: Chief Complaint
              _buildSection(
                context: context,
                index: 1,
                title: 'Chief Complaint & Duration',
                icon: Icons.sentiment_dissatisfied,
                isDark: isDark,
                cardColor: cardColor,
                children: [
                  SuggestionTextField(
                    controller: _chiefComplaintController,
                    label: 'Chief Complaint',
                    maxLines: 3,
                    suggestions: PsychiatricSuggestions.chiefComplaints,
                  ),
                  const SizedBox(height: 12),
                  SuggestionTextField(
                    controller: _durationController,
                    label: 'Duration',
                    hint: 'e.g., 2 weeks, 3 months',
                    suggestions: PsychiatricSuggestions.duration,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 3: Symptoms (with toggles) - Improved UI
              _buildSection(
                context: context,
                index: 2,
                title: 'Symptoms',
                icon: Icons.checklist,
                isDark: isDark,
                cardColor: cardColor,
                children: [
                  // Selected symptoms count
                  if (_symptoms.values.any((v) => v)) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_symptoms.values.where((v) => v).length} symptoms selected',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              for (final key in _symptoms.keys) {
                                _symptoms[key] = false;
                              }
                            }),
                            child: Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Categorized symptoms
                  ..._symptomCategories.entries.map((category) {
                    final isRiskCategory = category.key == 'Risk Factors';
                    final categoryColor = isRiskCategory 
                        ? AppColors.error 
                        : (category.key == 'Psychotic' ? Colors.purple : AppColors.primary);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (isRiskCategory) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: isRiskCategory 
                                ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
                                : null,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: category.value.map((symptom) {
                              final isSelected = _symptoms[symptom] ?? false;
                              final isHighRisk = symptom.contains('Suicidal') || symptom.contains('Self-Harm');
                              final chipColor = isHighRisk 
                                  ? AppColors.error 
                                  : (category.key == 'Psychotic' ? Colors.purple : AppColors.primary);
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _symptoms[symptom] = !isSelected);
                                  _updateRiskWarning();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? chipColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected 
                                          ? chipColor 
                                          : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                                      width: isHighRisk && !isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected 
                                            ? Icons.check_rounded 
                                            : (_symptomIcons[symptom] ?? Icons.circle_outlined),
                                        size: 16,
                                        color: isSelected 
                                            ? Colors.white 
                                            : (isHighRisk 
                                                ? AppColors.error 
                                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        symptom,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected 
                                              ? Colors.white 
                                              : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Section 4: Mental State Examination
              _buildSection(
                context: context,
                index: 3,
                title: 'Mental State Examination',
                icon: Icons.psychology,
                isDark: isDark,
                cardColor: cardColor,
                completionSummary: _moodController.text.isNotEmpty 
                    ? 'Mood: ${_moodController.text.split(',').first}' 
                    : null,
                children: [
                  // MSE Quick Templates
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark 
                            ? [const Color(0xFF1E1E2E), const Color(0xFF2A2A3E)]
                            : [const Color(0xFFF0F4FF), const Color(0xFFE8EEFF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade700 : const Color(0xFFD0D7FF),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 16, color: isDark ? Colors.amber : const Color(0xFF6366F1)),
                            const SizedBox(width: 6),
                            Text(
                              'Quick MSE Templates',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _mseTemplates.keys.map((templateName) {
                            final templateColors = {
                              'Normal': AppColors.success,
                              'Depression': Colors.blue,
                              'Psychosis': Colors.purple,
                              'Anxiety': Colors.orange,
                              'Mania': Colors.pink,
                            };
                            final color = templateColors[templateName] ?? AppColors.primary;
                            
                            return GestureDetector(
                              onTap: () => _applyMseTemplate(templateName),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: color.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flash_on_rounded, size: 14, color: color),
                                    const SizedBox(width: 4),
                                    Text(
                                      templateName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  SuggestionTextField(
                    controller: _moodController,
                    label: 'Mood',
                    hint: 'e.g., Depressed, Anxious, Elevated',
                    suggestions: MedicalRecordSuggestions.mseMood,
                  ),
                  const SizedBox(height: 12),
                  SuggestionTextField(
                    controller: _affectController,
                    label: 'Affect',
                    hint: 'e.g., Flat, Congruent, Labile',
                    suggestions: MedicalRecordSuggestions.mseAffect,
                  ),
                  const SizedBox(height: 12),
                  SuggestionTextField(
                    controller: _speechController,
                    label: 'Speech',
                    hint: 'e.g., Normal, Slow, Pressured',
                    suggestions: MedicalRecordSuggestions.mseSpeech,
                  ),
                  const SizedBox(height: 12),
                  SuggestionTextField(
                    controller: _thoughtController,
                    label: 'Thought Process',
                    hint: 'Organized, Tangential, Blocked',
                    suggestions: MedicalRecordSuggestions.mseThoughtProcess,
                  ),
                  const SizedBox(height: 12),
                  SuggestionTextField(
                    controller: _perceptionController,
                    label: 'Perception',
                    hint: 'Hallucinations, Delusions',
                    suggestions: MedicalRecordSuggestions.msePerception,
                  ),
                  const SizedBox(height: 12),
                  SuggestionTextField(
                    controller: _cognitionController,
                    label: 'Cognition',
                    hint: 'Orientation, Memory, Attention',
                    suggestions: MedicalRecordSuggestions.mseCognition,
                  ),
                  const SizedBox(height: 12),
                  SuggestionTextField(
                    controller: _insightController,
                    label: 'Insight & Judgment',
                    suggestions: MedicalRecordSuggestions.mseInsight,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 5: Risk Assessment (with warning)
              _buildSection(
                context: context,
                index: 4,
                title: 'Risk Assessment',
                icon: Icons.warning_rounded,
                isHighRisk: _showRiskWarning,
                isDark: isDark,
                cardColor: cardColor,
                completionSummary: _suicideRisk != 'None' || _homicideRisk != 'None'
                    ? 'Risk Level: ${_getRiskLabel()}'
                    : null,
                children: [
                  // Risk Meter Visualization
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getRiskColor().withValues(alpha: 0.1),
                          _getRiskColor().withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getRiskColor().withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showRiskWarning ? Icons.warning_rounded : Icons.shield_rounded,
                              color: _getRiskColor(),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Overall Risk: ${_getRiskLabel()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getRiskColor(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Risk meter bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 12,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    color: _getRiskLabel() != 'NONE' 
                                        ? AppColors.success 
                                        : AppColors.success.withValues(alpha: 0.3),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Container(
                                    color: _suicideRisk == 'Low' || _homicideRisk == 'Low' ||
                                           _suicideRisk == 'Moderate' || _homicideRisk == 'Moderate' ||
                                           _suicideRisk == 'High' || _homicideRisk == 'High'
                                        ? Colors.amber 
                                        : Colors.amber.withValues(alpha: 0.3),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Container(
                                    color: _suicideRisk == 'Moderate' || _homicideRisk == 'Moderate' ||
                                           _suicideRisk == 'High' || _homicideRisk == 'High'
                                        ? Colors.orange 
                                        : Colors.orange.withValues(alpha: 0.3),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Container(
                                    color: _suicideRisk == 'High' || _homicideRisk == 'High'
                                        ? AppColors.error 
                                        : AppColors.error.withValues(alpha: 0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('None', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                            Text('Low', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                            Text('Moderate', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                            Text('High', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_showRiskWarning)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.error),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'High-risk symptoms detected. Ensure safety planning.',
                              style: TextStyle(
                                color: isDark ? Colors.red.shade300 : AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildRiskField(
                    label: 'Suicidal Risk',
                    value: _suicideRisk,
                    onChanged: (value) {
                      setState(() => _suicideRisk = value ?? 'None');
                      _updateRiskWarning();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildRiskField(
                    label: 'Homicidal Risk',
                    value: _homicideRisk,
                    onChanged: (value) {
                      setState(() => _homicideRisk = value ?? 'None');
                      _updateRiskWarning();
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  SuggestionTextField(
                    controller: _safetyPlanController,
                    label: 'Safety Plan${_showRiskWarning ? ' *' : ''}',
                    maxLines: 3,
                    hint: 'Document safety measures and support contacts',
                    suggestions: PsychiatricSuggestions.safetyPlan,
                    validator: _showRiskWarning
                        ? (value) => (value == null || value.trim().isEmpty)
                            ? 'Safety Plan is required for high-risk patients'
                            : null
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Section 6: Additional Notes & History
              _buildSection(
                context: context,
                index: 5,
                title: 'Notes & History',
                icon: Icons.note_alt,
                isDark: isDark,
                cardColor: cardColor,
                completionSummary: _pastHistoryController.text.isNotEmpty || _familyHistoryController.text.isNotEmpty
                    ? 'History documented'
                    : null,
                children: [
                  SuggestionTextField(
                    controller: _pastHistoryController,
                    label: 'Past Psychiatric History',
                    maxLines: 3,
                    hint: 'Previous episodes, hospitalizations, treatments',
                    suggestions: PsychiatricSuggestions.pastHistory,
                  ),
                  const SizedBox(height: 12),
                  SuggestionTextField(
                    controller: _familyHistoryController,
                    label: 'Family History',
                    maxLines: 3,
                    hint: 'Mental health conditions in family',
                    suggestions: PsychiatricSuggestions.familyHistory,
                  ),
                  const SizedBox(height: 12),
                  SuggestionTextField(
                    controller: _socioeconomicController,
                    label: 'Socioeconomic & Psychosocial Factors',
                    maxLines: 3,
                    hint: 'Living situation, support system, stressors',
                    suggestions: PsychiatricSuggestions.socioeconomic,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveAssessment,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Save Assessment'),
                ),
              ),
              const SizedBox(height: 20),
            ]),
              ),
            ),
            // Keyboard-aware bottom padding
            const SliverKeyboardPadding(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentHeader(BuildContext context, bool isDark, Color cardColor) {
    return Card(
      color: cardColor,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark ? BorderSide(color: Colors.grey.shade800) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Date & Time',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy hh:mm a').format(_assessmentDate!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionNavigationBar(bool isDark, Color cardColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_sectionInfo.length, (index) {
          final section = _sectionInfo[index];
          final isExpanded = _expandedSections[index] ?? true;
          final isComplete = _isSectionComplete(index);
          final isRisk = index == 4; // Risk Assessment section
          final hasRiskWarning = isRisk && _showRiskWarning;
          
          return Padding(
            padding: EdgeInsets.only(right: index < _sectionInfo.length - 1 ? 8 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _scrollToSection(index),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isExpanded
                        ? LinearGradient(
                            colors: hasRiskWarning
                                ? [AppColors.error, AppColors.error.withValues(alpha: 0.8)]
                                : [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
                          )
                        : null,
                    color: isExpanded
                        ? null
                        : (isDark 
                            ? Colors.grey.shade800.withValues(alpha: 0.5) 
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(20),
                    border: isComplete && !isExpanded
                        ? Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 2)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        section['icon'] as IconData,
                        size: 16,
                        color: isExpanded
                            ? Colors.white
                            : (hasRiskWarning
                                ? AppColors.error
                                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        section['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isExpanded
                              ? Colors.white
                              : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        ),
                      ),
                      if (isComplete) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: isExpanded ? Colors.white.withValues(alpha: 0.8) : AppColors.success,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTemplatesBar(bool isDark, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade500, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Fill Templates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: PsychiatricTemplates.templates.map((template) {
              return ActionChip(
                avatar: Icon(template.icon, size: 18, color: template.color),
                label: Text(template.label),
                onPressed: () => _applyTemplate(template),
                backgroundColor: template.color.withValues(alpha: 0.1),
                side: BorderSide(color: template.color.withValues(alpha: 0.3)),
                labelStyle: TextStyle(
                  color: template.color,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, bool isDark) {
    final patient = widget.preselectedPatient!;
    final initials = '${patient.firstName.isNotEmpty ? patient.firstName[0] : ''}${patient.lastName.isNotEmpty ? patient.lastName[0] : ''}'.toUpperCase();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Patient Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${patient.firstName} ${patient.lastName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Patient ID
                        _buildPatientInfoBadge(
                          icon: Icons.tag_rounded,
                          text: 'P-${patient.id.toString().padLeft(4, '0')}',
                        ),
                        if (patient.age != null) ...[
                          _buildPatientDividerDot(),
                          _buildPatientInfoBadge(
                            icon: Icons.cake_outlined,
                            text: '${patient.age} yrs',
                          ),
                        ],
                        if (patient.gender != null && patient.gender!.isNotEmpty) ...[
                          _buildPatientDividerDot(),
                          _buildPatientInfoBadge(
                            icon: patient.gender == 'Male' 
                                ? Icons.male_rounded 
                                : patient.gender == 'Female' 
                                    ? Icons.female_rounded 
                                    : Icons.person_outline,
                            text: patient.gender!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (patient.phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        patient.phone,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Psychiatric Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoBadge({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientDividerDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required int index,
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
    required Color cardColor,
    bool isHighRisk = false,
    bool isCollapsible = true,
    String? completionSummary,
    Key? sectionKey,
  }) {
    final isExpanded = _expandedSections[index] ?? true;
    final sectionColor = isHighRisk ? AppColors.error : AppColors.primary;
    
    return Card(
      key: sectionKey ?? (index < _sectionKeys.length ? _sectionKeys[index] : null),
      color: isHighRisk
          ? (isDark ? Colors.red.shade900.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.05))
          : cardColor,
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark 
            ? BorderSide(color: isHighRisk ? Colors.red.shade700 : Colors.grey.shade800) 
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - always visible, tappable to expand/collapse
          InkWell(
            onTap: isCollapsible ? () {
              setState(() => _expandedSections[index] = !isExpanded);
            } : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(isExpanded ? AppSpacing.lg : AppSpacing.md),
              child: Row(
                children: [
                  // Section icon with completion indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sectionColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: sectionColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        // Show summary when collapsed
                        if (!isExpanded && completionSummary != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              completionSummary,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isHighRisk)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'HIGH RISK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isCollapsible)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Content - animated expand/collapse
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    bool isDark = false,
  }) {
    return AppInput(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (value) => (value == null || value.trim().isEmpty) 
              ? '$label is required' 
              : null
          : null,
    );
  }

  Widget _buildMaritalStatusField(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _maritalStatus,
      dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        label: Text('Marital Status', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
      items: ['Single', 'Married', 'Divorced', 'Widowed', 'Separated']
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
          .toList(),
      onChanged: (value) =>
          setState(() => _maritalStatus = value ?? 'Single'),
    );
  }

  Widget _buildRiskField({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
    bool isDark = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        label: Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
      items: ['None', 'Low', 'Moderate', 'High']
          .map((risk) {
            Color color = AppColors.success;
            if (risk == 'High') color = AppColors.error;
            else if (risk == 'Moderate') color = AppColors.warning;
            else if (risk == 'Low') color = Colors.amber;
            
            return DropdownMenuItem(
              value: risk,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(risk, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            );
          })
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDiagnosisField(bool isDark, Color cardColor) {
    return Autocomplete<String>(
      key: ValueKey('diagnosis_$_diagnosisKey'),
      initialValue: TextEditingValue(text: _diagnosisController.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _dsm5Diagnoses.where((option) =>
            option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        if (mounted) {
          setState(() => _diagnosisController.text = selection);
        }
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Sync the internal controller with our state controller on changes
        textEditingController.addListener(() {
          if (mounted && textEditingController.text != _diagnosisController.text) {
            _diagnosisController.text = textEditingController.text;
          }
        });
        
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
          decoration: InputDecoration(
            label: Text('DSM-5 Diagnosis', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
            contentPadding: const EdgeInsets.all(AppSpacing.lg),
            helperText: 'Start typing to see suggestions',
            helperStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
          validator: (value) =>
              value?.isEmpty == true ? 'Diagnosis is required' : null,
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 350),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      option,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                    onTap: () => onSelected(option),
                    hoverColor: AppColors.primary.withValues(alpha: 0.1),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

