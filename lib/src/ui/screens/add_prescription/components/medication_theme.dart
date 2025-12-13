import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Modern theme colors for medication components
class MedColors {
  static const primary = Color(0xFFD946EF);      // Bright Fuchsia - more visible
  static const primaryDark = Color(0xFFC026D3);  // Darker Fuchsia
  static const secondary = Color(0xFF8B5CF6);    // Purple  
  static const accent = Color(0xFF7C3AED);       // Violet - stronger
  static const success = Color(0xFF10B981);      // Emerald
  static const warning = Color(0xFFF59E0B);      // Amber
  static const info = Color(0xFF0EA5E9);         // Sky
  static const error = Color(0xFFEF4444);        // Red
  
  /// Get gradient for primary button/header
  static const primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Get gradient for success state
  static const successGradient = LinearGradient(
    colors: [success, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Helper class for building consistent input decorations
class MedicationInputDecoration {
  static InputDecoration build({
    String? hintText,
    IconData? prefixIcon,
    required bool isDark,
    Color? iconColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, color: iconColor ?? MedColors.primary, size: 20) 
          : null,
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : MedColors.primary.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: MedColors.primary.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : MedColors.primary.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MedColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MedColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

/// Helper for building styled containers
class MedicationContainerStyle {
  /// Card-style container decoration
  static BoxDecoration card({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : MedColors.primary.withValues(alpha: 0.15),
      ),
      boxShadow: isDark ? null : [
        BoxShadow(
          color: MedColors.primary.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  /// Selected state container decoration
  static BoxDecoration selected({required bool isDark}) {
    return BoxDecoration(
      gradient: MedColors.primaryGradient,
      borderRadius: BorderRadius.circular(20),
    );
  }
  
  /// Unselected state container decoration  
  static BoxDecoration unselected({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
      ),
    );
  }
}

/// Styled label with optional required indicator
class MedicationInputLabel extends StatelessWidget {
  const MedicationInputLabel({
    super.key,
    required this.label,
    this.isRequired = false,
  });

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MedColors.primary,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MedColors.error,
            ),
          ),
      ],
    );
  }
}

/// Colored tag/badge component for medication details
class MedicationTag extends StatelessWidget {
  const MedicationTag({
    super.key,
    required this.text,
    required this.color,
    this.size = TagSize.normal,
  });

  final String text;
  final Color color;
  final TagSize size;

  @override
  Widget build(BuildContext context) {
    final padding = size == TagSize.small 
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    final fontSize = size == TagSize.small ? 10.0 : 11.0;
    final borderRadius = size == TagSize.small ? 6.0 : 20.0;
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

enum TagSize { small, normal }
