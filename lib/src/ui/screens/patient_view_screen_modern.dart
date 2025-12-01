// Modern Patient View Screen - Redesigned for Better UX
// ignore_for_file: unused_element

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/whatsapp_service.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_input.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import '../widgets/patient_avatar.dart';
import 'add_appointment_screen.dart';
import 'add_invoice_screen.dart';
import 'add_prescription_screen.dart';
import 'follow_ups_screen.dart';
import 'invoice_detail_screen.dart';
import 'lab_results_screen.dart';
import 'medical_record_detail_screen.dart';
import 'records/records.dart';
import '../../core/routing/app_router.dart';
import 'treatment_outcomes_screen.dart';
import 'treatment_progress_screen.dart';
import 'vital_signs_screen.dart';

class PatientViewScreenModern extends ConsumerStatefulWidget {
  const PatientViewScreenModern({required this.patient, super.key});
  final Patient patient;

  @override
  ConsumerState<PatientViewScreenModern> createState() =>
      _PatientViewScreenModernState();
}

class _PatientViewScreenModernState
    extends ConsumerState<PatientViewScreenModern>
    with SingleTickerProviderStateMixin {
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
    // 6 tabs: Overview, Appointments, Prescriptions, Medical Records, Vitals, Documents
    _tabController = TabController(length: 6, vsync: this);
    
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

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riskColor = _getRiskColor(patient.riskLevel);
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: surfaceColor,
              foregroundColor: textColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  color: const Color(0xFF25D366),
                  tooltip: 'WhatsApp',
                  onPressed: () {
                    if (patient.phone.isNotEmpty) {
                      WhatsAppService.openChat(patient.phone);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.phone_outlined),
                  tooltip: 'Call',
                  onPressed: () {
                    if (widget.patient.phone.isNotEmpty) {
                      _callPatient(widget.patient.phone);
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
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () => _showOptionsMenu(context),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: surfaceColor,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar with risk badge
                          Stack(
                            children: [
                              PatientAvatarCircle(
                                patientId: patient.id,
                                firstName: patient.firstName,
                                lastName: patient.lastName,
                                size: 80,
                                editable: true,
                                onPhotoChanged: () => setState(() {}),
                              ),
                              // Risk badge
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: riskColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: surfaceColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    _getRiskLabel(patient.riskLevel)[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Name and ID
                          Text(
                            '${patient.firstName} ${patient.lastName}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.badge_rounded,
                                size: 14,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ID: ${patient.id.toString().padLeft(4, '0')}',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (patient.dateOfBirth != null) ...[
                                Icon(
                                  Icons.cake_outlined,
                                  size: 14,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_calculateAge(patient.dateOfBirth!)} years',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Risk & Tags
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: riskColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: riskColor),
                                ),
                                child: Text(
                                  _getRiskLabel(patient.riskLevel),
                                  style: TextStyle(
                                    color: riskColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...patient.tags.split(',').where((t) => t.trim().isNotEmpty).map((tag) {
                                final tagColor = _getTagColor(tag.trim());
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tagColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: tagColor),
                                  ),
                                  child: Text(
                                    tag.trim(),
                                    style: TextStyle(
                                      color: tagColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
                  Tab(icon: Icon(Icons.event), text: 'Appointments'),
                  Tab(icon: Icon(Icons.local_pharmacy), text: 'Prescriptions'),
                  Tab(icon: Icon(Icons.description), text: 'Records'),
                  Tab(icon: Icon(Icons.receipt_long), text: 'Billing'),
                  Tab(icon: Icon(Icons.attachment), text: 'Documents'),
                ],
                labelColor: AppColors.primary,
                unselectedLabelColor: secondaryTextColor,
                indicatorColor: AppColors.primary,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildAppointmentsTab(),
            _buildPrescriptionsTab(),
            _buildMedicalRecordsTab(),
            _buildBillingTab(),
            _buildDocumentsTab(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'appointment',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddAppointmentScreen(
                  preselectedPatient: widget.patient,
                ),
              ),
            );
          },
          tooltip: 'New Appointment',
          child: const Icon(Icons.event_note_rounded),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'prescription',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPrescriptionScreen(
                  preselectedPatient: widget.patient,
                ),
              ),
            );
          },
          tooltip: 'New Prescription',
          child: const Icon(Icons.local_pharmacy_rounded),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'medical_record',
          onPressed: _navigateToAddRecord,
          backgroundColor: AppColors.info,
          tooltip: 'New Medical Record',
          child: const Icon(Icons.medical_services_rounded),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'invoice',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddInvoiceScreen(
                  patientId: widget.patient.id,
                ),
              ),
            );
          },
          tooltip: 'New Invoice',
          child: const Icon(Icons.receipt_rounded),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final patient = widget.patient;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Info Cards
          _buildInfoCard(
            icon: Icons.phone_rounded,
            title: 'Phone',
            value: patient.phone.isEmpty ? 'Not provided' : patient.phone,
            action: patient.phone.isNotEmpty
                ? () => WhatsAppService.openChat(patient.phone)
                : null,
            actionIcon: Icons.chat_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.email_rounded,
            title: 'Email',
            value: patient.email.isEmpty ? 'Not provided' : patient.email,
            actionIcon: Icons.mail_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.location_on_rounded,
            title: 'Address',
            value: patient.address.isEmpty ? 'Not provided' : patient.address,
            actionIcon: Icons.map_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          // Medical History
          Text(
            'Medical History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(12),
              color: cardColor,
            ),
            child: Text(
              patient.medicalHistory.isEmpty
                  ? 'No medical history recorded'
                  : patient.medicalHistory,
              style: TextStyle(
                color: patient.medicalHistory.isEmpty 
                    ? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
                    : textColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Clinical Quick Actions
          Text(
            'Clinical Features',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.monitor_heart_rounded,
                  title: 'Vital Signs',
                  subtitle: 'Track vitals',
                  color: Colors.red,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VitalSignsScreen(
                        patientId: patient.id,
                        patientName: '${patient.firstName} ${patient.lastName}',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.medical_services_rounded,
                  title: 'Treatments',
                  subtitle: 'Track outcomes',
                  color: Colors.purple,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreatmentOutcomesScreen(
                        patientId: patient.id,
                        patientName: '${patient.firstName} ${patient.lastName}',
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
                child: _buildQuickActionCard(
                  icon: Icons.event_repeat_rounded,
                  title: 'Follow-ups',
                  subtitle: 'Manage follow-ups',
                  color: Colors.orange,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowUpsScreen(
                        patientId: patient.id,
                        patientName: '${patient.firstName} ${patient.lastName}',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.science_rounded,
                  title: 'Lab Results',
                  subtitle: 'View history',
                  color: Colors.teal,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LabResultsScreen(
                        patientId: patient.id,
                        patientName: '${patient.firstName} ${patient.lastName}',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Treatment Progress - Sessions, Medications, Goals, Side Effects
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Progress',
                  subtitle: 'Sessions & goals',
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreatmentProgressScreen(
                        patientId: patient.id,
                        patientName: '${patient.firstName} ${patient.lastName}',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  subtitle: 'Treatment overview',
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  onTap: () => context.goToTreatmentDashboard(
                    patient.id,
                    '${patient.firstName} ${patient.lastName}',
                  ),
                ),
              ),
            ],
          ),
          if (_isEditingProfile)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _buildEditProfileSection(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditProfileSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final fillColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: borderColor),
        const SizedBox(height: 16),
        Text(
          'Edit Patient Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        AppInput.phone(
          controller: _phoneController,
          label: 'Phone',
          prefixIcon: Icons.phone,
        ),
        const SizedBox(height: 12),
        AppInput.email(
          controller: _emailController,
          label: 'Email',
          prefixIcon: Icons.email,
        ),
        const SizedBox(height: 12),
        AppInput.multiline(
          controller: _addressController,
          label: 'Address',
          prefixIcon: Icons.location_on,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        AppInput.multiline(
          controller: _medicalHistoryController,
          label: 'Medical History',
          prefixIcon: Icons.note_alt,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        AppInput.text(
          controller: _tagsController,
          label: 'Tags (comma-separated)',
          prefixIcon: Icons.label,
        ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save Changes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _discardChanges,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? action,
    IconData? actionIcon,
    required bool isDark,
  }) {
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          if (action != null && actionIcon != null)
            IconButton(
              icon: Icon(actionIcon, color: AppColors.primary),
              onPressed: action,
              tooltip: 'Open',
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<Appointment>>(
        future: _getPatientAppointments(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.calendar_today_outlined,
              title: 'No Appointments',
              subtitle: 'Schedule an appointment for this patient',
              actionLabel: 'Schedule Appointment',
              onAction: () => _navigateToAddAppointment(),
            );
          }

          appointments.sort((a, b) => b.appointmentDateTime.compareTo(a.appointmentDateTime));

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: appointments.length,
            itemBuilder: (context, index) => _buildAppointmentCard(appointments[index], isDark),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => _buildEmptyState(
        context,
        icon: Icons.error_outline,
        title: 'Error Loading Appointments',
        subtitle: 'Please try again later',
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    Color statusColor;
    switch (appointment.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
      case 'cancelled':
        statusColor = AppColors.error;
      case 'no-show':
        statusColor = AppColors.warning;
      default:
        statusColor = AppColors.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.reason.isNotEmpty ? appointment.reason : 'Appointment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(appointment.appointmentDateTime),
                  style: TextStyle(color: secondaryColor, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              appointment.status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<Prescription>>(
        future: db.getPrescriptionsForPatient(widget.patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final prescriptions = snapshot.data ?? [];

          if (prescriptions.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.medication_outlined,
              title: 'No Prescriptions',
              subtitle: 'Create a prescription for this patient',
              actionLabel: 'Create Prescription',
              onAction: () => _navigateToAddPrescription(),
            );
          }

          prescriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) => _buildPrescriptionCard(prescriptions[index], isDark),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => _buildEmptyState(
        context,
        icon: Icons.error_outline,
        title: 'Error Loading Prescriptions',
        subtitle: 'Please try again later',
      ),
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    List<dynamic> medications = [];
    try {
      medications = jsonDecode(prescription.itemsJson) as List<dynamic>;
    } catch (e) {
      // Handle parsing error
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_pharmacy, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prescription #${prescription.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(prescription.createdAt),
                      style: TextStyle(color: secondaryColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                '${medications.length} med${medications.length != 1 ? 's' : ''}',
                style: TextStyle(color: secondaryColor, fontSize: 12),
              ),
            ],
          ),
          if (medications.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medications.take(3).map((med) {
                final name = med is Map ? (med['name'] ?? 'Unknown') : med.toString();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name.toString(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalRecordsTab() {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<MedicalRecord>>(
        future: db.getMedicalRecordsForPatient(widget.patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.description_outlined,
              title: 'No Medical Records',
              subtitle: 'Add medical records to track patient history',
              actionLabel: 'Add Record',
              onAction: () => _navigateToAddRecord(),
            );
          }

          records.sort((a, b) => b.recordDate.compareTo(a.recordDate));

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: records.length,
            itemBuilder: (context, index) => _buildMedicalRecordCard(records[index], isDark),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => _buildEmptyState(
        context,
        icon: Icons.error_outline,
        title: 'Error Loading Records',
        subtitle: 'Please try again later',
      ),
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(record.dataJson) as Map<String, dynamic>;
    } catch (e) {
      // Handle parsing error
    }

    IconData recordIcon;
    Color recordColor;
    switch (record.recordType) {
      case 'pulmonary_evaluation':
        recordIcon = Icons.air;
        recordColor = const Color(0xFF00ACC1);
      case 'psychiatric_assessment':
        recordIcon = Icons.psychology;
        recordColor = AppColors.primary;
      case 'lab_result':
        recordIcon = Icons.science_outlined;
        recordColor = AppColors.warning;
      case 'imaging':
        recordIcon = Icons.image_outlined;
        recordColor = AppColors.info;
      case 'procedure':
        recordIcon = Icons.healing_outlined;
        recordColor = AppColors.accent;
      case 'follow_up':
        recordIcon = Icons.event_repeat;
        recordColor = AppColors.success;
      default:
        recordIcon = Icons.medical_services_outlined;
        recordColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showMedicalRecordDetails(record, data),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: recordColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(recordIcon, color: recordColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(record.recordDate),
                            style: TextStyle(color: secondaryColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: recordColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getRecordTypeLabel(record.recordType),
                        style: TextStyle(
                          color: recordColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (record.diagnosis.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    record.diagnosis,
                    style: TextStyle(color: secondaryColor, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillingTab() {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<Invoice>>(
        future: db.getInvoicesForPatient(widget.patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final invoices = snapshot.data ?? [];

          if (invoices.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'No Invoices',
              subtitle: 'Create an invoice for this patient',
              actionLabel: 'Create Invoice',
              onAction: () => _navigateToAddInvoice(),
            );
          }

          double totalBilled = 0;
          double totalPaid = 0;
          for (final invoice in invoices) {
            totalBilled += invoice.grandTotal;
            if (invoice.paymentStatus.toLowerCase() == 'paid') {
              totalPaid += invoice.grandTotal;
            }
          }
          final totalOutstanding = totalBilled - totalPaid;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildBillingSummaryCard('Total', totalBilled, AppColors.primary, isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildBillingSummaryCard('Paid', totalPaid, AppColors.success, isDark)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBillingSummaryCard(
                  'Outstanding', 
                  totalOutstanding, 
                  totalOutstanding > 0 ? AppColors.warning : AppColors.success, 
                  isDark,
                  fullWidth: true,
                ),
                const SizedBox(height: 20),
                Text(
                  'Recent Invoices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                ...invoices.take(10).map((invoice) => _buildInvoiceCard(invoice, isDark)),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => _buildEmptyState(
        context,
        icon: Icons.error_outline,
        title: 'Error Loading Invoices',
        subtitle: 'Please try again later',
      ),
    );
  }

  Widget _buildBillingSummaryCard(String label, double amount, Color color, bool isDark, {bool fullWidth = false}) {
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              color: color,
              fontSize: fullWidth ? 22 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice, bool isDark) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    final isPaid = invoice.paymentStatus.toLowerCase() == 'paid';
    final statusColor = isPaid ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceDetailScreen(
                  invoice: invoice,
                  patient: widget.patient,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.billing.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt, color: AppColors.billing),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice #${invoice.invoiceNumber}',
                        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(invoice.createdAt),
                        style: TextStyle(color: secondaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(invoice.grandTotal),
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        invoice.paymentStatus,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return FutureBuilder<List<_PatientDocument>>(
      future: _getPatientDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final documents = snapshot.data ?? [];

        if (documents.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.folder_outlined,
            title: 'No Documents',
            subtitle: 'Upload documents for this patient',
            actionLabel: 'Upload Document',
            onAction: _uploadDocument,
          );
        }

        return Column(
          children: [
            // Upload button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _uploadDocument,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Document'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                ),
              ),
            ),
            // Documents list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: _getDocTypeColor(doc.extension).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getDocTypeIcon(doc.extension),
                          color: _getDocTypeColor(doc.extension),
                        ),
                      ),
                      title: Text(
                        doc.name,
                        style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${doc.formattedSize} • ${doc.formattedDate}',
                        style: TextStyle(color: secondaryColor, fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) => _handleDocumentAction(value, doc),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: ListTile(
                              leading: Icon(Icons.open_in_new),
                              title: Text('Open'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: AppColors.error),
                              title: Text('Delete', style: TextStyle(color: AppColors.error)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<_PatientDocument>> _getPatientDocuments() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final patientDocsDir = Directory(p.join(docsDir.path, 'patient_documents', '${widget.patient.id}'));

      if (!await patientDocsDir.exists()) {
        return [];
      }

      final files = patientDocsDir.listSync().whereType<File>().toList();
      return files.map((file) {
        final stat = file.statSync();
        return _PatientDocument(
          name: p.basename(file.path),
          path: file.path,
          size: stat.size,
          date: stat.modified,
          extension: p.extension(file.path).toLowerCase().replaceAll('.', ''),
        );
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
    } catch (e) {
      return [];
    }
  }

  Future<void> _uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 12),
                Text('Uploading document...'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Create patient documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final patientDocsDir = Directory(p.join(docsDir.path, 'patient_documents', '${widget.patient.id}'));
      if (!await patientDocsDir.exists()) {
        await patientDocsDir.create(recursive: true);
      }

      // Copy file to patient's documents folder
      final sourceFile = File(file.path!);
      final destPath = p.join(patientDocsDir.path, file.name);
      await sourceFile.copy(destPath);

      // Refresh and show success
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Document uploaded successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleDocumentAction(String action, _PatientDocument doc) async {
    switch (action) {
      case 'open':
        // Open file using system default app
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${doc.name}...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Note: For full implementation, use open_file or url_launcher package
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Document'),
            content: Text('Are you sure you want to delete "${doc.name}"?'),
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

        if (confirmed == true) {
          try {
            await File(doc.path).delete();
            if (mounted) {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting document: $e'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
        break;
    }
  }

  IconData _getDocTypeIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.article;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocTypeColor(String extension) {
    switch (extension) {
      case 'pdf':
        return const Color(0xFFE53935); // Red
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Color(0xFF4CAF50); // Green
      case 'doc':
      case 'docx':
        return const Color(0xFF2196F3); // Blue
      case 'txt':
        return const Color(0xFF9E9E9E); // Grey
      default:
        return AppColors.primary;
    }
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: secondaryColor),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              AppButton.primary(
                label: actionLabel,
                icon: Icons.add,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getRecordTypeLabel(String type) {
    switch (type) {
      case 'pulmonary_evaluation':
        return 'Pulmonary';
      case 'psychiatric_assessment':
        return 'Psychiatric';
      case 'lab_result':
        return 'Lab Result';
      case 'imaging':
        return 'Imaging';
      case 'procedure':
        return 'Procedure';
      case 'follow_up':
        return 'Follow-up';
      default:
        return 'General';
    }
  }

  void _showMedicalRecordDetails(MedicalRecord record, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalRecordDetailScreen(
          record: record,
          patient: widget.patient,
        ),
      ),
    );
  }

  void _navigateToAddAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAppointmentScreen(preselectedPatient: widget.patient),
      ),
    );
  }

  void _navigateToAddPrescription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPrescriptionScreen(preselectedPatient: widget.patient),
      ),
    );
  }

  void _navigateToAddRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectRecordTypeScreen(preselectedPatient: widget.patient),
      ),
    );
  }

  void _navigateToAddInvoice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddInvoiceScreen(patientId: widget.patient.id),
      ),
    );
  }

  Future<void> _callPatient(String phone) async {
    unawaited(HapticFeedback.lightImpact());
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone call'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email, String patientName) async {
    unawaited(HapticFeedback.lightImpact());
    final url = Uri(
      scheme: 'mailto',
      path: email,
      query: Uri.encodeComponent('subject=Patient: $patientName'),
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email client'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _sharePatientProfile(Patient patient) {
    final shareText = '''Patient Profile: ${patient.firstName} ${patient.lastName}
Phone: ${patient.phone.isNotEmpty ? patient.phone : 'N/A'}
Email: ${patient.email.isNotEmpty ? patient.email : 'N/A'}
Medical History: ${patient.medicalHistory.isNotEmpty ? patient.medicalHistory : 'None'}
Allergies: ${patient.allergies.isNotEmpty ? patient.allergies : 'None'}''';
    
    Share.share(shareText, subject: '${patient.firstName} ${patient.lastName} - Patient Profile');
  }

  void _showDeleteConfirmation(Patient patient) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete ${patient.firstName} ${patient.lastName}? This action cannot be undone.'),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(dialogContext),
          ),
          AppButton.danger(
            label: 'Delete',
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deletePatient(patient);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deletePatient(Patient patient) async {
    try {
      final db = await ref.watch(doctorDbProvider).asData?.value;
      if (db != null) {
        await db.deletePatient(patient.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${patient.firstName} ${patient.lastName} deleted successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
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

  Future<List<Appointment>> _getPatientAppointments(DoctorDatabase db) async {
    final allAppointments = await db.getAllAppointments();
    return allAppointments.where((a) => a.patientId == widget.patient.id).toList();
  }
}

/// Model for patient document
class _PatientDocument {
  _PatientDocument({
    required this.name,
    required this.path,
    required this.size,
    required this.date,
    required this.extension,
  });

  final String name;
  final String path;
  final int size;
  final DateTime date;
  final String extension;

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return DateFormat('MMM d, yyyy').format(date);
  }
}

