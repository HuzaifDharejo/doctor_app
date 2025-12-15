import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import 'quick_picker_bottom_sheet.dart';
import 'record_form_section.dart';
import 'styled_text_fields.dart';

/// A reusable Chief Complaint section for medical record forms
/// 
/// This section is common to almost all medical record types and includes:
/// - Chief complaint text field (with optional voice dictation)
/// - Duration field
/// - Symptom chips selector
/// 
/// Example:
/// ```dart
/// ChiefComplaintSection(
///   sectionKey: _sectionKeys['complaint'],
///   isExpanded: _expandedSections['complaint'] ?? true,
///   onToggle: (expanded) => setState(() => _expandedSections['complaint'] = expanded),
///   chiefComplaintController: _chiefComplaintController,
///   durationController: _durationController,
///   selectedSymptoms: _selectedSymptoms,
///   onSymptomsChanged: (list) => setState(() => _selectedSymptoms = list),
///   symptomOptions: ['Chest Pain', 'Dyspnea', ...],
///   accentColor: Colors.red,
/// )
/// ```
class ChiefComplaintSection extends StatelessWidget {
  const ChiefComplaintSection({
    super.key,
    this.sectionKey,
    required this.isExpanded,
    required this.onToggle,
    required this.chiefComplaintController,
    this.durationController,
    this.selectedSymptoms,
    this.onSymptomsChanged,
    this.symptomOptions,
    this.accentColor,
    this.title = 'Chief Complaint',
    this.icon = Icons.report_problem_rounded,
    this.showDuration = true,
    this.showSymptoms = true,
    this.chiefComplaintLabel = 'Chief Complaint',
    this.chiefComplaintHint = 'Describe the main presenting complaint...',
    this.durationLabel = 'Duration',
    this.durationHint = 'e.g., 3 days, 2 weeks',
    this.symptomsLabel = 'Associated Symptoms',
    this.maxLines = 3,
  });

  /// GlobalKey for scroll navigation
  final GlobalKey? sectionKey;
  
  /// Whether section is expanded (for collapsible mode)
  final bool isExpanded;
  
  /// Callback when section is toggled
  final void Function(bool expanded) onToggle;
  
  /// Controller for chief complaint text
  final TextEditingController chiefComplaintController;
  
  /// Controller for duration (optional)
  final TextEditingController? durationController;
  
  /// Currently selected symptoms
  final List<String>? selectedSymptoms;
  
  /// Callback when symptoms change
  final ValueChanged<List<String>>? onSymptomsChanged;
  
  /// Available symptom options
  final List<String>? symptomOptions;
  
  /// Accent color for the section
  final Color? accentColor;
  
  /// Section title
  final String title;
  
  /// Section icon
  final IconData icon;
  
  /// Whether to show duration field
  final bool showDuration;
  
  /// Whether to show symptoms chips
  final bool showSymptoms;
  
  /// Label for chief complaint field
  final String chiefComplaintLabel;
  
  /// Hint for chief complaint field
  final String chiefComplaintHint;
  
  /// Label for duration field
  final String durationLabel;
  
  /// Hint for duration field
  final String durationHint;
  
  /// Label for symptoms section
  final String symptomsLabel;
  
  /// Max lines for chief complaint field
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    
    return RecordFormSection(
      sectionKey: sectionKey,
      title: title,
      icon: icon,
      accentColor: color,
      collapsible: true,
      initiallyExpanded: isExpanded,
      onToggle: onToggle,
      completionSummary: _buildCompletionSummary(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chief Complaint TextField with voice and suggestions
          StyledTextField(
            label: chiefComplaintLabel,
            controller: chiefComplaintController,
            hint: chiefComplaintHint,
            icon: Icons.description_rounded,
            maxLines: maxLines,
            minLines: 2,
            isRequired: true,
            accentColor: color,
            enableVoice: true,
            suggestions: chiefComplaintSuggestions,
          ),
          
          // Duration Field
          if (showDuration && durationController != null) ...[
            const SizedBox(height: 16),
            StyledTextField(
              label: durationLabel,
              controller: durationController,
              hint: durationHint,
              icon: Icons.schedule_rounded,
              accentColor: color,
            ),
          ],
          
          // Symptoms - Quick Picker with icons
          if (showSymptoms && onSymptomsChanged != null) ...[
            const SizedBox(height: 20),
            QuickPickerField(
              label: symptomsLabel,
              selected: selectedSymptoms ?? [],
              options: commonSymptomOptions,
              onChanged: onSymptomsChanged!,
              accentColor: color,
              icon: Icons.sick_rounded,
              hint: 'Tap to select symptoms',
              pickerTitle: 'Associated Symptoms',
              pickerSubtitle: 'Select all that apply',
            ),
          ],
        ],
      ),
    );
  }
  
  String? _buildCompletionSummary() {
    final parts = <String>[];
    
    if (chiefComplaintController.text.isNotEmpty) {
      final text = chiefComplaintController.text;
      parts.add(text.length > 30 ? '${text.substring(0, 30)}...' : text);
    }
    
    if (selectedSymptoms != null && selectedSymptoms!.isNotEmpty) {
      parts.add('${selectedSymptoms!.length} symptom${selectedSymptoms!.length > 1 ? 's' : ''}');
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : null;
  }
}

