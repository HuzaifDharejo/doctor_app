import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../providers/encounter_provider.dart';
import '../../services/encounter_service.dart';
import '../../services/logger_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/diagnosis_picker.dart';
import '../widgets/soap_note_editor.dart';
import '../widgets/vitals_entry_modal.dart';
import 'add_appointment_screen.dart';
import 'add_invoice_screen.dart';
import 'add_patient_screen.dart';
import 'add_prescription_screen.dart';
import 'records/records.dart';
import 'patient_view/patient_view_screen.dart';
import 'records/add_follow_up_screen.dart';
import 'vital_signs_screen.dart';
import 'encounter_screen.dart';

/// Guided workflow wizard for complete patient journey
/// From registration to invoice in a step-by-step process
class WorkflowWizardScreen extends ConsumerStatefulWidget {
  const WorkflowWizardScreen({
    super.key,
    this.existingPatient,
    this.existingAppointment,
  });

  /// Start workflow with existing patient (skip registration)
  final Patient? existingPatient;
  
  /// Start workflow with existing appointment
  final Appointment? existingAppointment;

  @override
  ConsumerState<WorkflowWizardScreen> createState() => _WorkflowWizardScreenState();
}

class _WorkflowWizardScreenState extends ConsumerState<WorkflowWizardScreen> {
  int _currentStep = 0;
  
  // Workflow data
  Patient? _patient;
  Appointment? _appointment;
  Encounter? _encounter; // New: Central encounter for this workflow
  MedicalRecord? _medicalRecord;
  TreatmentOutcome? _treatmentPlan; // Treatment plan for this visit
  Prescription? _prescription;
  ScheduledFollowUp? _followUp;
  Invoice? _invoice;
  
  // Diagnosis data (shared between steps)
  String _currentDiagnosis = '';
  List<String> _currentDiagnoses = [];
  
  // Step completion status
  final Map<int, bool> _completedSteps = {};
  
  // Optional steps
  bool _skipVitals = false;
  bool _skipDiagnosis = false;
  bool _skipTreatmentPlan = false;
  bool _skipPrescription = false;
  bool _skipFollowUp = true; // Default skip
  
