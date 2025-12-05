import 'package:flutter/material.dart';
import '../../../../db/doctor_db.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../theme/app_theme.dart';

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
