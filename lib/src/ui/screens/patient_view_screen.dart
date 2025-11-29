import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../theme/app_theme.dart';
import '../../services/whatsapp_service.dart';
import '../../services/pdf_service.dart';
import '../widgets/patient_avatar.dart';
import 'add_appointment_screen.dart';
import 'add_invoice_screen.dart';
import 'add_prescription_screen.dart';
import 'add_medical_record_screen.dart';

class PatientViewScreen extends ConsumerStatefulWidget {
  final Patient patient;

  const PatientViewScreen({super.key, required this.patient});

  @override
  ConsumerState<PatientViewScreen> createState() => _PatientViewScreenState();
}

class _PatientViewScreenState extends ConsumerState<PatientViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  String _getInitials(String firstName, String lastName) {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.warning,
      AppColors.info,
      const Color(0xFF9B59B6),
      const Color(0xFFE74C3C),
    ];
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final riskColor = _getRiskColor(patient.riskLevel);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  tooltip: 'WhatsApp',
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
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit patient feature coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    _showOptionsMenu(context);
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Avatar with photo support
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: PatientAvatarCircle(
                            patientId: patient.id,
                            firstName: patient.firstName,
                            lastName: patient.lastName,
                            size: 90,
                            editable: true,
                            onPhotoChanged: () => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          '${patient.firstName} ${patient.lastName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Risk Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: riskColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getRiskLabel(patient.riskLevel),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Container(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'History'),
                          Tab(text: 'Appointments'),
                          Tab(text: 'Prescriptions'),
                        ],
                      ),
                    );
                  },
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
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(context),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final patient = widget.patient;
    final dateFormat = DateFormat('MMM d, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information Card
          _buildSectionCard(
            context,
            title: 'Contact Information',
            icon: Icons.contact_phone_outlined,
            children: [
              _buildInfoRow(Icons.phone_outlined, 'Phone', patient.phone.isNotEmpty ? patient.phone : 'Not provided'),
              _buildInfoRow(Icons.email_outlined, 'Email', patient.email.isNotEmpty ? patient.email : 'Not provided'),
              _buildInfoRow(Icons.location_on_outlined, 'Address', patient.address.isNotEmpty ? patient.address : 'Not provided'),
            ],
          ),
          const SizedBox(height: 16),

          // Personal Information Card
          _buildSectionCard(
            context,
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              _buildInfoRow(
                Icons.cake_outlined,
                'Date of Birth',
                patient.dateOfBirth != null ? dateFormat.format(patient.dateOfBirth!) : 'Not provided',
              ),
              if (patient.dateOfBirth != null)
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Age',
                  '${_calculateAge(patient.dateOfBirth!)} years old',
                ),
              _buildInfoRow(
                Icons.event_outlined,
                'Patient Since',
                dateFormat.format(patient.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tags Card
          if (patient.tags.isNotEmpty)
            _buildSectionCard(
              context,
              title: 'Tags',
              icon: Icons.label_outline,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: patient.tags.split(',').map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        tag.trim(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Quick Stats
          _buildQuickStats(context),
        ],
      ),
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

                // Quick Add Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAddButton(
                        context,
                        icon: Icons.psychology,
                        label: 'Psychiatric\nAssessment',
                        color: AppColors.primary,
                        onTap: () => _addMedicalRecord(context, 'psychiatric_assessment'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAddButton(
                        context,
                        icon: Icons.medical_services_outlined,
                        label: 'General\nConsultation',
                        color: AppColors.accent,
                        onTap: () => _addMedicalRecord(context, 'general'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAddButton(
                        context,
                        icon: Icons.science_outlined,
                        label: 'Lab\nResult',
                        color: AppColors.warning,
                        onTap: () => _addMedicalRecord(context, 'lab_result'),
                      ),
                    ),
                  ],
                ),
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
      case 'psychiatric_assessment':
        recordIcon = Icons.psychology;
        recordColor = AppColors.primary;
        break;
      case 'lab_result':
        recordIcon = Icons.science_outlined;
        recordColor = AppColors.warning;
        break;
      case 'imaging':
        recordIcon = Icons.image_outlined;
        recordColor = AppColors.info;
        break;
      case 'procedure':
        recordIcon = Icons.healing_outlined;
        recordColor = AppColors.accent;
        break;
      case 'follow_up':
        recordIcon = Icons.event_repeat;
        recordColor = AppColors.success;
        break;
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
            border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                            color: recordColor.withOpacity(0.1),
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
                            color: recordColor.withOpacity(0.1),
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
                          _buildRiskChip('Suicidal', data['risk_assessment']['suicidal_risk'] ?? 'None'),
                          const SizedBox(width: 8),
                          _buildRiskChip('Homicidal', data['risk_assessment']['homicidal_risk'] ?? 'None'),
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
        break;
      case 'moderate':
        chipColor = AppColors.warning;
        break;
      case 'low':
        chipColor = AppColors.info;
        break;
      default:
        chipColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.3)),
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

  Widget _buildEmptyHistoryCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
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

  void _addMedicalRecord(BuildContext context, String recordType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicalRecordScreen(
          preselectedPatient: widget.patient,
          initialRecordType: recordType,
        ),
      ),
    );
    if (result == true) {
      setState(() {}); // Refresh the list
    }
  }

  void _showMedicalRecordDetails(BuildContext context, MedicalRecord record, Map<String, dynamic> data) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get record type icon and color
    IconData recordIcon;
    Color recordColor;
    switch (record.recordType) {
      case 'psychiatric_assessment':
        recordIcon = Icons.psychology;
        recordColor = AppColors.primary;
        break;
      case 'lab_result':
        recordIcon = Icons.science_outlined;
        recordColor = AppColors.warning;
        break;
      case 'imaging':
        recordIcon = Icons.image_outlined;
        recordColor = AppColors.info;
        break;
      case 'procedure':
        recordIcon = Icons.healing_outlined;
        recordColor = AppColors.accent;
        break;
      default:
        recordIcon = Icons.medical_services_outlined;
        recordColor = AppColors.primary;
    }

    showModalBottomSheet(
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
                        color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5),
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
                      color: recordColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      recordIcon,
                      color: recordColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: recordColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getRecordTypeLabel(record.recordType),
                                style: TextStyle(
                                  color: recordColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateFormat.format(record.recordDate),
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                fontSize: 13,
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
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Description if available
                      if (record.description.isNotEmpty)
                        _buildDetailSection('Description', record.description, Icons.description_outlined, isDark),
                    
                    // Always show diagnosis if available
                    if (record.diagnosis.isNotEmpty)
                      _buildDetailSection('Diagnosis', record.diagnosis, Icons.medical_information_outlined, isDark),
                    
                    // Always show treatment if available
                    if (record.treatment.isNotEmpty)
                      _buildDetailSection('Treatment', record.treatment, Icons.healing_outlined, isDark),
                    
                    // Doctor's notes
                    if (record.doctorNotes.isNotEmpty)
                      _buildDetailSection("Doctor's Notes", record.doctorNotes, Icons.note_alt_outlined, isDark),
                    
                    // ===== PSYCHIATRIC ASSESSMENT DATA =====
                    if (record.recordType == 'psychiatric_assessment') ...[
                      if (data['chiefComplaint'] != null && data['chiefComplaint'].toString().isNotEmpty)
                        _buildDetailSection('Chief Complaint', data['chiefComplaint'].toString(), Icons.report_outlined, isDark),
                      if (data['symptoms'] != null && data['symptoms'].toString().isNotEmpty)
                        _buildDetailSection('Presenting Symptoms', data['symptoms'].toString(), Icons.sick_outlined, isDark),
                      if (data['hopi'] != null && data['hopi'].toString().isNotEmpty)
                        _buildDetailSection('History of Present Illness', data['hopi'].toString(), Icons.history, isDark),
                      if (data['moodAssessment'] != null)
                        _buildDetailSection('Mood Assessment', data['moodAssessment'].toString(), Icons.mood, isDark),
                      if (data['anxietyLevel'] != null)
                        _buildDetailSection('Anxiety Level', data['anxietyLevel'].toString(), Icons.psychology_alt, isDark),
                      if (data['sleepQuality'] != null)
                        _buildDetailSection('Sleep Quality', data['sleepQuality'].toString(), Icons.bedtime, isDark),
                      if (data['appetiteChanges'] != null)
                        _buildDetailSection('Appetite Changes', data['appetiteChanges'].toString(), Icons.restaurant, isDark),
                      if (data['substanceUse'] != null)
                        _buildDetailSection('Substance Use', data['substanceUse'].toString(), Icons.local_bar, isDark),
                      // PHQ-9 and GAD-7 scores
                      if (data['phq9Score'] != null || data['gad7Score'] != null)
                        _buildScoresCard(data, isDark),
                      // MSE (Mental State Examination)
                      if (data['mse'] != null && data['mse'] is Map) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Mental State Examination',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMseGrid(data['mse'] as Map<String, dynamic>, isDark),
                      ],
                      // Risk Assessment
                      if (data['risk_assessment'] != null && data['risk_assessment'] is Map)
                        _buildRiskAssessmentCard(data['risk_assessment'] as Map<String, dynamic>, isDark),
                      if (data['suicidalIdeation'] != null)
                        _buildDetailSection('Suicidal Ideation', data['suicidalIdeation'].toString(), Icons.warning_amber, isDark),
                    ],
                    
                    // ===== LAB RESULT DATA =====
                    if (record.recordType == 'lab_result') ...[
                      _buildLabResultsCard(data, isDark),
                    ],
                    
                    // ===== IMAGING DATA =====
                    if (record.recordType == 'imaging') ...[
                      _buildImagingCard(data, isDark),
                    ],
                    
                    // ===== PROCEDURE DATA =====
                    if (record.recordType == 'procedure') ...[
                      _buildProcedureCard(data, isDark),
                    ],
                    
                    // ===== GENERAL RECORD DATA =====
                    if (record.recordType == 'general' && data.isNotEmpty) ...[
                      _buildGenericDataCard(data, isDark),
                    ],
                    
                    // Vitals if present (common across types)
                    if (data['vitals'] != null && data['vitals'] is Map)
                      _buildVitalsCard(data['vitals'] as Map<String, dynamic>, isDark),
                    
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
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
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

  Widget _buildVitalsCard(Map<String, dynamic> vitals, [bool isDark = false]) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: AppColors.info, size: 20),
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
        color: AppColors.info.withOpacity(0.15),
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
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: AppColors.primary, size: 20),
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
        break;
      case 'moderately severe':
      case 'moderate':
        severityColor = AppColors.warning;
        break;
      case 'mild':
        severityColor = AppColors.info;
        break;
      default:
        severityColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: severityColor.withOpacity(0.3)),
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
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: AppColors.warning, size: 20),
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
          }).toList(),
        ],
      ),
    );
  }

  String _formatLabLabel(String key) {
    // Convert camelCase to readable format
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
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
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image_outlined, color: AppColors.info, size: 20),
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
          }).toList(),
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
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing, color: AppColors.accent, size: 20),
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
          }).toList(),
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
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
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
          }).toList(),
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

  Future<List<Appointment>> _getPatientAppointments(DoctorDatabase db) async {
    final allAppointments = await db.getAllAppointments();
    return allAppointments.where((a) => a.patientId == widget.patient.id).toList();
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
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

  Widget _buildConditionItem(BuildContext context, String condition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
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

  Widget _buildInstructionItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final dbAsync = ref.watch(doctorDbProvider);

    return dbAsync.when(
      data: (db) => FutureBuilder(
        future: Future.wait([
          _getPatientAppointments(db),
          db.getPrescriptionsForPatient(widget.patient.id),
        ]),
        builder: (context, snapshot) {
          int appointmentCount = 0;
          int prescriptionCount = 0;

          if (snapshot.hasData) {
            final data = snapshot.data!;
            appointmentCount = (data[0] as List).length;
            prescriptionCount = (data[1] as List).length;
          }

          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Appointments',
                  appointmentCount.toString(),
                  Icons.calendar_today_outlined,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Prescriptions',
                  prescriptionCount.toString(),
                  Icons.medication_outlined,
                  AppColors.accent,
                ),
              ),
            ],
          );
        },
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
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
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                            .withOpacity(0.1),
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
                        color: statusColor.withOpacity(0.1),
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
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                        color: AppColors.accent.withOpacity(0.1),
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
                          color: AppColors.success.withOpacity(0.1),
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
                          color: AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          name,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDial(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'patient_view_fab',
      onPressed: () {
        showModalBottomSheet(
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
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _buildActionTile(
                  context,
                  Icons.calendar_today_outlined,
                  'Schedule Appointment',
                  AppColors.primary,
                  () {
                    Navigator.pop(context);
                    _scheduleAppointment(context);
                  },
                ),
                _buildActionTile(
                  context,
                  Icons.medication_outlined,
                  'Create Prescription',
                  AppColors.accent,
                  () {
                    Navigator.pop(context);
                    _createPrescription(context);
                  },
                ),
                _buildActionTile(
                  context,
                  Icons.note_add_outlined,
                  'Add Medical Record',
                  AppColors.warning,
                  () {
                    Navigator.pop(context);
                    _addMedicalRecord(context, 'general');
                  },
                ),
                _buildActionTile(
                  context,
                  Icons.receipt_long_outlined,
                  'Create Invoice',
                  const Color(0xFF6366F1),
                  () {
                    Navigator.pop(context);
                    _createInvoice(context);
                  },
                ),
                _buildActionTile(
                  context,
                  Icons.psychology_outlined,
                  'Psychiatric Assessment',
                  AppColors.primary,
                  () {
                    Navigator.pop(context);
                    _addMedicalRecord(context, 'psychiatric_assessment');
                  },
                ),
                _buildActionTile(
                  context,
                  Icons.phone_outlined,
                  'Call Patient',
                  AppColors.info,
                  () {
                    Navigator.pop(context);
                    if (widget.patient.phone.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling ${widget.patient.phone}...'),
                          behavior: SnackBarBehavior.floating,
                          action: SnackBarAction(
                            label: 'OK',
                            onPressed: () {},
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No phone number available for this patient'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add),
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
          color: color.withOpacity(0.1),
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
    showModalBottomSheet(
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

    showModalBottomSheet(
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
                        color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5),
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
                      color: AppColors.accent.withOpacity(0.1),
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
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, size: 12, color: AppColors.success),
                                    const SizedBox(width: 4),
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
                    colors: [AppColors.accent.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
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
                  Icon(Icons.medication_outlined, color: AppColors.accent, size: 20),
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
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    med['name'] ?? 'Unknown',
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
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.note_outlined, size: 16, color: AppColors.info),
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
                    }).toList(),
                    // Doctor's instructions
                    if (prescription.instructions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.assignment_outlined, color: AppColors.info, size: 20),
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
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withOpacity(0.3)),
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
        color: isDark ? AppColors.darkBackground.withOpacity(0.5) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5)),
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
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case 'no-show':
        statusColor = AppColors.warning;
        statusIcon = Icons.person_off;
        break;
      case 'confirmed':
        statusColor = AppColors.primary;
        statusIcon = Icons.verified;
        break;
      default:
        statusColor = AppColors.info;
        statusIcon = Icons.schedule;
    }

    showModalBottomSheet(
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
                        color: (isDark ? AppColors.darkDivider : AppColors.divider).withOpacity(0.5),
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
                      color: (isUpcoming ? AppColors.primary : statusColor).withOpacity(0.1),
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
                            color: statusColor.withOpacity(0.1),
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
                            (isUpcoming ? AppColors.primary : statusColor).withOpacity(0.1),
                            (isUpcoming ? AppColors.primary : statusColor).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: (isUpcoming ? AppColors.primary : statusColor).withOpacity(0.2)),
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
                            Icon(Icons.alarm, size: 18, color: AppColors.warning),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reschedule feature coming soon'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cancel feature coming soon'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Confirm feature coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mark as completed feature coming soon'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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
            color: color.withOpacity(0.15),
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
      MaterialPageRoute(
        builder: (_) => AddAppointmentScreen(preselectedPatient: widget.patient),
      ),
    );
  }

  void _createPrescription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPrescriptionScreen(preselectedPatient: widget.patient),
      ),
    );
  }

  void _createInvoice(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddInvoiceScreen(
          patientId: widget.patient.id,
          patientName: '${widget.patient.firstName} ${widget.patient.lastName}',
        ),
      ),
    );
  }
}
