// ignore_for_file: unused_element

import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/patient_avatar.dart';
import 'add_appointment_screen.dart';
import 'add_invoice_screen.dart';
import 'add_prescription_screen.dart';
import 'invoice_detail_screen.dart';
import 'medical_record_detail_screen.dart';
import 'psychiatric_assessment_screen_modern.dart';
import 'records/records.dart';

class PatientViewScreen extends ConsumerStatefulWidget {

  const PatientViewScreen({required this.patient, super.key});
  final Patient patient;

  @override
  ConsumerState<PatientViewScreen> createState() => _PatientViewScreenState();
}

class _PatientViewScreenState extends ConsumerState<PatientViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Editable field controllers
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _medicalHistoryController;
  
  // Track changes
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isEditingProfile = false;
  
  // Store initial values for comparison
  late String _initialPhone;
  late String _initialEmail;
  late String _initialAddress;
  late String _initialMedicalHistory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    // Initialize controllers with patient data
    final patient = widget.patient;
    _phoneController = TextEditingController(text: patient.phone);
    _emailController = TextEditingController(text: patient.email);
    _addressController = TextEditingController(text: patient.address);
    _medicalHistoryController = TextEditingController(text: patient.medicalHistory);
    
    // Store initial values
    _initialPhone = patient.phone;
    _initialEmail = patient.email;
    _initialAddress = patient.address;
    _initialMedicalHistory = patient.medicalHistory;
    
    // Add listeners for change detection
    _phoneController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
    _medicalHistoryController.addListener(_checkForChanges);
  }
  
  void _checkForChanges() {
    final hasChanges = _phoneController.text != _initialPhone ||
        _emailController.text != _initialEmail ||
        _addressController.text != _initialAddress ||
        _medicalHistoryController.text != _initialMedicalHistory;
    
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }
  
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    try {
      final db = await ref.read(doctorDbProvider.future);
      
      // Create a companion with updated fields
      final updatedPatient = PatientsCompanion(
        id: Value(widget.patient.id),
        firstName: Value(widget.patient.firstName),
        lastName: Value(widget.patient.lastName),
        dateOfBirth: Value(widget.patient.dateOfBirth),
        phone: Value(_phoneController.text),
        email: Value(_emailController.text),
        address: Value(_addressController.text),
        medicalHistory: Value(_medicalHistoryController.text),
        tags: Value(widget.patient.tags),
        riskLevel: Value(widget.patient.riskLevel),
        createdAt: Value(widget.patient.createdAt),
      );
      
      // Update patient in database
      await db.updatePatient(updatedPatient);
      
      // Update initial values
      _initialPhone = _phoneController.text;
      _initialEmail = _emailController.text;
      _initialAddress = _addressController.text;
      _initialMedicalHistory = _medicalHistoryController.text;
      
      setState(() {
        _hasChanges = false;
        _isSaving = false;
        _isEditingProfile = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient information updated successfully'),
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
            content: Text('Error saving changes: $e'),
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
    super.dispose();
  }

  Color _getRiskColor(int riskLevel) {
    if (riskLevel <= 2) return AppColors.riskLow;
    if (riskLevel <= 4) return AppColors.riskMedium;
    return AppColors.riskHigh;
  }

  String _getRiskLabel(int riskLevel) {
    if (riskLevel <= 2) return 'Low Risk';
    if (riskLevel <= 4) return 'Medium Risk';
    return 'High Risk';
  }

  String _getPatientSubtitle(Patient patient) {
    if (patient.dateOfBirth == null) {
      return 'ID: ${patient.id.toString().padLeft(4, '0')}';
    }
    final age = _calculateAge(patient.dateOfBirth!);
    return '$age years old • ID: ${patient.id.toString().padLeft(4, '0')}';
  }

  Color _getTagColor(String tag) {
    final tagLower = tag.toLowerCase();
    if (tagLower.contains('urgent') || tagLower.contains('high') || tagLower.contains('critical')) {
      return AppColors.error;
    } else if (tagLower.contains('follow') || tagLower.contains('pending')) {
      return AppColors.warning;
    } else if (tagLower.contains('new') || tagLower.contains('active')) {
      return AppColors.success;
    } else if (tagLower.contains('vip') || tagLower.contains('premium')) {
      return const Color(0xFF9B59B6);
    }
    // Default: use hash-based color
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.info,
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
    ];
    return colors[tag.hashCode.abs() % colors.length];
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap, Color? bgColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: isLast ? 12 : 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor ?? color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final riskColor = _getRiskColor(patient.riskLevel);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = isDark ? AppColors.darkSurface : colorScheme.surface;
    final onSurfaceColor = isDark ? Colors.white : colorScheme.onSurface;
    final primaryContainer = isDark ? AppColors.primary.withValues(alpha: 0.2) : colorScheme.primaryContainer;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 340,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: surfaceColor,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: innerBoxIsScrolled ? onSurfaceColor : onSurfaceColor,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.chat_outlined),
                  color: const Color(0xFF25D366),
                  onPressed: () {
                    if (patient.phone.isNotEmpty) {
                      WhatsAppService.openChat(patient.phone);
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
                  icon: Icon(Icons.more_vert_rounded, color: onSurfaceColor),
                  onPressed: () => _showOptionsMenu(context),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar with M3 style container
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryContainer,
                          ),
                          child: PatientAvatarCircle(
                            patientId: patient.id,
                            firstName: patient.firstName,
                            lastName: patient.lastName,
                            size: 72,
                            editable: true,
                            onPhotoChanged: () => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Name - Large Title style
                        Text(
                          '${patient.firstName} ${patient.lastName}',
                          style: TextStyle(
                            color: onSurfaceColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Subtitle with age and ID
                        Text(
                          _getPatientSubtitle(patient),
                          style: TextStyle(
                            color: onSurfaceColor.withValues(alpha: 0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Risk chip row
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Risk Level Chip
                            _buildInfoChip(
                              color: riskColor,
                              label: _getRiskLabel(patient.riskLevel),
                              showDot: true,
                            ),
                            if (patient.phone.isNotEmpty)
                              _buildInfoChip(
                                color: onSurfaceColor,
                                label: patient.phone,
                                icon: Icons.phone_outlined,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(
                      bottom: BorderSide(
                        color: onSurfaceColor.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: onSurfaceColor.withValues(alpha: 0.6),
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.dashboard_rounded, size: 18),
                        text: 'Overview',
                        iconMargin: EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: Icon(Icons.folder_special_rounded, size: 18),
                        text: 'Records',
                        iconMargin: EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: Icon(Icons.calendar_month_rounded, size: 18),
                        text: 'Visits',
                        iconMargin: EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: Icon(Icons.medication_rounded, size: 18),
                        text: 'Rx',
                        iconMargin: EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: Icon(Icons.receipt_long_rounded, size: 18),
                        text: 'Billing',
                        iconMargin: EdgeInsets.only(bottom: 4),
                      ),
                      Tab(
                        icon: Icon(Icons.person_rounded, size: 18),
                        text: 'Profile',
                        iconMargin: EdgeInsets.only(bottom: 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context),
            _buildMedicalHistoryTab(context),
            _buildAppointmentsTab(context),
            _buildPrescriptionsTab(context),
            _buildBillingTab(context),
            _buildProfileTab(context),
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(context),
    );
  }

  Widget _buildInfoChip({
    required Color color,
    required String label,
    IconData? icon,
    bool showDot = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
          SizedBox(width: showDot || icon != null ? 6 : 0),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final patient = widget.patient;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Section at top
              _buildQuickStats(context),
              const SizedBox(height: 20),
              
              // Contact Information Card (Editable)
              _buildSectionCard(
                context,
                title: 'Contact Information',
                icon: Icons.contact_phone_rounded,
                accentColor: AppColors.info,
                children: [
                  _buildEditableInfoRow(Icons.phone_rounded, 'Phone', _phoneController, hint: 'Enter phone number', keyboardType: TextInputType.phone),
                  _buildEditableInfoRow(Icons.email_rounded, 'Email', _emailController, hint: 'Enter email address', keyboardType: TextInputType.emailAddress),
                  _buildEditableInfoRow(Icons.location_on_rounded, 'Address', _addressController, hint: 'Enter address', maxLines: 2),
                ],
              ),
              const SizedBox(height: 16),

              // Personal Information Card (Read-only)
              _buildSectionCard(
                context,
                title: 'Personal Information',
                icon: Icons.person_rounded,
                accentColor: AppColors.accent,
                children: [
                  _buildInfoRow(
                    Icons.cake_rounded,
                    'Date of Birth',
                    patient.dateOfBirth != null ? dateFormat.format(patient.dateOfBirth!) : 'Not provided',
                  ),
                  if (patient.dateOfBirth != null)
                    _buildInfoRow(
                      Icons.calendar_today_rounded,
                      'Age',
                      '${_calculateAge(patient.dateOfBirth!)} years old',
                    ),
                  _buildInfoRow(
                    Icons.event_rounded,
                    'Patient Since',
                    dateFormat.format(patient.createdAt),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tags Card (Read-only)
              if (patient.tags.isNotEmpty)
                _buildSectionCard(
                  context,
                  title: 'Tags',
                  icon: Icons.label_rounded,
                  accentColor: const Color(0xFF9B59B6),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: patient.tags.split(',').where((tag) => tag.trim().isNotEmpty).map((tag) {
                        final tagColor = _getTagColor(tag.trim());
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            tag.trim(),
                            style: TextStyle(
                              color: tagColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              const SizedBox(height: 100), // Space for save button and FAB
            ],
          ),
        ),
        
        // Save Button (appears when changes are made)
        if (_hasChanges)
          Positioned(
            bottom: 16, // Same as FAB default position
            left: 20,
            right: 76, // FAB is ~56px wide + 16px margin + 4px gap
            child: Material(
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _isSaving ? null : _saveChanges,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 56, // Same height as FAB
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaving)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isSaving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMedicalHistoryTab(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final patient = widget.patient;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<MedicalRecord>>(
        future: db.getMedicalRecordsForPatient(patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final records = snapshot.data ?? [];
          final conditions = patient.medicalHistory.split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Existing Medical Conditions
                if (conditions.isNotEmpty) ...[
                  _buildSectionCard(
                    context,
                    title: 'Known Conditions',
                    icon: Icons.medical_services_outlined,
                    children: conditions.map((condition) {
                      return _buildConditionItem(context, condition);
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Medical Records from Database
                if (records.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Medical Records',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${records.length} record${records.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...records.map((record) => _buildMedicalRecordCard(context, record)),
                  const SizedBox(height: 16),
                ],

                if (records.isEmpty && conditions.isEmpty)
                  _buildEmptyHistoryCard(context),

                const SizedBox(height: 16),

                // Quick Add Buttons - Dynamic based on enabled record types
                _buildQuickAddRecordButtons(context),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => _buildEmptyState(
        context,
        icon: Icons.error_outline,
        title: 'Error Loading Records',
        subtitle: 'Please try again later',
      ),
    );
  }

  Widget _buildMedicalRecordCard(BuildContext context, MedicalRecord record) {
    final dateFormat = DateFormat('MMM d, yyyy');
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
        recordColor = const Color(0xFF00ACC1); // Cyan color for pulmonary
      case 'psychiatric_assessment':
        recordIcon = Icons.psychology;
        recordColor = AppColors.primary;
      case 'detailed_psychiatric_assessment':
        recordIcon = Icons.psychology_alt;
        recordColor = const Color(0xFF8E44AD);
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

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showMedicalRecordDetails(context, record, data),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: recordColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(recordIcon, color: recordColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(record.recordDate),
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: recordColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRecordTypeLabel(record.recordType),
                            style: TextStyle(
                              color: recordColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (record.diagnosis.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.medical_information_outlined,
                            size: 16,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Diagnosis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  record.diagnosis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Show risk assessment for psychiatric records
                    if (record.recordType == 'psychiatric_assessment' && data['risk_assessment'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildRiskChip('Suicidal', (data['risk_assessment']['suicidal_risk'] as String?) ?? 'None'),
                          const SizedBox(width: 8),
                          _buildRiskChip('Homicidal', (data['risk_assessment']['homicidal_risk'] as String?) ?? 'None'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiskChip(String label, String risk) {
    Color chipColor;
    switch (risk.toLowerCase()) {
      case 'high':
        chipColor = AppColors.error;
      case 'moderate':
        chipColor = AppColors.warning;
      case 'low':
        chipColor = AppColors.info;
      default:
        chipColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: chipColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $risk',
            style: TextStyle(
              fontSize: 11,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getRecordTypeLabel(String type) {
    switch (type) {
      case 'pulmonary_evaluation':
        return 'Pulmonary Eval';
      case 'psychiatric_assessment':
        return 'Quick Assessment';
      case 'detailed_psychiatric_assessment':
        return 'Comprehensive Assessment';
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

  Widget _buildEmptyHistoryCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_information_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Medical Records',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add medical records to track patient history',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddRecordButtons(BuildContext context) {
    final appSettingsService = ref.watch(appSettingsProvider);
    final enabledTypes = appSettingsService.settings.enabledMedicalRecordTypes;
    
    // Define all record types with their properties
    final allRecordTypes = [
      {'type': 'pulmonary_evaluation', 'icon': Icons.air, 'label': 'Pulmonary\nEvaluation', 'color': const Color(0xFF00ACC1)},
      {'type': 'psychiatric_assessment', 'icon': Icons.psychology, 'label': 'Psychiatric\nAssessment', 'color': AppColors.primary},
      {'type': 'general', 'icon': Icons.medical_services_outlined, 'label': 'General\nConsultation', 'color': AppColors.accent},
      {'type': 'lab_result', 'icon': Icons.science_outlined, 'label': 'Lab\nResult', 'color': AppColors.warning},
      {'type': 'imaging', 'icon': Icons.image_outlined, 'label': 'Imaging\nStudy', 'color': AppColors.info},
      {'type': 'procedure', 'icon': Icons.healing_outlined, 'label': 'Procedure', 'color': const Color(0xFF9C27B0)},
      {'type': 'follow_up', 'icon': Icons.event_repeat, 'label': 'Follow-up\nVisit', 'color': AppColors.success},
    ];
    
    // Filter to only enabled types
    final enabledRecordTypes = allRecordTypes
        .where((rt) => enabledTypes.contains(rt['type']))
        .toList();
    
    if (enabledRecordTypes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Build rows of 3 buttons each
    final List<Widget> rows = [];
    for (int i = 0; i < enabledRecordTypes.length; i += 3) {
      final rowItems = enabledRecordTypes.skip(i).take(3).toList();
      rows.add(
        Row(
          children: [
            for (int j = 0; j < rowItems.length; j++) ...[
              if (j > 0) const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAddButton(
                  context,
                  icon: rowItems[j]['icon']! as IconData,
                  label: rowItems[j]['label']! as String,
                  color: rowItems[j]['color']! as Color,
                  onTap: () => _addMedicalRecord(context, rowItems[j]['type']! as String),
                ),
              ),
            ],
            // Add empty spacers to maintain 3-column layout
            for (int k = rowItems.length; k < 3; k++) ...[
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ],
        ),
      );
      if (i + 3 < enabledRecordTypes.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    
    return Column(children: rows);
  }

  Widget _buildQuickAddButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to the record type selection screen
  Future<void> _showSelectRecordTypeScreen(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => SelectRecordTypeScreen(preselectedPatient: widget.patient),
      ),
    );
    if (result ?? false) {
      setState(() {}); // Refresh the list
    }
  }

  Future<void> _addMedicalRecord(BuildContext context, String recordType) async {
    Widget targetScreen;
    
    // Route to the appropriate screen based on record type
    switch (recordType) {
      case 'general':
        targetScreen = AddGeneralRecordScreen(preselectedPatient: widget.patient);
      case 'pulmonary_evaluation':
        targetScreen = AddPulmonaryScreen(preselectedPatient: widget.patient);
      case 'psychiatric_assessment':
        targetScreen = PsychiatricAssessmentScreenModern(preselectedPatient: widget.patient);
      case 'lab_result':
        targetScreen = AddLabResultScreen(preselectedPatient: widget.patient);
      case 'imaging':
        targetScreen = AddImagingScreen(preselectedPatient: widget.patient);
      case 'procedure':
        targetScreen = AddProcedureScreen(preselectedPatient: widget.patient);
      case 'follow_up':
        targetScreen = AddFollowUpScreen(preselectedPatient: widget.patient);
      default:
        targetScreen = SelectRecordTypeScreen(preselectedPatient: widget.patient);
    }
    
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => targetScreen),
    );
    if (result ?? false) {
      setState(() {}); // Refresh the list
    }
  }

  Future<void> _openDetailedPsychiatricAssessment(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PsychiatricAssessmentScreenModern(
          preselectedPatient: widget.patient,
        ),
      ),
    );
    if (result ?? false) {
      setState(() {}); // Refresh the list
    }
  }

  void _showMedicalRecordDetails(BuildContext context, MedicalRecord record, Map<String, dynamic> data) {
    // Navigate to the new modern medical record detail screen
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MedicalRecordDetailScreen(
          record: record,
          patient: widget.patient,
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon, [bool isDark = false]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMseGrid(Map<String, dynamic> mse, [bool isDark = false]) {
    final fields = [
      {'key': 'appearance', 'label': 'Appearance'},
      {'key': 'behavior', 'label': 'Behavior'},
      {'key': 'speech', 'label': 'Speech'},
      {'key': 'mood', 'label': 'Mood'},
      {'key': 'affect', 'label': 'Affect'},
      {'key': 'thought_content', 'label': 'Thought Content'},
      {'key': 'thought_process', 'label': 'Thought Process'},
      {'key': 'perception', 'label': 'Perception'},
      {'key': 'cognition', 'label': 'Cognition'},
      {'key': 'insight', 'label': 'Insight'},
      {'key': 'judgment', 'label': 'Judgment'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        children: fields.where((f) => mse[f['key']] != null && mse[f['key']].toString().isNotEmpty).map((f) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${f['label']}:',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    mse[f['key']].toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRiskAssessmentCard(Map<String, dynamic> risk, [bool isDark = false]) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Risk Assessment',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildRiskChip('Suicidal', risk['suicidal_risk']?.toString() ?? 'None'),
              _buildRiskChip('Homicidal', risk['homicidal_risk']?.toString() ?? 'None'),
            ],
          ),
          if (risk['notes'] != null && risk['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              risk['notes'].toString(),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComprehensiveSymptomsCard(Map<String, dynamic> symptoms, bool isDark) {
    final entries = symptoms.entries.where((e) => 
      e.value != null && e.value.toString().isNotEmpty && e.value.toString() != 'null',
    ).toList();
    
    if (entries.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        children: entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    '${_formatSymptomLabel(e.key)}:',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  String _formatSymptomLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  Widget _buildPhysicalExamCard(Map<String, dynamic> exam, bool isDark) {
    final entries = exam.entries.where((e) => 
      e.value != null && e.value.toString().isNotEmpty && e.value.toString() != 'null',
    ).toList();
    
    if (entries.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_information, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Physical Examination',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_formatSymptomLabel(e.key)}: ',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      e.value.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsCard(Map<String, dynamic> vitals, [bool isDark = false]) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Vitals',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (vitals['bp'] != null && vitals['bp'].toString().isNotEmpty)
                _buildVitalItem('BP', vitals['bp'].toString(), isDark),
              if (vitals['pulse'] != null && vitals['pulse'].toString().isNotEmpty)
                _buildVitalItem('Pulse', vitals['pulse'].toString(), isDark),
              if (vitals['temperature'] != null && vitals['temperature'].toString().isNotEmpty)
                _buildVitalItem('Temp', vitals['temperature'].toString(), isDark),
              if (vitals['weight'] != null && vitals['weight'].toString().isNotEmpty)
                _buildVitalItem('Weight', vitals['weight'].toString(), isDark),
              if (vitals['height'] != null && vitals['height'].toString().isNotEmpty)
                _buildVitalItem('Height', vitals['height'].toString(), isDark),
              if (vitals['spo2'] != null && vitals['spo2'].toString().isNotEmpty)
                _buildVitalItem('SpO2', vitals['spo2'].toString(), isDark),
              if (vitals['respiratoryRate'] != null && vitals['respiratoryRate'].toString().isNotEmpty)
                _buildVitalItem('RR', vitals['respiratoryRate'].toString(), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, [bool isDark = false]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // New helper widgets for different record types
  Widget _buildScoresCard(Map<String, dynamic> data, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Assessment Scores',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (data['phq9Score'] != null)
                Expanded(
                  child: _buildScoreItem('PHQ-9', data['phq9Score'].toString(), _getPhq9Severity(data['phq9Score']), isDark),
                ),
              if (data['phq9Score'] != null && data['gad7Score'] != null)
                const SizedBox(width: 12),
              if (data['gad7Score'] != null)
                Expanded(
                  child: _buildScoreItem('GAD-7', data['gad7Score'].toString(), _getGad7Severity(data['gad7Score']), isDark),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String score, String severity, bool isDark) {
    Color severityColor;
    switch (severity.toLowerCase()) {
      case 'severe':
        severityColor = AppColors.error;
      case 'moderately severe':
      case 'moderate':
        severityColor = AppColors.warning;
      case 'mild':
        severityColor = AppColors.info;
      default:
        severityColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: severityColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            severity,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: severityColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getPhq9Severity(dynamic score) {
    final s = int.tryParse(score.toString()) ?? 0;
    if (s >= 20) return 'Severe';
    if (s >= 15) return 'Moderately Severe';
    if (s >= 10) return 'Moderate';
    if (s >= 5) return 'Mild';
    return 'Minimal';
  }

  String _getGad7Severity(dynamic score) {
    final s = int.tryParse(score.toString()) ?? 0;
    if (s >= 15) return 'Severe';
    if (s >= 10) return 'Moderate';
    if (s >= 5) return 'Mild';
    return 'Minimal';
  }

  Widget _buildLabResultsCard(Map<String, dynamic> data, bool isDark) {
    // Filter out non-result keys
    final resultKeys = data.keys.where((k) => k != 'notes' && data[k] != null && data[k].toString().isNotEmpty).toList();
    
    if (resultKeys.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Lab Results',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...resultKeys.map((key) {
            final label = _formatLabLabel(key);
            final value = data[key].toString();
            final isAbnormal = value.contains('(H)') || value.contains('(L)');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: isAbnormal ? AppColors.error : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isAbnormal ? FontWeight.w600 : FontWeight.normal,
                        color: isAbnormal 
                            ? AppColors.error 
                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatLabLabel(String key) {
    // Convert camelCase to readable format
    return key
        .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(1)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  Widget _buildImagingCard(Map<String, dynamic> data, bool isDark) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Imaging Findings',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...data.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      _formatLabLabel(e.key),
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProcedureCard(Map<String, dynamic> data, bool isDark) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.healing, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Procedure Details',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...data.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      _formatLabLabel(e.key),
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGenericDataCard(Map<String, dynamic> data, bool isDark) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Additional Details',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...data.entries.where((e) => e.value != null && e.value.toString().isNotEmpty && e.key != 'vitals').map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      _formatLabLabel(e.key),
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);

    return dbAsync.when(
      data: (db) => FutureBuilder<List<Appointment>>(
        future: _getPatientAppointments(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.calendar_today_outlined,
              title: 'No Appointments',
              subtitle: 'Schedule an appointment for this patient',
              actionLabel: 'Schedule Appointment',
              onAction: () => _scheduleAppointment(context),
            );
          }

          // Sort by date (upcoming first)
          appointments.sort((a, b) => b.appointmentDateTime.compareTo(a.appointmentDateTime));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return _buildAppointmentCard(context, appointments[index]);
            },
          );
        },
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => _buildEmptyState(
        context,
        icon: Icons.error_outline,
        title: 'Error Loading Appointments',
        subtitle: 'Please try again later',
      ),
    );
  }

  Widget _buildPrescriptionsTab(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);

    return dbAsync.when(
      data: (db) => FutureBuilder<List<Prescription>>(
        future: db.getPrescriptionsForPatient(widget.patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final prescriptions = snapshot.data ?? [];

          if (prescriptions.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.medication_outlined,
              title: 'No Prescriptions',
              subtitle: 'Create a prescription for this patient',
              actionLabel: 'Create Prescription',
              onAction: () => _createPrescription(context),
            );
          }

          // Sort by date (newest first)
          prescriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              return _buildPrescriptionCard(context, prescriptions[index]);
            },
          );
        },
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => _buildEmptyState(
        context,
        icon: Icons.error_outline,
        title: 'Error Loading Prescriptions',
        subtitle: 'Please try again later',
      ),
    );
  }

  Widget _buildBillingTab(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<Invoice>>(
        future: db.getInvoicesForPatient(widget.patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final invoices = snapshot.data ?? [];

          if (invoices.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'No Invoices',
              subtitle: 'Create an invoice for this patient',
              actionLabel: 'Create Invoice',
              onAction: () => _createInvoice(context),
            );
          }

          // Calculate totals
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Billing Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildBillingSummaryCard(
                        context,
                        icon: Icons.receipt_rounded,
                        label: 'Total Billed',
                        amount: totalBilled,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBillingSummaryCard(
                        context,
                        icon: Icons.check_circle_rounded,
                        label: 'Paid',
                        amount: totalPaid,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBillingSummaryCard(
                  context,
                  icon: Icons.pending_rounded,
                  label: 'Outstanding',
                  amount: totalOutstanding,
                  color: totalOutstanding > 0 ? AppColors.warning : AppColors.success,
                  fullWidth: true,
                ),
                const SizedBox(height: 24),
                
                // Recent Invoices Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Invoices',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _createInvoice(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Invoice'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Invoice List
                ...invoices.take(10).map((invoice) => _buildInvoiceCard(context, invoice)),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, stack) => _buildEmptyState(
        context,
        icon: Icons.error_outline,
        title: 'Error Loading Invoices',
        subtitle: 'Please try again later',
      ),
    );
  }

  Widget _buildBillingSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    bool fullWidth = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
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
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    
    Color statusColor;
    IconData statusIcon;
    switch (invoice.paymentStatus.toLowerCase()) {
      case 'paid':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_rounded;
        break;
      case 'overdue':
        statusColor = AppColors.error;
        statusIcon = Icons.error_rounded;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.receipt_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(invoice.invoiceDate),
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(invoice.grandTotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        invoice.paymentStatus.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildProfileTab(BuildContext context) {
    final patient = widget.patient;
    final dateFormat = DateFormat('MMMM d, yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    PatientAvatarCircle(
                      patientId: patient.id,
                      firstName: patient.firstName,
                      lastName: patient.lastName,
                      size: 80,
                      editable: true,
                      onPhotoChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${patient.firstName} ${patient.lastName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patient ID: ${patient.id.toString().padLeft(4, '0')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Member since ${dateFormat.format(patient.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Editable Contact Information
              _buildSectionCard(
                context,
                title: 'Contact Information',
                icon: Icons.contact_phone_rounded,
                accentColor: AppColors.info,
                children: [
                  _buildEditableInfoRow(Icons.phone_rounded, 'Phone', _phoneController, hint: 'Enter phone number', keyboardType: TextInputType.phone),
                  _buildEditableInfoRow(Icons.email_rounded, 'Email', _emailController, hint: 'Enter email address', keyboardType: TextInputType.emailAddress),
                  _buildEditableInfoRow(Icons.location_on_rounded, 'Address', _addressController, hint: 'Enter address', maxLines: 2),
                ],
              ),
              const SizedBox(height: 16),

              // Personal Details
              _buildSectionCard(
                context,
                title: 'Personal Details',
                icon: Icons.person_outline_rounded,
                accentColor: AppColors.accent,
                children: [
                  _buildInfoRow(
                    Icons.cake_rounded,
                    'Date of Birth',
                    patient.dateOfBirth != null ? dateFormat.format(patient.dateOfBirth!) : 'Not provided',
                  ),
                  if (patient.dateOfBirth != null)
                    _buildInfoRow(
                      Icons.calendar_today_rounded,
                      'Age',
                      '${_calculateAge(patient.dateOfBirth!)} years old',
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Medical Information
              _buildSectionCard(
                context,
                title: 'Medical Notes',
                icon: Icons.medical_information_rounded,
                accentColor: AppColors.warning,
                children: [
                  _buildEditableInfoRow(
                    Icons.note_alt_rounded,
                    'Medical History',
                    _medicalHistoryController,
                    hint: 'Enter known conditions, allergies, etc.',
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Risk Level Card
              _buildSectionCard(
                context,
                title: 'Risk Assessment',
                icon: Icons.warning_amber_rounded,
                accentColor: _getRiskColor(patient.riskLevel),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getRiskColor(patient.riskLevel).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getRiskIcon(patient.riskLevel),
                          color: _getRiskColor(patient.riskLevel),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getRiskLabel(patient.riskLevel),
                              style: TextStyle(
                                color: _getRiskColor(patient.riskLevel),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Level ${patient.riskLevel}/5',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tags Card
              if (patient.tags.isNotEmpty)
                _buildSectionCard(
                  context,
                  title: 'Tags & Labels',
                  icon: Icons.label_rounded,
                  accentColor: const Color(0xFF9B59B6),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: patient.tags.split(',').where((tag) => tag.trim().isNotEmpty).map((tag) {
                        final tagColor = _getTagColor(tag.trim());
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: tagColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            tag.trim(),
                            style: TextStyle(
                              color: tagColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              const SizedBox(height: 100), // Space for save button
            ],
          ),
        ),
        
        // Save Button (appears when changes are made)
        if (_hasChanges)
          Positioned(
            bottom: 16,
            left: 20,
            right: 76,
            child: Material(
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _isSaving ? null : _saveChanges,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaving)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isSaving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _getRiskIcon(int riskLevel) {
    if (riskLevel <= 2) return Icons.check_circle_rounded;
    if (riskLevel <= 4) return Icons.warning_rounded;
    return Icons.error_rounded;
  }

  Future<List<Appointment>> _getPatientAppointments(DoctorDatabase db) async {
    final allAppointments = await db.getAllAppointments();
    return allAppointments.where((a) => a.patientId == widget.patient.id).toList();
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;
    
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? AppColors.darkDivider.withValues(alpha: 0.5)
              : AppColors.divider.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simpler Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Icon(
                icon, 
                size: 20, 
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditableInfoRow(IconData icon, String label, TextEditingController controller, {String? hint, TextInputType? keyboardType, int maxLines = 1}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
                child: Icon(
                  icon, 
                  size: 20, 
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller,
                      keyboardType: keyboardType,
                      maxLines: maxLines,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: hint ?? 'Enter $label',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.5) : AppColors.textSecondary.withValues(alpha: 0.5),
                          fontWeight: FontWeight.normal,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
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
      },
    );
  }

  Widget _buildConditionItem(BuildContext context, String condition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              condition,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => FutureBuilder(
        future: Future.wait([
          _getPatientAppointments(db),
          db.getPrescriptionsForPatient(widget.patient.id),
          db.getMedicalRecordsForPatient(widget.patient.id),
        ]),
        builder: (context, snapshot) {
          int appointmentCount = 0;
          int prescriptionCount = 0;
          int recordCount = 0;
          int upcomingVisits = 0;

          if (snapshot.hasData) {
            final data = snapshot.data!;
            final appointments = data[0] as List;
            appointmentCount = appointments.length;
            upcomingVisits = appointments.where((a) => 
              (a as Appointment).appointmentDateTime.isAfter(DateTime.now()) &&
              a.status.toLowerCase() != 'cancelled',
            ).length;
            prescriptionCount = (data[1] as List).length;
            recordCount = (data[2] as List).length;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Grid - 2x2 layout
              Row(
                children: [
                  Expanded(
                    child: _buildModernStatCard(
                      context,
                      label: 'Total Visits',
                      value: appointmentCount.toString(),
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      subtitle: upcomingVisits > 0 ? '$upcomingVisits upcoming' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernStatCard(
                      context,
                      label: 'Prescriptions',
                      value: prescriptionCount.toString(),
                      icon: Icons.medication_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModernStatCard(
                      context,
                      label: 'Records',
                      value: recordCount.toString(),
                      icon: Icons.folder_rounded,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernStatCard(
                      context,
                      label: 'Risk Level',
                      value: _getRiskLabel(widget.patient.riskLevel).split(' ')[0],
                      icon: Icons.warning_amber_rounded,
                      color: _getRiskColor(widget.patient.riskLevel),
                      isRisk: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Quick Actions Section
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActionsGrid(context),
            ],
          );
        },
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildModernStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    bool isRisk = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (isRisk)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final actions = [
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Appointment',
        'color': AppColors.primary,
        'onTap': () => _scheduleAppointment(context),
      },
      {
        'icon': Icons.medication_rounded,
        'label': 'Prescription',
        'color': AppColors.accent,
        'onTap': () => _createPrescription(context),
      },
      {
        'icon': Icons.note_add_rounded,
        'label': 'Add Record',
        'color': AppColors.warning,
        'onTap': () => _showSelectRecordTypeScreen(context),
      },
      {
        'icon': Icons.receipt_long_rounded,
        'label': 'Invoice',
        'color': const Color(0xFF6366F1),
        'onTap': () => _createInvoice(context),
      },
      {
        'icon': Icons.psychology_rounded,
        'label': 'Psych Eval',
        'color': const Color(0xFF9B59B6),
        'onTap': () => _addMedicalRecord(context, 'psychiatric_assessment'),
      },
      {
        'icon': Icons.air_rounded,
        'label': 'Pulmonary',
        'color': const Color(0xFF00ACC1),
        'onTap': () => _addMedicalRecord(context, 'pulmonary_evaluation'),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // First row - 3 actions
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: actions[i]['icon']! as IconData,
                    label: actions[i]['label']! as String,
                    color: actions[i]['color']! as Color,
                    onTap: actions[i]['onTap']! as VoidCallback,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Second row - 3 actions
          Row(
            children: [
              for (int i = 3; i < 6; i++) ...[
                if (i > 3) const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: actions[i]['icon']! as IconData,
                    label: actions[i]['label']! as String,
                    color: actions[i]['color']! as Color,
                    onTap: actions[i]['onTap']! as VoidCallback,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final isUpcoming = appointment.appointmentDateTime.isAfter(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    switch (appointment.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
      case 'cancelled':
        statusColor = AppColors.error;
      default:
        statusColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAppointmentDetails(context, appointment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isUpcoming ? AppColors.primary : AppColors.textSecondary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: isUpcoming ? AppColors.primary : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormat.format(appointment.appointmentDateTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${timeFormat.format(appointment.appointmentDateTime)} • ${appointment.durationMinutes} min',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        appointment.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (appointment.reason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.notes_outlined,
                        size: 18,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.reason,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, Prescription prescription) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<dynamic> medications = [];

    try {
      medications = jsonDecode(prescription.itemsJson) as List;
    } catch (e) {
      // Handle parsing error
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showPrescriptionDetails(context, prescription, medications);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medication_rounded,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prescription #${prescription.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(prescription.createdAt),
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (prescription.isRefillable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh, size: 14, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              'Refillable',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (medications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '${medications.length} medication${medications.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: medications.take(3).map((med) {
                      final name = med['name'] ?? 'Unknown';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          name as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (prescription.instructions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prescription.instructions,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.accent.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(icon, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDial(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'patient_view_fab',
        onPressed: () {
          _showModernActionSheet(context);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }

  void _showModernActionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action list
            _buildActionListTile(
              context,
              icon: Icons.calendar_today_rounded,
              title: 'Schedule Appointment',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _scheduleAppointment(context);
              },
            ),
            _buildActionListTile(
              context,
              icon: Icons.medication_rounded,
              title: 'Create Prescription',
              color: AppColors.accent,
              onTap: () {
                Navigator.pop(context);
                _createPrescription(context);
              },
            ),
            _buildActionListTile(
              context,
              icon: Icons.note_add_rounded,
              title: 'Add Medical Record',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                _showSelectRecordTypeScreen(context);
              },
            ),
            _buildActionListTile(
              context,
              icon: Icons.receipt_long_rounded,
              title: 'Create Invoice',
              color: const Color(0xFF6366F1),
              onTap: () {
                Navigator.pop(context);
                _createInvoice(context);
              },
            ),
            _buildActionListTile(
              context,
              icon: Icons.psychology_rounded,
              title: 'Quick Psychiatric Assessment',
              color: const Color(0xFF9B59B6),
              onTap: () {
                Navigator.pop(context);
                _addMedicalRecord(context, 'psychiatric_assessment');
              },
            ),
            _buildActionListTile(
              context,
              icon: Icons.psychology_alt_rounded,
              title: 'Comprehensive Psychiatric Assessment',
              color: const Color(0xFF8E44AD),
              onTap: () {
                Navigator.pop(context);
                _openDetailedPsychiatricAssessment(context);
              },
            ),
            _buildActionListTile(
              context,
              icon: Icons.phone_rounded,
              title: 'Call Patient',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                if (widget.patient.phone.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${widget.patient.phone}...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: Icon(Icons.chevron_right, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
      onTap: onTap,
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              context,
              Icons.print_outlined,
              'Print Patient Card',
              AppColors.textSecondary,
              () => Navigator.pop(context),
            ),
            _buildActionTile(
              context,
              Icons.share_outlined,
              'Share Medical Records',
              AppColors.textSecondary,
              () => Navigator.pop(context),
            ),
            _buildActionTile(
              context,
              Icons.archive_outlined,
              'Archive Patient',
              AppColors.warning,
              () => Navigator.pop(context),
            ),
            _buildActionTile(
              context,
              Icons.delete_outline,
              'Delete Patient',
              AppColors.error,
              () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPrescriptionDetails(
    BuildContext context,
    Prescription prescription,
    List<dynamic> medications,
  ) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header with back button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription #${prescription.id}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateFormat.format(prescription.createdAt),
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (prescription.isRefillable)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, size: 12, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      'Refillable',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPrescriptionStat(
                      Icons.medication,
                      '${medications.length}',
                      'Medications',
                      AppColors.accent,
                      isDark,
                    ),
                    Container(width: 1, height: 40, color: (isDark ? AppColors.darkDivider : AppColors.divider)),
                    _buildPrescriptionStat(
                      Icons.refresh,
                      prescription.isRefillable ? 'Yes' : 'No',
                      'Refillable',
                      prescription.isRefillable ? AppColors.success : AppColors.textSecondary,
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Medications title
              Row(
                children: [
                  const Icon(Icons.medication_outlined, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Medications (${medications.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Medications list
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ...medications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final med = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Medication number and name
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    (med['name'] as String?) ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            // Medication details grid
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                if (med['dosage'] != null && med['dosage'].toString().isNotEmpty)
                                  _buildMedDetailChip(Icons.medical_services_outlined, 'Dosage', med['dosage'].toString(), isDark),
                                if (med['frequency'] != null && med['frequency'].toString().isNotEmpty)
                                  _buildMedDetailChip(Icons.schedule_outlined, 'Frequency', med['frequency'].toString(), isDark),
                                if (med['duration'] != null && med['duration'].toString().isNotEmpty)
                                  _buildMedDetailChip(Icons.timer_outlined, 'Duration', med['duration'].toString(), isDark),
                                if (med['route'] != null && med['route'].toString().isNotEmpty)
                                  _buildMedDetailChip(Icons.alt_route, 'Route', med['route'].toString(), isDark),
                                if (med['quantity'] != null && med['quantity'].toString().isNotEmpty)
                                  _buildMedDetailChip(Icons.inventory_2_outlined, 'Quantity', med['quantity'].toString(), isDark),
                              ],
                            ),
                            // Special instructions for this medication
                            if (med['notes'] != null && med['notes'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.note_outlined, size: 16, color: AppColors.info),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        med['notes'].toString(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                    }),
                    // Doctor's instructions
                    if (prescription.instructions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.assignment_outlined, color: AppColors.info, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Doctor's Instructions",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                prescription.instructions,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final doctorSettings = ref.read(doctorSettingsProvider);
                              final profile = doctorSettings.profile;
                              await WhatsAppService.sharePrescription(
                                patient: widget.patient,
                                prescription: prescription,
                                doctorName: profile.displayName,
                                clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
                                clinicPhone: profile.clinicPhone,
                              );
                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                            label: const Text('WhatsApp'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF25D366),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final doctorSettings = ref.read(doctorSettingsProvider);
                              final profile = doctorSettings.profile;
                              Navigator.pop(context);
                              await PdfService.sharePrescriptionPdf(
                                patient: widget.patient,
                                prescription: prescription,
                                doctorName: profile.displayName,
                                clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
                                clinicPhone: profile.clinicPhone,
                                clinicAddress: profile.clinicAddress,
                                signatureData: (profile.signatureData?.isNotEmpty ?? false) ? profile.signatureData : null,
                              );
                            },
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Share PDF'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionStat(IconData icon, String value, String label, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMedDetailChip(IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground.withValues(alpha: 0.5) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, Appointment appointment) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUpcoming = appointment.appointmentDateTime.isAfter(DateTime.now());
    final isPast = appointment.appointmentDateTime.isBefore(DateTime.now());

    Color statusColor;
    IconData statusIcon;
    switch (appointment.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
      case 'no-show':
        statusColor = AppColors.warning;
        statusIcon = Icons.person_off;
      case 'confirmed':
        statusColor = AppColors.primary;
        statusIcon = Icons.verified;
      default:
        statusColor = AppColors.info;
        statusIcon = Icons.schedule;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header with back button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today_rounded,
                      color: isUpcoming ? AppColors.primary : statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointment Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                appointment.status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Date & Time Card
                      Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.1),
                            (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (isUpcoming ? AppColors.primary : statusColor).withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildAppointmentInfoTile(
                                  Icons.calendar_month,
                                  'Date',
                                  dateFormat.format(appointment.appointmentDateTime),
                                  isUpcoming ? AppColors.primary : statusColor,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAppointmentInfoTile(
                                  Icons.access_time,
                                  'Time',
                                  timeFormat.format(appointment.appointmentDateTime),
                                  isUpcoming ? AppColors.primary : statusColor,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildAppointmentInfoTile(
                                  Icons.timer_outlined,
                                  'Duration',
                                  '${appointment.durationMinutes} minutes',
                                  isUpcoming ? AppColors.primary : statusColor,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Reason for visit
                    if (appointment.reason.isNotEmpty) ...[
                      _buildAppointmentSection(
                        context,
                        'Reason for Visit',
                        Icons.medical_services_outlined,
                        AppColors.accent,
                        isDark,
                        child: Text(
                          appointment.reason,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Notes
                    if (appointment.notes.isNotEmpty) ...[
                      _buildAppointmentSection(
                        context,
                        'Notes',
                        Icons.note_alt_outlined,
                        AppColors.info,
                        isDark,
                        child: Text(
                          appointment.notes,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Reminder info
                    if (appointment.reminderAt != null) ...[
                      _buildAppointmentSection(
                        context,
                        'Reminder',
                        Icons.notifications_outlined,
                        AppColors.warning,
                        isDark,
                        child: Row(
                          children: [
                            const Icon(Icons.alarm, size: 18, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d, yyyy h:mm a').format(appointment.reminderAt!),
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Time info (relative)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPast ? Icons.history : Icons.upcoming,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getRelativeTimeText(appointment.appointmentDateTime),
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    if (isUpcoming && appointment.status.toLowerCase() != 'cancelled') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _rescheduleAppointment(appointment);
                              },
                              icon: const Icon(Icons.edit_calendar),
                              label: const Text('Reschedule'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _cancelAppointment(appointment);
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isUpcoming && appointment.status.toLowerCase() == 'scheduled')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmAppointment(appointment);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirm Appointment'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    if (isPast && appointment.status.toLowerCase() != 'completed')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _markAppointmentCompleted(appointment);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Mark as Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentInfoTile(IconData icon, String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppointmentSection(BuildContext context, String title, IconData icon, Color color, bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _getRelativeTimeText(DateTime dateTime) {
    final now = DateTime.now();
    final diff = dateTime.difference(now);
    
    if (diff.isNegative) {
      final absDiff = diff.abs();
      if (absDiff.inDays > 30) {
        return 'This appointment was ${(absDiff.inDays / 30).floor()} month(s) ago';
      } else if (absDiff.inDays > 0) {
        return 'This appointment was ${absDiff.inDays} day(s) ago';
      } else if (absDiff.inHours > 0) {
        return 'This appointment was ${absDiff.inHours} hour(s) ago';
      } else {
        return 'This appointment was ${absDiff.inMinutes} minute(s) ago';
      }
    } else {
      if (diff.inDays > 30) {
        return 'Scheduled in ${(diff.inDays / 30).floor()} month(s)';
      } else if (diff.inDays > 0) {
        return 'Scheduled in ${diff.inDays} day(s)';
      } else if (diff.inHours > 0) {
        return 'Scheduled in ${diff.inHours} hour(s)';
      } else {
        return 'Scheduled in ${diff.inMinutes} minute(s)';
      }
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _scheduleAppointment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddAppointmentScreen(preselectedPatient: widget.patient),
      ),
    );
  }

  void _createPrescription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddPrescriptionScreen(preselectedPatient: widget.patient),
      ),
    );
  }

  void _createInvoice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddInvoiceScreen(
          patientId: widget.patient.id,
          patientName: '${widget.patient.firstName} ${widget.patient.lastName}',
        ),
      ),
    );
  }

  // ============ Appointment Action Methods ============

  Future<void> _rescheduleAppointment(Appointment appointment) async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: appointment.appointmentDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select new appointment date',
    );

    if (newDate == null || !mounted) return;

    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointment.appointmentDateTime),
      helpText: 'Select new appointment time',
    );

    if (newTime == null || !mounted) return;

    final newDateTime = DateTime(
      newDate.year,
      newDate.month,
      newDate.day,
      newTime.hour,
      newTime.minute,
    );

    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.when(
        data: (db) => db,
        loading: () => throw Exception('Database loading'),
        error: (e, _) => throw e,
      );

      // Create updated appointment
      final updatedAppointment = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        appointmentDateTime: newDateTime,
        durationMinutes: appointment.durationMinutes,
        reason: appointment.reason,
        status: appointment.status,
        reminderAt: appointment.reminderAt,
        notes: appointment.notes,
        createdAt: appointment.createdAt,
      );

      await db.update(db.appointments).replace(updatedAppointment);
      
      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Appointment rescheduled to ${DateFormat('MMM d, yyyy h:mm a').format(newDateTime)}'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rescheduling appointment: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Cancel Appointment'),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel the appointment on ${DateFormat('MMMM d, yyyy').format(appointment.appointmentDateTime)} at ${DateFormat('h:mm a').format(appointment.appointmentDateTime)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.when(
        data: (db) => db,
        loading: () => throw Exception('Database loading'),
        error: (e, _) => throw e,
      );

      // Create updated appointment with cancelled status
      final updatedAppointment = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        appointmentDateTime: appointment.appointmentDateTime,
        durationMinutes: appointment.durationMinutes,
        reason: appointment.reason,
        status: 'cancelled',
        reminderAt: appointment.reminderAt,
        notes: appointment.notes,
        createdAt: appointment.createdAt,
      );

      await db.update(db.appointments).replace(updatedAppointment);
      
      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Appointment cancelled'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling appointment: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmAppointment(Appointment appointment) async {
    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.when(
        data: (db) => db,
        loading: () => throw Exception('Database loading'),
        error: (e, _) => throw e,
      );

      // Create updated appointment with confirmed status
      final updatedAppointment = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        appointmentDateTime: appointment.appointmentDateTime,
        durationMinutes: appointment.durationMinutes,
        reason: appointment.reason,
        status: 'confirmed',
        reminderAt: appointment.reminderAt,
        notes: appointment.notes,
        createdAt: appointment.createdAt,
      );

      await db.update(db.appointments).replace(updatedAppointment);
      
      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Appointment confirmed'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming appointment: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markAppointmentCompleted(Appointment appointment) async {
    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.when(
        data: (db) => db,
        loading: () => throw Exception('Database loading'),
        error: (e, _) => throw e,
      );

      // Create updated appointment with completed status
      final updatedAppointment = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        appointmentDateTime: appointment.appointmentDateTime,
        durationMinutes: appointment.durationMinutes,
        reason: appointment.reason,
        status: 'completed',
        reminderAt: appointment.reminderAt,
        notes: appointment.notes,
        createdAt: appointment.createdAt,
      );

      await db.update(db.appointments).replace(updatedAppointment);
      
      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Appointment marked as completed'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating appointment: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Custom painter for header background pattern
class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw subtle curved lines
    for (int i = 0; i < 5; i++) {
      paint.color = Colors.white.withValues(alpha: 0.03 + (i * 0.01));
      
      final startY = size.height * (0.2 + (i * 0.15));
      final path = Path()
        ..moveTo(0, startY)
        ..quadraticBezierTo(
          size.width * 0.25,
          startY - 30 + (i * 10),
          size.width * 0.5,
          startY + 20,
        )
        ..quadraticBezierTo(
          size.width * 0.75,
          startY + 50 - (i * 8),
          size.width,
          startY - 10,
        );
      
      canvas.drawPath(path, paint);
    }

    // Add subtle dots
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (size.width / 20) * i + 10;
      final y = (size.height / 8) * (i % 4) + 50;
      canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
