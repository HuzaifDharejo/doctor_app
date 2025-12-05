// Patient View - Overview Tab
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../db/doctor_db.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../diagnoses_screen.dart';
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

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: 100, // Extra padding for FAB
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Save/Cancel buttons when editing (at top for visibility)
          if (widget.isEditing && widget.hasChanges) ...[
            _buildSaveButtons(),
            const SizedBox(height: 16),
          ],
          
          // Contact Info Card
          _buildContactInfoCard(isDark, textColor, secondaryColor, cardColor, borderColor),
          const SizedBox(height: 20),
          
          // Medical History (with inline editing)
          _buildMedicalHistorySection(isDark, textColor, cardColor, borderColor),
          const SizedBox(height: 20),
          
          // Clinical Quick Actions (hide when editing for cleaner UI)
          if (!widget.isEditing)
            _buildClinicalActionsSection(isDark, textColor),
        ],
      ),
    );
  }

  Widget _buildSaveButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: widget.isSaving ? null : widget.onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: widget.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  widget.isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppColors.darkSurface 
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: OutlinedButton(
              onPressed: widget.onDiscard,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(bool isDark, Color textColor, Color secondaryColor, Color cardColor, Color borderColor) {
    final patient = widget.patient;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: widget.isEditing 
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2) 
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.contact_phone_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  widget.isEditing ? Icons.close : Icons.edit,
                  size: 20,
                  color: AppColors.primary,
                ),
                onPressed: widget.isEditing ? widget.onDiscard : widget.onToggleEdit,
                tooltip: widget.isEditing ? 'Cancel' : 'Edit',
              ),
            ],
          ),
          const Divider(height: 24),
          
          // Show editable fields or read-only display
          if (widget.isEditing) ...[
            _buildEditableField(
              controller: widget.phoneController,
              label: 'Phone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              controller: widget.emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              controller: widget.addressController,
              label: 'Address',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              controller: widget.tagsController,
              label: 'Tags (comma-separated)',
              icon: Icons.label,
            ),
          ] else ...[
            _buildInfoRow(Icons.phone, 'Phone', patient.phone.isNotEmpty ? patient.phone : 'Not provided', secondaryColor, textColor),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, 'Email', patient.email.isNotEmpty ? patient.email : 'Not provided', secondaryColor, textColor),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, 'Address', patient.address.isNotEmpty ? patient.address : 'Not provided', secondaryColor, textColor),
            if (patient.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.label, 'Tags', patient.tags, AppColors.primary, textColor),
            ],
          ],
          
          if (patient.allergies.isNotEmpty && !widget.isEditing) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.warning_amber, 'Allergies', patient.allergies, Colors.orange, textColor),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.history_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Medical History',
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
        if (widget.isEditing)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: widget.medicalHistoryController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter medical history...',
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              patient.medicalHistory.isEmpty
                  ? 'No medical history recorded'
                  : patient.medicalHistory,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
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
}
