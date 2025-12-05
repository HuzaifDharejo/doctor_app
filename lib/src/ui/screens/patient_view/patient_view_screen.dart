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
import '../../widgets/patient_avatar.dart';
import '../add_appointment_screen.dart';
import '../add_invoice_screen.dart';
import '../add_prescription_screen.dart';
import '../records/records.dart';

// Import modular tab components
import 'patient_overview_tab.dart';
import 'patient_appointments_tab.dart';
import 'patient_prescriptions_tab.dart';
import 'patient_records_tab.dart';
import 'patient_billing_tab.dart';
import 'patient_documents_tab.dart';
import 'patient_encounters_tab.dart';
import 'patient_timeline_tab.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _initializeControllers();
    // Log patient view for HIPAA compliance
    _logPatientView();
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
              onTap: () {
                Navigator.pop(context);
                setState(() => _isEditingProfile = !_isEditingProfile);
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
                    tabs: [
                      _buildModernTab(Icons.dashboard_rounded, 'Overview'),
                      _buildModernTab(Icons.timeline_rounded, 'Timeline'),
                      _buildModernTab(Icons.medical_services_rounded, 'Encounters'),
                      _buildModernTab(Icons.event_rounded, 'Appointments'),
                      _buildModernTab(Icons.medication_rounded, 'Prescriptions'),
                      _buildModernTab(Icons.folder_special_rounded, 'Records'),
                      _buildModernTab(Icons.receipt_long_rounded, 'Billing'),
                      _buildModernTab(Icons.attach_file_rounded, 'Documents'),
                    ],
                    labelColor: AppColors.primary,
                    unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
            PatientOverviewTab(
              patient: patient,
              isEditing: _isEditingProfile,
              hasChanges: _hasChanges,
              isSaving: _isSaving,
              phoneController: _phoneController,
              emailController: _emailController,
              addressController: _addressController,
              medicalHistoryController: _medicalHistoryController,
              tagsController: _tagsController,
              onSave: _saveChanges,
              onDiscard: _discardChanges,
              onToggleEdit: () => setState(() => _isEditingProfile = !_isEditingProfile),
            ),
            PatientTimelineTab(patient: patient),
            PatientEncountersTab(patient: patient),
            PatientAppointmentsTab(patient: patient),
            PatientPrescriptionsTab(patient: patient),
            PatientRecordsTab(patient: patient),
            PatientBillingTab(patient: patient),
            PatientDocumentsTab(patient: patient),
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  Widget _buildModernTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
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
    final avatarSize = isCompactScreen ? 48.0 : 56.0;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompactScreen ? 12 : 20,
        isCompactScreen ? 48 : 52,
        isCompactScreen ? 12 : 20,
        64,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar with glow effect
          Stack(
            alignment: Alignment.center,
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                child: PatientAvatarCircle(
                  patientId: patient.id,
                  firstName: patient.firstName,
                  lastName: patient.lastName,
                  size: avatarSize,
                  editable: true,
                  onPhotoChanged: () => setState(() {}),
                ),
              ),
              // Risk badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: riskColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    patient.riskLevel == 0
                        ? Icons.check
                        : (patient.riskLevel == 1 ? Icons.warning_amber : Icons.priority_high),
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Patient Name
          Text(
            '${patient.firstName} ${patient.lastName}',
            style: TextStyle(
              fontSize: isCompactScreen ? 17 : 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Info chips row - use Wrap for flexibility
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildHeaderChip(
                icon: Icons.badge_outlined,
                label: '#${patient.id.toString().padLeft(4, '0')}',
              ),
              if (patient.dateOfBirth != null)
                _buildHeaderChip(
                  icon: Icons.cake_outlined,
                  label: '${_calculateAge(patient.dateOfBirth!)} yrs',
                ),
              _buildHeaderChip(
                icon: patient.riskLevel == 0 ? Icons.shield_outlined : Icons.warning_amber_rounded,
                label: _getRiskLabel(patient.riskLevel),
                color: riskColor,
              ),
            ],
          ),
          // Tags - only show if has tags
          if (patient.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: patient.tags
                  .split(',')
                  .where((t) => t.trim().isNotEmpty)
                  .take(2) // Only take 2 tags to save space
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (color ?? Colors.white).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'patient_actions',
        onPressed: _showQuickActionsSheet,
        tooltip: 'Quick Actions',
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white),
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
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Actions Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.event_note_rounded,
                        label: 'Appointment',
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
                        icon: Icons.local_pharmacy_rounded,
                        label: 'Prescription',
                        color: AppColors.warning,
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
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.medical_services_rounded,
                        label: 'Medical Record',
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
                        icon: Icons.receipt_rounded,
                        label: 'Invoice',
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