/// A reusable Assessment/Diagnosis section for medical record forms
/// 
/// This section is common to all medical record types and includes:
/// - Diagnosis field (with suggestions)
/// - Treatment plan field
/// - Clinical notes field
/// 
/// Example:
/// ```dart
/// AssessmentSection(
///   sectionKey: _sectionKeys['assessment'],
///   isExpanded: _expandedSections['assessment'] ?? true,
///   onToggle: (expanded) => setState(() => _expandedSections['assessment'] = expanded),
///   diagnosisController: _diagnosisController,
///   treatmentController: _treatmentController,
///   notesController: _clinicalNotesController,
///   accentColor: Colors.red,
/// )
/// ```
class AssessmentSection extends StatelessWidget {
  const AssessmentSection({
    super.key,
    this.sectionKey,
    required this.isExpanded,
    required this.onToggle,
    required this.diagnosisController,
    this.treatmentController,
    this.notesController,
    this.accentColor,
    this.title = 'Assessment & Plan',
    this.icon = Icons.assignment_rounded,
    this.showTreatment = true,
    this.showNotes = true,
    this.diagnosisLabel = 'Diagnosis',
    this.diagnosisHint = 'Enter diagnosis or impression...',
    this.treatmentLabel = 'Treatment Plan',
    this.treatmentHint = 'Describe the treatment plan...',
    this.notesLabel = 'Clinical Notes',
    this.notesHint = 'Additional notes, recommendations, follow-up...',
    this.diagnosisRequired = true,
  });

  /// GlobalKey for scroll navigation
  final GlobalKey? sectionKey;
  
  /// Whether section is expanded
  final bool isExpanded;
  
  /// Callback when section is toggled
  final void Function(bool expanded) onToggle;
  
  /// Controller for diagnosis field
  final TextEditingController diagnosisController;
  
  /// Controller for treatment field
  final TextEditingController? treatmentController;
  
  /// Controller for notes field
  final TextEditingController? notesController;
  
  /// Accent color
  final Color? accentColor;
  
  /// Section title
  final String title;
  
  /// Section icon
  final IconData icon;
  
  /// Whether to show treatment field
  final bool showTreatment;
  
  /// Whether to show notes field
  final bool showNotes;
  
  /// Labels and hints
  final String diagnosisLabel;
  final String diagnosisHint;
  final String treatmentLabel;
  final String treatmentHint;
  final String notesLabel;
  final String notesHint;
  
  /// Whether diagnosis is required
  final bool diagnosisRequired;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    
    return RecordFormSection(
      sectionKey: sectionKey,
      title: title,
      icon: icon,
      accentColor: color,
      collapsible: true,
      initiallyExpanded: isExpanded,
      onToggle: onToggle,
      completionSummary: _buildCompletionSummary(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diagnosis Field with voice and suggestions
          StyledTextField(
            label: diagnosisLabel,
            controller: diagnosisController,
            hint: diagnosisHint,
            icon: Icons.medical_information_rounded,
            maxLines: 2,
            isRequired: diagnosisRequired,
            accentColor: color,
            enableVoice: true,
            suggestions: diagnosisSuggestions,
          ),
          
          // Treatment Plan with voice and suggestions
          if (showTreatment && treatmentController != null) ...[
            const SizedBox(height: 16),
            StyledTextField(
              label: treatmentLabel,
              controller: treatmentController,
              hint: treatmentHint,
              icon: Icons.healing_rounded,
              maxLines: 3,
              minLines: 2,
              accentColor: color,
              enableVoice: true,
              suggestions: treatmentSuggestions,
            ),
          ],
          
          // Clinical Notes with voice and suggestions
          if (showNotes && notesController != null) ...[
            const SizedBox(height: 16),
            StyledTextField(
              label: notesLabel,
              controller: notesController,
              hint: notesHint,
              icon: Icons.note_alt_rounded,
              maxLines: 4,
              minLines: 2,
              accentColor: color,
              enableVoice: true,
              suggestions: clinicalNotesSuggestions,
            ),
          ],
        ],
      ),
    );
  }
  
  String? _buildCompletionSummary() {
    final parts = <String>[];
    
    if (diagnosisController.text.isNotEmpty) {
      final text = diagnosisController.text;
      parts.add(text.length > 40 ? '${text.substring(0, 40)}...' : text);
    }
    
    if (treatmentController != null && treatmentController!.text.isNotEmpty) {
      parts.add('Treatment added');
    }
    
    if (notesController != null && notesController!.text.isNotEmpty) {
      parts.add('Notes added');
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : null;
  }
}

