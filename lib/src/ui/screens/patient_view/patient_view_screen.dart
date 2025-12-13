// Optimized Patient View Screen - Modular Architecture
// This file imports separate tab components for better maintainability

import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/routing/app_router.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/audit_provider.dart';
import '../../../providers/db_provider.dart';
import '../../../services/pdf_service.dart';
import '../../../services/whatsapp_service.dart';
import '../../../services/family_history_service.dart';
import '../../../services/problem_list_service.dart';
import '../../../services/immunization_service.dart';
import '../../../core/components/app_button.dart';
import '../../../core/mixins/responsive_mixin.dart';
import '../../../theme/app_theme.dart';
import '../add_appointment_screen.dart';
import '../add_invoice_screen.dart';
import '../add_patient_screen.dart';
import '../add_prescription_screen.dart';
import '../diagnoses_screen.dart';
import '../follow_ups_screen.dart';
import '../lab_orders_screen.dart';
import '../treatment_progress_screen.dart';
import '../vital_signs_screen.dart';
import '../workflow_wizard_screen.dart';
import '../allergy_management_screen.dart';
import '../family_history_screen.dart';
import '../problem_list_screen.dart';
import '../immunizations_screen.dart';
import '../records/records.dart';

// Import modular tab components
import 'patient_clinical_tab.dart';
import 'patient_billing_tab.dart';
import 'patient_timeline_tab.dart';
import 'patient_visits_tab.dart';
import 'patient_view_widgets.dart';
import 'widgets/patient_view_widgets.dart' as widgets;

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
  int _dataRefreshKey = 0; // Used to force refresh of child tabs
  
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
  
  // Clinical features data counts
  int _familyHistoryCount = 0;
  int _problemListCount = 0;
  int _immunizationCount = 0;
  List<ProblemListData> _activeProblems = [];
  List<FamilyMedicalHistoryData> _recentFamilyHistory = [];
  
  // Enhanced UI data
  int _activePrescriptionCount = 0;
  int _upcomingAppointmentCount = 0;
  int _unpaidInvoiceCount = 0;
  int _clinicalRecordsCount = 0;
  int _timelineEventsCount = 0;
  List<VitalSign> _recentVitals = [];
  List<widgets.ActivityItem> _recentActivities = [];
  DateTime? _lastVisitDate;

  @override
  void initState() {
    super.initState();
    // 5 tabs: Summary, Visits, Clinical (Rx+Records+Docs), Billing, Timeline
    _tabController = TabController(length: 5, vsync: this);
    _initializeControllers();
    _loadPatientData();
    _logPatientView();
  }
  
  Future<void> _loadPatientData() async {
    final db = await ref.read(doctorDbProvider.future);
    final vitals = await db.getLatestVitalSignsForPatient(widget.patient.id);
    final appointments = await db.getAppointmentsForPatient(widget.patient.id);
    final encounters = await db.getEncountersForPatient(widget.patient.id);
    
    // Load clinical features data
    final familyHistoryService = FamilyHistoryService(db: db);
    final problemListService = ProblemListService(db: db);
    final immunizationService = ImmunizationService(db: db);
    
    final familyHistory = await familyHistoryService.getFamilyHistoryForPatient(widget.patient.id);
    final problems = await problemListService.getProblemsForPatient(widget.patient.id);
    final activeProblems = await problemListService.getActiveProblems(widget.patient.id);
    final immunizations = await immunizationService.getImmunizationsForPatient(widget.patient.id);
    
    // Load enhanced UI data
    final prescriptions = await db.getPrescriptionsForPatient(widget.patient.id);
    // Prescriptions are considered active if created within 30 days
    final activePrescriptions = prescriptions.where((p) => 
        DateTime.now().difference(p.createdAt).inDays <= 30).toList();
    final invoices = await db.getInvoicesForPatient(widget.patient.id);
    final unpaidInvoices = invoices.where((i) => i.paymentStatus != 'paid').toList();
    final medicalRecords = await db.getMedicalRecordsForPatient(widget.patient.id);
    final allVitals = await db.getVitalSignsForPatient(widget.patient.id);
    
    // Find next upcoming appointment
    final now = DateTime.now();
    final upcoming = appointments
        .where((a) => a.appointmentDateTime.isAfter(now) && a.status == 'scheduled')
        .toList()
      ..sort((a, b) => a.appointmentDateTime.compareTo(b.appointmentDateTime));
    
    // Get last visit date from encounters
    DateTime? lastVisit;
    if (encounters.isNotEmpty) {
      final sortedEncounters = List<Encounter>.from(encounters)
        ..sort((a, b) => b.encounterDate.compareTo(a.encounterDate));
      lastVisit = sortedEncounters.first.encounterDate;
    }
    
    // Build recent activities list
    final activities = <widgets.ActivityItem>[];
    
    // Add recent appointments
    for (final apt in appointments.take(2)) {
      activities.add(widgets.ActivityItem(
        type: widgets.ActivityType.appointment,
        title: apt.reason.isNotEmpty ? apt.reason : 'Appointment',
        timestamp: apt.appointmentDateTime,
        subtitle: apt.status,
      ));
    }
    
    // Add recent prescriptions
    for (final rx in prescriptions.take(2)) {
      // Parse itemsJson to get medication info
      final rxTitle = rx.diagnosis.isNotEmpty ? rx.diagnosis : 'Prescription';
      activities.add(widgets.ActivityItem(
        type: widgets.ActivityType.prescription,
        title: rxTitle,
        timestamp: rx.createdAt,
        subtitle: rx.instructions.isNotEmpty ? rx.instructions.split('\n').first : 'Medication',
      ));
    }
    
    // Add recent vitals
    if (allVitals.isNotEmpty) {
      for (final v in allVitals.take(2)) {
        activities.add(widgets.ActivityItem(
          type: widgets.ActivityType.vitalSigns,
          title: 'Vital Signs Recorded',
          timestamp: v.recordedAt,
          subtitle: 'BP: ${v.systolicBp?.toInt() ?? '--'}/${v.diastolicBp?.toInt() ?? '--'}',
        ));
      }
    }
    
    // Sort by timestamp descending
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (mounted) {
      setState(() {
        _latestVitals = vitals;
        _nextAppointment = upcoming.isNotEmpty ? upcoming.first : null;
        _totalEncounters = encounters.length;
        _familyHistoryCount = familyHistory.length;
        _problemListCount = problems.length;
        _immunizationCount = immunizations.length;
        _activeProblems = activeProblems.take(3).toList();
        _recentFamilyHistory = familyHistory.take(3).toList();
        // Enhanced UI data
        _activePrescriptionCount = activePrescriptions.length;
        _upcomingAppointmentCount = upcoming.length;
        _unpaidInvoiceCount = unpaidInvoices.length;
        _clinicalRecordsCount = medicalRecords.length + prescriptions.length;
        _timelineEventsCount = appointments.length + prescriptions.length + invoices.length + medicalRecords.length;
        _recentVitals = allVitals.take(5).toList();
        _recentActivities = activities.take(5).toList();
        _lastVisitDate = lastVisit;
      });
    }
  }
  
  /// Refresh all patient data and trigger child widget rebuilds
  void _refreshAllData() {
    _loadPatientData();
    // Increment refresh key to force child widgets to rebuild
    setState(() {
      _dataRefreshKey++;
    });
  }
  
  Future<void> _logPatientView() async {
    final db = await ref.read(doctorDbProvider.future);
    final auditService = ref.read(auditServiceProvider);
    final patient = widget.patient;
    final patientName = '${patient.firstName} ${patient.lastName ?? ''}'.trim();
    
    // Log to audit trail
    await auditService.logPatientViewed(patient.id, patientName);
    
    // Track for recent patients quick access
    await db.trackRecentPatient(patient.id, accessType: 'view');
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
        age: Value(widget.patient.age),
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
    ).then((_) => _refreshAllData());
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
              floating: true,
              snap: false,
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
                    isScrollable: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tabs: [
                      const Tab(text: 'Summary'),
                      widgets.BadgedTab(
                        text: 'Visits',
                        count: _upcomingAppointmentCount,
                        showBadge: _upcomingAppointmentCount > 0,
                      ),
                      widgets.BadgedTab(
                        text: 'Clinical',
                        count: _activePrescriptionCount,
                      ),
                      widgets.BadgedTab(
                        text: 'Billing',
                        count: _unpaidInvoiceCount,
                        showBadge: _unpaidInvoiceCount > 0,
                      ),
                      widgets.BadgedTab(
                        text: 'Timeline',
                        count: _timelineEventsCount > 9 ? 0 : _timelineEventsCount,
                        showBadge: _timelineEventsCount > 0,
                      ),
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
            // Summary tab - overview with clinical quick-glance
            _buildSummaryTab(patient, isDark),
            // Visits - unified view combining appointments + clinical data
            PatientVisitsTab(key: ValueKey('visits_$_dataRefreshKey'), patient: patient),
            // Clinical - combined Rx + Records + Documents
            PatientClinicalTab(key: ValueKey('clinical_$_dataRefreshKey'), patient: patient),
            // Billing - invoices and payments
            PatientBillingTab(key: ValueKey('billing_$_dataRefreshKey'), patient: patient),
            // Timeline - chronological view
            PatientTimelineTab(key: ValueKey('timeline_$_dataRefreshKey'), patient: patient),
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
      primary: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QUICK ACTIONS STRIP
          _buildQuickActionsStrip(patient),
          
          const SizedBox(height: 16),
          
          // CLINICAL FLAGS RIBBON
          _buildClinicalFlagsRibbon(patient),
          
          const SizedBox(height: 16),
          
          // CRITICAL ALERTS SECTION (Always First)
          _buildCriticalAlertsSection(patient, isDark),
          
          const SizedBox(height: 16),
          
          // APPOINTMENT COUNTDOWN (if next appointment exists)
          if (_nextAppointment != null)
            widgets.AppointmentCountdown(
              appointmentDateTime: _nextAppointment!.appointmentDateTime,
              appointmentType: _nextAppointment!.reason.isNotEmpty ? _nextAppointment!.reason : 'Check-up',
              onReschedule: () => _navigateToRescheduleAppointment(_nextAppointment!),
            ),
          
          if (_nextAppointment != null)
            const SizedBox(height: 16),
          
          // HEALTH SCORE AND QUICK STATS ROW
          _buildHealthScoreRow(isDark),
          
          const SizedBox(height: 16),
          
          // VITALS TREND SPARKLINES
          if (_recentVitals.isNotEmpty)
            _buildVitalsTrendSection(isDark),
          
          if (_recentVitals.isNotEmpty)
            const SizedBox(height: 16),
          
          // MEDICATION ADHERENCE
          widgets.MedicationAdherenceWidget(
            activePrescriptions: _activePrescriptionCount,
            onViewMedications: () => _tabController.animateTo(2), // Clinical tab
            onAddPrescription: () => _navigateToAddPrescription(patient),
          ),
          
          const SizedBox(height: 16),
          
          // RECENT ACTIVITY TIMELINE
          widgets.RecentActivityTimeline(
            activities: _recentActivities,
            maxItems: 4,
            onViewAll: () => _tabController.animateTo(4), // Timeline tab
          ),
          
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
          
          const SizedBox(height: 100), // Space for FAB + emergency button
        ],
      ),
    );
  }
  
  /// Build quick actions strip
  Widget _buildQuickActionsStrip(Patient patient) {
    return widgets.QuickActionStrip(
      padding: EdgeInsets.zero,
      actions: [
        widgets.QuickAction(
          icon: Icons.event_rounded,
          label: 'Schedule',
          color: const Color(0xFF3B82F6),
          onTap: () => _navigateToAddAppointment(patient),
        ),
        widgets.QuickAction(
          icon: Icons.medication_rounded,
          label: 'Prescribe',
          color: const Color(0xFF8B5CF6),
          onTap: () => _navigateToAddPrescription(patient),
        ),
        widgets.QuickAction(
          icon: Icons.science_rounded,
          label: 'Lab Order',
          color: const Color(0xFFF59E0B),
          onTap: () => Navigator.push(
            context,
            AppRouter.route(LabOrdersScreen(patientId: patient.id)),
          ).then((_) => _refreshAllData()),
        ),
        widgets.QuickAction(
          icon: Icons.description_rounded,
          label: 'Record',
          color: const Color(0xFF10B981),
          onTap: () => _navigateToAddRecord(),
        ),
        widgets.QuickAction(
          icon: Icons.receipt_long_rounded,
          label: 'Invoice',
          color: const Color(0xFF6366F1),
          onTap: () => Navigator.push(
            context,
            AppRouter.route(AddInvoiceScreen(preselectedPatient: patient)),
          ).then((_) => _refreshAllData()),
        ),
      ],
    );
  }
  
  /// Build clinical flags ribbon
  Widget _buildClinicalFlagsRibbon(Patient patient) {
    final flags = <widgets.ClinicalFlag>[];
    
    // Check for allergies
    if (patient.allergies.isNotEmpty && 
        patient.allergies.toLowerCase() != 'none' &&
        patient.allergies.toLowerCase() != 'nkda') {
      flags.add(widgets.ClinicalFlag(
        type: widgets.ClinicalFlagType.allergy,
        label: 'Allergy',
        details: patient.allergies.split(',').first.trim(),
        severity: widgets.FlagSeverity.critical,
        onTap: () => Navigator.push(
          context,
          AppRouter.route(AllergyManagementScreen(patientId: patient.id)),
        ),
      ));
    }
    
    // Check for overdue immunizations
    if (_immunizationCount == 0) {
      flags.add(widgets.ClinicalFlag(
        type: widgets.ClinicalFlagType.overdueImmunization,
        label: 'Immunization',
        details: 'Check Due',
        severity: widgets.FlagSeverity.medium,
        onTap: () => Navigator.push(
          context,
          AppRouter.route(ImmunizationsScreen(patientId: patient.id)),
        ),
      ));
    }
    
    // Check for chronic conditions
    if (patient.chronicConditions.isNotEmpty && 
        patient.chronicConditions.toLowerCase() != 'none') {
      flags.add(widgets.ClinicalFlag(
        type: widgets.ClinicalFlagType.chronicPain,
        label: 'Chronic',
        details: patient.chronicConditions.split(',').first.trim(),
        severity: widgets.FlagSeverity.high,
      ));
    }
    
    // Check risk level
    if (patient.riskLevel >= 4) {
      flags.add(widgets.ClinicalFlag(
        type: widgets.ClinicalFlagType.fallRisk,
        label: 'High Risk',
        severity: widgets.FlagSeverity.high,
      ));
    }
    
    if (flags.isEmpty) return const SizedBox.shrink();
    
    return widgets.ClinicalFlagsRibbon(flags: flags);
  }
  
  /// Build health score and stats row
  Widget _buildHealthScoreRow(bool isDark) {
    // Calculate a simple health score based on available data
    int healthScore = 70; // Base score
    
    // Adjust based on vitals
    if (_latestVitals != null) {
      healthScore += 10;
      // Check BP
      if (_latestVitals!.systolicBp != null && 
          _latestVitals!.systolicBp! >= 90 && _latestVitals!.systolicBp! <= 140) {
        healthScore += 5;
      }
    }
    
    // Adjust based on appointments
    if (_nextAppointment != null) healthScore += 5;
    
    // Adjust based on risk level
    healthScore -= (widget.patient.riskLevel * 5);
    
    // Clamp score
    healthScore = healthScore.clamp(0, 100);
    
    return Row(
      children: [
        // Compact health score
        widgets.PatientHealthScoreCompact(
          score: healthScore,
          previousScore: healthScore - 3, // Simulated previous score
        ),
        const SizedBox(width: 12),
        // Quick stats
        Expanded(child: _buildQuickStatsDashboard(isDark, isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
      ],
    );
  }
  
  /// Build vitals trend section with sparklines
  Widget _buildVitalsTrendSection(bool isDark) {
    // Extract values for sparklines
    final bpSystolic = _recentVitals
        .where((v) => v.systolicBp != null)
        .map((v) => v.systolicBp!)
        .toList();
    final heartRates = _recentVitals
        .where((v) => v.heartRate != null)
        .map((v) => v.heartRate!.toDouble())
        .toList();
    final spO2Values = _recentVitals
        .where((v) => v.oxygenSaturation != null)
        .map((v) => v.oxygenSaturation!)
        .toList();
    final temps = _recentVitals
        .where((v) => v.temperature != null)
        .map((v) => v.temperature!)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.show_chart_rounded, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'Vitals Trend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VitalSignsScreen(
                      patientId: widget.patient.id,
                      patientName: '${widget.patient.firstName} ${widget.patient.lastName}'.trim(),
                    ),
                  ),
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        widgets.VitalsTrendRow(
          bpSystolic: bpSystolic,
          bpDiastolic: [], // Can add diastolic if needed
          heartRate: heartRates,
          spO2: spO2Values,
          temperature: temps.isNotEmpty ? temps : null,
        ),
      ],
    );
  }
  
  void _navigateToAddAppointment(Patient patient) {
    Navigator.push(
      context,
      AppRouter.route(AddAppointmentScreen(preselectedPatient: patient)),
    ).then((_) => _refreshAllData());
  }
  
  void _navigateToAddPrescription(Patient patient) {
    Navigator.push(
      context,
      AppRouter.route(AddPrescriptionScreen(preselectedPatient: patient)),
    ).then((_) => _refreshAllData());
  }
  
  void _navigateToRescheduleAppointment(Appointment apt) {
    // Navigate to reschedule - for now just show the appointments tab
    _tabController.animateTo(1);
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
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
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
            overflow: TextOverflow.ellipsis,
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
  
  Widget _buildClinicalDataSummary(Patient patient, bool isDark, Color textColor, Color cardColor) {
    final patientName = '${patient.firstName} ${patient.lastName}';
    
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
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Clinical Records',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Clinical data counts row
          Row(
            children: [
              Expanded(
                child: _buildClinicalCountItem(
                  icon: Icons.list_alt_rounded,
                  label: 'Problems',
                  count: _problemListCount,
                  color: const Color(0xFFEF4444),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProblemListScreen(patientId: patient.id),
                    ),
                  ).then((_) => _loadPatientData()),
                ),
              ),
              Expanded(
                child: _buildClinicalCountItem(
                  icon: Icons.family_restroom_rounded,
                  label: 'Family Hx',
                  count: _familyHistoryCount,
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FamilyHistoryScreen(patientId: patient.id),
                    ),
                  ).then((_) => _loadPatientData()),
                ),
              ),
              Expanded(
                child: _buildClinicalCountItem(
                  icon: Icons.vaccines_rounded,
                  label: 'Vaccines',
                  count: _immunizationCount,
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImmunizationsScreen(patientId: patient.id),
                    ),
                  ).then((_) => _loadPatientData()),
                ),
              ),
            ],
          ),
          
          // Active problems preview
          if (_activeProblems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'Active Problems',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            ...(_activeProblems.map((problem) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getSeverityColor(problem.severity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      problem.problemName,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(problem.severity).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      problem.severity,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getSeverityColor(problem.severity),
                      ),
                    ),
                  ),
                ],
              ),
            ))),
          ],
        ],
      ),
    );
  }
  
  Widget _buildClinicalCountItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return const Color(0xFF10B981);
      case 'moderate':
        return const Color(0xFFF59E0B);
      case 'severe':
        return const Color(0xFFEF4444);
      case 'life_threatening':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF64748B);
    }
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
        // Row 1: Core Clinical
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
                icon: Icons.trending_up_rounded,
                title: 'Treatments',
                subtitle: 'Progress & outcomes',
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
        const SizedBox(height: 12),
        // Row 2: Labs & Diagnoses
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.science_rounded,
                title: 'Lab Orders',
                subtitle: 'Orders & results',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LabOrdersScreen(
                      patientId: patient.id,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: Follow-ups & Allergies
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.event_repeat_rounded,
                title: 'Follow-ups',
                subtitle: 'Scheduled visits',
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
                icon: Icons.warning_rounded,
                title: 'Allergies',
                subtitle: 'Manage allergies',
                color: const Color(0xFFDC2626),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllergyManagementScreen(
                      patientId: patient.id,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 4: History & Problems
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.family_restroom_rounded,
                title: 'Family History',
                subtitle: 'Hereditary info',
                color: const Color(0xFFEC4899),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FamilyHistoryScreen(
                      patientId: patient.id,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionCard(
                icon: Icons.list_alt_rounded,
                title: 'Problem List',
                subtitle: 'Active conditions',
                color: const Color(0xFFEF4444),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProblemListScreen(
                      patientId: patient.id,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 5: Immunizations (single item, centered)
        Row(
          children: [
            Expanded(
              child: QuickActionCard(
                icon: Icons.vaccines_rounded,
                title: 'Immunizations',
                subtitle: 'Vaccine records',
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImmunizationsScreen(
                      patientId: patient.id,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()), // Placeholder
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
    final age = patient.age;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompactScreen ? 16 : 24,
        isCompactScreen ? 56 : 60,
        isCompactScreen ? 16 : 24,
        64, // Reduced from 72 to prevent overflow
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Patient Icon with Risk Indicator
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: isCompactScreen ? 68 : 80, // Slightly reduced
                  height: isCompactScreen ? 68 : 80,
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
                      size: isCompactScreen ? 34 : 40, // Slightly reduced
                      color: Colors.white,
                    ),
                  ),
                ),
                // Risk badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5), // Slightly reduced
                    decoration: BoxDecoration(
                      color: riskColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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
                      size: 11, // Slightly reduced
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Reduced from 12
            
            // Patient Name
            Text(
              '${patient.firstName} ${patient.lastName}'.trim(),
              style: TextStyle(
                fontSize: isCompactScreen ? 19 : 22, // Slightly reduced
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
            const SizedBox(height: 6), // Reduced from 8
          
            // Patient Info Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), // Reduced padding
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
            const SizedBox(height: 8), // Reduced from 10
            
            // Risk Level & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduced padding
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Emergency Info Button
        widgets.EmergencyInfoButton(
          patientName: '${widget.patient.firstName} ${widget.patient.lastName}'.trim(),
          bloodType: widget.patient.bloodType,
          allergies: widget.patient.allergies,
          emergencyContactName: widget.patient.emergencyContactName,
          emergencyContactPhone: widget.patient.emergencyContactPhone,
        ),
        const SizedBox(height: 12),
        // Main FAB
        FloatingActionButton.extended(
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
        ),
      ],
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
                // Start Visit - Main Action
                SizedBox(
                  width: double.infinity,
                  child: _buildQuickActionCard(
                    icon: Icons.play_circle_filled_rounded,
                    label: 'Start Visit Workflow',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    isLarge: true,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkflowWizardScreen(
                            existingPatient: widget.patient,
                          ),
                        ),
                      ).then((_) {
                        // Refresh data when returning from workflow
                        _refreshAllData();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
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
                          ).then((_) => _refreshAllData());
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
                          ).then((_) => _refreshAllData());
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
                          ).then((_) => _refreshAllData());
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
                          ).then((_) => _refreshAllData());
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
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isLarge ? 16 : 18, 
          horizontal: isLarge ? 20 : 12,
        ),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: isLarge
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              )
            : Column(
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
