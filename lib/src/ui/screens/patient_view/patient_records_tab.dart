// Patient View - Medical Records Tab
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../medical_record_detail_screen.dart';
import '../records/records.dart';
import 'patient_view_widgets.dart';

class PatientRecordsTab extends ConsumerWidget {
  const PatientRecordsTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => FutureBuilder<List<MedicalRecord>>(
        future: db.getMedicalRecordsForPatient(patient.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return PatientTabEmptyState(
              icon: Icons.description_outlined,
              title: 'No Medical Records',
              subtitle: 'Add medical records to track patient history',
              actionLabel: 'Add Record',
              onAction: () => _navigateToAddRecord(context),
            );
          }

          records.sort((a, b) => b.recordDate.compareTo(a.recordDate));

          return ListView.builder(
            primary: false,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: records.length,
            itemBuilder: (context, index) => _MedicalRecordCard(
              record: records[index],
              patient: patient,
              isDark: isDark,
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => PatientTabEmptyState(
        icon: Icons.error_outline,
        title: 'Error Loading Records',
        subtitle: 'Please try again later',
      ),
    );
  }

  void _navigateToAddRecord(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectRecordTypeScreen(preselectedPatient: patient),
      ),
    );
  }
}

class _MedicalRecordCard extends StatelessWidget {
  const _MedicalRecordCard({
    required this.record,
    required this.patient,
    required this.isDark,
  });

  final MedicalRecord record;
  final Patient patient;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(record.dataJson) as Map<String, dynamic>;
    } catch (e) {
      // Handle parsing error
    }

    final recordInfo = _getRecordTypeInfo(record.recordType);
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    // Extract summary from data
    String summary = '';
    if (data.containsKey('diagnosis')) {
      summary = data['diagnosis']?.toString() ?? '';
    } else if (data.containsKey('notes')) {
      summary = data['notes']?.toString() ?? '';
    } else if (data.containsKey('summary')) {
      summary = data['summary']?.toString() ?? '';
    }

    return PatientItemCard(
      icon: recordInfo.icon,
      iconColor: recordInfo.color,
      title: recordInfo.label,
      subtitle: dateFormat.format(record.recordDate),
      trailing: Icon(Icons.chevron_right, color: secondaryColor),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicalRecordDetailScreen(
            record: record,
            patient: patient,
          ),
        ),
      ),
      bottomWidget: summary.isNotEmpty
          ? Text(
              summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: secondaryColor,
              ),
            )
          : null,
    );
  }

  ({IconData icon, Color color, String label}) _getRecordTypeInfo(String type) {
    switch (type) {
      case 'general':
        return (icon: Icons.medical_services_rounded, color: const Color(0xFF10B981), label: 'General Consultation'); // Clinical Green
      case 'pulmonary_evaluation':
        return (icon: Icons.air_rounded, color: const Color(0xFF06B6D4), label: 'Pulmonary Evaluation'); // Info Cyan
      case 'psychiatric_assessment':
        return (icon: Icons.psychology_rounded, color: const Color(0xFF8B5CF6), label: 'Psychiatric Assessment'); // Billing Purple
      case 'lab_result':
        return (icon: Icons.science_rounded, color: const Color(0xFF14B8A6), label: 'Lab Result'); // Lab Teal
      case 'imaging':
        return (icon: Icons.image_rounded, color: const Color(0xFF6366F1), label: 'Imaging / Radiology'); // Patient Indigo
      case 'procedure':
        return (icon: Icons.healing_rounded, color: const Color(0xFFEC4899), label: 'Medical Procedure'); // Medication Pink
      case 'follow_up':
        return (icon: Icons.event_repeat_rounded, color: const Color(0xFFF59E0B), label: 'Follow-up Visit'); // Notes Amber
      default:
        return (icon: Icons.medical_services_rounded, color: const Color(0xFF10B981), label: 'Medical Record');
    }
  }
}
