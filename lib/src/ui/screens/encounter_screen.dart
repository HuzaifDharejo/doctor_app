import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../providers/encounter_provider.dart';
import '../../services/encounter_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/diagnosis_picker.dart';
import '../widgets/soap_note_editor.dart';
import '../widgets/vitals_entry_modal.dart';
import '../widgets/persistent_allergy_warning_banner.dart';
import 'add_invoice_screen.dart';
import 'add_prescription_screen.dart';
import 'records/add_follow_up_screen.dart';
import '../../core/extensions/context_extensions.dart';

/// Central hub for managing a patient encounter
/// 
/// This screen provides a unified workflow for:
/// - Recording vitals
/// - Adding clinical notes (SOAP format)
/// - Managing diagnoses
/// - Creating prescriptions
/// - Completing the encounter
class EncounterScreen extends ConsumerStatefulWidget {
  const EncounterScreen({
    super.key,
    required this.encounterId,
    this.patient,
  });

  final int encounterId;
  final Patient? patient;

  @override
  ConsumerState<EncounterScreen> createState() => _EncounterScreenState();
}

class _EncounterScreenState extends ConsumerState<EncounterScreen> {
  bool _isLoading = false;
  int _selectedSection = 0;

  final List<_EncounterSection> _sections = [
    _EncounterSection(
      title: 'Vitals',
      icon: Icons.monitor_heart_rounded,
      color: const Color(0xFFEC4899),
    ),
    _EncounterSection(
      title: 'Clinical Notes',
      icon: Icons.edit_note_rounded,
      color: const Color(0xFF10B981),
    ),
    _EncounterSection(
      title: 'Diagnoses',
      icon: Icons.medical_information_rounded,
      color: const Color(0xFF6366F1),
    ),
    _EncounterSection(
      title: 'Actions',
      icon: Icons.checklist_rounded,
      color: const Color(0xFFF59E0B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final encounterAsync = ref.watch(encounterSummaryProvider(widget.encounterId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: encounterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading encounter', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(error.toString(), style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(encounterSummaryProvider(widget.encounterId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (summary) => _buildBody(context, summary),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EncounterSummary summary) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, summary),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildPatientHeader(context, summary),
              _buildStatusBanner(context, summary),
              _buildSectionSelector(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
          sliver: SliverToBoxAdapter(
            child: _buildCurrentSection(context, summary),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, EncounterSummary summary) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
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
                          'Visit #${summary.encounter.id}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Clinical Encounter',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
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
      actions: [
        if (summary.encounter.status != 'completed')
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => _completeEncounter(summary),
            tooltip: 'Complete Visit',
          ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showMoreOptions(summary),
          tooltip: 'More Options',
        ),
      ],
    );
  }

  Widget _buildPatientHeader(BuildContext context, EncounterSummary summary) {
    final patient = summary.patient ?? widget.patient;
    if (patient == null) return const SizedBox.shrink();

    // Get age directly from patient
    String? ageText;
    if (patient.age != null) {
      ageText = '${patient.age} yrs';
    }

    // Check for allergies
    final hasAllergies = patient.allergies.isNotEmpty && 
        patient.allergies.toLowerCase() != 'none' &&
        patient.allergies.toLowerCase() != 'nkda';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient basic info row
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.patients.withValues(alpha: 0.1),
                child: Text(
                  '${patient.firstName[0]}${patient.lastName.isNotEmpty ? patient.lastName[0] : ''}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.patients,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${patient.firstName} ${patient.lastName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (ageText != null) ...[
                          Text(
                            ageText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                        if (patient.gender.isNotEmpty)
                          Text(
                            patient.gender,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (patient.bloodType.isNotEmpty) ...[
                          const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                          Text(
                            patient.bloodType,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (summary.encounter.chiefComplaint.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'CC: ${summary.encounter.chiefComplaint}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  _buildStatusChip(summary.encounter.status),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(summary.encounter.encounterDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Allergies alert (if any) - using persistent banner
          if (hasAllergies) ...[
            const SizedBox(height: 12),
            PersistentAllergyWarningBanner(
              allergies: patient.allergies,
              compact: true,
            ),
          ],
          
          // Chronic conditions (if any)
          if (patient.chronicConditions.isNotEmpty && patient.chronicConditions.toLowerCase() != 'none') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_information_outlined, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chronic: ${patient.chronicConditions}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, EncounterSummary summary) {
    final hasVitals = summary.hasVitals;
    final hasNotes = summary.hasNotes;
    final hasDiagnoses = summary.hasDiagnoses;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem('Vitals', hasVitals, Icons.monitor_heart_rounded),
          _buildStatusItem('Notes', hasNotes, Icons.edit_note_rounded),
          _buildStatusItem('Dx', hasDiagnoses, Icons.medical_information_rounded),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isComplete, IconData icon) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle : icon,
          size: 20,
          color: isComplete ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isComplete ? AppColors.success : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionSelector(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: List.generate(_sections.length, (index) {
          final section = _sections[index];
          final isSelected = _selectedSection == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSection = index),
              child: Container(
                margin: EdgeInsets.only(
                  right: index < _sections.length - 1 ? 8 : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? section.color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? section.color : AppColors.divider,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      section.icon,
                      color: isSelected ? Colors.white : section.color,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentSection(BuildContext context, EncounterSummary summary) {
    switch (_selectedSection) {
      case 0:
        return _buildVitalsSection(context, summary);
      case 1:
        return _buildNotesSection(context, summary);
      case 2:
        return _buildDiagnosesSection(context, summary);
      case 3:
        return _buildActionsSection(context, summary);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVitalsSection(BuildContext context, EncounterSummary summary) {
    final vitals = summary.latestVitals;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vital Signs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _addVitals(summary),
              icon: const Icon(Icons.add, size: 18),
              label: Text(vitals == null ? 'Record Vitals' : 'Update'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (vitals == null)
          _buildEmptyState(
            'No vitals recorded',
            'Tap "Record Vitals" to add blood pressure, heart rate, and other vital signs.',
            Icons.monitor_heart_rounded,
          )
        else
          _buildVitalsCard(vitals),
      ],
    );
  }

  Widget _buildVitalsCard(VitalSign vitals) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildVitalItem('BP', '${vitals.systolicBp?.toInt() ?? '--'}/${vitals.diastolicBp?.toInt() ?? '--'}', 'mmHg')),
              Expanded(child: _buildVitalItem('HR', '${vitals.heartRate ?? '--'}', 'bpm')),
              Expanded(child: _buildVitalItem('Temp', '${vitals.temperature?.toStringAsFixed(1) ?? '--'}', '°C')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildVitalItem('SpO2', '${vitals.oxygenSaturation?.toStringAsFixed(0) ?? '--'}', '%')),
              Expanded(child: _buildVitalItem('RR', '${vitals.respiratoryRate ?? '--'}', '/min')),
              Expanded(child: _buildVitalItem('Pain', '${vitals.painLevel ?? '--'}', '/10')),
            ],
          ),
          if (vitals.notes.isNotEmpty) ...[
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                vitals.notes,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, EncounterSummary summary) {
    final notes = summary.notes;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Clinical Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _addClinicalNote(summary),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Note'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (notes.isEmpty)
          _buildEmptyState(
            'No clinical notes',
            'Tap "Add Note" to create a SOAP note for this encounter.',
            Icons.edit_note_rounded,
          )
        else
          ...notes.map((note) => _buildNoteCard(note)),
      ],
    );
  }

  Widget _buildNoteCard(ClinicalNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.noteType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (note.isLocked) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.lock, size: 14, color: AppColors.success),
                  ],
                ],
              ),
              Text(
                DateFormat('MMM d, h:mm a').format(note.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (note.subjective.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSoapSection('S', 'Subjective', note.subjective),
          ],
          if (note.objective.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSoapSection('O', 'Objective', note.objective),
          ],
          if (note.assessment.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSoapSection('A', 'Assessment', note.assessment),
          ],
          if (note.plan.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSoapSection('P', 'Plan', note.plan),
          ],
          if (note.signedBy.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Signed by ${note.signedBy} on ${DateFormat('MMM d, yyyy').format(note.signedAt ?? note.createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.success,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSoapSection(String letter, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosesSection(BuildContext context, EncounterSummary summary) {
    final diagnoses = summary.diagnoses;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Diagnoses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _addDiagnosis(summary),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Dx'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (diagnoses.isEmpty)
          _buildEmptyState(
            'No diagnoses',
            'Tap "Add Dx" to record diagnoses for this encounter.',
            Icons.medical_information_rounded,
          )
        else
          ...diagnoses.map((dx) => _buildDiagnosisCard(dx, summary)),
      ],
    );
  }

  Widget _buildDiagnosisCard(Diagnose diagnosis, EncounterSummary summary) {
    final isNew = summary.newDiagnoses.any((d) => d.id == diagnosis.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew ? AppColors.success.withValues(alpha: 0.5) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getDiagnosisCategoryColor(diagnosis.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                _getDiagnosisCategoryIcon(diagnosis.category),
                color: _getDiagnosisCategoryColor(diagnosis.category),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (diagnosis.isPrimary)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRIMARY',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                if (diagnosis.isPrimary || isNew) const SizedBox(height: 4),
                Text(
                  diagnosis.description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (diagnosis.icdCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ICD-10: ${diagnosis.icdCode}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildStatusChip(diagnosis.diagnosisStatus),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, EncounterSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          'Create Prescription',
          'Write medications for this encounter',
          Icons.medication_rounded,
          AppColors.prescriptions,
          () => _createPrescription(summary),
        ),
        _buildActionTile(
          'Schedule Follow-up',
          'Book next appointment',
          Icons.event_repeat_rounded,
          AppColors.appointments,
          () => _scheduleFollowUp(summary),
        ),
        _buildActionTile(
          'Generate Invoice',
          'Bill for this visit',
          Icons.receipt_long_rounded,
          AppColors.billing,
          () => _generateInvoice(summary),
        ),
        if (summary.encounter.status != 'completed')
          _buildActionTile(
            'Complete Visit',
            'Finish and lock this visit',
            Icons.check_circle_rounded,
            AppColors.success,
            () => _completeEncounter(summary),
          ),
      ],
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(context.responsivePadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(icon, color: color),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'in_progress':
        color = AppColors.info;
        break;
      case 'completed':
        color = AppColors.success;
        break;
      case 'cancelled':
        color = AppColors.error;
        break;
      case 'active':
        color = AppColors.primary;
        break;
      case 'resolved':
        color = AppColors.success;
        break;
      case 'chronic':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getDiagnosisCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'psychiatric':
        return AppColors.primary;
      case 'medical':
        return AppColors.success;
      case 'substance':
        return AppColors.warning;
      case 'developmental':
        return AppColors.info;
      case 'neurological':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getDiagnosisCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'psychiatric':
        return Icons.psychology_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'substance':
        return Icons.local_pharmacy_rounded;
      case 'developmental':
        return Icons.child_care_rounded;
      case 'neurological':
        return Icons.emoji_objects_rounded;
      default:
        return Icons.medical_information_rounded;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  void _addVitals(EncounterSummary summary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VitalsEntryModal(
        encounterId: summary.encounter.id,
        patientId: summary.encounter.patientId,
        onSaved: (vitalId) {
          // Refresh the encounter data
          ref.invalidate(encounterSummaryProvider(summary.encounter.id));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vitals saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _addClinicalNote(EncounterSummary summary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SOAPNoteEditor(
        encounterId: summary.encounter.id,
        patientId: summary.encounter.patientId,
        existingNote: summary.notes.isNotEmpty ? summary.notes.first : null,
        onSaved: (noteId) {
          // Refresh the encounter data
          ref.invalidate(encounterSummaryProvider(summary.encounter.id));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Clinical note saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _addDiagnosis(EncounterSummary summary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiagnosisPicker(
        encounterId: summary.encounter.id,
        patientId: summary.encounter.patientId,
        selectedDiagnoses: summary.diagnoses,
        onDiagnosisAdded: (code, isPrimary) {
          // Refresh the encounter data
          ref.invalidate(encounterSummaryProvider(summary.encounter.id));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Diagnosis ${code.code} added'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _createPrescription(EncounterSummary summary) {
    final patient = summary.patient ?? widget.patient;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Get diagnosis from encounter if available
    final diagnosis = summary.diagnoses.isNotEmpty 
        ? summary.diagnoses.map((d) => d.description).join(', ')
        : null;
    
    // Get symptoms from chief complaint
    final symptoms = summary.encounter.chiefComplaint;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPrescriptionScreen(
          preselectedPatient: patient,
          encounterId: summary.encounter.id,
          appointmentId: summary.encounter.appointmentId,
          diagnosis: diagnosis,
          symptoms: symptoms,
        ),
      ),
    );
  }

  void _scheduleFollowUp(EncounterSummary summary) {
    final patient = summary.patient ?? widget.patient;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Get diagnosis and treatment plan from encounter
    final diagnosis = summary.diagnoses.isNotEmpty 
        ? summary.diagnoses.map((d) => d.description).join(', ')
        : null;
    
    final treatmentPlan = summary.primaryNote?.plan;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFollowUpScreen(
          preselectedPatient: patient,
          encounterId: summary.encounter.id,
          diagnosis: diagnosis,
          treatmentPlan: treatmentPlan,
          reason: summary.encounter.chiefComplaint,
        ),
      ),
    );
  }

  void _generateInvoice(EncounterSummary summary) {
    final patient = summary.patient ?? widget.patient;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Get diagnosis for invoice notes
    final diagnosis = summary.diagnoses.isNotEmpty 
        ? summary.diagnoses.map((d) => d.description).join(', ')
        : null;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddInvoiceScreen(
          preselectedPatient: patient,
          encounterId: summary.encounter.id,
          appointmentId: summary.encounter.appointmentId,
          diagnosis: diagnosis,
        ),
      ),
    );
  }

  Future<void> _completeEncounter(EncounterSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Visit?'),
        content: const Text(
          'This will mark the visit as completed. '
          'Clinical notes will be locked and cannot be edited.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final service = ref.read(encounterServiceProvider);
        await service.completeEncounter(summary.encounter.id);
        ref.invalidate(encounterSummaryProvider(widget.encounterId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visit completed successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  /// Print encounter summary as PDF
  Future<void> _printEncounterSummary(EncounterSummary summary) async {
    final patient = summary.patient ?? widget.patient;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final settings = ref.read(doctorSettingsProvider);
      final dateStr = DateFormat('MMM d, yyyy').format(summary.encounter.encounterDate);
      
      // Build encounter summary text
      final summaryText = _buildEncounterSummaryText(summary);
      
      // For now, share as text since we don't have a dedicated encounter PDF
      // This can be enhanced later to generate a proper PDF
      final printText = '''
═══════════════════════════════════════════
ENCOUNTER SUMMARY
═══════════════════════════════════════════
Patient: ${patient.firstName} ${patient.lastName ?? ''}
Date: $dateStr
Type: ${summary.encounter.encounterType}
Chief Complaint: ${summary.encounter.chiefComplaint}
Status: ${summary.encounter.status}

$summaryText
═══════════════════════════════════════════
${settings.profile.clinicName}
Dr. ${settings.profile.name}
${settings.profile.phone ?? ''}
═══════════════════════════════════════════
''';
      
      // Use Share for now - can be enhanced to PDF later
      await Share.share(
        printText,
        subject: 'Encounter Summary - ${patient.firstName} - $dateStr',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Summary ready to share/print'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Share encounter summary
  Future<void> _shareEncounterSummary(EncounterSummary summary) async {
    final patient = summary.patient ?? widget.patient;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final settings = ref.read(doctorSettingsProvider);
      final summaryText = _buildEncounterSummaryText(summary);
      final dateStr = DateFormat('MMM d, yyyy').format(summary.encounter.encounterDate);
      
      // Share as text
      final shareText = '''
ENCOUNTER SUMMARY
=================
Patient: ${patient.firstName} ${patient.lastName ?? ''}
Date: $dateStr
Chief Complaint: ${summary.encounter.chiefComplaint}

$summaryText

---
${settings.profile.clinicName}
Dr. ${settings.profile.name}
''';
      
      await Share.share(
        shareText,
        subject: 'Encounter Summary - ${patient.firstName} ${patient.lastName ?? ''} - $dateStr',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Build summary text from encounter data
  String _buildEncounterSummaryText(EncounterSummary summary) {
    final buffer = StringBuffer();
    
    // Vitals
    if (summary.hasVitals) {
      final v = summary.latestVitals!;
      buffer.writeln('VITALS:');
      if (v.systolicBp != null && v.diastolicBp != null) {
        buffer.writeln('  BP: ${v.systolicBp!.toInt()}/${v.diastolicBp!.toInt()} mmHg');
      }
      if (v.heartRate != null) buffer.writeln('  HR: ${v.heartRate} bpm');
      if (v.temperature != null) buffer.writeln('  Temp: ${v.temperature}°C');
      if (v.respiratoryRate != null) buffer.writeln('  RR: ${v.respiratoryRate}/min');
      if (v.oxygenSaturation != null) buffer.writeln('  SpO2: ${v.oxygenSaturation}%');
      if (v.weight != null) buffer.writeln('  Weight: ${v.weight} kg');
      buffer.writeln();
    }
    
    // Diagnoses
    if (summary.hasDiagnoses) {
      buffer.writeln('DIAGNOSES:');
      for (final d in summary.diagnoses) {
        final isNew = summary.newDiagnoses.contains(d);
        buffer.writeln('  ${isNew ? "[NEW] " : ""}${d.description}');
        if (d.icdCode != null) buffer.writeln('    ICD: ${d.icdCode}');
      }
      buffer.writeln();
    }
    
    // Clinical Notes
    if (summary.hasNotes) {
      final note = summary.primaryNote!;
      buffer.writeln('CLINICAL NOTES:');
      if (note.subjective != null && note.subjective!.isNotEmpty) {
        buffer.writeln('  Subjective: ${note.subjective}');
      }
      if (note.objective != null && note.objective!.isNotEmpty) {
        buffer.writeln('  Objective: ${note.objective}');
      }
      if (note.assessment != null && note.assessment!.isNotEmpty) {
        buffer.writeln('  Assessment: ${note.assessment}');
      }
      if (note.plan != null && note.plan!.isNotEmpty) {
        buffer.writeln('  Plan: ${note.plan}');
      }
    }
    
    return buffer.toString();
  }

  /// Delete encounter with confirmation
  Future<void> _deleteEncounter(EncounterSummary summary) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Encounter?'),
        content: const Text(
          'This will permanently delete this encounter and all associated '
          'clinical notes. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final db = await ref.read(doctorDbProvider.future);
        
        // Delete associated clinical notes first
        await (db.delete(db.clinicalNotes)
          ..where((t) => t.encounterId.equals(summary.encounter.id)))
          .go();
        
        // Delete encounter diagnosis links
        await (db.delete(db.encounterDiagnoses)
          ..where((t) => t.encounterId.equals(summary.encounter.id)))
          .go();
        
        // Delete vital signs linked to encounter
        await (db.delete(db.vitalSigns)
          ..where((t) => t.encounterId.equals(summary.encounter.id)))
          .go();
        
        // Delete the encounter itself
        await (db.delete(db.encounters)
          ..where((t) => t.id.equals(summary.encounter.id)))
          .go();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Encounter deleted'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(); // Go back after deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showMoreOptions(EncounterSummary summary) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.print_rounded),
              title: const Text('Print Summary'),
              onTap: () async {
                Navigator.pop(context);
                await _printEncounterSummary(summary);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () async {
                Navigator.pop(context);
                await _shareEncounterSummary(summary);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: AppColors.error),
              title: Text('Delete Encounter', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _deleteEncounter(summary);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _EncounterSection {
  final String title;
  final IconData icon;
  final Color color;

  _EncounterSection({
    required this.title,
    required this.icon,
    required this.color,
  });
}
