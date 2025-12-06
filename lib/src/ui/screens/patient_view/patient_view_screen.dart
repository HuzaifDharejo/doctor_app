// Optimized Patient View Screen - Modular Architecture
// This file imports separate tab components for better maintainability

import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/audit_provider.dart';
import '../../../providers/db_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/whatsapp_service.dart';
import '../../../core/components/app_button.dart';
import '../../../core/mixins/responsive_mixin.dart';
import '../../../theme/app_theme.dart';
import '../add_appointment_screen.dart';
import '../add_invoice_screen.dart';
import '../add_patient_screen.dart';
import '../add_prescription_screen.dart';
import '../diagnoses_screen.dart';
import '../follow_ups_screen.dart';
import '../lab_results_screen.dart';
import '../treatment_outcomes_screen.dart';
import '../treatment_progress_screen.dart';
import '../vital_signs_screen.dart';
import '../records/records.dart';

// Import modular tab components
import 'patient_prescriptions_tab.dart';
import 'patient_records_tab.dart';
import 'patient_billing_tab.dart';
import 'patient_documents_tab.dart';
import 'patient_timeline_tab.dart';
import 'patient_visits_tab.dart';
import 'patient_view_widgets.dart';

/// Alias for backward compatibility with PatientViewScreenModern
typedef PatientViewScreenModern = PatientViewScreen;

class PatientViewScreen extends ConsumerStatefulWidget {
  const PatientViewScreen({required this.patient, super.key});
  final Patient patient;

  @override
  ConsumerState<PatientViewScreen> createState() => _PatientViewScreenState();
}

