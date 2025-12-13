/// Lab Test Theme Components
/// 
/// Consistent theming for lab test components including colors,
/// decorations, and styled widgets for a cohesive lab test UI.

import 'package:flutter/material.dart';

/// Lab module color palette - Purple theme for lab orders
class LabColors {
  LabColors._();

  // Primary theme colors
  static const Color primary = Color(0xFF8B5CF6);      // Purple
  static const Color primaryDark = Color(0xFF7C3AED);  // Darker purple
  static const Color secondary = Color(0xFFA78BFA);    // Light purple
  
  // Gradient colors
  static const List<Color> primaryGradient = [primary, primaryDark];
  static const List<Color> lightGradient = [Color(0xFFEDE9FE), Color(0xFFDDD6FE)];
  
  // Status colors
  static const Color ordered = Colors.blue;
  static const Color collected = Color(0xFF8B5CF6);
  static const Color inProgress = Colors.orange;
  static const Color completed = Color(0xFF10B981);
  static const Color cancelled = Color(0xFFEF4444);
  
  // Priority/urgency colors  
  static const Color statUrgent = Color(0xFFEF4444);
  static const Color urgent = Color(0xFFF59E0B);
  static const Color routine = Color(0xFF10B981);
  
  // Result status colors
  static const Color normal = Color(0xFF10B981);
  static const Color abnormal = Color(0xFFF59E0B);
  static const Color critical = Color(0xFFEF4444);
  static const Color pending = Colors.grey;
  static const Color warning = Color(0xFFF59E0B);
  
  // Surface colors
  static const Color lightSurface = Colors.white;
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F0F1A);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  
  /// Get status color from string
  static Color getStatusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'ordered':
        return ordered;
      case 'collected':
        return collected;
      case 'in_progress':
        return inProgress;
      case 'completed':
        return completed;
      case 'cancelled':
        return cancelled;
      default:
        return pending;
    }
  }
  
  /// Get priority/urgency color
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'stat':
        return statUrgent;
      case 'urgent':
        return urgent;
      case 'routine':
        return routine;
      default:
        return pending;
    }
  }
  
  /// Get result status color
  static Color getResultColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return normal;
      case 'abnormal':
      case 'high':
      case 'low':
        return abnormal;
      case 'critical':
        return critical;
      default:
        return pending;
    }
  }
}

/// Input decoration builder for lab components
class LabInputDecoration {
  LabInputDecoration._();
  
  /// Build standard input decoration for lab forms
  static InputDecoration build({
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffix,
    bool isDark = false,
    Color? borderColor,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
      ),
      hintStyle: TextStyle(
        color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
      ),
      prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, color: LabColors.primary, size: 20)
          : null,
      suffix: suffix,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
  