/// A reusable Investigations section for medical record forms
/// 
/// Common pattern for selecting investigations/tests and adding results.
/// Uses the new QuickPicker UI with icons for test selection.
/// 
/// Example:
/// ```dart
/// InvestigationsSection(
///   sectionKey: _sectionKeys['tests'],
///   isExpanded: _expandedSections['tests'] ?? true,
///   onToggle: (expanded) => setState(() => _expandedSections['tests'] = expanded),
///   selectedInvestigations: _selectedInvestigations,
///   onInvestigationsChanged: (list) => setState(() => _selectedInvestigations = list),
///   resultsController: _investigationResultsController,
/// )
/// ```
class InvestigationsSection extends StatelessWidget {
  const InvestigationsSection({
    super.key,
    this.sectionKey,
    required this.isExpanded,
    required this.onToggle,
    required this.selectedInvestigations,
    required this.onInvestigationsChanged,
    this.resultsController,
    this.accentColor,
    this.title = 'Investigations',
    this.icon = Icons.biotech_rounded,
    this.investigationsLabel = 'Tests Ordered',
    this.resultsLabel = 'Results / Findings',
    this.resultsHint = 'Document investigation results...',
    this.showResults = true,
  });

  final GlobalKey? sectionKey;
  final bool isExpanded;
  final void Function(bool expanded) onToggle;
  final List<String> selectedInvestigations;
  final ValueChanged<List<String>> onInvestigationsChanged;
  final TextEditingController? resultsController;
  final Color? accentColor;
  final String title;
  final IconData icon;
  final String investigationsLabel;
  final String resultsLabel;
  final String resultsHint;
  final bool showResults;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    
    return RecordFormSection(
      sectionKey: sectionKey,
      title: title,
      icon: icon,
      accentColor: color,
      collapsible: true,
      initiallyExpanded: isExpanded,
      onToggle: onToggle,
      completionSummary: selectedInvestigations.isNotEmpty 
          ? '${selectedInvestigations.length} test${selectedInvestigations.length > 1 ? 's' : ''} ordered'
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Investigation - Quick Picker with icons
          QuickPickerField(
            label: investigationsLabel,
            selected: selectedInvestigations,
            options: commonInvestigationOptions,
            onChanged: onInvestigationsChanged,
            accentColor: color,
            icon: Icons.biotech_rounded,
            hint: 'Tap to select tests',
            pickerTitle: 'Investigations',
            pickerSubtitle: 'Select tests to order',
          ),
          
          // Results field with voice and suggestions
          if (showResults && resultsController != null) ...[
            const SizedBox(height: 20),
            StyledTextField(
              label: resultsLabel,
              controller: resultsController,
              hint: resultsHint,
              icon: Icons.analytics_rounded,
              maxLines: 4,
              minLines: 2,
              accentColor: color,
              enableVoice: true,
              suggestions: investigationResultsSuggestions,
            ),
          ],
        ],
      ),
    );
  }
}

/// A reusable Clinical Notes section
/// 
/// Simple notes-only section for additional documentation
class ClinicalNotesSection extends StatelessWidget {
  const ClinicalNotesSection({
    super.key,
    this.sectionKey,
    required this.isExpanded,
    required this.onToggle,
    required this.notesController,
    this.accentColor,
    this.title = 'Clinical Notes',
    this.icon = Icons.note_alt_rounded,
    this.label = 'Notes',
    this.hint = 'Additional observations, recommendations, follow-up instructions...',
    this.maxLines = 5,
  });

  final GlobalKey? sectionKey;
  final bool isExpanded;
  final void Function(bool expanded) onToggle;
  final TextEditingController notesController;
  final Color? accentColor;
  final String title;
  final IconData icon;
  final String label;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    
    return RecordFormSection(
      sectionKey: sectionKey,
      title: title,
      icon: icon,
      accentColor: color,
      collapsible: true,
      initiallyExpanded: isExpanded,
      onToggle: onToggle,
      completionSummary: notesController.text.isNotEmpty 
          ? 'Notes added (${notesController.text.length} chars)'
          : null,
      child: StyledTextField(
        label: label,
        controller: notesController,
        hint: hint,
        icon: Icons.edit_note_rounded,
        maxLines: maxLines,
        minLines: 3,
        accentColor: color,
        enableVoice: true,
        suggestions: clinicalNotesSuggestions,
      ),
    );
  }
}
