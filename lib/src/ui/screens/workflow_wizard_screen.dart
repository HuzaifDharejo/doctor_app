import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../providers/encounter_provider.dart';
import '../../services/encounter_service.dart';
import '../../services/lab_order_service.dart';
import '../../services/logger_service.dart';
import '../../services/problem_list_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/vitals_entry_modal.dart';
import 'add_appointment_screen.dart';
import 'add_invoice_screen.dart';
import 'add_patient_screen.dart';
import 'add_prescription_screen.dart';
import 'encounter_screen.dart';
import 'patient_view/patient_view_screen.dart';
import 'records/records.dart';
import 'vital_signs_screen.dart';

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
  int _prescriptionMedicationCount = 0; // V5: Cached count from normalized table
  ScheduledFollowUp? _followUp;
  Invoice? _invoice;
  
  // Diagnosis data (shared between steps)
  List<String> _currentDiagnoses = [];
  
  // Chief Complaint data
  String _chiefComplaint = '';
  String _historyOfPresentIllness = '';
  
  // Lab Orders data
  List<Map<String, dynamic>> _labOrders = [];
  
  // Clinical Notes data
  String _subjective = '';
  String _objective = '';
  String _assessment = '';
  String _plan = '';
  
  // Step completion status
  final Map<int, bool> _completedSteps = {};
  
  // Optional steps
  bool _skipChiefComplaint = false;
  bool _skipVitals = false;
  bool _skipDiagnosis = false;
  bool _skipLabOrders = false; // Don't skip by default - user must explicitly choose
  bool _skipPrescription = false;
  bool _skipFollowUp = false; // Don't skip by default - user must explicitly choose
  bool _skipClinicalNotes = false;
  
  // New optimized workflow steps:
  // 0: Register Patient
  // 1: Schedule Appointment  
  // 2: Check-In Patient
  // 3: Chief Complaint & History (NEW)
  // 4: Record Vitals
  // 5: Examination & Diagnosis
  // 6: Lab Orders (NEW)
  // 7: Prescription & Treatment (MERGED)
  // 8: Schedule Follow-Up
  // 9: Clinical Notes/SOAP (NEW)
  // 10: Complete & Invoice
  
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
      color: AppColors.billing,
      isRequired: true,
    ),
    _WorkflowStep(
      title: 'Chief Complaint',
      subtitle: 'Patient\'s main concern & history',
      icon: Icons.speaker_notes_rounded,
      color: AppColors.warning,
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Record Vitals',
      subtitle: 'Blood pressure, temperature, etc.',
      icon: Icons.monitor_heart_rounded,
      color: const Color(0xFFEC4899), // Pink for vitals
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Examination & Diagnosis',
      subtitle: 'Physical exam and diagnoses',
      icon: Icons.medical_information_rounded,
      color: AppColors.success,
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Lab Orders',
      subtitle: 'Order laboratory tests',
      icon: Icons.science_rounded,
      color: AppColors.billing,
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Prescription & Treatment',
      subtitle: 'Medications and treatment plan',
      icon: Icons.medication_rounded,
      color: AppColors.warning,
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Schedule Follow-Up',
      subtitle: 'Book next visit if needed',
      icon: Icons.event_repeat_rounded,
      color: AppColors.prescriptions,
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Clinical Notes',
      subtitle: 'SOAP notes and summary',
      icon: Icons.note_alt_rounded,
      color: AppColors.info,
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
      case 3: return _skipChiefComplaint;  // Chief Complaint step
      case 4: return _skipVitals;          // Vitals step
      case 5: return _skipDiagnosis;       // Diagnosis step
      case 6: return _skipLabOrders;       // Lab Orders step
      case 7: return _skipPrescription;    // Prescription step
      case 8: return _skipFollowUp;        // Follow-up step
      case 9: return _skipClinicalNotes;   // Clinical Notes step
      default: return false;
    }
  }

  bool _isStepCompleted(int index) {
    if (_isStepSkipped(index)) return true;
    
    // Check both the flag AND the actual data presence
    // This ensures button is active when record exists
    switch (index) {
      case 0: // Patient
        return _completedSteps[index] == true || _patient != null;
      case 1: // Appointment
        return _completedSteps[index] == true || _appointment != null;
      case 2: // Check-in
        return _completedSteps[index] == true || _encounter != null;
      case 3: // Chief Complaint
        return _completedSteps[index] == true || _chiefComplaint.isNotEmpty;
      case 4: // Vitals
        return _completedSteps[index] == true; // Vitals are recorded in encounter
      case 5: // Diagnosis
        return _completedSteps[index] == true || _currentDiagnoses.isNotEmpty || _medicalRecord != null;
      case 6: // Lab Orders
        return _completedSteps[index] == true || _labOrders.isNotEmpty;
      case 7: // Prescription
        return _completedSteps[index] == true || _prescription != null;
      case 8: // Follow-up
        return _completedSteps[index] == true || _followUp != null;
      case 9: // Clinical Notes
        return _completedSteps[index] == true || 
               _subjective.isNotEmpty || _objective.isNotEmpty || 
               _assessment.isNotEmpty || _plan.isNotEmpty;
      case 10: // Invoice
        return _completedSteps[index] == true || _invoice != null;
      default:
        return _completedSteps[index] == true;
    }
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
    
    // Final data sync: Save any remaining workflow data to prescription
    if (_prescription != null) {
      try {
        // Save clinical notes if not already saved
        if (_subjective.isNotEmpty || _objective.isNotEmpty || 
            _assessment.isNotEmpty || _plan.isNotEmpty) {
          final existingNotes = await db.getClinicalNotesForPrescriptionCompat(_prescription!.id);
          if (existingNotes.isEmpty) {
            final soapNotes = StringBuffer();
            if (_subjective.isNotEmpty) {
              soapNotes.writeln('S: $_subjective');
            }
            if (_objective.isNotEmpty) {
              soapNotes.writeln('O: $_objective');
            }
            if (_assessment.isNotEmpty) {
              soapNotes.writeln('A: $_assessment');
            }
            if (_plan.isNotEmpty) {
              soapNotes.writeln('P: $_plan');
            }
            
            await db.updatePrescription(
              PrescriptionsCompanion(
                id: Value(_prescription!.id),
                clinicalNotes: Value(soapNotes.toString().trim()),
              ),
            );
            log.d('WORKFLOW', 'Clinical notes saved to prescription on completion');
          }
        }
        
        // Update follow-up info if scheduled but not yet saved to prescription
        if (_followUp != null) {
          final prescription = await db.getPrescriptionById(_prescription!.id);
          if (prescription != null && prescription.followUpDate == null) {
            await db.updatePrescription(
              PrescriptionsCompanion(
                id: Value(_prescription!.id),
                followUpDate: Value(_followUp!.scheduledDate),
                followUpNotes: Value(_followUp!.reason),
              ),
            );
            log.d('WORKFLOW', 'Follow-up saved to prescription on completion');
          }
        }
      } catch (e) {
        log.e('WORKFLOW', 'Error syncing workflow data to prescription', error: e);
      }
    }
    
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
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      color: surfaceColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                    duration: AppDuration.quick,
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
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(step.icon, color: step.color, size: 28),
              ),
              SizedBox(width: AppSpacing.lg),
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
                              fontSize: AppFontSize.xxxl,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!step.isRequired)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: AppFontSize.xs,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      step.subtitle,
                      style: TextStyle(
                        fontSize: AppFontSize.lg,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.xxl),
          
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
        return _buildChiefComplaintStep(isDark);
      case 4:
        return _buildVitalsStep(isDark);
      case 5:
        return _buildDiagnosisStep(isDark);
      case 6:
        return _buildLabOrdersStep(isDark);
      case 7:
        return _buildPrescriptionStep(isDark);
      case 8:
        return _buildFollowUpStep(isDark);
      case 9:
        return _buildClinicalNotesStep(isDark);
      case 10:
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
      final isWalkIn = _appointment!.notes.contains('Walk-in');
      
      return _buildCompletedCard(
        isDark: isDark,
        title: _appointment!.reason,
        subtitle: isWalkIn ? 'Walk-in appointment' : 'Appointment scheduled',
        icon: isWalkIn ? Icons.directions_walk_rounded : Icons.calendar_month_rounded,
        color: AppColors.appointments,
        onEdit: () => _scheduleAppointment(),
        details: [
          'Date: ${dateFormat.format(_appointment!.appointmentDateTime)}',
          'Time: ${timeFormat.format(_appointment!.appointmentDateTime)}',
          if (!isWalkIn) 'Duration: ${_appointment!.durationMinutes} minutes',
          if (isWalkIn) 'Type: Walk-In (Current Time)',
        ],
      );
    }

    return Column(
      children: [
        // Walk-In / Instant Appointment (Primary option for workflow)
        _buildActionCard(
          isDark: isDark,
          title: 'Walk-In Appointment',
          subtitle: 'Start consultation now (current time)',
          icon: Icons.directions_walk_rounded,
          color: const Color(0xFF10B981),
          onTap: () => _createWalkInAppointment(),
        ),
        const SizedBox(height: 12),
        // Schedule for later
        _buildActionCard(
          isDark: isDark,
          title: 'Schedule Appointment',
          subtitle: 'Book for a specific date/time',
          icon: Icons.calendar_month_rounded,
          color: AppColors.appointments,
          onTap: () => _scheduleAppointment(),
        ),
      ],
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

  // Step 3: Chief Complaint & History
  Widget _buildChiefComplaintStep(bool isDark) {
    final hasData = _chiefComplaint.isNotEmpty;
    
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'Skip Chief Complaint',
          value: _skipChiefComplaint,
          onChanged: (value) => setState(() {
            _skipChiefComplaint = value;
            if (value) _completedSteps[3] = true;
          }),
        ),
        const SizedBox(height: 16),
        
        if (!_skipChiefComplaint) ...[
          if (hasData)
            _buildCompletedCard(
              isDark: isDark,
              title: 'Chief Complaint Recorded',
              subtitle: _chiefComplaint,
              icon: Icons.speaker_notes_rounded,
              color: const Color(0xFFF59E0B),
              onEdit: () => _recordChiefComplaint(),
              details: [
                if (_historyOfPresentIllness.isNotEmpty) 
                  'HPI: ${_historyOfPresentIllness.length > 50 ? '${_historyOfPresentIllness.substring(0, 50)}...' : _historyOfPresentIllness}',
              ],
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Record Chief Complaint',
              subtitle: 'Document patient\'s main concern',
              icon: Icons.speaker_notes_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () => _recordChiefComplaint(),
            ),
          
          const SizedBox(height: 12),
          
          _buildActionCard(
            isDark: isDark,
            title: 'Quick Complaint Entry',
            subtitle: 'Common complaints quick select',
            icon: Icons.flash_on_rounded,
            color: Colors.amber,
            onTap: () => _showQuickComplaintPicker(isDark),
          ),
        ],
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
            if (value) _completedSteps[4] = true;
          }),
        ),
        SizedBox(height: AppSpacing.lg),
        
        if (!_skipVitals) ...[
          if (_completedSteps[4] == true)
            _buildCompletedCard(
              isDark: isDark,
              title: 'Vitals Recorded',
              subtitle: 'Patient vital signs saved',
              icon: Icons.monitor_heart_rounded,
              color: const Color(0xFFEC4899), // Pink for vitals
              onEdit: () => _recordVitals(),
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Record Vital Signs',
              subtitle: 'BP, heart rate, temperature, SpO2',
              icon: Icons.monitor_heart_rounded,
              color: const Color(0xFFEC4899), // Pink for vitals
              onTap: () => _recordVitals(),
            ),
        ],
      ],
    );
  }

  // Step 6: Diagnosis (index 5)
  Widget _buildDiagnosisStep(bool isDark) {
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'Skip Diagnosis',
          value: _skipDiagnosis,
          onChanged: (value) => setState(() {
            _skipDiagnosis = value;
            if (value) _completedSteps[5] = true;
          }),
        ),
        SizedBox(height: AppSpacing.lg),
        
        if (!_skipDiagnosis) ...[
          // Show current diagnoses if any
          if (_currentDiagnoses.isNotEmpty) ...[
            _buildCompletedCard(
              isDark: isDark,
              title: 'Diagnoses Added',
              subtitle: '${_currentDiagnoses.length} diagnosis(es)',
              icon: Icons.medical_information_rounded,
              color: AppColors.success,
              onEdit: () => _addDiagnosis(),
              details: _currentDiagnoses.take(3).toList(),
            ),
            SizedBox(height: AppSpacing.md),
            _buildActionCard(
              isDark: isDark,
              title: 'Add More Diagnoses',
              subtitle: 'Add additional diagnoses',
              icon: Icons.add_circle_outline_rounded,
              color: AppColors.success,
              onTap: () => _addDiagnosis(),
            ),
          ] else ...[
            _buildActionCard(
              isDark: isDark,
              title: 'Add Diagnosis',
              subtitle: 'Document patient diagnoses (ICD-10)',
              icon: Icons.medical_information_rounded,
              color: AppColors.success,
              onTap: () => _addDiagnosis(),
            ),
          ],
          
          SizedBox(height: AppSpacing.lg),
          
          // Also allow adding a medical record for detailed findings
          if (_medicalRecord != null)
            _buildCompletedCard(
              isDark: isDark,
              title: _medicalRecord!.recordType,
              subtitle: 'Medical record added',
              icon: Icons.folder_rounded,
              color: AppColors.accent,
              onEdit: () => _addMedicalRecord(),
              details: [
                'Date: ${DateFormat('MMM d, yyyy').format(_medicalRecord!.recordDate)}',
                if (_medicalRecord!.diagnosis.isNotEmpty)
                  'Diagnosis: ${_medicalRecord!.diagnosis}',
              ],
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Add Medical Record',
              subtitle: 'Document detailed findings (optional)',
              icon: Icons.folder_rounded,
              color: AppColors.accent,
              onTap: () => _addMedicalRecord(),
            ),
        ],
      ],
    );
  }

  // Step 6: Lab Orders
  Widget _buildLabOrdersStep(bool isDark) {
    final hasOrders = _labOrders.isNotEmpty;
    
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'No Lab Tests Needed',
          value: _skipLabOrders,
          onChanged: (value) => setState(() {
            _skipLabOrders = value;
            if (value) _completedSteps[6] = true;
          }),
        ),
        const SizedBox(height: 16),
        
        // Show diagnosis summary if available
        if (_currentDiagnoses.isNotEmpty) ...[
          _buildInfoCard(
            isDark: isDark,
            title: 'Diagnosis',
            message: _currentDiagnoses.join(', '),
            icon: Icons.medical_information_rounded,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
        ],
        
        if (!_skipLabOrders) ...[
          if (hasOrders) ...[
            _buildCompletedCard(
              isDark: isDark,
              title: '${_labOrders.length} Lab Test${_labOrders.length > 1 ? 's' : ''} Ordered',
              subtitle: _labOrders.map((o) => o['name'] ?? 'Test').take(3).join(', '),
              icon: Icons.science_rounded,
              color: const Color(0xFF8B5CF6),
              onEdit: () => _orderLabTests(),
              details: _labOrders.length > 3 
                  ? ['...and ${_labOrders.length - 3} more']
                  : [],
            ),
            const SizedBox(height: 12),
          ],
          
          _buildActionCard(
            isDark: isDark,
            title: hasOrders ? 'Add More Lab Tests' : 'Order Lab Tests',
            subtitle: 'Blood work, imaging, and other tests',
            icon: Icons.science_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => _orderLabTests(),
          ),
          
          const SizedBox(height: 12),
          
          // Quick common tests
          _buildActionCard(
            isDark: isDark,
            title: 'Quick Lab Panels',
            subtitle: 'CBC, LFT, RFT, Lipid Profile, etc.',
            icon: Icons.flash_on_rounded,
            color: Colors.purple[300]!,
            onTap: () => _showQuickLabPanels(isDark),
          ),
        ],
      ],
    );
  }

  // Step 7: Prescription & Treatment
  Widget _buildPrescriptionStep(bool isDark) {
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'Skip Prescription',
          value: _skipPrescription,
          onChanged: (value) => setState(() {
            _skipPrescription = value;
            if (value) _completedSteps[7] = true;
          }),
        ),
        const SizedBox(height: 16),
        
        // Show diagnosis summary
        if (_currentDiagnoses.isNotEmpty) ...[
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
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    '• Diagnosis: ${_currentDiagnoses.join(", ")}',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
                if (_chiefComplaint.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      '• Chief Complaint: $_chiefComplaint',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                if (_labOrders.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      '• Lab Orders: ${_labOrders.length} test(s)',
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
            
          const SizedBox(height: 12),
          
          // Treatment plan option (integrated)
          if (_treatmentPlan != null)
            _buildCompletedCard(
              isDark: isDark,
              title: 'Treatment Plan',
              subtitle: _treatmentPlan!.treatmentDescription,
              icon: Icons.assignment_rounded,
              color: const Color(0xFF8B5CF6),
              onEdit: () => _addTreatmentPlan(),
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Add Treatment Plan',
              subtitle: 'Define treatment goals (optional)',
              icon: Icons.assignment_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () => _addTreatmentPlan(),
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
            if (value) _completedSteps[8] = true;
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

  // Step 9: Clinical Notes (SOAP)
  Widget _buildClinicalNotesStep(bool isDark) {
    final hasNotes = _subjective.isNotEmpty || _objective.isNotEmpty || 
                     _assessment.isNotEmpty || _plan.isNotEmpty;
    
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'Skip Clinical Notes',
          value: _skipClinicalNotes,
          onChanged: (value) => setState(() {
            _skipClinicalNotes = value;
            if (value) _completedSteps[9] = true;
          }),
        ),
        const SizedBox(height: 16),
        
        if (!_skipClinicalNotes) ...[
          if (hasNotes)
            _buildCompletedCard(
              isDark: isDark,
              title: 'Clinical Notes Recorded',
              subtitle: 'SOAP notes documented',
              icon: Icons.note_alt_rounded,
              color: const Color(0xFF06B6D4),
              onEdit: () => _recordClinicalNotes(),
              details: [
                if (_subjective.isNotEmpty) 'S: ${_subjective.length > 30 ? '${_subjective.substring(0, 30)}...' : _subjective}',
                if (_assessment.isNotEmpty) 'A: ${_assessment.length > 30 ? '${_assessment.substring(0, 30)}...' : _assessment}',
              ],
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Record Clinical Notes',
              subtitle: 'SOAP notes and visit summary',
              icon: Icons.note_alt_rounded,
              color: const Color(0xFF06B6D4),
              onTap: () => _recordClinicalNotes(),
            ),
          
          const SizedBox(height: 12),
          
          // Auto-generate from visit data
          _buildActionCard(
            isDark: isDark,
            title: 'Auto-Generate Notes',
            subtitle: 'Create notes from visit data',
            icon: Icons.auto_awesome_rounded,
            color: Colors.cyan[300]!,
            onTap: () => _autoGenerateNotes(),
          ),
        ],
      ],
    );
  }

  // Step 10: Invoice
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
    if (_chiefComplaint.isNotEmpty) items.add('Chief Complaint: $_chiefComplaint');
    if (_currentDiagnoses.isNotEmpty) items.add('Diagnosis: ${_currentDiagnoses.join(", ")}');
    if (_labOrders.isNotEmpty) items.add('Lab Orders: ${_labOrders.length} test(s)');
    if (_prescription != null) items.add('Prescription: Created');
    if (_followUp != null) items.add('Follow-up: ${DateFormat('MMM d').format(_followUp!.scheduledDate)}');

    return Container(
      padding: EdgeInsets.all(context.responsivePadding),
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
      padding: EdgeInsets.all(AppSpacing.lg),
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
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
            if (!isFirstStep) SizedBox(width: AppSpacing.md),
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
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        hoverColor: color.withValues(alpha: 0.05),
        focusColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: AppFontSize.headlineSmall,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppFontSize.bodyMedium,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
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
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppFontSize.titleLarge,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppFontSize.bodyMedium,
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
            SizedBox(height: AppSpacing.md),
            ...details.map((detail) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                detail,
                style: TextStyle(
                  fontSize: AppFontSize.bodyMedium,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppFontSize.titleMedium,
                    color: color,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: AppFontSize.bodyMedium,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.error),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppFontSize.titleMedium,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: AppFontSize.bodyMedium,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
      AppRouter.route(const AddPatientScreen()),
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

  Future<void> _createWalkInAppointment() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot create walk-in appointment - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Creating walk-in appointment for patient: ${_patient!.firstName}');
    
    // Show quick reason picker
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _WalkInReasonPicker(patientName: _patient!.firstName),
    );
    
    if (reason == null || !mounted) {
      log.d('WORKFLOW', 'Walk-in appointment cancelled');
      return;
    }
    
    try {
      final db = await ref.read(doctorDbProvider.future);
      final now = DateTime.now();
      
      // Create appointment at current time - mark as Walk-in in notes
      final appointmentId = await db.insertAppointment(
        AppointmentsCompanion.insert(
          patientId: _patient!.id,
          appointmentDateTime: now,
          durationMinutes: const Value(15),
          reason: Value(reason),
          status: const Value('checked_in'), // Already checked in for walk-ins
          notes: const Value('Walk-in patient'),
        ),
      );
      
      // Fetch the created appointment
      final appointment = await db.getAppointmentById(appointmentId);
      
      if (appointment != null && mounted) {
        log.i('WORKFLOW', 'Walk-in appointment created', extra: {
          'appointmentId': appointmentId,
          'time': now.toIso8601String(),
          'reason': reason,
        });
        
        setState(() {
          _appointment = appointment;
          _completedSteps[1] = true;
          // Also auto-complete check-in for walk-ins
          _completedSteps[2] = true;
        });
        
        // Auto-create encounter for walk-in
        await _autoCreateEncounterForWalkIn(reason);
        
        // Move to next step after check-in (skip check-in step)
        _goToNextStep();
        _goToNextStep(); // Skip check-in since it's already done
      }
    } catch (e) {
      log.e('WORKFLOW', 'Failed to create walk-in appointment', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _autoCreateEncounterForWalkIn(String chiefComplaint) async {
    if (_patient == null || _appointment == null) return;
    
    try {
      final db = await ref.read(doctorDbProvider.future);
      final encounterService = EncounterService(db: db);
      
      final encounterId = await encounterService.startEncounter(
        patientId: _patient!.id,
        appointmentId: _appointment!.id,
        chiefComplaint: chiefComplaint,
        encounterType: _getEncounterType(chiefComplaint),
      );
      
      _encounter = await db.getEncounterById(encounterId);
      
      // Also set the chief complaint for the workflow
      setState(() {
        _chiefComplaint = chiefComplaint;
        _completedSteps[3] = true; // Chief complaint also done
      });
      
      log.i('WORKFLOW', 'Auto-created encounter for walk-in', extra: {
        'encounterId': encounterId,
      });
    } catch (e) {
      log.e('WORKFLOW', 'Failed to auto-create encounter for walk-in', error: e);
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
        chiefComplaint: _appointment!.reason.isNotEmpty 
            ? _appointment!.reason 
            : 'Scheduled appointment',
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
    
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
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
            _completedSteps[4] = true; // Vitals
            _completedSteps[5] = true; // Diagnosis
          }
        });
      }
    }
  }

  Future<void> _viewPatientHistory() async {
    if (_patient == null) return;
    
    log.d('WORKFLOW', 'Viewing patient history: ${_patient!.firstName} ${_patient!.lastName}');
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
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
      final vitalId = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => VitalsEntryModal(
            encounterId: _encounter!.id,
            patientId: _patient!.id,
            onSaved: (vitalId) {
              log.i('WORKFLOW', 'Vitals saved via encounter modal', extra: {
                'vitalId': vitalId,
                'encounterId': _encounter!.id,
              });
            },
          ),
        ),
      );
      
      // Mark as completed only if vitals were actually saved
      if (vitalId != null && mounted) {
        log.i('WORKFLOW', 'Vitals recorded successfully', extra: {'vitalId': vitalId});
        setState(() {
          _completedSteps[4] = true;
        });
      }
    } else {
      // Fallback to original vitals screen
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => VitalSignsScreen(
            patientId: _patient!.id,
            patientName: '${_patient!.firstName} ${_patient!.lastName}',
          ),
        ),
      );
      
      // Mark as completed after visiting vitals screen
      if (mounted) {
        log.i('WORKFLOW', 'Vitals screen visited for patient: ${_patient!.firstName}');
        setState(() {
          _completedSteps[4] = true;
        });
      }
    }
  }

  // Chief Complaint Actions
  Future<void> _recordChiefComplaint() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot record chief complaint - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening chief complaint form');
    
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChiefComplaintModal(
        chiefComplaint: _chiefComplaint,
        historyOfPresentIllness: _historyOfPresentIllness,
      ),
    );
    
    if (result != null && mounted) {
      log.i('WORKFLOW', 'Chief complaint recorded', extra: {
        'complaint': result['chiefComplaint'],
      });
      setState(() {
        _chiefComplaint = result['chiefComplaint'] ?? '';
        _historyOfPresentIllness = result['hpi'] ?? '';
        if (_chiefComplaint.isNotEmpty) {
          _completedSteps[3] = true;
        }
      });
      
      // Save complaints as problems
      if (_chiefComplaint.isNotEmpty && _patient != null) {
        _saveComplaintsAsProblems(_chiefComplaint);
      }
    }
  }

  void _showQuickComplaintPicker(bool isDark) {
    final commonComplaints = [
      ('Fever', Icons.thermostat_rounded),
      ('Cough', Icons.air_rounded),
      ('Cold', Icons.ac_unit_rounded),
      ('Headache', Icons.psychology_rounded),
      ('Body Pain', Icons.accessibility_new_rounded),
      ('Stomach Pain', Icons.restaurant_rounded),
      ('Vomiting', Icons.sick_rounded),
      ('Diarrhea', Icons.water_drop_rounded),
      ('Chest Pain', Icons.favorite_rounded),
      ('Shortness of Breath', Icons.airline_seat_flat_rounded),
      ('Dizziness', Icons.rotate_right_rounded),
      ('Fatigue', Icons.battery_1_bar_rounded),
      ('Back Pain', Icons.accessibility_rounded),
      ('Joint Pain', Icons.sports_martial_arts_rounded),
      ('Skin Rash', Icons.blur_on_rounded),
      ('Sore Throat', Icons.record_voice_over_rounded),
    ];
    
    // Parse existing complaints into a set for multi-select
    final selectedComplaints = <String>{};
    if (_chiefComplaint.isNotEmpty) {
      selectedComplaints.addAll(_chiefComplaint.split(', ').map((s) => s.trim()).where((s) => s.isNotEmpty));
    }
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.all(context.responsivePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.flash_on_rounded, size: 20, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Select Complaints',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Tap to select multiple',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedComplaints.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${selectedComplaints.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: commonComplaints.map((complaint) {
                    final isSelected = selectedComplaints.contains(complaint.$1);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            selectedComplaints.remove(complaint.$1);
                          } else {
                            selectedComplaints.add(complaint.$1);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFFF59E0B) 
                                : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.check_rounded : complaint.$2,
                              size: 16,
                              color: isSelected 
                                  ? Colors.white 
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              complaint.$1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected 
                                    ? Colors.white 
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() => selectedComplaints.clear());
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: selectedComplaints.isNotEmpty ? () {
                        Navigator.pop(context);
                        final complaintsText = selectedComplaints.join(', ');
                        setState(() {
                          _chiefComplaint = complaintsText;
                          _completedSteps[3] = true;
                        });
                        
                        // Save complaints as problems
                        if (_patient != null) {
                          _saveComplaintsAsProblems(complaintsText);
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        disabledBackgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        selectedComplaints.isEmpty 
                            ? 'Select Complaints' 
                            : 'Done (${selectedComplaints.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selectedComplaints.isNotEmpty ? Colors.white : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Save chief complaints as problems in the ProblemList table
  Future<void> _saveComplaintsAsProblems(String complaintsText) async {
    if (_patient == null || complaintsText.isEmpty) {
      return;
    }

    try {
      final problemService = ProblemListService();
      
      // Get existing problems to check for duplicates
      final existingProblems = await problemService.getProblemsForPatient(_patient!.id);
      final existingProblemNames = existingProblems
          .map((p) => p.problemName.toLowerCase().trim())
          .toSet();

      // Split complaints by comma and process each
      final complaintList = complaintsText
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();

      for (final complaint in complaintList) {
        // Check if this problem already exists (case-insensitive)
        final complaintLower = complaint.toLowerCase();
        if (existingProblemNames.contains(complaintLower)) {
          log.d('WORKFLOW', 'Problem already exists, skipping: $complaint');
          continue;
        }

        // Create problem with isChiefConcern flag set to true
        await problemService.createProblem(
          patientId: _patient!.id,
          problemName: complaint,
          isChiefConcern: true,
          status: 'active',
          category: 'medical',
          priority: 1, // High priority for chief concerns
        );

        log.i('WORKFLOW', 'Saved complaint as problem', extra: {
          'complaint': complaint,
          'patientId': _patient!.id,
        });
      }
    } catch (e) {
      log.e('WORKFLOW', 'Error saving complaints as problems', error: e);
      // Don't show error to user - this is a background operation
    }
  }

  // Lab Orders Actions
  Future<void> _orderLabTests() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot order lab tests - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening lab orders');
    
    final result = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LabOrderModal(
        patientId: _patient!.id,
        existingOrders: _labOrders,
        diagnosis: _currentDiagnoses.isNotEmpty ? _currentDiagnoses.first : null,
      ),
    );
    
    if (result != null && mounted) {
      log.i('WORKFLOW', 'Lab tests ordered', extra: {
        'count': result.length,
      });
      setState(() {
        _labOrders = result;
        if (_labOrders.isNotEmpty) {
          _completedSteps[6] = true;
        }
      });
    }
  }

  void _showQuickLabPanels(bool isDark) {
    final quickPanels = [
      {'name': 'CBC (Complete Blood Count)', 'code': 'CBC'},
      {'name': 'LFT (Liver Function Test)', 'code': 'LFT'},
      {'name': 'RFT (Renal Function Test)', 'code': 'RFT'},
      {'name': 'Lipid Profile', 'code': 'LIPID'},
      {'name': 'Thyroid Profile', 'code': 'THYROID'},
      {'name': 'HbA1c', 'code': 'HBA1C'},
      {'name': 'Fasting Blood Sugar', 'code': 'FBS'},
      {'name': 'Urine Routine', 'code': 'URINE'},
      {'name': 'Chest X-Ray', 'code': 'CXR'},
      {'name': 'ECG', 'code': 'ECG'},
    ];
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(context.responsivePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Lab Panels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickPanels.map((panel) => 
                ActionChip(
                  label: Text(panel['name']!),
                  backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: const Color(0xFF8B5CF6)),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      if (!_labOrders.any((o) => o['code'] == panel['code'])) {
                        _labOrders.add(panel);
                      }
                      _completedSteps[6] = true;
                    });
                  },
                ),
              ).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Clinical Notes Actions
  Future<void> _recordClinicalNotes() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot record clinical notes - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening clinical notes form');
    
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClinicalNotesModal(
        subjective: _subjective,
        objective: _objective,
        assessment: _assessment,
        plan: _plan,
        chiefComplaint: _chiefComplaint,
        diagnoses: _currentDiagnoses,
      ),
    );
    
    if (result != null && mounted) {
      log.i('WORKFLOW', 'Clinical notes recorded');
      setState(() {
        _subjective = result['subjective'] ?? '';
        _objective = result['objective'] ?? '';
        _assessment = result['assessment'] ?? '';
        _plan = result['plan'] ?? '';
        _completedSteps[9] = true;
      });
      
      // If prescription already exists, save clinical notes immediately
      if (_prescription != null) {
        try {
          final db = await ref.read(doctorDbProvider.future);
          final soapNotes = StringBuffer();
          if (_subjective.isNotEmpty) {
            soapNotes.writeln('S: $_subjective');
          }
          if (_objective.isNotEmpty) {
            soapNotes.writeln('O: $_objective');
          }
          if (_assessment.isNotEmpty) {
            soapNotes.writeln('A: $_assessment');
          }
          if (_plan.isNotEmpty) {
            soapNotes.writeln('P: $_plan');
          }
          
          await db.updatePrescription(
            PrescriptionsCompanion(
              id: Value(_prescription!.id),
              clinicalNotes: Value(soapNotes.toString().trim()),
            ),
          );
          
          log.i('WORKFLOW', 'Clinical notes saved to existing prescription', extra: {
            'prescriptionId': _prescription!.id,
          });
        } catch (e) {
          log.e('WORKFLOW', 'Failed to save clinical notes to prescription', error: e);
        }
      }
    }
  }

  void _autoGenerateNotes() {
    // Auto-generate SOAP notes from visit data
    setState(() {
      _subjective = _chiefComplaint.isNotEmpty 
          ? 'Patient presents with: $_chiefComplaint\n${_historyOfPresentIllness.isNotEmpty ? 'HPI: $_historyOfPresentIllness' : ''}'
          : '';
      
      _objective = ''; // Would need vitals data
      
      _assessment = _currentDiagnoses.isNotEmpty 
          ? _currentDiagnoses.join('\n')
          : '';
      
      _plan = '';
      if (_prescription != null) _plan += 'Medications prescribed\n';
      if (_labOrders.isNotEmpty) _plan += 'Lab tests ordered: ${_labOrders.map((o) => o['name']).join(", ")}\n';
      if (_followUp != null) _plan += 'Follow-up scheduled: ${DateFormat('MMM d, yyyy').format(_followUp!.scheduledDate)}';
      
      if (_subjective.isNotEmpty || _assessment.isNotEmpty || _plan.isNotEmpty) {
        _completedSteps[9] = true;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 12),
            Text('Notes auto-generated from visit data'),
          ],
        ),
        backgroundColor: const Color(0xFF06B6D4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Helper method to link a diagnosis string to encounter (checks for duplicates)
  Future<void> _linkDiagnosisToEncounterIfNeeded(String diagnosisName) async {
    if (_encounter == null || _patient == null) return;
    
    try {
      final db = await ref.read(doctorDbProvider.future);
      
      // Find or create diagnosis
      final existingDiagnoses = await db.getDiagnosesForPatient(_patient!.id);
      var diagnosis = existingDiagnoses.where(
        (d) => d.description.toLowerCase() == diagnosisName.toLowerCase(),
      ).firstOrNull;
      
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
      
      // Check if already linked to encounter
      if (diagnosis != null) {
        final existingLinks = await db.getDiagnosesForEncounter(_encounter!.id);
        final linkExists = existingLinks.any((ed) => ed.diagnosisId == diagnosis!.id);
        
        if (!linkExists) {
          await db.into(db.encounterDiagnoses).insert(
            EncounterDiagnosesCompanion.insert(
              encounterId: _encounter!.id,
              diagnosisId: diagnosis.id,
              isNewDiagnosis: const Value(true),
              encounterStatus: const Value('addressed'),
            ),
          );
          log.d('WORKFLOW', 'Auto-linked diagnosis from medical record to encounter');
        }
      }
    } catch (e) {
      log.w('WORKFLOW', 'Failed to auto-link diagnosis to encounter: $e');
      // Non-critical error, continue
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
          chiefComplaint: _chiefComplaint,
          historyOfPresentIllness: _historyOfPresentIllness,
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
          
          // If encounter exists, also link this diagnosis to the encounter
          // (Medical record screens may not always do this automatically)
          if (_encounter != null) {
            _linkDiagnosisToEncounterIfNeeded(result.diagnosis);
          }
        }
        // Mark diagnosis step as complete since we have a medical record
        _completedSteps[5] = true;
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
      // Only save NEW diagnoses that aren't already in the database
      if (_encounter != null && diagnoses.isNotEmpty) {
        try {
          final db = await ref.read(doctorDbProvider.future);
          
          // Get existing encounter-diagnosis links to avoid duplicates
          final existingLinks = await db.getDiagnosesForEncounter(_encounter!.id);
          final linkedDiagnosisIds = existingLinks.map((ed) => ed.diagnosisId).toSet();
          
          // Get all patient diagnoses to check if diagnosis exists
          final existingDiagnoses = await db.getDiagnosesForPatient(_patient!.id);
          final existingDiagnosisMap = <String, Diagnose>{};
          for (final d in existingDiagnoses) {
            existingDiagnosisMap[d.description.toLowerCase()] = d;
          }
          
          for (final diagnosisName in diagnoses) {
            // Find or create diagnosis
            Diagnose? diagnosis = existingDiagnosisMap[diagnosisName.toLowerCase()];
            
            if (diagnosis == null) {
              // Create new diagnosis if it doesn't exist
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
              
              if (diagnosis != null) {
                existingDiagnosisMap[diagnosisName.toLowerCase()] = diagnosis;
                log.d('WORKFLOW', 'Created new diagnosis: $diagnosisName');
              }
            }
            
            // Link diagnosis to encounter only if not already linked
            // Note: diagnosis.id is non-nullable (autoIncrement), so no null check needed
            if (diagnosis != null && !linkedDiagnosisIds.contains(diagnosis.id)) {
              await db.into(db.encounterDiagnoses).insert(
                EncounterDiagnosesCompanion.insert(
                  encounterId: _encounter!.id,
                  diagnosisId: diagnosis.id,
                  isNewDiagnosis: Value(!existingDiagnosisMap.containsKey(diagnosisName.toLowerCase())),
                  encounterStatus: const Value('addressed'),
                ),
              );
              linkedDiagnosisIds.add(diagnosis.id); // Track as linked
              log.d('WORKFLOW', 'Linked diagnosis ${diagnosis.id} to encounter ${_encounter!.id}');
            } else if (diagnosis != null) {
              log.d('WORKFLOW', 'Diagnosis ${diagnosis.id} already linked to encounter ${_encounter!.id}, skipping');
            }
          }
          log.i('WORKFLOW', 'Diagnoses processed (${diagnoses.length} total, ${linkedDiagnosisIds.length - existingLinks.length} new links created)');
        } catch (e) {
          log.e('WORKFLOW', 'Failed to save diagnoses', error: e);
        }
      }
      
      setState(() {
        _currentDiagnoses = diagnoses;
        if (diagnoses.isNotEmpty) {
          _completedSteps[5] = true; // Diagnosis is step 5
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
      // Only save if not already saved (check if treatment plan already exists)
      if (_patient != null && _treatmentPlan == null) {
        try {
          final db = await ref.read(doctorDbProvider.future);
          
          // Check if a similar treatment outcome already exists for this patient
          final existingOutcomes = await db.getTreatmentOutcomesForPatient(_patient!.id);
          try {
            final similarOutcome = existingOutcomes.firstWhere(
              (to) => to.treatmentDescription == description && to.diagnosis == diagnosis,
            );
            
            // Use existing treatment outcome
            log.d('WORKFLOW', 'Treatment plan already exists, reusing existing outcome');
            if (mounted) {
              setState(() {
                _treatmentPlan = similarOutcome;
                _completedSteps[5] = true;
              });
            }
            return; // Exit early, don't create duplicate
          } catch (_) {
            // No similar outcome found, continue to create new one
          }
          
          // Create new treatment outcome
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
      } else if (_patient != null && _treatmentPlan != null) {
        // Treatment plan already exists, just mark as completed
        setState(() {
          _completedSteps[5] = true;
        });
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
      
      final db = await ref.read(doctorDbProvider.future);
      
      // V5: Load medication count from normalized table
      final medications = await db.getMedicationsForPrescriptionCompat(result.id);
      
      // Save lab orders to database and link to prescription
      if (_labOrders.isNotEmpty) {
        try {
          final labOrderService = LabOrderService();
          final baseTimestamp = DateTime.now().millisecondsSinceEpoch;
          
          for (int i = 0; i < _labOrders.length; i++) {
            final test = _labOrders[i];
            final orderNumber = 'LO-${baseTimestamp + i}';
            
            // Create lab order linked to prescription
            final labOrderId = await labOrderService.createLabOrder(
              patientId: _patient!.id,
              orderNumber: orderNumber,
              testCodes: '[]', // V5: Use LabTestResults table
              testNames: '[]', // V5: Use LabTestResults table
              orderingProvider: 'Doctor',
              orderedDate: DateTime.now(),
              encounterId: _encounter?.id,
              prescriptionId: result.id, // Link to prescription
              orderType: 'lab',
              priority: 'routine',
              notes: 'Ordered via workflow wizard',
            );
            
            // Save test to normalized LabTestResults table
            await db.insertLabTestResult(
              LabTestResultsCompanion.insert(
                labOrderId: labOrderId,
                patientId: _patient!.id,
                testName: test['name'] as String? ?? 'Unknown Test',
                testCode: Value(test['code'] as String? ?? ''),
                category: Value(test['category'] as String? ?? ''),
                displayOrder: Value(i),
              ),
            );
          }
          
          log.i('WORKFLOW', 'Lab orders saved and linked to prescription', extra: {
            'prescriptionId': result.id,
            'labOrderCount': _labOrders.length,
          });
        } catch (e) {
          log.e('WORKFLOW', 'Failed to save lab orders', error: e);
        }
      }
      
      // Save clinical notes to prescription if available
      if (_subjective.isNotEmpty || _objective.isNotEmpty || 
          _assessment.isNotEmpty || _plan.isNotEmpty) {
        try {
          final soapNotes = StringBuffer();
          if (_subjective.isNotEmpty) {
            soapNotes.writeln('S: $_subjective');
          }
          if (_objective.isNotEmpty) {
            soapNotes.writeln('O: $_objective');
          }
          if (_assessment.isNotEmpty) {
            soapNotes.writeln('A: $_assessment');
          }
          if (_plan.isNotEmpty) {
            soapNotes.writeln('P: $_plan');
          }
          
          await db.updatePrescription(
            PrescriptionsCompanion(
              id: Value(result.id),
              clinicalNotes: Value(soapNotes.toString().trim()),
            ),
          );
          
          log.i('WORKFLOW', 'Clinical notes saved to prescription', extra: {
            'prescriptionId': result.id,
          });
        } catch (e) {
          log.e('WORKFLOW', 'Failed to save clinical notes', error: e);
        }
      }
      
      setState(() {
        _prescription = result;
        _prescriptionMedicationCount = medications.length;
        _completedSteps[7] = true; // Prescription is step 7 (index 7)
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
      
      // Also update prescription with follow-up info if prescription exists
      if (_prescription != null) {
        try {
          final db = await ref.read(doctorDbProvider.future);
          await db.updatePrescription(
            PrescriptionsCompanion(
              id: Value(_prescription!.id),
              followUpDate: Value(result.scheduledDate),
              followUpNotes: Value(result.reason),
            ),
          );
          
          log.i('WORKFLOW', 'Follow-up saved to prescription', extra: {
            'prescriptionId': _prescription!.id,
          });
        } catch (e) {
          log.e('WORKFLOW', 'Failed to update prescription with follow-up', error: e);
        }
      }
      
      setState(() {
        _followUp = result;
        _completedSteps[8] = true; // Follow-up is step 8 (index 8)
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
        _completedSteps[10] = true; // Invoice is step 10 (index 10)
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
    // V5: Use cached count loaded from normalized table
    return '$_prescriptionMedicationCount medication(s)';
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
            padding: EdgeInsets.all(context.responsivePadding),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
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
            SizedBox(height: AppSpacing.lg),
            Text(
              'Visit Complete!',
              style: TextStyle(
                fontSize: AppFontSize.display,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              '${patient.firstName} ${patient.lastName}\'s visit has been completed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFontSize.bodyLarge,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            
            // Summary
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
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
            SizedBox(height: AppSpacing.xxl),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
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
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.success),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: AppFontSize.bodyLarge),
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
            padding: EdgeInsets.all(context.responsivePadding),
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
            padding: EdgeInsets.all(context.responsivePadding),
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
              padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
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
            padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
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
              padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
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
  
  // Treatment plan templates organized by diagnosis category
  static const Map<String, List<Map<String, String>>> _treatmentTemplates = {
    // Cardiovascular
    'Hypertension': [
      {
        'name': 'Standard HTN - Lifestyle + ACE-I',
        'description': '1. Start Lisinopril 10mg once daily\n2. Low sodium diet (<2g/day)\n3. Regular aerobic exercise 30min/day\n4. Weight management if overweight\n5. Limit alcohol intake',
        'goals': 'Target BP: <130/80 mmHg within 3 months\nReduce cardiovascular risk',
        'instructions': 'Take medication in the morning. Monitor BP at home twice daily. Report dizziness, persistent cough, or swelling. Follow DASH diet. Exercise regularly.',
      },
      {
        'name': 'HTN - CCB First Line',
        'description': '1. Start Amlodipine 5mg once daily\n2. Dietary sodium restriction\n3. Regular physical activity\n4. Smoking cessation if applicable',
        'goals': 'Target BP: <130/80 mmHg\nPrevent end-organ damage',
        'instructions': 'Take medication at same time daily. May cause ankle swelling initially. Avoid grapefruit juice. Monitor BP regularly.',
      },
      {
        'name': 'HTN - Combination Therapy',
        'description': '1. Amlodipine 5mg + Losartan 50mg daily\n2. Low sodium diet\n3. Weight loss goal: 5-10% if overweight\n4. Stress management',
        'goals': 'Target BP: <130/80 mmHg\nCardiovascular risk reduction',
        'instructions': 'Take both medications together in morning. Stay hydrated. Report any unusual symptoms.',
      },
    ],
    
    'Type 2 Diabetes': [
      {
        'name': 'T2DM - Metformin First Line',
        'description': '1. Start Metformin 500mg twice daily with meals\n2. Increase to 1000mg BID after 2 weeks if tolerated\n3. Diabetic diet counseling\n4. Regular exercise\n5. Blood glucose monitoring',
        'goals': 'HbA1c target: <7%\nFasting glucose: 80-130 mg/dL\nPost-meal glucose: <180 mg/dL',
        'instructions': 'Take with meals to reduce GI upset. Check blood sugar as directed. Report nausea, vomiting, or unusual fatigue. Follow diabetic diet. Exercise 150 min/week.',
      },
      {
        'name': 'T2DM - Add Sulfonylurea',
        'description': '1. Continue Metformin 1000mg BID\n2. Add Glimepiride 2mg once daily before breakfast\n3. Blood glucose monitoring\n4. Hypoglycemia education',
        'goals': 'HbA1c target: <7%\nAvoid hypoglycemia\nWeight maintenance',
        'instructions': 'Take Glimepiride before breakfast. Carry glucose tablets for low sugar. Know hypoglycemia symptoms. Never skip meals.',
      },
      {
        'name': 'T2DM - Insulin Initiation',
        'description': '1. Start Insulin Glargine 10 units at bedtime\n2. Continue oral medications\n3. Titrate insulin by 2 units every 3 days until FBG <130\n4. Intensive glucose monitoring',
        'goals': 'HbA1c: <7%\nFasting glucose: <130 mg/dL\nSafe insulin titration',
        'instructions': 'Inject insulin at same time each night. Rotate injection sites. Store insulin properly. Check blood sugar daily. Report hypoglycemia.',
      },
    ],
    
    'Diabetes Mellitus': [
      {
        'name': 'Standard Diabetes Management',
        'description': '1. Metformin 500mg BID with meals\n2. Diabetic diet - low carb, high fiber\n3. Regular glucose monitoring\n4. Annual eye and foot exams',
        'goals': 'HbA1c <7%\nFasting glucose 80-130 mg/dL\nPrevent complications',
        'instructions': 'Take medication with food. Monitor blood sugar regularly. Follow diabetic diet. Exercise 30 minutes daily. Annual screening tests.',
      },
    ],
    
    // Respiratory
    'Asthma': [
      {
        'name': 'Mild Intermittent Asthma',
        'description': '1. Salbutamol inhaler PRN for symptoms\n2. Avoid known triggers\n3. Peak flow monitoring\n4. Asthma action plan provided',
        'goals': 'Symptom control\nNo nighttime symptoms\nNormal activity level',
        'instructions': 'Use rescue inhaler as needed (max 2 puffs every 4-6 hours). Identify and avoid triggers. Seek emergency care if inhaler not helping.',
      },
      {
        'name': 'Mild Persistent Asthma',
        'description': '1. Fluticasone 100mcg 2 puffs BID (controller)\n2. Salbutamol inhaler PRN (rescue)\n3. Spacer device use\n4. Trigger avoidance',
        'goals': 'Minimal symptoms\nNo nocturnal awakening\nNormal lung function',
        'instructions': 'Use controller inhaler daily even when feeling well. Rinse mouth after steroid inhaler. Keep rescue inhaler available. Review technique.',
      },
      {
        'name': 'Moderate Persistent Asthma',
        'description': '1. Fluticasone/Salmeterol 250/50 1 puff BID\n2. Salbutamol PRN\n3. Consider oral steroids for exacerbations\n4. Pulmonology referral if needed',
        'goals': 'Well-controlled asthma\nReduced exacerbations\nImproved quality of life',
        'instructions': 'Use combination inhaler twice daily. Never stop suddenly. Rescue inhaler for breakthrough symptoms. Report increased rescue use.',
      },
    ],
    
    'Upper Respiratory Tract Infection': [
      {
        'name': 'Viral URTI - Symptomatic',
        'description': '1. Rest and adequate hydration\n2. Paracetamol 500mg q6h PRN for fever/pain\n3. Saline nasal spray\n4. Honey for cough (if >1 year old)\n5. No antibiotics needed',
        'goals': 'Symptom relief\nPrevention of complications\nRecovery in 7-10 days',
        'instructions': 'This is a viral infection - antibiotics won\'t help. Rest well. Drink plenty of fluids. Use paracetamol for fever. Return if symptoms worsen or persist >10 days.',
      },
      {
        'name': 'URTI with Bacterial Suspicion',
        'description': '1. Amoxicillin 500mg TID x 7 days\n2. Paracetamol PRN for fever\n3. Steam inhalation\n4. Rest and hydration',
        'goals': 'Resolution of infection\nPrevention of complications',
        'instructions': 'Complete full course of antibiotics. Take with food. Rest and stay hydrated. Return if not improving in 48-72 hours.',
      },
    ],
    
    // Gastrointestinal
    'Gastroesophageal Reflux Disease': [
      {
        'name': 'GERD - PPI First Line',
        'description': '1. Omeprazole 20mg once daily before breakfast x 4-8 weeks\n2. Lifestyle modifications\n3. Avoid trigger foods\n4. Elevate head of bed',
        'goals': 'Symptom relief\nHealing of esophagitis if present\nPrevent complications',
        'instructions': 'Take PPI 30 min before breakfast. Avoid spicy, acidic, fatty foods. No eating 3 hours before bed. Elevate head of bed 6 inches. Lose weight if overweight.',
      },
      {
        'name': 'GERD - Step-up Therapy',
        'description': '1. Omeprazole 40mg daily (or 20mg BID)\n2. Add H2 blocker at bedtime if nocturnal symptoms\n3. Strict dietary compliance\n4. Consider GI referral',
        'goals': 'Complete symptom control\nQuality of life improvement',
        'instructions': 'Higher dose PPI for refractory symptoms. Strict diet adherence. May add Ranitidine at bedtime. Follow up in 4 weeks.',
      },
    ],
    
    // Mental Health
    'Depression': [
      {
        'name': 'Mild-Moderate Depression - SSRI',
        'description': '1. Start Sertraline 50mg once daily\n2. Psychotherapy referral\n3. Regular exercise\n4. Sleep hygiene\n5. Social support',
        'goals': 'Symptom improvement in 4-6 weeks\nImproved functioning\nSuicide risk monitoring',
        'instructions': 'Take medication at same time daily. May take 2-4 weeks to feel better. Do not stop suddenly. Report any thoughts of self-harm immediately. Follow up in 2 weeks.',
      },
      {
        'name': 'Depression - Dose Optimization',
        'description': '1. Increase Sertraline to 100mg daily\n2. Continue therapy\n3. Monitor response and side effects\n4. Consider augmentation if partial response',
        'goals': 'Full remission of symptoms\nFunctional recovery',
        'instructions': 'Gradual dose increase. Continue medication even if feeling better. Regular follow-ups essential. Report side effects.',
      },
    ],
    
    'Anxiety Disorder': [
      {
        'name': 'GAD - SSRI + CBT',
        'description': '1. Escitalopram 10mg daily\n2. CBT therapy referral\n3. Relaxation techniques\n4. Limit caffeine\n5. Regular exercise',
        'goals': 'Reduced anxiety symptoms\nImproved daily functioning\nDevelop coping skills',
        'instructions': 'Take medication daily. May cause initial anxiety increase - this improves. Practice relaxation techniques. Attend therapy sessions. Avoid alcohol.',
      },
      {
        'name': 'Acute Anxiety - Short-term',
        'description': '1. Alprazolam 0.25mg PRN (max 3x daily)\n2. Short-term use only (2-4 weeks)\n3. Start SSRI for long-term management\n4. Behavioral therapy',
        'goals': 'Acute symptom relief\nTransition to long-term treatment',
        'instructions': 'Use only when needed. Do not drive after taking. Can cause drowsiness. Not for long-term use. Start SSRI for ongoing treatment.',
      },
    ],
    
    // Pain
    'Migraine': [
      {
        'name': 'Acute Migraine Treatment',
        'description': '1. Sumatriptan 50mg at onset, may repeat in 2 hours\n2. NSAIDs as alternative\n3. Rest in dark, quiet room\n4. Identify and avoid triggers',
        'goals': 'Abort acute attacks\nReturn to function within 2 hours',
        'instructions': 'Take at first sign of migraine. Limit to 10 days/month to avoid rebound. Keep headache diary. Identify triggers. Rest when possible.',
      },
      {
        'name': 'Migraine Prophylaxis',
        'description': '1. Propranolol 40mg BID (or Amitriptyline 25mg at bedtime)\n2. Lifestyle modifications\n3. Headache diary\n4. Acute treatment PRN',
        'goals': 'Reduce migraine frequency by 50%\nImprove quality of life',
        'instructions': 'Take preventive medication daily. May take 2-3 months to see full benefit. Do not stop suddenly. Continue headache diary.',
      },
    ],
    
    'Low Back Pain': [
      {
        'name': 'Acute LBP - Conservative',
        'description': '1. NSAIDs: Ibuprofen 400mg TID with food x 5-7 days\n2. Muscle relaxant if spasm: Cyclobenzaprine 10mg at bedtime\n3. Heat/ice therapy\n4. Gentle activity as tolerated\n5. Avoid bed rest',
        'goals': 'Pain relief\nReturn to normal activity\nPrevent chronicity',
        'instructions': 'Stay active - bed rest worsens outcomes. Take NSAIDs with food. Apply heat for muscle spasm. Gentle stretching. Return if weakness, numbness, or bladder issues.',
      },
      {
        'name': 'Chronic LBP - Multimodal',
        'description': '1. Physical therapy referral\n2. NSAIDs PRN\n3. Core strengthening exercises\n4. Consider duloxetine if neuropathic component\n5. Weight management',
        'goals': 'Functional improvement\nPain management\nPrevent disability',
        'instructions': 'Attend all PT sessions. Exercise daily. Maintain healthy weight. Use proper lifting techniques. Ergonomic workstation.',
      },
    ],
    
    // Infections
    'Urinary Tract Infection': [
      {
        'name': 'Uncomplicated UTI - Female',
        'description': '1. Nitrofurantoin 100mg BID x 5 days\n2. Increased fluid intake\n3. Urinate after intercourse\n4. Cranberry products optional',
        'goals': 'Resolution of symptoms in 24-48 hours\nCure of infection',
        'instructions': 'Complete full course even if feeling better. Drink plenty of water. Take with food. Return if fever, back pain, or not improving in 48 hours.',
      },
      {
        'name': 'UTI - Alternative Regimen',
        'description': '1. Trimethoprim-Sulfamethoxazole DS BID x 3 days\n2. Hydration\n3. Urine culture if recurrent',
        'goals': 'Infection resolution\nPrevention of recurrence',
        'instructions': 'Take with full glass of water. Complete entire course. May cause sun sensitivity. Report rash or difficulty breathing.',
      },
    ],
    
    // Allergies
    'Allergic Rhinitis': [
      {
        'name': 'Seasonal Allergic Rhinitis',
        'description': '1. Cetirizine 10mg once daily\n2. Fluticasone nasal spray 2 sprays each nostril daily\n3. Avoid allergen exposure\n4. Saline nasal irrigation',
        'goals': 'Symptom control\nImproved quality of life',
        'instructions': 'Start nasal spray before allergy season. Use antihistamine daily during season. Keep windows closed. Shower after outdoor activities.',
      },
      {
        'name': 'Perennial Allergic Rhinitis',
        'description': '1. Intranasal corticosteroid daily\n2. Second-gen antihistamine\n3. Allergen avoidance measures\n4. Consider allergy testing/immunotherapy',
        'goals': 'Year-round symptom control\nIdentify specific allergens',
        'instructions': 'Use nasal spray consistently. Dust mite covers for bedding. HEPA filters. Consider allergy specialist referral.',
      },
    ],
    
    // Musculoskeletal
    'Osteoarthritis': [
      {
        'name': 'OA - Conservative Management',
        'description': '1. Paracetamol 1g QID (max 4g/day)\n2. Topical NSAIDs to affected joints\n3. Physical therapy\n4. Weight loss if overweight\n5. Low-impact exercise',
        'goals': 'Pain reduction\nMaintain joint function\nDelay disease progression',
        'instructions': 'Regular paracetamol more effective than PRN. Apply topical gel 3-4 times daily. Exercise in water if joint pain. Lose weight to reduce joint stress.',
      },
      {
        'name': 'OA - Step-up Therapy',
        'description': '1. Add oral NSAID: Naproxen 500mg BID with food\n2. Consider PPI for GI protection\n3. Intra-articular injection if severe\n4. Orthopedic referral if failing conservative',
        'goals': 'Improved pain control\nMaintain mobility',
        'instructions': 'Take NSAIDs with food. Report GI symptoms. Continue exercises. Joint injections available for severe cases.',
      },
    ],
    
    // Thyroid
    'Hypothyroidism': [
      {
        'name': 'Hypothyroidism - Levothyroxine',
        'description': '1. Start Levothyroxine 50mcg daily (25mcg if elderly/cardiac)\n2. Take on empty stomach, 30-60 min before breakfast\n3. Recheck TSH in 6-8 weeks\n4. Titrate by 25mcg increments',
        'goals': 'Normalize TSH (0.5-4.0 mIU/L)\nResolve symptoms',
        'instructions': 'Take on empty stomach with water. Wait 4 hours before calcium or iron supplements. Same brand preferred. Annual monitoring once stable.',
      },
    ],
    
    // Lipids
    'Hyperlipidemia': [
      {
        'name': 'Dyslipidemia - Statin Therapy',
        'description': '1. Atorvastatin 20mg at bedtime\n2. Low cholesterol diet\n3. Regular exercise\n4. Recheck lipids in 6-8 weeks',
        'goals': 'LDL <100 mg/dL (or <70 if high risk)\nReduce cardiovascular risk',
        'instructions': 'Take at bedtime for best effect. Report muscle pain or weakness. Limit alcohol. Follow heart-healthy diet. Regular exercise.',
      },
    ],
  };
  
  // Get templates for selected diagnosis
  List<Map<String, String>> _getTemplatesForDiagnosis(String diagnosis) {
    // Try exact match first
    if (_treatmentTemplates.containsKey(diagnosis)) {
      return _treatmentTemplates[diagnosis]!;
    }
    
    // Try partial match
    final lowerDiag = diagnosis.toLowerCase();
    for (final entry in _treatmentTemplates.entries) {
      if (lowerDiag.contains(entry.key.toLowerCase()) || 
          entry.key.toLowerCase().contains(lowerDiag)) {
        return entry.value;
      }
    }
    
    // Check for keywords
    if (lowerDiag.contains('hypertension') || lowerDiag.contains('high blood pressure') || lowerDiag.contains('htn')) {
      return _treatmentTemplates['Hypertension']!;
    }
    if (lowerDiag.contains('diabetes') || lowerDiag.contains('dm') || lowerDiag.contains('sugar')) {
      return _treatmentTemplates['Type 2 Diabetes']!;
    }
    if (lowerDiag.contains('asthma') || lowerDiag.contains('wheez')) {
      return _treatmentTemplates['Asthma']!;
    }
    if (lowerDiag.contains('depress')) {
      return _treatmentTemplates['Depression']!;
    }
    if (lowerDiag.contains('anxiety') || lowerDiag.contains('gad')) {
      return _treatmentTemplates['Anxiety Disorder']!;
    }
    if (lowerDiag.contains('gerd') || lowerDiag.contains('reflux') || lowerDiag.contains('heartburn')) {
      return _treatmentTemplates['Gastroesophageal Reflux Disease']!;
    }
    if (lowerDiag.contains('migraine') || lowerDiag.contains('headache')) {
      return _treatmentTemplates['Migraine']!;
    }
    if (lowerDiag.contains('back pain') || lowerDiag.contains('lbp')) {
      return _treatmentTemplates['Low Back Pain']!;
    }
    if (lowerDiag.contains('uti') || lowerDiag.contains('urinary')) {
      return _treatmentTemplates['Urinary Tract Infection']!;
    }
    if (lowerDiag.contains('urti') || lowerDiag.contains('cold') || lowerDiag.contains('flu')) {
      return _treatmentTemplates['Upper Respiratory Tract Infection']!;
    }
    if (lowerDiag.contains('allerg') || lowerDiag.contains('rhinitis')) {
      return _treatmentTemplates['Allergic Rhinitis']!;
    }
    if (lowerDiag.contains('arthritis') || lowerDiag.contains('oa')) {
      return _treatmentTemplates['Osteoarthritis']!;
    }
    if (lowerDiag.contains('thyroid') || lowerDiag.contains('hypothyroid')) {
      return _treatmentTemplates['Hypothyroidism']!;
    }
    if (lowerDiag.contains('cholesterol') || lowerDiag.contains('lipid')) {
      return _treatmentTemplates['Hyperlipidemia']!;
    }
    
    return [];
  }
  
  void _applyTemplate(Map<String, String> template) {
    setState(() {
      _descriptionController.text = template['description'] ?? '';
      _goalsController.text = template['goals'] ?? '';
      _instructionsController.text = template['instructions'] ?? '';
    });
  }
  
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
    final templates = _selectedDiagnosis.isNotEmpty 
        ? _getTemplatesForDiagnosis(_selectedDiagnosis)
        : <Map<String, String>>[];
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
              padding: EdgeInsets.all(context.responsivePadding),
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
                padding: EdgeInsets.all(context.responsivePadding),
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
                        isExpanded: true,
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
                          child: Text(
                            d,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )).toList(),
                        onChanged: (value) {
                          setState(() => _selectedDiagnosis = value ?? '');
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Quick Templates Section
                    if (templates.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.flash_on_rounded,
                            size: 18,
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Templates',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: templates.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final template = templates[index];
                            return ActionChip(
                              avatar: Icon(
                                Icons.content_paste_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              label: Text(
                                template['name'] ?? 'Template ${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.grey.shade800,
                                ),
                              ),
                              backgroundColor: isDark 
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                              onPressed: () => _applyTemplate(template),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else if (_selectedDiagnosis.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.grey.shade800.withValues(alpha: 0.5)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No templates available for "$_selectedDiagnosis". Enter custom plan below.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Treatment Description (main content)
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Treatment Plan*',
                        hintText: 'e.g., Start Amlodipine 5mg daily, lifestyle modifications...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
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
                        alignLabelWithHint: true,
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
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Save button
            Padding(
              padding: EdgeInsets.all(context.responsivePadding),
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
            padding: EdgeInsets.all(context.responsivePadding),
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
              padding: EdgeInsets.all(context.responsivePadding),
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
                      padding: EdgeInsets.all(context.responsivePadding),
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
            padding: EdgeInsets.all(context.responsivePadding),
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

/// Modal for entering chief complaint
class _ChiefComplaintModal extends StatefulWidget {
  final String chiefComplaint;
  final String historyOfPresentIllness;
  
  const _ChiefComplaintModal({
    required this.chiefComplaint,
    required this.historyOfPresentIllness,
  });
  
  @override
  State<_ChiefComplaintModal> createState() => _ChiefComplaintModalState();
}

class _ChiefComplaintModalState extends State<_ChiefComplaintModal> {
  late TextEditingController _complaintController;
  late TextEditingController _hpiController;
  
  @override
  void initState() {
    super.initState();
    _complaintController = TextEditingController(text: widget.chiefComplaint);
    _hpiController = TextEditingController(text: widget.historyOfPresentIllness);
  }
  
  @override
  void dispose() {
    _complaintController.dispose();
    _hpiController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.speaker_notes_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chief Complaint',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Patient\'s main concern',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chief Complaint *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _complaintController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Fever and cough for 3 days',
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    'History of Present Illness (HPI)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hpiController,
                    decoration: InputDecoration(
                      hintText: 'Detailed history of the current illness...',
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 5,
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Save Button
          Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'chiefComplaint': _complaintController.text,
                    'hpi': _hpiController.text,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Chief Complaint',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

/// Modal for ordering lab tests
class _LabOrderModal extends StatefulWidget {
  final int patientId;
  final List<Map<String, dynamic>> existingOrders;
  final String? diagnosis;
  
  const _LabOrderModal({
    required this.patientId,
    required this.existingOrders,
    this.diagnosis,
  });
  
  @override
  State<_LabOrderModal> createState() => _LabOrderModalState();
}

class _LabOrderModalState extends State<_LabOrderModal> {
  late List<Map<String, dynamic>> _orders;
  final _testController = TextEditingController();
  
  final List<Map<String, dynamic>> _commonTests = [
    {'name': 'CBC (Complete Blood Count)', 'code': 'CBC', 'category': 'Hematology'},
    {'name': 'LFT (Liver Function Test)', 'code': 'LFT', 'category': 'Biochemistry'},
    {'name': 'RFT (Renal Function Test)', 'code': 'RFT', 'category': 'Biochemistry'},
    {'name': 'Lipid Profile', 'code': 'LIPID', 'category': 'Biochemistry'},
    {'name': 'Thyroid Profile (T3, T4, TSH)', 'code': 'THYROID', 'category': 'Hormones'},
    {'name': 'HbA1c', 'code': 'HBA1C', 'category': 'Diabetes'},
    {'name': 'Fasting Blood Sugar', 'code': 'FBS', 'category': 'Diabetes'},
    {'name': 'Random Blood Sugar', 'code': 'RBS', 'category': 'Diabetes'},
    {'name': 'Urine Routine', 'code': 'URINE', 'category': 'Urinalysis'},
    {'name': 'Chest X-Ray', 'code': 'CXR', 'category': 'Radiology'},
    {'name': 'ECG', 'code': 'ECG', 'category': 'Cardiology'},
    {'name': 'Ultrasound Abdomen', 'code': 'USG', 'category': 'Radiology'},
    {'name': 'Serum Electrolytes', 'code': 'LYTES', 'category': 'Biochemistry'},
    {'name': 'PT/INR', 'code': 'PT', 'category': 'Coagulation'},
    {'name': 'ESR', 'code': 'ESR', 'category': 'Hematology'},
    {'name': 'CRP', 'code': 'CRP', 'category': 'Inflammation'},
  ];
  
  @override
  void initState() {
    super.initState();
    _orders = List.from(widget.existingOrders);
  }
  
  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.science_rounded,
                    color: const Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lab Orders',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${_orders.length} test(s) selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Selected Orders
          if (_orders.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _orders.map((order) => Chip(
                  label: Text((order['name'] as String?) ?? 'Test'),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _orders.removeWhere((o) => o['code'] == order['code']);
                    });
                  },
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                )).toList(),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Common Tests
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
              children: [
                Text(
                  'Common Tests',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ..._commonTests.map((test) => CheckboxListTile(
                  title: Text(
                    test['name'] as String,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    test['category'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  value: _orders.any((o) => o['code'] == test['code']),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        if (!_orders.any((o) => o['code'] == test['code'])) {
                          _orders.add(test);
                        }
                      } else {
                        _orders.removeWhere((o) => o['code'] == test['code']);
                      }
                    });
                  },
                  activeColor: const Color(0xFF8B5CF6),
                  contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
          ),
          
          // Save Button
          Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _orders),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Order ${_orders.length} Test${_orders.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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

/// Modal for clinical notes (SOAP)
class _ClinicalNotesModal extends StatefulWidget {
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;
  final String chiefComplaint;
  final List<String> diagnoses;
  
  const _ClinicalNotesModal({
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
    required this.chiefComplaint,
    required this.diagnoses,
  });
  
  @override
  State<_ClinicalNotesModal> createState() => _ClinicalNotesModalState();
}

class _ClinicalNotesModalState extends State<_ClinicalNotesModal> {
  late TextEditingController _subjectiveController;
  late TextEditingController _objectiveController;
  late TextEditingController _assessmentController;
  late TextEditingController _planController;
  
  @override
  void initState() {
    super.initState();
    _subjectiveController = TextEditingController(text: widget.subjective);
    _objectiveController = TextEditingController(text: widget.objective);
    _assessmentController = TextEditingController(text: widget.assessment);
    _planController = TextEditingController(text: widget.plan);
  }
  
  @override
  void dispose() {
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.note_alt_rounded,
                    color: const Color(0xFF06B6D4),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'SOAP Notes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSOAPSection(
                    'S - Subjective',
                    'Patient\'s symptoms, complaints, and history',
                    _subjectiveController,
                    isDark,
                    Colors.orange,
                  ),
                  _buildSOAPSection(
                    'O - Objective',
                    'Physical examination findings, vitals, test results',
                    _objectiveController,
                    isDark,
                    Colors.blue,
                  ),
                  _buildSOAPSection(
                    'A - Assessment',
                    'Diagnosis and clinical impression',
                    _assessmentController,
                    isDark,
                    Colors.green,
                  ),
                  _buildSOAPSection(
                    'P - Plan',
                    'Treatment plan, medications, follow-up',
                    _planController,
                    isDark,
                    Colors.purple,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Save Button
          Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'subjective': _subjectiveController.text,
                    'objective': _objectiveController.text,
                    'assessment': _assessmentController.text,
                    'plan': _planController.text,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Clinical Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSOAPSection(
    String title,
    String hint,
    TextEditingController controller,
    bool isDark,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: color.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color),
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

// Walk-In Reason Picker Modal
class _WalkInReasonPicker extends StatefulWidget {
  final String patientName;
  
  const _WalkInReasonPicker({required this.patientName});
  
  @override
  State<_WalkInReasonPicker> createState() => _WalkInReasonPickerState();
}

class _WalkInReasonPickerState extends State<_WalkInReasonPicker> {
  final _reasonController = TextEditingController();
  String? _selectedReason;
  
  final _commonReasons = [
    'General Consultation',
    'Fever / Cold / Cough',
    'Follow-up Visit',
    'Prescription Refill',
    'Pain / Body Ache',
    'Stomach Issues',
    'Skin Problem',
    'Injury / Wound',
    'Blood Pressure Check',
    'Sugar Level Check',
    'Lab Report Review',
    'Vaccination',
    'Health Certificate',
    'Emergency',
  ];
  
  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Walk-In Appointment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'For ${widget.patientName}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'What brings you here today?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Common reasons
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                height: 200,
                padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: context.responsive(
                      compact: 2,
                      medium: 3,
                      expanded: 4,
                    ),
                    mainAxisSpacing: context.responsiveItemSpacing,
                    crossAxisSpacing: context.responsiveItemSpacing,
                    childAspectRatio: context.responsive(
                      compact: 3.0,
                      medium: 3.2,
                      expanded: 3.5,
                    ),
                  ),
                  itemCount: _commonReasons.length,
              itemBuilder: (context, index) {
                final reason = _commonReasons[index];
                final isSelected = _selectedReason == reason;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                      _reasonController.text = reason;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF10B981)
                            : isDark ? Colors.white12 : Colors.grey[300]!,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        reason,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected 
                              ? const Color(0xFF10B981)
                              : isDark ? Colors.white70 : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
                ),
              );
            },
          ),
          
          // Custom reason input
          Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Or type custom reason...',
                prefixIcon: const Icon(Icons.edit_note, size: 20),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() => _selectedReason = null);
                }
              },
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final reason = _reasonController.text.trim().isNotEmpty 
                          ? _reasonController.text.trim()
                          : _selectedReason ?? 'General Consultation';
                      Navigator.pop(context, reason);
                    },
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('Start Consultation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}