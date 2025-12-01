import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/components/app_input.dart';
import '../../../db/doctor_db.dart';
import '../../../theme/app_theme.dart';

/// Shared UI widgets for medical record forms
class RecordFormWidgets {
  // Private constructor to prevent instantiation
  RecordFormWidgets._();

  /// Builds the gradient header with icon and title
  static Widget buildGradientHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    List<Color>? gradientColors,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final padding = isCompact ? 12.0 : 20.0;
    final colors = gradientColors ?? [AppColors.primary, AppColors.primaryDark];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              // Custom App Bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
              const SizedBox(height: 20),
              // Record Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Section header with icon
  static Widget buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Builds a section card with title and children
  static Widget buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? accentColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? AppColors.primary;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Patient selector dropdown
  static Widget buildPatientSelector({
    required BuildContext context,
    required DoctorDatabase db,
    required int? selectedPatientId,
    required void Function(int?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<List<Patient>>(
      future: db.getAllPatients(),
      builder: (context, snapshot) {
        final patients = snapshot.data ?? [];
        
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
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
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: patients.map((p) => DropdownMenuItem(
              value: p.id,
              child: Text('${p.firstName} ${p.lastName}'),
            )).toList(),
            onChanged: onChanged,
            validator: (value) => value == null ? 'Please select a patient' : null,
            dropdownColor: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  /// Date selector widget
  static Widget buildDateSelector({
    required BuildContext context,
    required DateTime selectedDate,
    required void Function(DateTime) onDateSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.edit,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Simple text field
  static Widget buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return maxLines > 1
        ? AppInput.multiline(
            controller: controller,
            hint: hint,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
          )
        : AppInput.text(
            controller: controller,
            hint: hint,
            keyboardType: keyboardType,
            validator: validator,
          );
  }

  /// Vital sign field with label and unit
  static Widget buildVitalField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String unit,
    String? hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05) 
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1) 
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppInput.text(
              controller: controller,
              hint: hint ?? '---',
              keyboardType: TextInputType.text,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Chip selector for multiple selections
  static Widget buildChipSelector({
    required BuildContext context,
    required List<String> options,
    required List<String> selectedOptions,
    required void Function(List<String>) onChanged,
    Color? color,
    String? label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? AppColors.primary;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.05) 
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1) 
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final isSelected = selectedOptions.contains(option);
          return FilterChip(
            label: Text(
              option,
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              final newList = List<String>.from(selectedOptions);
              if (selected) {
                newList.add(option);
              } else {
                newList.remove(option);
              }
              onChanged(newList);
            },
            selectedColor: chipColor,
            checkmarkColor: Colors.white,
            backgroundColor: isDark 
                ? Colors.white.withValues(alpha: 0.08) 
                : Colors.grey.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? chipColor : Colors.transparent,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Risk selector for low/moderate/high ratings
  static Widget buildRiskSelector({
    required BuildContext context,
    required String label,
    required String value,
    required void Function(String) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final risks = ['None', 'Low', 'Moderate', 'High'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: risks.map((risk) {
            final isSelected = value == risk;
            Color chipColor;
            switch (risk) {
              case 'High':
                chipColor = AppColors.error;
              case 'Moderate':
                chipColor = AppColors.warning;
              case 'Low':
                chipColor = AppColors.info;
              default:
                chipColor = AppColors.success;
            }
            
            return ChoiceChip(
              label: Text(risk),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onChanged(risk);
              },
              selectedColor: chipColor.withValues(alpha: 0.2),
              backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
              labelStyle: TextStyle(
                color: isSelected 
                    ? chipColor 
                    : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected 
                      ? chipColor 
                      : (isDark ? AppColors.darkDivider : AppColors.divider),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Save button with gradient
  static Widget buildSaveButton({
    required BuildContext context,
    required bool isSaving,
    required String label,
    required VoidCallback onPressed,
    List<Color>? gradientColors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = gradientColors ?? [AppColors.primary, AppColors.primaryDark];
    
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isSaving ? null : LinearGradient(colors: colors),
          color: isSaving 
              ? (isDark ? AppColors.darkTextSecondary : AppColors.textHint) 
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSaving ? null : [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isSaving ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_outlined, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Shows a success snackbar
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Shows an error snackbar
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
