/// Empty State Widgets
/// Beautiful empty states for when lists are empty
library;

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../../theme/app_theme.dart';

/// Generic empty state widget
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    super.key,
    this.icon,
    this.title,
    this.actionLabel,
    this.onAction,
    this.illustration,
  });

  final String message;
  final IconData? icon;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration or Icon
            if (illustration != null)
              illustration!
            else if (icon != null)
              Container(
                padding: EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppIconSize.xxl,
                  color: AppColors.primary,
                ),
              ),
            SizedBox(height: AppSpacing.xl),
            // Title
            if (title != null)
              Text(
                title!,
                style: TextStyle(
                  fontSize: AppFontSize.titleLarge,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            if (title != null) SizedBox(height: AppSpacing.sm),
            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: AppFontSize.bodyMedium,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            // Action button
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: AppIconSize.sm),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for patient list
class EmptyPatientList extends StatelessWidget {
  const EmptyPatientList({
    super.key,
    this.onAddPatient,
  });

  final VoidCallback? onAddPatient;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.people_outline_rounded,
      title: 'No Patients Yet',
      message: 'Start by adding your first patient to the system.',
      actionLabel: 'Add Patient',
      onAction: onAddPatient,
    );
  }
}

/// Empty state for appointment list
class EmptyAppointmentList extends StatelessWidget {
  const EmptyAppointmentList({
    super.key,
    this.onAddAppointment,
    this.message,
  });

  final VoidCallback? onAddAppointment;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.calendar_today_outlined,
      title: 'No Appointments',
      message: message ?? 'No appointments scheduled for this period.',
      actionLabel: onAddAppointment != null ? 'Schedule Appointment' : null,
      onAction: onAddAppointment,
    );
  }
}

/// Empty state for prescription list
class EmptyPrescriptionList extends StatelessWidget {
  const EmptyPrescriptionList({
    super.key,
    this.onAddPrescription,
  });

  final VoidCallback? onAddPrescription;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.medication_outlined,
      title: 'No Prescriptions',
      message: 'No prescriptions have been created yet.',
      actionLabel: onAddPrescription != null ? 'Add Prescription' : null,
      onAction: onAddPrescription,
    );
  }
}

/// Empty state for invoice list
class EmptyInvoiceList extends StatelessWidget {
  const EmptyInvoiceList({
    super.key,
    this.onAddInvoice,
  });

  final VoidCallback? onAddInvoice;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No Invoices',
      message: 'No invoices have been created yet.',
      actionLabel: onAddInvoice != null ? 'Create Invoice' : null,
      onAction: onAddInvoice,
    );
  }
}

/// Empty state for search results
class EmptySearchResults extends StatelessWidget {
  const EmptySearchResults({
    super.key,
    this.query,
  });

  final String? query;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No Results Found',
      message: query != null
          ? 'No results found for "$query". Try a different search term.'
          : 'No results found. Try adjusting your search criteria.',
    );
  }
}

/// Empty state for follow-ups
class EmptyFollowUpsList extends StatelessWidget {
  const EmptyFollowUpsList({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.event_repeat_outlined,
      title: 'No Follow-ups',
      message: message ?? 'No follow-ups scheduled.',
    );
  }
}

/// Empty state for medical records
class EmptyMedicalRecordsList extends StatelessWidget {
  const EmptyMedicalRecordsList({
    super.key,
    this.onAddRecord,
  });

  final VoidCallback? onAddRecord;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.description_outlined,
      title: 'No Medical Records',
      message: 'No medical records have been added yet.',
      actionLabel: onAddRecord != null ? 'Add Record' : null,
      onAction: onAddRecord,
    );
  }
}
