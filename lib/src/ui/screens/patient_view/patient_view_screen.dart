// Optimized Patient View Screen - Modular Architecture
// This file imports separate tab components for better maintainability

import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/whatsapp_service.dart';
import '../../../core/components/app_button.dart';
import '../../../core/mixins/responsive_mixin.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/patient_avatar.dart';
import '../add_appointment_screen.dart';
import '../add_invoice_screen.dart';
import '../add_medical_record_screen.dart';
import '../add_prescription_screen.dart';

// Import modular tab components
import 'patient_overview_tab.dart';
import 'patient_appointments_tab.dart';
import 'patient_prescriptions_tab.dart';
import 'patient_records_tab.dart';
import 'patient_billing_tab.dart';
import 'patient_documents_tab.dart';

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
    _tabController = TabController(length: 6, vsync: this);
    _initializeControllers();
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
        builder: (context) => AddMedicalRecordScreen(
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
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    // Responsive values
    final headerHeight = isCompact ? 220.0 : 280.0;
    final headerPadding = isCompact 
        ? const EdgeInsets.fromLTRB(16, 48, 16, 12)
        : const EdgeInsets.fromLTRB(24, 56, 24, 16);
    final tabFontSize = isCompact ? 12.0 : 13.0;
    final tabIconSize = isCompact ? 16.0 : 18.0;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: headerHeight,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: surfaceColor,
              foregroundColor: textColor,
              leading: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(isCompact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_back_rounded, size: isCompact ? 18 : 20),
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
              actions: [
                _buildHeaderActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: const Color(0xFF25D366),
                  onTap: () {
                    if (patient.phone.isNotEmpty) {
                      WhatsAppService.openChat(patient.phone);
                    }
                  },
                  isDark: isDark,
                ),
                _buildHeaderActionButton(
                  icon: Icons.phone_outlined,
                  color: AppColors.primary,
                  onTap: () {
                    if (widget.patient.phone.isNotEmpty) {
                      _callPatient(widget.patient.phone);
                    }
                  },
                  isDark: isDark,
                ),
                _buildHeaderActionButton(
                  icon: Icons.more_vert_rounded,
                  onTap: () => _showOptionsMenu(context),
                  isDark: isDark,
                ),
                SizedBox(width: isCompact ? 4 : 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: surfaceColor,
                  child: SafeArea(
                    child: Padding(
                      padding: headerPadding,
                      child: _buildPatientHeader(patient, isDark, riskColor, surfaceColor, textColor),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.dashboard_rounded, size: tabIconSize), SizedBox(width: isCompact ? 4 : 6), Text('Overview')])),
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.event_rounded, size: tabIconSize), SizedBox(width: isCompact ? 4 : 6), Text('Appointments')])),
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.medication_rounded, size: tabIconSize), SizedBox(width: isCompact ? 4 : 6), Text('Prescriptions')])),
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.folder_special_rounded, size: tabIconSize), SizedBox(width: isCompact ? 4 : 6), Text('Records')])),
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.receipt_long_rounded, size: tabIconSize), SizedBox(width: isCompact ? 4 : 6), Text('Billing')])),
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.attach_file_rounded, size: tabIconSize), SizedBox(width: isCompact ? 4 : 6), Text('Documents')])),
                ],
                labelColor: AppColors.primary,
                unselectedLabelColor: secondaryTextColor,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: tabFontSize),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: tabFontSize),
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
            PatientAppointmentsTab(patient: patient),
            PatientPrescriptionsTab(patient: patient),
            PatientRecordsTab(patient: patient),
            PatientBillingTab(patient: patient),
            PatientDocumentsTab(patient: patient),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildPatientHeader(Patient patient, bool isDark, Color riskColor, Color surfaceColor, Color textColor) {
    final avatarSizeValue = isCompact ? 56.0 : 72.0;
    final nameSize = isCompact ? 18.0 : 22.0;
    final spacingSmall = isCompact ? 4.0 : 6.0;
    final spacingMedium = isCompact ? 6.0 : 10.0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with risk badge
        Stack(
          children: [
            PatientAvatarCircle(
              patientId: patient.id,
              firstName: patient.firstName,
              lastName: patient.lastName,
              size: avatarSizeValue,
              editable: true,
              onPhotoChanged: () => setState(() {}),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(isCompact ? 4 : 6),
                decoration: BoxDecoration(
                  color: riskColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: surfaceColor, width: 2),
                ),
                child: Icon(
                  patient.riskLevel == 0 ? Icons.check : (patient.riskLevel == 1 ? Icons.warning_amber : Icons.priority_high),
                  color: Colors.white,
                  size: isCompact ? 10 : 12,
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: isCompact ? 12 : 16),
        // Patient Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${patient.firstName} ${patient.lastName}',
                style: TextStyle(
                  fontSize: nameSize,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: spacingSmall),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.badge_outlined,
                    label: 'ID: ${patient.id.toString().padLeft(4, '0')}',
                    isDark: isDark,
                  ),
                  SizedBox(width: isCompact ? 6 : 8),
                  if (patient.dateOfBirth != null)
                    _buildInfoChip(
                      icon: Icons.cake_outlined,
                      label: '${_calculateAge(patient.dateOfBirth!)} yrs',
                      isDark: isDark,
                    ),
                ],
              ),
              SizedBox(height: spacingMedium),
              // Risk & Tags
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10, vertical: isCompact ? 4 : 5),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            patient.riskLevel == 0 ? Icons.shield_outlined : Icons.warning_amber_rounded,
                            size: isCompact ? 12 : 14,
                            color: riskColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getRiskLabel(patient.riskLevel),
                            style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    ...patient.tags.split(',').where((t) => t.trim().isNotEmpty).take(2).map((tag) {
                      final tagColor = _getTagColor(tag.trim());
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag.trim(),
                            style: TextStyle(color: tagColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? (isDark ? Colors.white : AppColors.textPrimary)).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return FloatingActionButton(
      heroTag: 'patient_actions',
      onPressed: _showQuickActionsSheet,
      tooltip: 'Quick Actions',
      child: const Icon(Icons.add_rounded),
    );
  }

  void _showQuickActionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActionTile(
                icon: Icons.event_note_rounded,
                label: 'New Appointment',
                color: AppColors.primary,
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
              _buildQuickActionTile(
                icon: Icons.local_pharmacy_rounded,
                label: 'New Prescription',
                color: AppColors.warning,
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
              _buildQuickActionTile(
                icon: Icons.medical_services_rounded,
                label: 'New Medical Record',
                color: const Color(0xFF10B981), // Clinical Green
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddRecord();
                },
              ),
              _buildQuickActionTile(
                icon: Icons.receipt_rounded,
                label: 'New Invoice',
                color: const Color(0xFF8B5CF6), // Billing Purple
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
