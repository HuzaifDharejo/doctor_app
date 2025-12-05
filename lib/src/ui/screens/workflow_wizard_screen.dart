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
  Prescription? _prescription;
  ScheduledFollowUp? _followUp;
  Invoice? _invoice;
  
  // Step completion status
  final Map<int, bool> _completedSteps = {};
  
  // Optional steps
  bool _skipVitals = false;
  bool _skipMedicalRecord = false;
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
      title: 'Add Medical Record',
      subtitle: 'Diagnosis and findings',
      icon: Icons.medical_information_rounded,
      color: const Color(0xFF10B981),
      isRequired: false,
    ),
    _WorkflowStep(
      title: 'Create Prescription',
      subtitle: 'Medications and instructions',
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
      case 3: return _skipVitals;
      case 4: return _skipMedicalRecord;
      case 5: return _skipPrescription;
      case 6: return _skipFollowUp;
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
        title: const Text('Patient Workflow'),
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
        return _buildMedicalRecordStep(isDark);
      case 5:
        return _buildPrescriptionStep(isDark);
      case 6:
        return _buildFollowUpStep(isDark);
      case 7:
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
              'Encounter #${_encounter!.id}',
              'Status: ${_encounter!.status}',
              'Started: ${DateFormat('h:mm a').format(checkInTime)}',
              if (_encounter!.chiefComplaint.isNotEmpty) 
                'Chief Complaint: ${_encounter!.chiefComplaint}',
            ],
          ),
          const SizedBox(height: 16),
          // Open full encounter screen
          _buildActionCard(
            isDark: isDark,
            title: 'Open Encounter Workstation',
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

  // Step 5: Medical Record
  Widget _buildMedicalRecordStep(bool isDark) {
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'Skip Medical Record',
          value: _skipMedicalRecord,
          onChanged: (value) => setState(() {
            _skipMedicalRecord = value;
            if (value) _completedSteps[4] = true;
          }),
        ),
        const SizedBox(height: 16),
        
        if (!_skipMedicalRecord) ...[
          if (_medicalRecord != null)
            _buildCompletedCard(
              isDark: isDark,
              title: _medicalRecord!.recordType,
              subtitle: 'Medical record added',
              icon: Icons.medical_information_rounded,
              color: const Color(0xFF10B981),
              onEdit: () => _addMedicalRecord(),
              details: [
                'Date: ${DateFormat('MMM d, yyyy').format(_medicalRecord!.recordDate)}',
              ],
            )
          else
            _buildActionCard(
              isDark: isDark,
              title: 'Add Medical Record',
              subtitle: 'Document diagnosis and findings',
              icon: Icons.medical_information_rounded,
              color: const Color(0xFF10B981),
              onTap: () => _addMedicalRecord(),
            ),
        ],
      ],
    );
  }

  // Step 6: Prescription
  Widget _buildPrescriptionStep(bool isDark) {
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'Skip Prescription',
          value: _skipPrescription,
          onChanged: (value) => setState(() {
            _skipPrescription = value;
            if (value) _completedSteps[5] = true;
          }),
        ),
        const SizedBox(height: 16),
        
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

  // Step 7: Follow-Up
  Widget _buildFollowUpStep(bool isDark) {
    return Column(
      children: [
        _buildSkipOption(
          isDark: isDark,
          title: 'No Follow-Up Needed',
          value: _skipFollowUp,
          onChanged: (value) => setState(() {
            _skipFollowUp = value;
            if (value) _completedSteps[6] = true;
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

  // Step 8: Invoice
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
    if (_medicalRecord != null) items.add('Record: ${_medicalRecord!.recordType}');
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
                Text(
                  item,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 13,
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
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
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
        builder: (_) => SelectRecordTypeScreen(preselectedPatient: _patient),
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
        _completedSteps[4] = true;
      });
    } else {
      log.d('WORKFLOW', 'Medical record creation cancelled');
    }
  }

  Future<void> _createPrescription() async {
    if (_patient == null) {
      log.w('WORKFLOW', 'Cannot create prescription - no patient selected');
      return;
    }
    
    log.d('WORKFLOW', 'Opening prescription form');
    final result = await Navigator.push<Prescription>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPrescriptionScreen(preselectedPatient: _patient),
      ),
    );
    
    if (result != null && mounted) {
      log.i('WORKFLOW', 'Prescription created', extra: {
        'prescriptionId': result.id,
        'patientId': result.patientId,
      });
      setState(() {
        _prescription = result;
        _completedSteps[5] = true;
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
    final result = await Navigator.push<ScheduledFollowUp>(
      context,
      MaterialPageRoute(
        builder: (_) => AddFollowUpScreen(preselectedPatient: _patient),
      ),
    );
    
    if (result != null && mounted) {
      log.i('WORKFLOW', 'Follow-up scheduled', extra: {
        'patientId': _patient!.id,
      });
      setState(() {
        _followUp = result;
        _completedSteps[6] = true;
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
        _completedSteps[7] = true;
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
                    _buildSummaryRow(Icons.medical_services_rounded, 'Encounter #${encounter!.id} completed'),
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
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