  /// Build search input decoration
  static InputDecoration search({
    String hint = 'Search lab tests...',
    bool isDark = false,
    VoidCallback? onClear,
    bool showClear = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
      ),
      prefixIcon: Icon(
        Icons.search_rounded,
        color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
      ),
      suffixIcon: showClear && onClear != null
          ? IconButton(
              icon: Icon(
                Icons.clear_rounded,
                color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
              ),
              onPressed: onClear,
            )
          : null,
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

/// Container style builder for lab components
class LabContainerStyle {
  LabContainerStyle._();
  
  /// Standard card container decoration
  static BoxDecoration card({bool isDark = false, bool hasAbnormal = false}) {
    return BoxDecoration(
      color: isDark ? LabColors.darkSurface : LabColors.lightSurface,
      borderRadius: BorderRadius.circular(20),
      border: hasAbnormal 
          ? Border.all(color: LabColors.abnormal.withValues(alpha: 0.5), width: 2)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  /// Form field container decoration
  static BoxDecoration formField({bool isDark = false}) {
    return BoxDecoration(
      color: isDark 
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.2),
      ),
    );
  }
  
  /// Icon container decoration
  static BoxDecoration iconContainer({
    Color? color,
    bool isDark = false,
    bool gradient = false,
  }) {
    final effectiveColor = color ?? LabColors.primary;
    
    if (gradient) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [effectiveColor, effectiveColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
    
    return BoxDecoration(
      color: effectiveColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    );
  }
  
  /// Section container with subtle background
  static BoxDecoration section({bool isDark = false, Color? color}) {
    final effectiveColor = color ?? LabColors.primary;
    return BoxDecoration(
      color: isDark 
          ? Colors.white.withValues(alpha: 0.05)
          : effectiveColor.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark 
            ? Colors.white.withValues(alpha: 0.1)
            : effectiveColor.withValues(alpha: 0.2),
      ),
    );
  }
  
  /// Bottom sheet container decoration
  static BoxDecoration bottomSheet({bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? LabColors.darkSurface : LabColors.lightSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    );
  }
}

/// Status tag/chip widget for lab orders
class LabStatusTag extends StatelessWidget {
  const LabStatusTag({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = LabColors.getStatusColor(status);
    final displayText = status.replaceAll('_', ' ').toUpperCase();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 8 : 20),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Priority/urgency tag widget
class LabPriorityTag extends StatelessWidget {
  const LabPriorityTag({
    super.key,
    required this.priority,
    this.showIcon = true,
    this.compact = false,
  });

  final String priority;
  final bool showIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = LabColors.getPriorityColor(priority);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(Icons.priority_high_rounded, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              priority[0].toUpperCase() + priority.substring(1),
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Result status tag with color coding
class LabResultTag extends StatelessWidget {
  const LabResultTag({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  final String status;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final color = LabColors.getResultColor(status);
    
    IconData icon;
    switch (status.toLowerCase()) {
      case 'normal':
        icon = Icons.check_circle_rounded;
      case 'abnormal':
      case 'high':
      case 'low':
        icon = Icons.warning_rounded;
      case 'critical':
        icon = Icons.error_rounded;
      default:
        icon = Icons.schedule_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Abnormal indicator badge
class AbnormalBadge extends StatelessWidget {
  const AbnormalBadge({
    super.key,
    this.isCritical = false,
    this.compact = false,
  });

  final bool isCritical;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? LabColors.critical : LabColors.abnormal;
    final text = isCritical ? 'CRITICAL' : 'ABNORMAL';
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_rounded, 
            size: compact ? 10 : 12, 
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient button for lab actions
class LabGradientButton extends StatelessWidget {
  const LabGradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: LabColors.primaryGradient),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: LabColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon ?? Icons.check_rounded, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
    
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Icon with test type detection
class LabTestIcon extends StatelessWidget {
  const LabTestIcon({
    super.key,
    required this.testName,
    this.size = 24,
    this.color,
  });

  final String testName;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      _getTestIcon(),
      size: size,
      color: color ?? LabColors.primary,
    );
  }
  
  IconData _getTestIcon() {
    final lower = testName.toLowerCase();
    if (lower.contains('blood') || lower.contains('cbc') || lower.contains('hemoglobin')) {
      return Icons.bloodtype;
    }
    if (lower.contains('urine') || lower.contains('urinal')) return Icons.water_drop;
    if (lower.contains('glucose') || lower.contains('sugar') || lower.contains('hba1c')) {
      return Icons.monitor_heart;
    }
    if (lower.contains('cholesterol') || lower.contains('lipid')) return Icons.favorite;
    if (lower.contains('thyroid') || lower.contains('tsh')) return Icons.biotech;
    if (lower.contains('liver') || lower.contains('hepat') || lower.contains('ast') || lower.contains('alt')) {
      return Icons.medical_services;
    }
    if (lower.contains('kidney') || lower.contains('creatinine') || lower.contains('bun')) {
      return Icons.water_drop;
    }
    if (lower.contains('culture') || lower.contains('bacteria')) return Icons.coronavirus;
    if (lower.contains('xray') || lower.contains('ct') || lower.contains('mri')) {
      return Icons.medical_information;
    }
    return Icons.science;
  }
}
