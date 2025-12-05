// Patient View - Prescriptions Tab
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../add_prescription_screen.dart';
import 'patient_view_widgets.dart';

class PatientPrescriptionsTab extends ConsumerWidget {
  const PatientPrescriptionsTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<Prescription>>(
        future: db.getPrescriptionsForPatient(patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final prescriptions = snapshot.data ?? [];

          if (prescriptions.isEmpty) {
            return PatientTabEmptyState(
              icon: Icons.local_pharmacy_outlined,
              title: 'No Prescriptions',
              subtitle: 'Create a prescription for this patient',
              actionLabel: 'Add Prescription',
              onAction: () => _navigateToAddPrescription(context),
            );
          }

          prescriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            primary: false,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) => _PrescriptionCard(
              prescription: prescriptions[index],
              isDark: isDark,
              onTap: () => _showPrescriptionDetails(context, prescriptions[index], isDark),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => PatientTabEmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading Prescriptions',
        subtitle: 'Please try again later',
      ),
    );
  }

  void _navigateToAddPrescription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPrescriptionScreen(preselectedPatient: patient),
      ),
    );
  }

  void _showPrescriptionDetails(BuildContext context, Prescription prescription, bool isDark) {
    List<dynamic> medications = [];
    try {
      medications = jsonDecode(prescription.itemsJson) as List<dynamic>;
    } catch (e) {
      // Handle parsing error
    }

    final dateFormat = DateFormat('MMMM d, yyyy');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication_rounded, color: AppColors.warning, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription #${prescription.id}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          dateFormat.format(prescription.createdAt),
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Medications
              Text(
                'Medications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    final name = med is Map ? (med['name'] ?? 'Unknown') : med.toString();
                    final dosage = med is Map ? (med['dosage'] ?? '') : '';
                    final frequency = med is Map ? (med['frequency'] ?? '') : '';
                    final duration = med is Map ? (med['duration'] ?? '') : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkDivider : AppColors.divider,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (dosage.toString().isNotEmpty)
                            _buildMedDetailRow('Dosage', dosage.toString(), isDark),
                          if (frequency.toString().isNotEmpty)
                            _buildMedDetailRow('Frequency', frequency.toString(), isDark),
                          if (duration.toString().isNotEmpty)
                            _buildMedDetailRow('Duration', duration.toString(), isDark),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.isDark,
    required this.onTap,
  });

  final Prescription prescription;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    List<dynamic> medications = [];
    try {
      medications = jsonDecode(prescription.itemsJson) as List<dynamic>;
    } catch (e) {
      // Handle parsing error
    }

    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return PatientItemCard(
      icon: Icons.local_pharmacy,
      iconColor: AppColors.warning,
      title: 'Prescription #${prescription.id}',
      subtitle: dateFormat.format(prescription.createdAt),
      trailing: Icon(Icons.chevron_right, color: secondaryColor),
      onTap: onTap,
      bottomWidget: medications.isNotEmpty
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: medications.take(3).map((med) {
                final name = med is Map ? (med['name'] ?? 'Unknown') : med.toString();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name.toString(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            )
          : null,
    );
  }
}
