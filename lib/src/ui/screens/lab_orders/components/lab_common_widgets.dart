/// Lab Common Widgets
/// 
/// Reusable widget components for lab order screens.

import 'package:flutter/material.dart';
import 'lab_theme.dart';
import 'lab_models.dart';
import '../../../../core/extensions/context_extensions.dart';

/// A row displaying a label and value pair for lab details
class LabDetailRow extends StatelessWidget {
  const LabDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: LabColors.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? (isDark ? LabColors.darkTextPrimary : LabColors.textPrimary),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }
    return content;
  }
}

/// A compact info chip for displaying lab metadata
class LabInfoChip extends StatelessWidget {
  const LabInfoChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = color ?? LabColors.primary;
    final bgColor = backgroundColor ?? chipColor.withValues(alpha: 0.1);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: chipColor),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: chipColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A search bar for filtering lab tests
class LabSearchBar extends StatelessWidget {
  const LabSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.hintText = 'Search lab tests...',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: LabContainerStyle.formField(isDark: isDark),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: LabColors.primary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
                  ),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// A header section for lab order lists
class LabSectionHeader extends StatelessWidget {
  const LabSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: LabContainerStyle.iconContainer(gradient: false),
              child: Icon(icon, size: 18, color: LabColors.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A loading indicator with lab theme
class LabLoadingIndicator extends StatelessWidget {
  const LabLoadingIndicator({
    super.key,
    this.message,
    this.size = 32,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(LabColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A confirmation dialog for lab actions
class LabConfirmationDialog extends StatelessWidget {
  const LabConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.confirmColor,
    this.icon,
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final IconData? icon;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = confirmColor ?? 
        (isDestructive ? LabColors.cancelled : LabColors.primary);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? LabColors.darkSurface : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(context.responsivePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Container(
                padding: EdgeInsets.all(context.responsivePadding),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: actionColor),
              ),
            if (icon != null) const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(cancelLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => LabConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        icon: icon,
        isDestructive: isDestructive,
      ),
    );
  }
}

/// A reference range indicator for lab results
class LabReferenceRange extends StatelessWidget {
  const LabReferenceRange({
    super.key,
    required this.value,
    required this.referenceRange,
    this.unit,
    this.isAbnormal = false,
  });

  final String value;
  final String referenceRange;
  final String? unit;
  final bool isAbnormal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAbnormal 
            ? LabColors.abnormal.withValues(alpha: 0.1)
            : LabColors.normal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAbnormal 
              ? LabColors.abnormal.withValues(alpha: 0.3)
              : LabColors.normal.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Value section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Result',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isAbnormal ? LabColors.abnormal : LabColors.normal,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            height: 40,
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          
          // Reference range section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reference Range',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  referenceRange,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Status indicator
          Icon(
            isAbnormal 
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            size: 24,
            color: isAbnormal ? LabColors.abnormal : LabColors.normal,
          ),
        ],
      ),
    );
  }
}

/// A specimen collection details widget
class LabSpecimenDetails extends StatelessWidget {
  const LabSpecimenDetails({
    super.key,
    required this.specimenType,
    this.collectedAt,
    this.collectedBy,
    this.isFasting = false,
  });

  final LabSpecimenType specimenType;
  final DateTime? collectedAt;
  final String? collectedBy;
  final bool isFasting;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: LabContainerStyle.section(isDark: isDark, color: LabColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                specimenType.icon,
                size: 18,
                color: LabColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Specimen Details',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isFasting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: LabColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.no_food_rounded, size: 12, color: LabColors.warning),
                      SizedBox(width: 4),
                      Text(
                        'Fasting',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: LabColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Type',
            specimenType.value.toUpperCase(),
            Icons.water_drop_outlined,
            isDark,
          ),
          if (collectedAt != null)
            _buildDetailRow(
              'Collected',
              _formatDateTime(collectedAt!),
              Icons.schedule_outlined,
              isDark,
            ),
          if (collectedBy != null)
            _buildDetailRow(
              'Collected By',
              collectedBy!,
              Icons.person_outline,
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? LabColors.darkTextSecondary : LabColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? LabColors.darkTextPrimary : LabColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      final hours = dt.hour.toString().padLeft(2, '0');
      final mins = dt.minute.toString().padLeft(2, '0');
      return 'Today at $hours:$mins';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}

/// A badge showing the count of pending/abnormal results
class LabCountBadge extends StatelessWidget {
  const LabCountBadge({
    super.key,
    required this.count,
    this.label,
    this.color,
    this.icon,
  });

  final int count;
  final String? label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? LabColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: badgeColor),
            const SizedBox(width: 6),
          ],
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                color: badgeColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A quick action button for lab operations
class LabQuickAction extends StatelessWidget {
  const LabQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = color ?? LabColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: actionColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: actionColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: actionColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: actionColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