  final List<_WorkflowStep> _steps = [
    _WorkflowStep(
      title: 'Register Patient',
      subtitle: 'Add new patient or select existing',
      icon: Icons.person_add_rounded,
      color: AppColors.patients,
      isRequired: true,
    ),
    _WorkflowStep(
      title: 'Schedule Appointment',
      subtitle: 'Book consultation time',
      icon: Icons.calendar_month_rounded,
      color: AppColors.appointments,
      isRequired: true,
    ),
    _WorkflowStep(
      title: 'Check-In Patient',
      subtitle: 'Start the consultation',
      icon: Icons.login_rounded,
      color: const Color(0xFF8B5CF6),
      isRequired: true,
    ),
    _WorkflowStep(
      title: 'Record Vitals',
      subtitle: 'Blood pressure, temperature, etc.',
      icon: Icons.monitor_heart_rounded,
      color: const Color(0xFFEC4899),
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Add Diagnosis',
      subtitle: 'Document diagnoses and findings',
      icon: Icons.medical_information_rounded,
      color: const Color(0xFF10B981),
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Treatment Plan',
      subtitle: 'Plan treatment and medications',
      icon: Icons.assignment_rounded,
      color: const Color(0xFF8B5CF6),
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Create Prescription',
      subtitle: 'Medications with diagnosis',
      icon: Icons.medication_rounded,
      color: AppColors.warning,
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Schedule Follow-Up',
      subtitle: 'Book next visit if needed',
      icon: Icons.event_repeat_rounded,
      color: Colors.orange,
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Complete & Invoice',
      subtitle: 'Finish visit and generate bill',
      icon: Icons.receipt_long_rounded,
      color: AppColors.billing,
      isRequired: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    log.i('WORKFLOW', 'Workflow wizard started', extra: {
      'hasExistingPatient': widget.existingPatient != null,
      'hasExistingAppointment': widget.existingAppointment != null,
    });
    log.trackScreen('WorkflowWizard');
    
    // Initialize with existing data if provided
    if (widget.existingPatient != null) {
      _patient = widget.existingPatient;
      _completedSteps[0] = true;
      _currentStep = 1;
      log.d('WORKFLOW', 'Pre-loaded patient: ${_patient!.firstName} ${_patient!.lastName}');
    }
    if (widget.existingAppointment != null) {
      _appointment = widget.existingAppointment;
      _completedSteps[1] = true;
      if (_currentStep < 2) _currentStep = 2;
      log.d('WORKFLOW', 'Pre-loaded appointment ID: ${_appointment!.id}');
    }
  }

  bool _isStepSkipped(int index) {
    switch (index) {
      case 3: return _skipVitals;          // Vitals step
      case 4: return _skipDiagnosis;       // Diagnosis step
      case 5: return _skipTreatmentPlan;   // Treatment Plan step
      case 6: return _skipPrescription;    // Prescription step
      case 7: return _skipFollowUp;        // Follow-up step
      default: return false;
    }
  }

  bool _isStepCompleted(int index) {
    if (_isStepSkipped(index)) return true;
    return _completedSteps[index] == true;
  }

  bool _canProceed() {
    final step = _steps[_currentStep];
    if (!step.isRequired && _isStepSkipped(_currentStep)) return true;
    return _isStepCompleted(_currentStep);
  }

  void _goToNextStep() {
    if (_currentStep < _steps.length - 1) {
      final fromStep = _steps[_currentStep].title;
      setState(() {
        _currentStep++;
        // Skip optional steps if marked
        while (_currentStep < _steps.length - 1 && _isStepSkipped(_currentStep)) {
          log.d('WORKFLOW', 'Skipping step: ${_steps[_currentStep].title}');
          _completedSteps[_currentStep] = true;
          _currentStep++;
        }
      });
      log.i('WORKFLOW', 'Step navigation: $fromStep → ${_steps[_currentStep].title}', extra: {
        'stepIndex': _currentStep,
        'totalSteps': _steps.length,
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      final fromStep = _steps[_currentStep].title;
      setState(() {
        _currentStep--;
        // Skip optional steps if marked
        while (_currentStep > 0 && _isStepSkipped(_currentStep)) {
          _currentStep--;
        }
      });
      log.i('WORKFLOW', 'Step back: $fromStep → ${_steps[_currentStep].title}', extra: {
        'stepIndex': _currentStep,
      });
    }
  }

  Future<void> _completeWorkflow() async {
    log.i('WORKFLOW', 'Completing workflow', extra: {
      'patientId': _patient?.id,
      'appointmentId': _appointment?.id,
      'encounterId': _encounter?.id,
      'hasPrescription': _prescription != null,
      'hasInvoice': _invoice != null,
    });
    
    final db = await ref.read(doctorDbProvider.future);
    
    // Complete the encounter if exists
    if (_encounter != null) {
      final encounterService = EncounterService(db: db);
      await encounterService.completeEncounter(_encounter!.id);
      log.d('WORKFLOW', 'Encounter marked as completed');
    }
    
    // Mark appointment as completed
    if (_appointment != null) {
      await db.updateAppointment(
        AppointmentsCompanion(
          id: Value(_appointment!.id),
          patientId: Value(_appointment!.patientId),
          appointmentDateTime: Value(_appointment!.appointmentDateTime),
          status: const Value('completed'),
        ),
      );
      log.d('WORKFLOW', 'Appointment marked as completed');
    }
    
    // Invalidate encounter providers to refresh data
    ref.invalidate(todaysEncountersProvider);
    ref.invalidate(activeEncountersProvider);
    if (_patient != null) {
      ref.invalidate(patientEncountersProvider(_patient!.id));
    }
    
    if (mounted) {
      // Show success dialog
      await showDialog<void>(
        context: context,
        builder: (context) => _WorkflowCompleteDialog(
          patient: _patient!,
          appointment: _appointment,
          encounter: _encounter,
          prescription: _prescription,
          invoice: _invoice,
        ),
      );
      
      // Navigate back
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: const Text('Consult a Patient'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => _showExitConfirmation(context),
        ),
        actions: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Step ${_currentStep + 1} of ${_steps.length}',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress stepper
          _buildProgressStepper(isDark, surfaceColor),
          
          // Step content
          Expanded(
            child: _buildStepContent(isDark),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(isDark, surfaceColor),
        ],
      ),
    );
  }

  Widget _buildProgressStepper(bool isDark, Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: surfaceColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_steps.length, (index) {
            final step = _steps[index];
            final isActive = index == _currentStep;
            final isCompleted = _isStepCompleted(index);
            final isSkipped = _isStepSkipped(index);
            
            return Row(
              children: [
                GestureDetector(
                  onTap: isCompleted || index < _currentStep
                      ? () => setState(() => _currentStep = index)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isActive ? 48 : 36,
                    height: isActive ? 48 : 36,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? step.color
                          : isActive
                              ? step.color.withValues(alpha: 0.2)
                              : (isDark ? Colors.grey[800] : Colors.grey[200]),
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(color: step.color, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              isSkipped ? Icons.skip_next_rounded : Icons.check_rounded,
                              color: Colors.white,
                              size: isActive ? 24 : 18,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? step.color
                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                fontWeight: FontWeight.bold,
                                fontSize: isActive ? 16 : 12,
                              ),
                            ),
                    ),
                  ),
                ),
                if (index < _steps.length - 1)
                  Container(
                    width: 24,
                    height: 2,
                    color: _isStepCompleted(index)
                        ? step.color
                        : (isDark ? Colors.grey[700] : Colors.grey[300]),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    final step = _steps[_currentStep];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(step.icon, color: step.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!step.isRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.subtitle,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Step-specific content
          _buildStepSpecificContent(_currentStep, isDark),
        ],
      ),
    );
  }

  Widget _buildStepSpecificContent(int stepIndex, bool isDark) {
    switch (stepIndex) {
      case 0:
        return _buildPatientStep(isDark);
      case 1:
        return _buildAppointmentStep(isDark);
      case 2:
        return _buildCheckInStep(isDark);
      case 3:
        return _buildVitalsStep(isDark);
      case 4:
        return _buildDiagnosisStep(isDark);
      case 5:
        return _buildTreatmentPlanStep(isDark);
      case 6:
        return _buildPrescriptionStep(isDark);
      case 7:
        return _buildFollowUpStep(isDark);
      case 8:
        return _buildInvoiceStep(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Patient Registration
  Widget _buildPatientStep(bool isDark) {
    if (_patient != null) {
      return _buildCompletedCard(
        isDark: isDark,
        title: '${_patient!.firstName} ${_patient!.lastName}',
        subtitle: 'Patient selected',
        icon: Icons.person_rounded,
        color: AppColors.patients,
        onEdit: () => _selectOrAddPatient(),
        details: [
          if (_patient!.phone.isNotEmpty) 'Phone: ${_patient!.phone}',
          if (_patient!.email.isNotEmpty) 'Email: ${_patient!.email}',
          'Risk Level: ${_patient!.riskLevel}',
        ],
      );
    }

    return Column(
      children: [
        _buildActionCard(
          isDark: isDark,
          title: 'Add New Patient',
          subtitle: 'Register a new patient in the system',
          icon: Icons.person_add_rounded,
          color: AppColors.patients,
          onTap: () => _addNewPatient(),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          isDark: isDark,
          title: 'Select Existing Patient',
          subtitle: 'Choose from registered patients',
          icon: Icons.people_rounded,
          color: AppColors.primary,
          onTap: () => _selectExistingPatient(),
        ),
      ],
    );
  }

  // Step 2: Appointment Scheduling
  Widget _buildAppointmentStep(bool isDark) {
    if (_appointment != null) {
      final dateFormat = DateFormat('EEEE, MMM d, yyyy');
      final timeFormat = DateFormat('h:mm a');
      
      return _buildCompletedCard(
        isDark: isDark,
        title: _appointment!.reason,
        subtitle: 'Appointment scheduled',
        icon: Icons.calendar_month_rounded,
        color: AppColors.appointments,
        onEdit: () => _scheduleAppointment(),
        details: [
          'Date: ${dateFormat.format(_appointment!.appointmentDateTime)}',
          'Time: ${timeFormat.format(_appointment!.appointmentDateTime)}',
          'Duration: ${_appointment!.durationMinutes} minutes',
        ],
      );
    }

    return _buildActionCard(
      isDark: isDark,
      title: 'Schedule Appointment',
      subtitle: 'Book a consultation time for ${_patient?.firstName ?? "patient"}',
      icon: Icons.calendar_month_rounded,
      color: AppColors.appointments,
      onTap: () => _scheduleAppointment(),
    );
  }

  // Step 3: Check-In
  Widget _buildCheckInStep(bool isDark) {
    if (_completedSteps[2] == true && _encounter != null) {
      final checkInTime = _encounter!.checkInTime ?? _encounter!.encounterDate;
      return Column(
        children: [
          _buildCompletedCard(
            isDark: isDark,
            title: 'Patient Checked In',
            subtitle: 'Consultation in progress',
            icon: Icons.login_rounded,
            color: const Color(0xFF8B5CF6),
            details: [
              'Visit #${_encounter!.id}',
              'Status: ${_encounter!.status}',
              'Started: ${DateFormat('h:mm a').format(checkInTime)}',
              if (_encounter!.chiefComplaint.isNotEmpty) 
                'Chief Complaint: ${_encounter!.chiefComplaint}',
            ],
          ),
          const SizedBox(height: 16),
          // Open full visit screen
          _buildActionCard(
            isDark: isDark,
            title: 'Open Visit Workstation',
            subtitle: 'Full clinical workflow with vitals, notes & diagnoses',
            icon: Icons.medical_services_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => _openEncounterScreen(),
          ),
        ],
      );
    }
    
    if (_completedSteps[2] == true) {
      return _buildCompletedCard(
        isDark: isDark,
        title: 'Patient Checked In',
        subtitle: 'Consultation in progress',
        icon: Icons.login_rounded,
        color: const Color(0xFF8B5CF6),
        details: [
          'Status: In Progress',
          'Started: ${DateFormat('h:mm a').format(DateTime.now())}',
        ],
      );
    }

    return Column(
      children: [
        _buildInfoCard(
          isDark: isDark,
          title: 'Ready to Start',
          message: 'Patient ${_patient?.firstName ?? ""} is ready for consultation. '
              'Click below to check them in and begin the visit.',
          icon: Icons.info_outline_rounded,
          color: AppColors.info,
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          isDark: isDark,
          title: 'Check-In Patient',
          subtitle: 'Start the consultation now',
          icon: Icons.login_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () => _checkInPatient(),
        ),
        const SizedBox(height: 16),
        // Quick view patient history
        _buildActionCard(
          isDark: isDark,
          title: 'View Patient History',
          subtitle: 'Review past visits and records',
          icon: Icons.history_rounded,
          color: Colors.grey,
          onTap: () => _viewPatientHistory(),
        ),
      ],
    );
  }

  // Step 4: Vitals
  Widget _buildVitalsStep(bool isDark) {
    return Column(
      children: [
        // Skip option
        _buildSkipOption(
          isDark: isDark,
          title: 'Skip Vital Signs',
          value: _skipVitals,
          onChanged: (value) => setState(() {
            _skipVitals = value;
            if (value) _completedSteps[3] = true;
          }),
        ),
        const SizedBox(height: 16),
        
        if (!_skipVitals) ...[
          if (_completedSteps[3] == true)
            _buildCompletedCard(
              isDark: isDark,
              title: 'Vitals Recorded',
              subtitle: 'Patient vital signs saved',
              icon: Icons.monitor_heart_rounded,
              color: const Color(0xFFEC4899),
              onEdit: () => _recordVitals(),
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Record Vital Signs',
              subtitle: 'BP, heart rate, temperature, SpO2',
              icon: Icons.monitor_heart_rounded,
              color: const Color(0xFFEC4899),
              onTap: () => _recordVitals(),
            ),
        ],
      ],
    );
  }

  // Step 5: Diagnosis
  Widget _buildDiagnosisStep(bool isDark) {
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'Skip Diagnosis',
          value: _skipDiagnosis,
          onChanged: (value) => setState(() {
            _skipDiagnosis = value;
            if (value) _completedSteps[4] = true;
          }),
        ),
        const SizedBox(height: 16),
        
        if (!_skipDiagnosis) ...[
          // Show current diagnoses if any
          if (_currentDiagnoses.isNotEmpty) ...[
            _buildCompletedCard(
              isDark: isDark,
              title: 'Diagnoses Added',
              subtitle: '${_currentDiagnoses.length} diagnosis(es)',
              icon: Icons.medical_information_rounded,
              color: const Color(0xFF10B981),
              onEdit: () => _addDiagnosis(),
              details: _currentDiagnoses.take(3).toList(),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              isDark: isDark,
              title: 'Add More Diagnoses',
              subtitle: 'Add additional diagnoses',
              icon: Icons.add_circle_outline_rounded,
              color: const Color(0xFF10B981),
              onTap: () => _addDiagnosis(),
            ),
          ] else ...[
            _buildActionCard(
              isDark: isDark,
              title: 'Add Diagnosis',
              subtitle: 'Document patient diagnoses (ICD-10)',
              icon: Icons.medical_information_rounded,
              color: const Color(0xFF10B981),
              onTap: () => _addDiagnosis(),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Also allow adding a medical record for detailed findings
          if (_medicalRecord != null)
            _buildCompletedCard(
              isDark: isDark,
              title: _medicalRecord!.recordType,
              subtitle: 'Medical record added',
              icon: Icons.folder_rounded,
              color: Colors.teal,
              onEdit: () => _addMedicalRecord(),
              details: [
                'Date: ${DateFormat('MMM d, yyyy').format(_medicalRecord!.recordDate)}',
              ],
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Add Medical Record',
              subtitle: 'Document detailed findings (optional)',
              icon: Icons.folder_rounded,
              color: Colors.teal,
              onTap: () => _addMedicalRecord(),
            ),
        ],
      ],
    );
  }

  // Step 6: Treatment Plan
  Widget _buildTreatmentPlanStep(bool isDark) {
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'Skip Treatment Plan',
          value: _skipTreatmentPlan,
          onChanged: (value) => setState(() {
            _skipTreatmentPlan = value;
            if (value) _completedSteps[5] = true;
          }),
        ),
        const SizedBox(height: 16),
        
        // Show diagnosis summary if available
        if (_currentDiagnoses.isNotEmpty) ...[
          _buildInfoCard(
            isDark: isDark,
            title: 'Diagnoses for Treatment',
            message: _currentDiagnoses.join(', '),
            icon: Icons.medical_information_rounded,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
        ],
        
        if (!_skipTreatmentPlan) ...[
          if (_treatmentPlan != null)
            _buildCompletedCard(
              isDark: isDark,
              title: 'Treatment Plan Created',
              subtitle: _treatmentPlan!.treatmentDescription,
              icon: Icons.assignment_rounded,
              color: const Color(0xFF8B5CF6),
              onEdit: () => _addTreatmentPlan(),
              details: [
                'Status: ${_treatmentPlan!.outcome}',
                if (_treatmentPlan!.startDate != null)
                  'Started: ${DateFormat('MMM d, yyyy').format(_treatmentPlan!.startDate!)}',
              ],
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Create Treatment Plan',
              subtitle: 'Define treatment goals and medications',
              icon: Icons.assignment_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () => _addTreatmentPlan(),
            ),
        ],
      ],
    );
  }

  // Step 7: Prescription
  Widget _buildPrescriptionStep(bool isDark) {
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'Skip Prescription',
          value: _skipPrescription,
          onChanged: (value) => setState(() {
            _skipPrescription = value;
            if (value) _completedSteps[6] = true;
          }),
        ),
        const SizedBox(height: 16),
        
        // Show diagnosis and treatment plan summary
        if (_currentDiagnoses.isNotEmpty || _treatmentPlan != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Text(
                      'Prescription will include:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_currentDiagnoses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      '• Diagnosis: ${_currentDiagnoses.join(", ")}',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                if (_treatmentPlan != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      '• Treatment: ${_treatmentPlan!.treatmentDescription}',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        if (!_skipPrescription) ...[
          // Allergy warning if patient has allergies
          if (_patient != null && _patient!.allergies.isNotEmpty)
            _buildWarningCard(
              isDark: isDark,
              title: 'Patient Allergies',
              message: _patient!.allergies,
              icon: Icons.warning_rounded,
            ),
          const SizedBox(height: 12),
          
          if (_prescription != null)
            _buildCompletedCard(
              isDark: isDark,
              title: 'Prescription Created',
              subtitle: _getPrescriptionItemCount(_prescription!),
              icon: Icons.medication_rounded,
              color: AppColors.warning,
              onEdit: () => _createPrescription(),
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Create Prescription',
              subtitle: 'Add medications and instructions',
              icon: Icons.medication_rounded,
              color: AppColors.warning,
              onTap: () => _createPrescription(),
            ),
        ],
      ],
    );
  }

  // Step 8: Follow-Up
  Widget _buildFollowUpStep(bool isDark) {
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'No Follow-Up Needed',
          value: _skipFollowUp,
          onChanged: (value) => setState(() {
            _skipFollowUp = value;
            if (value) _completedSteps[7] = true;
          }),
        ),
        const SizedBox(height: 16),
        
        if (!_skipFollowUp) ...[
          if (_followUp != null)
            _buildCompletedCard(
              isDark: isDark,
              title: 'Follow-Up Scheduled',
              subtitle: DateFormat('EEEE, MMM d, yyyy').format(_followUp!.scheduledDate),
              icon: Icons.event_repeat_rounded,
              color: Colors.orange,
              onEdit: () => _scheduleFollowUp(),
              details: [
                'Reason: ${_followUp!.reason}',
              ],
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Schedule Follow-Up',
              subtitle: 'Book next appointment',
              icon: Icons.event_repeat_rounded,
              color: Colors.orange,
              onTap: () => _scheduleFollowUp(),
            ),
        ],
      ],
    );
  }

  // Step 9: Invoice
  Widget _buildInvoiceStep(bool isDark) {
    return Column(
      children: [
        // Summary of visit
        _buildSummaryCard(isDark),
        const SizedBox(height: 16),
        
        if (_invoice != null)
          _buildCompletedCard(
            isDark: isDark,
            title: 'Invoice Generated',
            subtitle: 'PKR ${_invoice!.grandTotal.toStringAsFixed(0)}',
            icon: Icons.receipt_long_rounded,
            color: AppColors.billing,
            onEdit: () => _createInvoice(),
            details: [
              'Status: ${_invoice!.paymentStatus}',
              'Date: ${DateFormat('MMM d, yyyy').format(_invoice!.invoiceDate)}',
            ],
          )
        else
          _buildActionCard(
            isDark: isDark,
            title: 'Generate Invoice',
            subtitle: 'Create bill for this visit',
            icon: Icons.receipt_long_rounded,
            color: AppColors.billing,
            onTap: () => _createInvoice(),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    final items = <String>[];
    if (_patient != null) items.add('Patient: ${_patient!.firstName} ${_patient!.lastName}');
    if (_appointment != null) items.add('Reason: ${_appointment!.reason}');
    if (_currentDiagnoses.isNotEmpty) items.add('Diagnosis: ${_currentDiagnoses.join(", ")}');
    if (_treatmentPlan != null) items.add('Treatment: ${_treatmentPlan!.treatmentDescription}');
    if (_prescription != null) items.add('Prescription: Created');
    if (_followUp != null) items.add('Follow-up: ${DateFormat('MMM d').format(_followUp!.scheduledDate)}');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_rounded,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Visit Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark, Color surfaceColor) {
    final isLastStep = _currentStep == _steps.length - 1;
    final isFirstStep = _currentStep == 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isFirstStep)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goToPreviousStep,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (!isFirstStep) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _canProceed()
                    ? (isLastStep ? _completeWorkflow : _goToNextStep)
                    : null,
                icon: Icon(isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded),
                label: Text(isLastStep ? 'Complete Visit' : 'Continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastStep ? AppColors.success : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildActionCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onEdit,
    List<String>? details,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
            ],
          ),
          if (details != null && details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                detail,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard({
    required bool isDark,
    required String title,
    required String message,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipOption({
    required bool isDark,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppColors.primary,
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _selectOrAddPatient() async {
    setState(() {
      _patient = null;
      _completedSteps[0] = false;
    });
  }

  Future<void> _addNewPatient() async {
    final result = await Navigator.push<Patient>(
      context,
      MaterialPageRoute(builder: (_) => const AddPatientScreen()),
    );
    
    if (result != null && mounted) {
      setState(() {
        _patient = result;
        _completedSteps[0] = true;
      });
    }
  }

  Future<void> _selectExistingPatient() async {
    log.d('WORKFLOW', 'Opening patient selection');
    final db = await ref.read(doctorDbProvider.future);
    final patients = await db.getAllPatients();
    log.v('WORKFLOW', 'Loaded ${patients.length} patients for selection');
    
    if (!mounted) return;
    
    final selected = await showModalBottomSheet<Patient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PatientSelectionSheet(patients: patients),
    );
    
    if (selected != null && mounted) {
      log.i('WORKFLOW', 'Patient selected: ${selected.firstName} ${selected.lastName}', extra: {
        'patientId': selected.id,
      });
      setState(() {
        _patient = selected;
        _completedSteps[0] = true;
      });
    } else {
      log.d('WORKFLOW', 'Patient selection cancelled');
    }
  }

  Future<void> _scheduleAppointment() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot schedule appointment - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening appointment scheduler for patient: ${_patient!.firstName}');
    final result = await Navigator.push<Appointment>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAppointmentScreen(preselectedPatient: _patient),
      ),
    );
    
    if (result != null && mounted) {
      log.i('WORKFLOW', 'Appointment scheduled', extra: {
        'appointmentId': result.id,
        'dateTime': result.appointmentDateTime.toIso8601String(),
        'patientId': result.patientId,
      });
      setState(() {
        _appointment = result;
        _completedSteps[1] = true;
      });
    } else {
      log.d('WORKFLOW', 'Appointment scheduling cancelled');
    }
  }

  Future<void> _checkInPatient() async {
    log.d('WORKFLOW', 'Checking in patient');
    if (_appointment != null && _patient != null) {
      final db = await ref.read(doctorDbProvider.future);
      
      // Update appointment status
      await db.updateAppointment(
        AppointmentsCompanion(
          id: Value(_appointment!.id),
          patientId: Value(_appointment!.patientId),
          appointmentDateTime: Value(_appointment!.appointmentDateTime),
          status: const Value('in_progress'),
        ),
      );
      
      // Create an encounter for this visit
      final encounterService = EncounterService(db: db);
      final encounterId = await encounterService.startEncounter(
        patientId: _patient!.id,
        appointmentId: _appointment!.id,
        chiefComplaint: _appointment!.reason ?? 'Scheduled appointment',
        encounterType: _getEncounterType(_appointment!.reason),
      );
      
      // Fetch the created encounter
      _encounter = await db.getEncounterById(encounterId);
      
      log.i('WORKFLOW', 'Patient checked in with encounter', extra: {
        'appointmentId': _appointment!.id,
        'encounterId': encounterId,
        'status': 'in_progress',
      });
    }
    
    HapticFeedback.mediumImpact();
    setState(() {
      _completedSteps[2] = true;
    });
  }
  
  String _getEncounterType(String? reason) {
    if (reason == null) return 'follow_up';
    final lowerReason = reason.toLowerCase();
    if (lowerReason.contains('new') || lowerReason.contains('initial')) {
      return 'initial';
    } else if (lowerReason.contains('follow') || lowerReason.contains('review')) {
      return 'follow_up';
    } else if (lowerReason.contains('urgent') || lowerReason.contains('emergency')) {
      return 'urgent';
    } else if (lowerReason.contains('consult')) {
      return 'consultation';
    }
    return 'follow_up';
  }
  
  Future<void> _openEncounterScreen() async {
    if (_encounter == null || _patient == null) return;
    
    log.d('WORKFLOW', 'Opening encounter workstation', extra: {
      'encounterId': _encounter!.id,
      'patientId': _patient!.id,
    });
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EncounterScreen(
          encounterId: _encounter!.id,
          patient: _patient,
        ),
      ),
    );
    
    // Refresh encounter data in case it was updated
    if (mounted) {
      final db = await ref.read(doctorDbProvider.future);
      final updatedEncounter = await db.getEncounterById(_encounter!.id);
      if (updatedEncounter != null) {
        setState(() {
          _encounter = updatedEncounter;
          // Auto-complete steps based on encounter data
          if (updatedEncounter.status == 'completed') {
            _completedSteps[3] = true; // Vitals
            _completedSteps[4] = true; // Medical Record
          }
        });
      }
    }
  }

  Future<void> _viewPatientHistory() async {
    if (_patient == null) return;
    
    log.d('WORKFLOW', 'Viewing patient history: ${_patient!.firstName} ${_patient!.lastName}');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientViewScreen(patient: _patient!),
      ),
    );
  }

  Future<void> _recordVitals() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot record vitals - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening vitals recording for: ${_patient!.firstName}');
    // Navigate to dedicated vital signs screen or use encounter vitals modal
    if (_encounter != null) {
      // Use the new encounter-based vitals modal
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VitalsEntryModal(
          encounterId: _encounter!.id,
          patientId: _patient!.id,
          onSaved: (vitalId) {
            log.i('WORKFLOW', 'Vitals saved via encounter modal', extra: {
              'vitalId': vitalId,
              'encounterId': _encounter!.id,
            });
          },
        ),
      );
    } else {
      // Fallback to original vitals screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VitalSignsScreen(
            patientId: _patient!.id,
            patientName: '${_patient!.firstName} ${_patient!.lastName}',
          ),
        ),
      );
    }
    
    // Mark as completed after visiting vitals screen
    if (mounted) {
      log.i('WORKFLOW', 'Vitals screen visited for patient: ${_patient!.firstName}');
      setState(() {
        _completedSteps[3] = true;
      });
    }
  }

  Future<void> _addMedicalRecord() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot add medical record - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening medical record form');
    final result = await Navigator.push<MedicalRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectRecordTypeScreen(
          preselectedPatient: _patient,
          encounterId: _encounter?.id,
          appointmentId: _appointment?.id,
        ),
      ),
    );
    
    if (result != null && mounted) {
      log.i('WORKFLOW', 'Medical record created', extra: {
        'recordId': result.id,
        'recordType': result.recordType,
        'patientId': result.patientId,
      });
      setState(() {
        _medicalRecord = result;
        // Extract diagnosis from medical record if available
        if (result.diagnosis.isNotEmpty && !_currentDiagnoses.contains(result.diagnosis)) {
          _currentDiagnoses.add(result.diagnosis);
          _currentDiagnosis = result.diagnosis;
        }
      });
    } else {
      log.d('WORKFLOW', 'Medical record creation cancelled');
    }
  }

  Future<void> _addDiagnosis() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot add diagnosis - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening diagnosis picker');
    
    // Show diagnosis picker modal
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DiagnosisEntryModal(
        patientId: _patient!.id,
        encounterId: _encounter?.id,
        existingDiagnoses: _currentDiagnoses,
      ),
    );
    
    if (result != null && mounted) {
      final diagnoses = result['diagnoses'] as List<String>? ?? [];
      log.i('WORKFLOW', 'Diagnoses added', extra: {
        'count': diagnoses.length,
        'diagnoses': diagnoses,
      });
      
      // Save diagnoses to database if encounter exists
      if (_encounter != null && diagnoses.isNotEmpty) {
        try {
          final db = await ref.read(doctorDbProvider.future);
          for (final diagnosisName in diagnoses) {
            // First, check if diagnosis already exists for this patient
            final existingDiagnoses = await db.getDiagnosesForPatient(_patient!.id);
            var diagnosis = existingDiagnoses.where(
              (d) => d.description.toLowerCase() == diagnosisName.toLowerCase()
            ).firstOrNull;
            
            // If not exists, create new diagnosis
            if (diagnosis == null) {
              final diagnosisId = await db.insertDiagnosis(DiagnosesCompanion.insert(
                patientId: _patient!.id,
                description: diagnosisName,
                category: const Value('general'),
                diagnosisStatus: const Value('active'),
                diagnosedDate: DateTime.now(),
              ));
              diagnosis = await (db.select(db.diagnoses)
                ..where((d) => d.id.equals(diagnosisId)))
                .getSingleOrNull();
            }
            
            // Link diagnosis to encounter
            if (diagnosis != null) {
              await db.into(db.encounterDiagnoses).insert(
                EncounterDiagnosesCompanion.insert(
                  encounterId: _encounter!.id,
                  diagnosisId: diagnosis.id,
                  isNewDiagnosis: const Value(true),
                  encounterStatus: const Value('addressed'),
                ),
              );
            }
          }
          log.i('WORKFLOW', 'Diagnoses saved to database');
        } catch (e) {
          log.e('WORKFLOW', 'Failed to save diagnoses', error: e);
        }
      }
      
      setState(() {
        _currentDiagnoses = diagnoses;
        if (diagnoses.isNotEmpty) {
          _currentDiagnosis = diagnoses.first;
          _completedSteps[4] = true;
        }
      });
    } else {
      log.d('WORKFLOW', 'Diagnosis entry cancelled');
    }
  }

  Future<void> _addTreatmentPlan() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot add treatment plan - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening treatment plan form');
    
    // Show treatment plan modal
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TreatmentPlanModal(
        patientId: _patient!.id,
        encounterId: _encounter?.id,
        diagnoses: _currentDiagnoses,
      ),
    );
    
    if (result != null && mounted) {
      final description = result['description'] as String? ?? '';
      final goals = result['goals'] as String? ?? '';
      final instructions = result['instructions'] as String? ?? '';
      final diagnosis = result['diagnosis'] as String? ?? '';
      
      log.i('WORKFLOW', 'Treatment plan created', extra: {
        'description': description,
        'diagnosis': diagnosis,
      });
      
      // Save treatment plan to database if patient exists
      if (_patient != null) {
        try {
          final db = await ref.read(doctorDbProvider.future);
          await db.insertTreatmentOutcome(
            TreatmentOutcomesCompanion.insert(
              patientId: _patient!.id,
              treatmentType: 'combination',
              treatmentDescription: description,
              providerType: const Value('psychiatrist'),
              providerName: const Value(''),
              diagnosis: Value(diagnosis),
              startDate: DateTime.now(),
              outcome: const Value('ongoing'),
              notes: Value('Goals: $goals\n\nPatient Instructions: $instructions'),
            ),
          );
          
          // Reload the treatment outcome for display
          final outcomes = await db.getTreatmentOutcomesForPatient(_patient!.id);
          if (outcomes.isNotEmpty && mounted) {
            setState(() {
              _treatmentPlan = outcomes.last;
              _completedSteps[5] = true;
            });
          } else if (mounted) {
            setState(() {
              _completedSteps[5] = true;
            });
          }
        } catch (e) {
          log.e('WORKFLOW', 'Failed to save treatment plan', error: e);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save treatment plan: $e')),
            );
          }
        }
      } else {
        // Just mark as completed without saving to DB
        setState(() {
          _completedSteps[5] = true;
        });
      }
    } else {
      log.d('WORKFLOW', 'Treatment plan creation cancelled');
    }
  }

  Future<void> _createPrescription() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot create prescription - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening prescription form with diagnosis', extra: {
      'diagnoses': _currentDiagnoses,
      'encounterId': _encounter?.id,
    });
    
    final result = await Navigator.push<Prescription>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPrescriptionScreen(
          preselectedPatient: _patient,
          encounterId: _encounter?.id,
          appointmentId: _appointment?.id,
          diagnosis: _currentDiagnoses.isNotEmpty ? _currentDiagnoses.join(', ') : null,
        ),
      ),
    );
    
    if (result != null && mounted) {
      log.i('WORKFLOW', 'Prescription created', extra: {
        'prescriptionId': result.id,
        'patientId': result.patientId,
      });
      setState(() {
        _prescription = result;
        _completedSteps[6] = true;
      });
    } else {
      log.d('WORKFLOW', 'Prescription creation cancelled');
    }
  }

  Future<void> _scheduleFollowUp() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot schedule follow-up - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening follow-up scheduler');
    
    // Use a modal for scheduling follow-up
    final result = await showModalBottomSheet<ScheduledFollowUp>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FollowUpSchedulerModal(
        patientId: _patient!.id,
        appointmentId: _appointment?.id,
        diagnosis: _currentDiagnoses.isNotEmpty ? _currentDiagnoses.join(', ') : null,
        treatmentPlan: _treatmentPlan?.treatmentDescription,
        reason: _appointment?.reason,
      ),
    );
    
    if (result != null && mounted) {
      log.i('WORKFLOW', 'Follow-up scheduled', extra: {
        'followUpId': result.id,
        'scheduledDate': result.scheduledDate.toIso8601String(),
        'patientId': _patient!.id,
      });
      setState(() {
        _followUp = result;
        _completedSteps[7] = true;
      });
    } else {
      log.d('WORKFLOW', 'Follow-up scheduling cancelled');
    }
  }

  Future<void> _createInvoice() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot create invoice - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening invoice form');
    final result = await Navigator.push<Invoice>(
      context,
      MaterialPageRoute(
        builder: (_) => AddInvoiceScreen(
          patientId: _patient?.id,
          patientName: _patient != null ? '${_patient!.firstName} ${_patient!.lastName}' : null,
          preselectedPatient: _patient,
          encounterId: _encounter?.id,
          appointmentId: _appointment?.id,
          prescriptionId: _prescription?.id,
          diagnosis: _currentDiagnoses.isNotEmpty ? _currentDiagnoses.join(', ') : null,
        ),
      ),
    );
    
    if (result != null && mounted) {
      log.i('WORKFLOW', 'Invoice created', extra: {
        'invoiceId': result.id,
        'invoiceNumber': result.invoiceNumber,
        'grandTotal': result.grandTotal,
        'patientId': result.patientId,
      });
      setState(() {
        _invoice = result;
        _completedSteps[8] = true;
      });
    } else {
      log.d('WORKFLOW', 'Invoice creation cancelled');
    }
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    log.d('WORKFLOW', 'Exit confirmation requested');
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Workflow?'),
        content: const Text(
          'Your progress will be saved. You can continue from where you left off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    
    if (shouldExit == true && mounted) {
      log.i('WORKFLOW', 'Workflow exited by user', extra: {
        'currentStep': _currentStep,
        'completedSteps': _completedSteps.entries.where((e) => e.value).map((e) => e.key).toList(),
        'patientId': _patient?.id,
      });
      Navigator.pop(context);
    } else {
      log.d('WORKFLOW', 'Exit cancelled, continuing workflow');
    }
  }

  String _getPrescriptionItemCount(Prescription prescription) {
    try {
      final items = jsonDecode(prescription.itemsJson) as List<dynamic>;
      return '${items.length} medication(s)';
    } catch (_) {
      return 'Prescription created';
    }
  }
}

