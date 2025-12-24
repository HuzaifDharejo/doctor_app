import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';

/// Persistent Allergy Warning Banner
/// Displays patient allergies prominently in any screen where medications or treatments are involved
class PersistentAllergyWarningBanner extends StatelessWidget {
  const PersistentAllergyWarningBanner({
    super.key,
    required this.allergies,
    this.onManageAllergies,
    this.compact = false,
  });

  /// Comma-separated list of allergies or allergy text
  final String allergies;
  
  /// Callback when user taps to manage allergies
  final VoidCallback? onManageAllergies;
  
  /// Compact mode for smaller spaces
  final bool compact;

  bool get hasAllergies {
    if (allergies.isEmpty) return false;
    final lower = allergies.toLowerCase().trim();
    return lower != 'none' && lower != 'nkda' && lower != 'no known drug allergies';
  }

  @override
  Widget build(BuildContext context) {
    if (!hasAllergies) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (compact) {
      return _buildCompactBanner(context, isDark);
    }
    
    return _buildFullBanner(context, isDark);
  }

  Widget _buildFullBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withValues(alpha: 0.15),
            AppColors.error.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PATIENT ALLERGIES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    allergies,
                    style: TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review before prescribing any medication',
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            // Manage Button (if callback provided)
            if (onManageAllergies != null) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onManageAllergies,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Manage'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALLERGIES',
                  style: TextStyle(
                    fontSize: AppFontSize.xs,
                    fontWeight: FontWeight.w900,
                    color: AppColors.error,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allergies,
                  style: TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onManageAllergies != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.error,
              onPressed: onManageAllergies,
              tooltip: 'Manage allergies',
            ),
        ],
      ),
    );
  }
}

