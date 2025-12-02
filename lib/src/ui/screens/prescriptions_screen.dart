import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/error_display.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/constants/app_strings.dart';
import '../../core/components/app_button.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_theme.dart';

class PrescriptionsScreen extends ConsumerWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(doctorDbProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: dbAsync.when(
                data: (db) => _buildPrescriptionsList(context, ref, db),
                loading: () => const LoadingState(),
                error: (err, stack) => ErrorState.generic(
                  message: err.toString(),
                  onRetry: () => ref.invalidate(doctorDbProvider),
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }

  Widget _buildHeader(BuildContext context) {
    final isCompact = AppBreakpoint.isCompact(MediaQuery.of(context).size.width);
    
    return AppHeader(
      title: AppStrings.prescriptions,
      subtitle: 'Manage medications & prescriptions',
      showBackButton: true,
      trailing: Container(
        padding: EdgeInsets.all(isCompact ? AppSpacing.xs : AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          Icons.medication_rounded,
          color: AppColors.warning,
          size: isCompact ? AppIconSize.smCompact : AppIconSize.md,
        ),
      ),
    );
  }

  Widget _buildPrescriptionsList(BuildContext context, WidgetRef ref, DoctorDatabase db) {
    final isCompact = AppBreakpoint.isCompact(MediaQuery.of(context).size.width);
    
    return FutureBuilder<List<Prescription>>(
      future: db.select(db.prescriptions).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingState();
        }
        
        final prescriptions = snapshot.data!;
        
        if (prescriptions.isEmpty) {
          return const EmptyState(
            icon: Icons.medication_outlined,
            title: 'No Prescriptions Yet',
            message: 'Prescriptions will appear here when created from patient details',
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? AppSpacing.md : AppSpacing.xl),
          itemCount: prescriptions.length,
          itemBuilder: (context, index) {
            return _buildPrescriptionCard(context, ref, db, prescriptions[index]);
          },
        );
      },
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, WidgetRef ref, DoctorDatabase db, Prescription prescription) {
    List<dynamic> medications = [];
    try {
      medications = jsonDecode(prescription.itemsJson) as List<dynamic>;
    } catch (_) {}
    
    return FutureBuilder<Patient?>(
      future: db.getPatientById(prescription.patientId),
      builder: (context, patientSnapshot) {
        final patient = patientSnapshot.data;
        final patientName = patient != null 
            ? '${patient.firstName} ${patient.lastName}'
            : 'Patient #${prescription.patientId}';
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final screenWidth = MediaQuery.of(context).size.width;
        final isCompact = screenWidth < 400;
        
        return AppCard(
          margin: EdgeInsets.only(bottom: isCompact ? 12 : 16),
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          borderColor: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
          borderWidth: 1,
          boxShadow: [
            BoxShadow(
              color: AppColors.prescriptions.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          onTap: () => _showPrescriptionDetails(context, ref, prescription, medications, patient),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with gradient
                  Container(
                    padding: EdgeInsets.all(isCompact ? 14 : 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.prescriptions.withValues(alpha: 0.15),
                          AppColors.prescriptions.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isCompact ? 10 : 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.prescriptions,
                                    AppColors.prescriptions.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.prescriptions.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.medication_rounded,
                                color: Colors.white,
                                size: isCompact ? 20 : 22,
                              ),
                            ),
                            SizedBox(width: isCompact ? 10 : 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rx #${prescription.id}',
                                  style: TextStyle(
                                    fontSize: isCompact ? 13 : 15,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                SizedBox(
                                  width: isCompact ? 100 : 140,
                                  child: Text(
                                    patientName,
                                    style: TextStyle(
                                      fontSize: isCompact ? 10 : 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('MMM d').format(prescription.createdAt),
                              style: TextStyle(
                                fontSize: isCompact ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                gradient: prescription.isRefillable
                                    ? LinearGradient(
                                        colors: [
                                          AppColors.success.withValues(alpha: 0.2),
                                          AppColors.success.withValues(alpha: 0.1),
                                        ],
                                      )
                                    : null,
                                color: prescription.isRefillable 
                                    ? null 
                                    : (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    prescription.isRefillable 
                                        ? Icons.autorenew_rounded 
                                        : Icons.do_not_disturb_rounded,
                                    size: 12,
                                    color: prescription.isRefillable
                                        ? AppColors.success
                                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    prescription.isRefillable ? 'Refill' : 'Once',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: prescription.isRefillable
                                          ? AppColors.success
                                          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Medications
                  if (medications.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.all(isCompact ? 14 : 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_pharmacy_rounded, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${medications.length} medications',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...medications.take(3).map((med) {
                            final medMap = med as Map<String, dynamic>;
                            final name = medMap['name'] as String? ?? 'Unknown';
                            final dosage = medMap['dosage'] as String? ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.prescriptions, AppColors.primary],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '$name${dosage.isNotEmpty ? " • $dosage" : ""}',
                                      style: TextStyle(
                                        fontSize: isCompact ? 11 : 12,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (medications.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const SizedBox(width: 18),
                                  Text(
                                    '+${medications.length - 3} more',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  // Instructions footer
                  if (prescription.instructions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isCompact ? 12 : 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.background,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              prescription.instructions,
                              style: TextStyle(
                                fontSize: isCompact ? 11 : 12,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
        );
      },
    );
  }

  void _showPrescriptionDetails(
    BuildContext context,
    WidgetRef ref,
    Prescription prescription,
    List<dynamic> medications,
    Patient? patient,
  ) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
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
              const SizedBox(height: 20),
              // Header with back button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: AppColors.warning,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription #${prescription.id}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateFormat.format(prescription.createdAt),
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (prescription.isRefillable)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, size: 12, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      'Refillable',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Patient info
              if (patient != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text(
                          patient.firstName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${patient.firstName} ${patient.lastName}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          if (patient.phone.isNotEmpty)
                            Text(
                              patient.phone,
                              style: TextStyle(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Summary card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warning.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.medication, color: AppColors.warning, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          '${medications.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.warning,
                          ),
                        ),
                        Text(
                          'Medications',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 40, color: (isDark ? AppColors.darkDivider : AppColors.divider)),
                    Column(
                      children: [
                        Icon(
                          Icons.refresh,
                          color: prescription.isRefillable ? AppColors.success : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.isRefillable ? 'Yes' : 'No',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: prescription.isRefillable ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Refillable',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Medications title
              Row(
                children: [
                  const Icon(Icons.medication_outlined, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Medications (${medications.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Medications list
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: ListView(
                    controller: scrollController,
                    children: [
                    ...medications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final med = entry.value as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    med['name'] as String? ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                if (med['dosage'] != null && med['dosage'].toString().isNotEmpty)
                                  _buildMedChip(Icons.medical_services_outlined, 'Dosage', med['dosage'].toString(), isDark),
                                if (med['frequency'] != null && med['frequency'].toString().isNotEmpty)
                                  _buildMedChip(Icons.schedule_outlined, 'Frequency', med['frequency'].toString(), isDark),
                                if (med['duration'] != null && med['duration'].toString().isNotEmpty)
                                  _buildMedChip(Icons.timer_outlined, 'Duration', med['duration'].toString(), isDark),
                                if (med['route'] != null && med['route'].toString().isNotEmpty)
                                  _buildMedChip(Icons.alt_route, 'Route', med['route'].toString(), isDark),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    // Doctor's instructions
                    if (prescription.instructions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.assignment_outlined, color: AppColors.info, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Doctor's Instructions",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                prescription.instructions,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.tertiary(
                            label: 'Refill',
                            icon: Icons.refresh,
                            onPressed: () {
                              Navigator.pop(context);
                              _handleRefill(context, ref, prescription, patient);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            label: 'WhatsApp',
                            icon: Icons.chat,
                            variant: AppButtonVariant.tertiary,
                            foregroundColor: const Color(0xFF25D366),
                            borderColor: const Color(0xFF25D366),
                            onPressed: () async {
                              Navigator.pop(context);
                              if (patient != null) {
                                final doctorSettings = ref.read(doctorSettingsProvider);
                                final profile = doctorSettings.profile;
                                await WhatsAppService.sharePrescription(
                                  patient: patient,
                                  prescription: prescription,
                                  doctorName: profile.displayName,
                                  clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
                                  clinicPhone: profile.clinicPhone,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Patient information not available'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton.primary(
                            label: 'PDF',
                            icon: Icons.picture_as_pdf,
                            onPressed: () async {
                              Navigator.pop(context);
                              if (patient != null) {
                                final doctorSettings = ref.read(doctorSettingsProvider);
                                final profile = doctorSettings.profile;
                                await PdfService.sharePrescriptionPdf(
                                  patient: patient,
                                  prescription: prescription,
                                  doctorName: profile.displayName,
                                  clinicName: profile.clinicName.isNotEmpty ? profile.clinicName : 'Medical Clinic',
                                  clinicPhone: profile.clinicPhone,
                                  clinicAddress: profile.clinicAddress,
                                  signatureData: (profile.signatureData?.isNotEmpty ?? false) ? profile.signatureData : null,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedChip(IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground.withValues(alpha: 0.5) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefill(BuildContext context, WidgetRef ref, Prescription prescription, Patient? patient) async {
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient information not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.refresh, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Refill Prescription'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create a new prescription with the same medications for ${patient.firstName} ${patient.lastName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A new prescription will be created with today\'s date.',
                      style: TextStyle(fontSize: 13, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton.primary(
            label: 'Create Refill',
            icon: Icons.add,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.when(
        data: (db) => db,
        loading: () => throw Exception('Database loading'),
        error: (e, _) => throw e,
      );

      // Create new prescription with same items
      final newPrescription = PrescriptionsCompanion.insert(
        patientId: prescription.patientId,
        itemsJson: prescription.itemsJson,
        instructions: Value(prescription.instructions),
        isRefillable: Value(prescription.isRefillable),
      );

      await db.insertPrescription(newPrescription);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Prescription refilled successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating refill: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
