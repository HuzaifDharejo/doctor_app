/// Empty state widget for lists and content areas
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../constants/app_constants.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_rounded,
    this.action,
    this.onAction,
    this.actionLabel,
    this.iconColor,
  });

  /// Creates an empty state for patients list
  const EmptyState.patients({
    super.key,
    this.onAction,
  })  : title = 'No patients yet',
        message = 'Add your first patient to get started',
        icon = Icons.people_outline_rounded,
        action = null,
        actionLabel = 'Add Patient',
        iconColor = AppColors.patients;

  /// Creates an empty state for appointments list
  const EmptyState.appointments({
    super.key,
    this.onAction,
  })  : title = 'No appointments',
        message = 'Schedule an appointment to get started',
        icon = Icons.calendar_today_rounded,
        action = null,
        actionLabel = 'Add Appointment',
        iconColor = AppColors.appointments;

  /// Creates an empty state for prescriptions list
  const EmptyState.prescriptions({
    super.key,
    this.onAction,
  })  : title = 'No prescriptions',
        message = 'Create a prescription to get started',
        icon = Icons.medication_outlined,
        action = null,
        actionLabel = 'Add Prescription',
        iconColor = AppColors.prescriptions;

  /// Creates an empty state for invoices list
  const EmptyState.invoices({
    super.key,
    this.onAction,
  })  : title = 'No invoices',
        message = 'Create an invoice to get started',
        icon = Icons.receipt_long_outlined,
        action = null,
        actionLabel = 'Create Invoice',
        iconColor = AppColors.billing;

  /// Creates an empty state for search results
  const EmptyState.searchResults({
    super.key,
    String? query,
  })  : title = 'No results found',
        message = query != null ? 'Try searching for something else' : null,
        icon = Icons.search_off_rounded,
        action = null,
        onAction = null,
        actionLabel = null,
        iconColor = null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppIconSize.xxl,
                color: effectiveIconColor,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: AppFontSize.xxl,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Message
            if (message != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: TextStyle(
                  fontSize: AppFontSize.lg,
                  color: isDark 
                      ? AppColors.darkTextSecondary 
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            SizedBox(height: AppSpacing.xl),
            
            // Action button or custom action
            if (action != null)
              action!
            else if (onAction != null && actionLabel != null)
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveIconColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact empty state for inline use
class EmptyStateCompact extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyStateCompact({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: AppIconSize.md,
            color: isDark 
                ? AppColors.darkTextSecondary 
                : AppColors.textSecondary,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            message,
            style: TextStyle(
              color: isDark 
                  ? AppColors.darkTextSecondary 
                  : AppColors.textSecondary,
              fontSize: AppFontSize.lg,
            ),
          ),
        ],
      ),
    );
  }
}
