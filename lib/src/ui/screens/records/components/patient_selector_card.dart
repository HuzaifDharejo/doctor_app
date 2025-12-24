import 'package:flutter/material.dart';
import '../../../../db/doctor_db.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/extensions/context_extensions.dart';

/// A reusable patient selector widget for medical record forms
/// Shows a dropdown of patients with basic info
class PatientSelectorCard extends StatelessWidget {
  const PatientSelectorCard({
    super.key,
    this.db,
    this.selectedPatientId,
    this.onChanged,
    this.onPatientSelected,  // Alternative callback that provides Patient object
    this.label = 'Patient',
    this.isRequired = true,
  });

  final DoctorDatabase? db;
  final int? selectedPatientId;
  final ValueChanged<int?>? onChanged;
  final ValueChanged<Patient?>? onPatientSelected;  // Alternative callback
  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If no db is provided, show error
    if (db == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Database not provided to PatientSelectorCard',
          style: TextStyle(color: AppColors.error),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.person_outline,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Patient Selector
        FutureBuilder<List<Patient>>(
          future: db!.getAllPatients(),
          builder: (context, snapshot) {
            final patients = snapshot.data ?? [];

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkDivider : AppColors.divider,
                ),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonFormField<int>(
                value: selectedPatientId,
                decoration: InputDecoration(
                  hintText: 'Select a patient',
                  prefixIcon: Icon(
                    Icons.person_search_rounded,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                items: patients.map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Row(
                    children: [
                      _buildAvatar(p, isDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${p.firstName} ${p.lastName}${p.phone != null && p.phone!.isNotEmpty ? ' - ${p.phone}' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                onChanged: (id) {
                  // Call onChanged if provided
                  if (onChanged != null) {
                    onChanged!(id);
                  }
                  // Call onPatientSelected if provided
                  if (onPatientSelected != null) {
                    final patient = id != null 
                        ? patients.firstWhere((p) => p.id == id, orElse: () => patients.first)
                        : null;
                    onPatientSelected!(id != null ? patient : null);
                  }
                },
                validator: isRequired 
                    ? (value) => value == null ? 'Please select a patient' : null
                    : null,
                dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                isExpanded: true,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvatar(Patient patient, bool isDark) {
    final initials = '${patient.firstName.isNotEmpty ? patient.firstName[0] : ''}${patient.lastName.isNotEmpty ? patient.lastName[0] : ''}'.toUpperCase();
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Inline patient selector (simpler version without section header)
class PatientSelectorInline extends StatelessWidget {
  const PatientSelectorInline({
    super.key,
    required this.db,
    this.selectedPatientId,
    required this.onChanged,
    this.hint = 'Select a patient',
    this.isRequired = true,
  });

  final DoctorDatabase db;
  final int? selectedPatientId;
  final ValueChanged<int?> onChanged;
  final String hint;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Patient>>(
      future: db.getAllPatients(),
      builder: (context, snapshot) {
        final patients = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
          ),
          child: DropdownButtonFormField<int>(
            value: selectedPatientId,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                Icons.person_search_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textHint,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            items: patients.map((p) => DropdownMenuItem(
              value: p.id,
              child: Text('${p.firstName} ${p.lastName}'),
            )).toList(),
            onChanged: onChanged,
            validator: isRequired 
                ? (value) => value == null ? 'Please select a patient' : null
                : null,
            dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            isExpanded: true,
          ),
        );
      },
    );
  }
}

/// A beautiful patient info card for displaying preselected patient information
/// Uses gradient background and modern design matching app theme
class PatientInfoCard extends StatelessWidget {
  const PatientInfoCard({
    super.key,
    required this.patient,
    this.gradientColors,
    this.icon = Icons.medical_services_rounded,
  });

  final Patient patient;
  final List<Color>? gradientColors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final initials = '${patient.firstName.isNotEmpty ? patient.firstName[0] : ''}${patient.lastName.isNotEmpty ? patient.lastName[0] : ''}'.toUpperCase();
    final colors = gradientColors ?? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    
    return Container(
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Patient Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Patient Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${patient.firstName} ${patient.lastName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
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
                        if (patient.age != null) ...[
                          _buildDividerDot(),
                          _buildInfoBadge(
                            icon: Icons.cake_outlined,
                            text: '${patient.age} yrs',
                          ),
                        ],
                        if (patient.gender != null && patient.gender!.isNotEmpty) ...[
                          _buildDividerDot(),
                          _buildInfoBadge(
                            icon: patient.gender == 'Male' 
                                ? Icons.male_rounded 
                                : patient.gender == 'Female' 
                                    ? Icons.female_rounded 
                                    : Icons.person_outline,
                            text: patient.gender!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (patient.phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        patient.phone,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Type Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDividerDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
}