class _PatientViewScreenState extends ConsumerState<PatientViewScreen>
    with SingleTickerProviderStateMixin, ResponsiveConsumerStateMixin {
  late TabController _tabController;
  
  // Editable field controllers
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _allergiesController;
  late TextEditingController _tagsController;
  
  // Track UI state
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isEditingProfile = false;
  
  // Store initial values
  late String _initialPhone;
  late String _initialEmail;
  late String _initialAddress;
  late String _initialMedicalHistory;
  late String _initialAllergies;
  late String _initialTags;
  
  // Patient clinical data (loaded async)
  VitalSign? _latestVitals;
  Appointment? _nextAppointment;
  int _totalEncounters = 0;

  @override
  void initState() {
    super.initState();
    // 7 tabs: Summary, Visits, Rx, Records, Billing, Documents, Timeline
    _tabController = TabController(length: 7, vsync: this);
    _initializeControllers();
    _loadPatientData();
    _logPatientView();
  }
  
  Future<void> _loadPatientData() async {
    final db = await ref.read(doctorDbProvider.future);
    final vitals = await db.getLatestVitalSignsForPatient(widget.patient.id);
    final appointments = await db.getAppointmentsForPatient(widget.patient.id);
    final encounters = await db.getEncountersForPatient(widget.patient.id);
    
    // Find next upcoming appointment
    final now = DateTime.now();
    final upcoming = appointments
        .where((a) => a.appointmentDateTime.isAfter(now) && a.status == 'scheduled')
        .toList()
      ..sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));
    
    if (mounted) {
      setState(() {
        _latestVitals = vitals;
        _nextAppointment = upcoming.isNotEmpty ? upcoming.first : null;
        _totalEncounters = encounters.length;
      });
    }
  }
  
  Future<void> _logPatientView() async {
    final auditService = ref.read(auditServiceProvider);
    final patient = widget.patient;
    final patientName = '${patient.firstName} ${patient.lastName ?? ''}'.trim();
    await auditService.logPatientViewed(patient.id, patientName);
  }
  
  void _initializeControllers() {
    final patient = widget.patient;
    _phoneController = TextEditingController(text: patient.phone);
    _emailController = TextEditingController(text: patient.email);
    _addressController = TextEditingController(text: patient.address);
    _medicalHistoryController = TextEditingController(text: patient.medicalHistory);
    _allergiesController = TextEditingController();
    _tagsController = TextEditingController(text: patient.tags);
    
    _initialPhone = patient.phone;
    _initialEmail = patient.email;
    _initialAddress = patient.address;
    _initialMedicalHistory = patient.medicalHistory;
    _initialAllergies = '';
    _initialTags = patient.tags;
    
    // Listen for changes
    _phoneController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
    _medicalHistoryController.addListener(_checkForChanges);
    _allergiesController.addListener(_checkForChanges);
    _tagsController.addListener(_checkForChanges);
  }
  
  void _checkForChanges() {
    final hasChanges = _phoneController.text != _initialPhone ||
        _emailController.text != _initialEmail ||
        _addressController.text != _initialAddress ||
        _medicalHistoryController.text != _initialMedicalHistory ||
        _allergiesController.text != _initialAllergies ||
        _tagsController.text != _initialTags;
    
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }
  
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    try {
      final db = await ref.read(doctorDbProvider.future);
      
      final tagsText = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .join(',');
      
      final updatedPatient = PatientsCompanion(
        id: Value(widget.patient.id),
        firstName: Value(widget.patient.firstName),
        lastName: Value(widget.patient.lastName),
        dateOfBirth: Value(widget.patient.dateOfBirth),
        phone: Value(_phoneController.text),
        email: Value(_emailController.text),
        address: Value(_addressController.text),
        medicalHistory: Value(_medicalHistoryController.text),
        tags: Value(tagsText),
        riskLevel: Value(widget.patient.riskLevel),
        createdAt: Value(widget.patient.createdAt),
      );
      
      await db.updatePatient(updatedPatient);
      
      // Log audit trail for HIPAA compliance
      final auditService = ref.read(auditServiceProvider);
      final patientName = '${widget.patient.firstName} ${widget.patient.lastName ?? ''}'.trim();
      await auditService.logPatientUpdated(
        widget.patient.id,
        patientName,
        before: {
          'phone': _initialPhone,
          'email': _initialEmail,
          'address': _initialAddress,
        },
        after: {
          'phone': _phoneController.text,
          'email': _emailController.text,
          'address': _addressController.text,
        },
      );
      
      _initialPhone = _phoneController.text;
      _initialEmail = _emailController.text;
      _initialAddress = _addressController.text;
      _initialMedicalHistory = _medicalHistoryController.text;
      _initialAllergies = _allergiesController.text;
      _initialTags = _tagsController.text;
      
      setState(() {
        _hasChanges = false;
        _isSaving = false;
        _isEditingProfile = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Patient information updated'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _discardChanges() {
    _phoneController.text = _initialPhone;
    _emailController.text = _initialEmail;
    _addressController.text = _initialAddress;
    _medicalHistoryController.text = _initialMedicalHistory;
    _allergiesController.text = _initialAllergies;
    _tagsController.text = _initialTags;
    setState(() {
      _hasChanges = false;
      _isEditingProfile = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
  
  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
  
  Color _getRiskColor(int riskLevel) {
    if (riskLevel == 0) return AppColors.riskLow;
    if (riskLevel == 1) return AppColors.riskMedium;
    return AppColors.riskHigh;
  }

  String _getRiskLabel(int riskLevel) {
    if (riskLevel == 0) return 'Low Risk';
    if (riskLevel == 1) return 'Medium Risk';
    return 'High Risk';
  }

  Color _getTagColor(String tag) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
    ];
    return colors[tag.hashCode.abs() % colors.length];
  }

  void _showOptionsMenu(BuildContext context) {
    final patient = widget.patient;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Patient'),
              onTap: () async {
                Navigator.pop(context);
                final updatedPatient = await Navigator.push<Patient>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPatientScreen(patient: patient),
                  ),
                );
                if (updatedPatient != null && mounted) {
                  // Refresh the screen with updated patient data
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientViewScreen(patient: updatedPatient),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Export Summary PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportPatientSummaryPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Call Patient'),
              onTap: () {
                Navigator.pop(context);
                if (patient.phone.isNotEmpty) {
                  _callPatient(patient.phone);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No phone number available'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send Email'),
              onTap: () {
                Navigator.pop(context);
                if (patient.email.isNotEmpty) {
                  _sendEmail(patient.email, '${patient.firstName} ${patient.lastName}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No email address available'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                _sharePatientProfile(patient);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete Patient', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(patient);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callPatient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email, String patientName) async {
    final uri = Uri.parse('mailto:$email?subject=Regarding your appointment');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _sharePatientProfile(Patient patient) {
    final info = '''
Patient Profile
Name: ${patient.firstName} ${patient.lastName}
Phone: ${patient.phone}
Email: ${patient.email}
Address: ${patient.address}
''';
    Share.share(info);
  }

  Future<void> _exportPatientSummaryPdf() async {
    final patient = widget.patient;
    
    // Show loading indicator
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating PDF...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );
    
    try {
      final db = await ref.read(doctorDbProvider.future);
      final settings = ref.read(doctorSettingsProvider);
      
      // Fetch all patient data
      final appointments = await db.getAppointmentsForPatient(patient.id);
      final prescriptions = await db.getPrescriptionsForPatient(patient.id);
      final vitalSigns = await db.getVitalSignsForPatient(patient.id);
      final invoices = await db.getInvoicesForPatient(patient.id);
      
      await PdfService.sharePatientSummaryPdf(
        patient: patient,
        appointments: appointments,
        prescriptions: prescriptions,
        vitalSigns: vitalSigns,
        invoices: invoices,
        doctorName: settings.profile.name,
        clinicName: settings.profile.clinicName,
        clinicPhone: settings.profile.clinicPhone,
        clinicAddress: settings.profile.clinicAddress,
      );
      
      // Log audit trail
      final auditService = ref.read(auditServiceProvider);
      final patientName = '${patient.firstName} ${patient.lastName ?? ''}'.trim();
      await auditService.logPdfExport(patient.id, patientName, notes: 'Patient summary PDF');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generated successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete ${patient.firstName} ${patient.lastName}? This action cannot be undone.'),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton.danger(
            label: 'Delete',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final db = await ref.read(doctorDbProvider.future);
        await db.deletePatient(patient.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting patient: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _navigateToAddRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectRecordTypeScreen(
          preselectedPatient: widget.patient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riskColor = _getRiskColor(patient.riskLevel);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactScreen = screenWidth < 400;
    
    // Modern theme colors
    const primaryGradient = [Color(0xFF6366F1), Color(0xFF8B5CF6)];
    
    // Calculate dynamic height based on content needs
    final expandedHeight = isCompactScreen ? 320.0 : 360.0;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: expandedHeight,
              pinned: true,
              stretch: true,
              elevation: 0,
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              actions: [
                _buildModernActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () {
                    if (patient.phone.isNotEmpty) {
                      WhatsAppService.openChat(patient.phone);
                    }
                  },
                ),
                _buildModernActionButton(
                  icon: Icons.phone_outlined,
                  onTap: () {
                    if (patient.phone.isNotEmpty) {
                      _callPatient(patient.phone);
                    }
                  },
                ),
                _buildModernActionButton(
                  icon: Icons.more_vert_rounded,
                  onTap: () => _showOptionsMenu(context),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: primaryGradient,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGradient[0].withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: _buildModernPatientHeader(patient, riskColor, isCompactScreen),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tabs: const [
                      Tab(text: 'Summary'),
                      Tab(text: 'Visits'),
                      Tab(text: 'Rx'),
                      Tab(text: 'Records'),
                      Tab(text: 'Billing'),
                      Tab(text: 'Documents'),
                      Tab(text: 'Timeline'),
                    ],
                    labelColor: AppColors.primary,
                    unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    dividerColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Summary tab - combines overview with clinical quick-glance
            _buildSummaryTab(patient, isDark),
            // Visits - unified view combining appointments + clinical data
            PatientVisitsTab(patient: patient),
            // Prescriptions
            PatientPrescriptionsTab(patient: patient),
            // Records - medical records, labs, etc
            PatientRecordsTab(patient: patient),
            // Billing - invoices and payments
            PatientBillingTab(patient: patient),
            // Documents - uploaded documents
            PatientDocumentsTab(patient: patient),
            // Timeline - chronological view (at end)
            PatientTimelineTab(patient: patient),
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }
  
  Widget _buildSummaryTab(Patient patient, bool isDark) {
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CRITICAL ALERTS SECTION (Always First)
          _buildCriticalAlertsSection(patient, isDark),
          
          const SizedBox(height: 16),
          
          // QUICK STATS DASHBOARD
          _buildQuickStatsDashboard(isDark, textColor),
          
          const SizedBox(height: 16),
          
          // LATEST VITALS CARD
          _buildVitalsCard(cardColor, textColor, secondaryColor, isDark),
          
          const SizedBox(height: 16),
          
          // CONTACT INFO
          _buildContactCard(patient, cardColor, textColor, secondaryColor),
          
          const SizedBox(height: 16),
          
          // MEDICAL HISTORY
          if (patient.medicalHistory.isNotEmpty)
            _buildInfoCard(
              title: 'Medical History',
              content: patient.medicalHistory,
              icon: Icons.history_rounded,
              color: const Color(0xFF6366F1),
              cardColor: cardColor,
              textColor: textColor,
            ),
          
          const SizedBox(height: 16),
          
          // CLINICAL FEATURES
          _buildClinicalFeaturesSection(patient, isDark, textColor),
          
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }
  
  Widget _buildCriticalAlertsSection(Patient patient, bool isDark) {
    final hasAllergies = patient.allergies.isNotEmpty && 
        patient.allergies.toLowerCase() != 'none' &&
        patient.allergies.toLowerCase() != 'nkda' &&
        patient.allergies.toLowerCase() != 'no known allergies';
    
    final hasChronicConditions = patient.chronicConditions.isNotEmpty && 
        patient.chronicConditions.toLowerCase() != 'none';
    
    // If no alerts, show NKDA badge
    if (!hasAllergies && !hasChronicConditions) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Known Drug Allergies (NKDA)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No chronic conditions recorded',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Allergies Alert
        if (hasAllergies)
          _buildAlertCard(
            icon: Icons.warning_amber_rounded,
            title: 'ALLERGIES',
            content: patient.allergies,
            color: AppColors.error,
            isDark: isDark,
          ),
        
        // Chronic Conditions Alert
        if (hasChronicConditions)
          Padding(
            padding: EdgeInsets.only(top: hasAllergies ? 10 : 0),
            child: _buildAlertCard(
              icon: Icons.medical_information_outlined,
              title: 'CHRONIC CONDITIONS',
              content: patient.chronicConditions,
              color: AppColors.warning,
              isDark: isDark,
            ),
          ),
      ],
    );
  }
  
  Widget _buildQuickStatsDashboard(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Quick Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDashboardItem(
                  icon: Icons.event_available_rounded,
                  label: 'Next Visit',
                  value: _nextAppointment != null 
                      ? _formatDate(_nextAppointment!.appointmentDateTime)
                      : 'Not Scheduled',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDashboardItem(
                  icon: Icons.history_rounded,
                  label: 'Total Visits',
                  value: '$_totalEncounters',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboardItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVitalsCard(Color cardColor, Color textColor, Color secondaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Latest Vitals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const Spacer(),
              if (_latestVitals != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDate(_latestVitals!.recordedAt),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: secondaryColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_latestVitals == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 32,
                      color: secondaryColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No vitals recorded yet',
                      style: TextStyle(color: secondaryColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                _buildVitalItem(
                  'BP', 
                  '${_latestVitals!.systolicBp?.toInt() ?? '--'}/${_latestVitals!.diastolicBp?.toInt() ?? '--'}', 
                  'mmHg', 
                  const Color(0xFFEF4444),
                  isDark,
                ),
                _buildVitalItem(
                  'HR', 
                  '${_latestVitals!.heartRate ?? '--'}', 
                  'bpm', 
                  const Color(0xFFEC4899),
                  isDark,
                ),
                _buildVitalItem(
                  'Temp', 
                  '${_latestVitals!.temperature?.toStringAsFixed(1) ?? '--'}', 
                  '°C', 
                  const Color(0xFFF59E0B),
                  isDark,
                ),
                _buildVitalItem(
                  'SpO₂', 
                  '${_latestVitals!.oxygenSaturation?.toInt() ?? '--'}', 
                  '%', 
                  const Color(0xFF3B82F6),
                  isDark,
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildVitalItem(String label, String value, String unit, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label, 
              style: TextStyle(
                fontSize: 10, 
                color: color, 
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value, 
              style: TextStyle(
                fontSize: 17, 
                fontWeight: FontWeight.w800, 
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            Text(
              unit, 
              style: TextStyle(
                fontSize: 10, 
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactCard(Patient patient, Color cardColor, Color textColor, Color secondaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.contact_phone_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (patient.phone.isNotEmpty)
            _buildContactRow(
              Icons.phone_rounded, 
              patient.phone, 
              const Color(0xFF10B981), 
              textColor, 
              () => _callPatient(patient.phone),
              isDark,
            ),
          if (patient.email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildContactRow(
                Icons.email_rounded, 
                patient.email, 
                const Color(0xFF3B82F6), 
                textColor, 
                () => _sendEmail(patient.email, patient.firstName),
                isDark,
              ),
            ),
          if (patient.address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildContactRow(
                Icons.location_on_rounded, 
                patient.address, 
                const Color(0xFF8B5CF6), 
                textColor, 
                null,
                isDark,
              ),
            ),
          if (patient.emergencyContactName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildContactRow(
                Icons.emergency_rounded, 
                '${patient.emergencyContactName} (${patient.emergencyContactPhone})', 
                const Color(0xFFEF4444), 
                textColor, 
                null,
                isDark,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildContactRow(IconData icon, String value, Color iconColor, Color textColor, VoidCallback? onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value, 
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: iconColor),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), 
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                title, 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w700, 
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content, 
              style: TextStyle(
                fontSize: 14, 
                color: textColor, 
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildClinicalFeaturesSection(Patient patient, bool isDark, Color textColor) {
    final patientName = '${patient.firstName} ${patient.lastName}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Clinical Features',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.monitor_heart_rounded,
                title: 'Vital Signs',
                subtitle: 'Track vitals',
                color: Colors.red,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VitalSignsScreen(
                      patientId: patient.id,
                      patientName: patientName,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                icon: Icons.medical_services_rounded,
                title: 'Treatments',
                subtitle: 'Track outcomes',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreatmentOutcomesScreen(
                      patientId: patient.id,
                      patientName: patientName,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.event_repeat_rounded,
                title: 'Follow-ups',
                subtitle: 'Manage follow-ups',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FollowUpsScreen(
                      patientId: patient.id,
                      patientName: patientName,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                icon: Icons.science_rounded,
                title: 'Lab Results',
                subtitle: 'View lab tests',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LabResultsScreen(
                      patientId: patient.id,
                      patientName: patientName,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.medical_information_rounded,
                title: 'Diagnoses',
                subtitle: 'View all diagnoses',
                color: Colors.indigo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiagnosesScreen(
                      patientId: patient.id,
                      patientName: patientName,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                icon: Icons.trending_up_rounded,
                title: 'Treatment Progress',
                subtitle: 'Sessions & goals',
                color: const Color(0xFF8B5CF6),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreatmentProgressScreen(
                      patientId: patient.id,
                      patientName: patientName,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays == -1) return 'Yesterday';
    if (diff.inDays > 0 && diff.inDays < 7) return 'In ${diff.inDays} days';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildModernPatientHeader(Patient patient, Color riskColor, bool isCompactScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final age = patient.dateOfBirth != null ? _calculateAge(patient.dateOfBirth!) : null;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompactScreen ? 16 : 24,
        isCompactScreen ? 56 : 60,
        isCompactScreen ? 16 : 24,
        72,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Patient Icon with Risk Indicator
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: isCompactScreen ? 72 : 84,
                height: isCompactScreen ? 72 : 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: isCompactScreen ? 36 : 42,
                    color: Colors.white,
                  ),
                ),
              ),
              // Risk badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: riskColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: riskColor.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    patient.riskLevel == 0
                        ? Icons.check_rounded
                        : (patient.riskLevel == 1 ? Icons.warning_amber_rounded : Icons.priority_high_rounded),
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Patient Name
          Text(
            '${patient.firstName} ${patient.lastName}'.trim(),
            style: TextStyle(
              fontSize: isCompactScreen ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Patient Info Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Patient ID
                _buildInfoBadge(
                  icon: Icons.tag_rounded,
                  text: 'P-${patient.id.toString().padLeft(4, '0')}',
                ),
                if (age != null) ...[
                  _buildDividerDot(),
                  _buildInfoBadge(
                    icon: Icons.cake_outlined,
                    text: '$age yrs',
                  ),
                ],
                if (patient.gender != null && patient.gender!.isNotEmpty) ...[
                  _buildDividerDot(),
                  _buildInfoBadge(
                    icon: patient.gender?.toLowerCase() == 'male' 
                        ? Icons.male_rounded 
                        : patient.gender?.toLowerCase() == 'female'
                            ? Icons.female_rounded
                            : Icons.person_outline_rounded,
                    text: patient.gender!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // Risk Level & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: riskColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      patient.riskLevel == 0 
                          ? Icons.verified_rounded 
                          : patient.riskLevel == 1 
                              ? Icons.warning_amber_rounded 
                              : Icons.error_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getRiskLabel(patient.riskLevel),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (patient.tags.isNotEmpty) ...[
                const SizedBox(width: 8),
                ...patient.tags
                    .split(',')
                    .where((t) => t.trim().isNotEmpty)
                    .take(2)
                    .map((tag) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag.trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoBadge({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDividerDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
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

  Widget _buildModernFAB() {
    return FloatingActionButton.extended(
      heroTag: 'patient_actions',
      onPressed: _showQuickActionsSheet,
      tooltip: 'Quick Actions',
      backgroundColor: Colors.transparent,
      elevation: 0,
      extendedPadding: EdgeInsets.zero,
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text(
              'New Action',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Title with icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'What would you like to do?',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // Actions Grid - Row 1
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.event_note_rounded,
                        label: 'Schedule\nAppointment',
                        color: AppColors.primary,
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAppointmentScreen(
                                preselectedPatient: widget.patient,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.medication_rounded,
                        label: 'Write\nPrescription',
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddPrescriptionScreen(
                                preselectedPatient: widget.patient,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Actions Grid - Row 2
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.note_add_rounded,
                        label: 'Add\nRecord',
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToAddRecord();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'Create\nInvoice',
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddInvoiceScreen(
                                patientId: widget.patient.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Actions Grid - Row 3
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.monitor_heart_rounded,
                        label: 'Record\nVitals',
                        color: const Color(0xFFEC4899),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VitalSignsScreen(
                                patientId: widget.patient.id,
                                patientName: '${widget.patient.firstName} ${widget.patient.lastName}',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.event_repeat_rounded,
                        label: 'Schedule\nFollow-up',
                        color: const Color(0xFF06B6D4),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowUpsScreen(
                                patientId: widget.patient.id,
                                patientName: '${widget.patient.firstName} ${widget.patient.lastName}',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