// Helper class for workflow steps
class _WorkflowStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isRequired;

  const _WorkflowStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isRequired,
  });
}

// Patient selection bottom sheet
class _PatientSelectionSheet extends StatefulWidget {
  final List<Patient> patients;

  const _PatientSelectionSheet({required this.patients});

  @override
  State<_PatientSelectionSheet> createState() => _PatientSelectionSheetState();
}

class _PatientSelectionSheetState extends State<_PatientSelectionSheet> {
  String _searchQuery = '';
  
  List<Patient> get _filteredPatients {
    if (_searchQuery.isEmpty) return widget.patients;
    final query = _searchQuery.toLowerCase();
    return widget.patients.where((p) =>
      p.firstName.toLowerCase().contains(query) ||
      p.lastName.toLowerCase().contains(query) ||
      p.phone.contains(query)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Select Patient',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
          // Patient list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = _filteredPatients[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.patients.withValues(alpha: 0.2),
                    child: Text(
                      '${patient.firstName[0]}${patient.lastName[0]}',
                      style: const TextStyle(
                        color: AppColors.patients,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('${patient.firstName} ${patient.lastName}'),
                  subtitle: Text(patient.phone),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRiskLevelColor(patient.riskLevel).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getRiskLevelLabel(patient.riskLevel),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getRiskLevelColor(patient.riskLevel),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onTap: () => Navigator.pop(context, patient),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskLevelColor(int riskLevel) {
    switch (riskLevel) {
      case 2: return AppColors.error;
      case 1: return AppColors.warning;
      default: return AppColors.success;
    }
  }

  String _getRiskLevelLabel(int riskLevel) {
    switch (riskLevel) {
      case 2: return 'High';
      case 1: return 'Medium';
      default: return 'Low';
    }
  }
}

// Workflow complete dialog
class _WorkflowCompleteDialog extends StatelessWidget {
  final Patient patient;
  final Appointment? appointment;
  final Encounter? encounter;
  final Prescription? prescription;
  final Invoice? invoice;

  const _WorkflowCompleteDialog({
    required this.patient,
    this.appointment,
    this.encounter,
    this.prescription,
    this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Visit Complete!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${patient.firstName} ${patient.lastName}\'s visit has been completed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (encounter != null)
                    _buildSummaryRow(Icons.medical_services_rounded, 'Visit #${encounter!.id} completed'),
                  if (appointment != null)
                    _buildSummaryRow(Icons.calendar_month_rounded, 'Appointment completed'),
                  if (prescription != null)
                    _buildSummaryRow(Icons.medication_rounded, 'Prescription created'),
                  if (invoice != null)
                    _buildSummaryRow(Icons.receipt_long_rounded, 'Invoice: PKR ${invoice!.grandTotal.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal for entering diagnoses in the workflow
class _DiagnosisEntryModal extends StatefulWidget {
  final int patientId;
  final int? encounterId;
  final List<String> existingDiagnoses;
  
  const _DiagnosisEntryModal({
    required this.patientId,
    this.encounterId,
    required this.existingDiagnoses,
  });
  
  @override
  State<_DiagnosisEntryModal> createState() => _DiagnosisEntryModalState();
}

class _DiagnosisEntryModalState extends State<_DiagnosisEntryModal> {
  final _controller = TextEditingController();
  late List<String> _diagnoses;
  
  // Common diagnoses for quick selection
  static const _commonDiagnoses = [
    'Hypertension',
    'Type 2 Diabetes Mellitus',
    'Upper Respiratory Tract Infection',
    'Gastroesophageal Reflux Disease',
    'Migraine',
    'Low Back Pain',
    'Anxiety Disorder',
    'Depression',
    'Allergic Rhinitis',
    'Asthma',
    'Urinary Tract Infection',
    'Osteoarthritis',
    'Hypothyroidism',
    'Hyperlipidemia',
    'Anemia',
  ];
  
  @override
  void initState() {
    super.initState();
    _diagnoses = List.from(widget.existingDiagnoses);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _addDiagnosis(String diagnosis) {
    final trimmed = diagnosis.trim();
    if (trimmed.isNotEmpty && !_diagnoses.contains(trimmed)) {
      setState(() {
        _diagnoses.add(trimmed);
        _controller.clear();
      });
    }
  }
  
  void _removeDiagnosis(String diagnosis) {
    setState(() {
      _diagnoses.remove(diagnosis);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.medical_information_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Diagnoses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_diagnoses.length} diagnosis(es) added',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, {'diagnoses': _diagnoses}),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Input field
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter diagnosis or select below...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _addDiagnosis,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () => _addDiagnosis(_controller.text),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Current diagnoses
          if (_diagnoses.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _diagnoses.map((d) => Chip(
                  label: Text(d),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeDiagnosis(d),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                )).toList(),
              ),
            ),
          
          if (_diagnoses.isNotEmpty)
            const SizedBox(height: 16),
          
          // Common diagnoses
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Common Diagnoses',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _commonDiagnoses.length,
              itemBuilder: (context, index) {
                final diagnosis = _commonDiagnoses[index];
                final isSelected = _diagnoses.contains(diagnosis);
                
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.add_circle_outline,
                    color: isSelected ? AppColors.success : AppColors.primary,
                    size: 20,
                  ),
                  title: Text(diagnosis),
                  onTap: () {
                    if (isSelected) {
                      _removeDiagnosis(diagnosis);
                    } else {
                      _addDiagnosis(diagnosis);
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tileColor: isSelected
                      ? AppColors.success.withOpacity(0.1)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal for entering treatment plan in the workflow
class _TreatmentPlanModal extends StatefulWidget {
  final int patientId;
  final int? encounterId;
  final List<String> diagnoses;
  
  const _TreatmentPlanModal({
    required this.patientId,
    this.encounterId,
    required this.diagnoses,
  });
  
  @override
  State<_TreatmentPlanModal> createState() => _TreatmentPlanModalState();
}

class _TreatmentPlanModalState extends State<_TreatmentPlanModal> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _goalsController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _selectedDiagnosis = '';
  
  @override
  void initState() {
    super.initState();
    if (widget.diagnoses.isNotEmpty) {
      _selectedDiagnosis = widget.diagnoses.first;
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    _goalsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Create Treatment Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Link to diagnosis
                    if (widget.diagnoses.isNotEmpty) ...[
                      Text(
                        'For Diagnosis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedDiagnosis.isEmpty ? null : _selectedDiagnosis,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: widget.diagnoses.map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d),
                        )).toList(),
                        onChanged: (value) {
                          setState(() => _selectedDiagnosis = value ?? '');
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Treatment Description (main content)
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Treatment Plan*',
                        hintText: 'e.g., Start Amlodipine 5mg daily, lifestyle modifications...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please describe the treatment plan';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Goals
                    TextFormField(
                      controller: _goalsController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Treatment Goals',
                        hintText: 'e.g., Maintain BP below 130/80',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Instructions
                    TextFormField(
                      controller: _instructionsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Patient Instructions',
                        hintText: 'Instructions for the patient...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context, {
                        'description': _descriptionController.text.trim(),
                        'goals': _goalsController.text.trim(),
                        'instructions': _instructionsController.text.trim(),
                        'diagnosis': _selectedDiagnosis,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Treatment Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal for scheduling follow-up in the workflow
class _FollowUpSchedulerModal extends ConsumerStatefulWidget {
  final int patientId;
  final int? appointmentId;
  final String? diagnosis;
  final String? treatmentPlan;
  final String? reason;
  
  const _FollowUpSchedulerModal({
    required this.patientId,
    this.appointmentId,
    this.diagnosis,
    this.treatmentPlan,
    this.reason,
  });
  
  @override
  ConsumerState<_FollowUpSchedulerModal> createState() => _FollowUpSchedulerModalState();
}

class _FollowUpSchedulerModalState extends ConsumerState<_FollowUpSchedulerModal> {
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;
  
  // Common follow-up intervals
  static const _intervals = [
    {'label': '1 Week', 'days': 7},
    {'label': '2 Weeks', 'days': 14},
    {'label': '1 Month', 'days': 30},
    {'label': '3 Months', 'days': 90},
    {'label': '6 Months', 'days': 180},
  ];
  
  @override
  void initState() {
    super.initState();
    // Pre-fill reason based on context
    if (widget.reason != null && widget.reason!.isNotEmpty) {
      _reasonController.text = 'Follow-up for: ${widget.reason}';
    } else if (widget.diagnosis != null && widget.diagnosis!.isNotEmpty) {
      _reasonController.text = 'Follow-up for: ${widget.diagnosis}';
    }
    // Pre-fill notes with treatment context
    if (widget.treatmentPlan != null && widget.treatmentPlan!.isNotEmpty) {
      _notesController.text = 'Treatment: ${widget.treatmentPlan}';
    }
  }
  
  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _selectInterval(int days) {
    setState(() {
      _scheduledDate = DateTime.now().add(Duration(days: days));
    });
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }
  
  Future<void> _save() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for follow-up')),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final db = await ref.read(doctorDbProvider.future);
      final id = await db.insertScheduledFollowUp(
        ScheduledFollowUpsCompanion.insert(
          patientId: widget.patientId,
          scheduledDate: _scheduledDate,
          reason: _reasonController.text.trim(),
          sourceAppointmentId: Value(widget.appointmentId),
          status: const Value('pending'),
          notes: Value(_notesController.text.trim()),
        ),
      );
      
      // Fetch the created follow-up
      final followUp = await (db.select(db.scheduledFollowUps)
        ..where((f) => f.id.equals(id)))
        .getSingleOrNull();
      
      if (mounted) {
        Navigator.pop(context, followUp);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.event_repeat_rounded,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Schedule Follow-Up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick intervals
                  Text(
                    'Quick Select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _intervals.map((interval) {
                      final days = interval['days'] as int;
                      final isSelected = _scheduledDate.difference(DateTime.now()).inDays == days;
                      return FilterChip(
                        label: Text(interval['label'] as String),
                        selected: isSelected,
                        onSelected: (_) => _selectInterval(days),
                        selectedColor: Colors.orange.withOpacity(0.2),
                        checkmarkColor: Colors.orange,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date picker
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scheduled Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(_scheduledDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Reason
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: 'Reason for Follow-Up*',
                      hintText: 'e.g., Check medication response',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Notes
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Additional notes...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          
          // Save button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Schedule Follow-Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
