// Patient View - Overview Tab
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../db/doctor_db.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../follow_ups_screen.dart';
import '../lab_results_screen.dart';
import '../treatment_outcomes_screen.dart';
import '../treatment_progress_screen.dart';
import '../vital_signs_screen.dart';
import 'patient_view_widgets.dart';

class PatientOverviewTab extends ConsumerStatefulWidget {
  const PatientOverviewTab({
    super.key,
    required this.patient,
    required this.isEditing,
    required this.onToggleEdit,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.medicalHistoryController,
    required this.tagsController,
    required this.hasChanges,
    required this.isSaving,
    required this.onSave,
    required this.onDiscard,
  });

  final Patient patient;
  final bool isEditing;
  final VoidCallback onToggleEdit;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController medicalHistoryController;
  final TextEditingController tagsController;
  final bool hasChanges;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  ConsumerState<PatientOverviewTab> createState() => _PatientOverviewTabState();
}

class _PatientOverviewTabState extends ConsumerState<PatientOverviewTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final patient = widget.patient;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Info Card
          _buildContactInfoCard(isDark, textColor, secondaryColor, cardColor, borderColor),
          const SizedBox(height: 20),
          
          // Medical History
          _buildMedicalHistorySection(isDark, textColor, cardColor, borderColor),
          const SizedBox(height: 20),
          
          // Clinical Quick Actions
          _buildClinicalActionsSection(isDark, textColor),
          const SizedBox(height: 20),
          
          // Edit Profile Section (expandable)
          if (widget.isEditing)
            _buildEditProfileSection(isDark, textColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(bool isDark, Color textColor, Color secondaryColor, Color cardColor, Color borderColor) {
    final patient = widget.patient;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.contact_phone_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  widget.isEditing ? Icons.close : Icons.edit,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: widget.onToggleEdit,
                tooltip: widget.isEditing ? 'Cancel' : 'Edit',
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow(Icons.phone, 'Phone', patient.phone.isNotEmpty ? patient.phone : 'Not provided', secondaryColor, textColor),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email, 'Email', patient.email.isNotEmpty ? patient.email : 'Not provided', secondaryColor, textColor),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Address', patient.address.isNotEmpty ? patient.address : 'Not provided', secondaryColor, textColor),
          if (patient.allergies.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.warning_amber, 'Allergies', patient.allergies, Colors.orange, textColor),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalHistorySection(bool isDark, Color textColor, Color cardColor, Color borderColor) {
    final patient = widget.patient;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
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
      ],
    );
  }

  Widget _buildClinicalActionsSection(bool isDark, Color textColor) {
    final patient = widget.patient;
    final patientName = '${patient.firstName} ${patient.lastName}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        QuickActionCard(
          icon: Icons.trending_up_rounded,
          title: 'Treatment Progress',
          subtitle: 'View sessions, medications & goals',
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
      ],
    );
  }

  Widget _buildEditProfileSection(bool isDark, Color textColor, Color borderColor) {
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
        TextField(
          controller: widget.phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.medicalHistoryController,
          decoration: const InputDecoration(
            labelText: 'Medical History',
            prefixIcon: Icon(Icons.note_alt),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.tagsController,
          decoration: const InputDecoration(
            labelText: 'Tags (comma-separated)',
            prefixIcon: Icon(Icons.label),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.isSaving ? null : widget.onSave,
                icon: widget.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(widget.isSaving ? 'Saving...' : 'Save Changes'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: widget.onDiscard,
              child: const Text('Cancel'),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
