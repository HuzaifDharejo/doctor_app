import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/components/app_button.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_theme.dart';
import 'edit_prescription_screen.dart';

class PrescriptionsScreen extends ConsumerWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(doctorDbProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildModernSliverAppBar(context),
          dbAsync.when(
            data: (db) => _buildPrescriptionsSliverList(context, ref, db),
            loading: () => const SliverFillRemaining(
              child: LoadingState(),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: ErrorState.generic(
                message: err.toString(),
                onRetry: () => ref.invalidate(doctorDbProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.dividerColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: theme.textTheme.bodyLarge?.color,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.surface, theme.scaffoldBackgroundColor],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescriptions',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.displayLarge?.color,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage medications & prescriptions',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionsSliverList(BuildContext context, WidgetRef ref, DoctorDatabase db) {
    final isCompact = AppBreakpoint.isCompact(MediaQuery.of(context).size.width);
    
    return FutureBuilder<List<Prescription>>(
      future: db.select(db.prescriptions).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverFillRemaining(
            child: LoadingState(),
          );
        }
        
        final prescriptions = snapshot.data!;
        
        if (prescriptions.isEmpty) {
          return SliverFillRemaining(
            child: _buildModernEmptyState(context),
          );
        }
        
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? AppSpacing.md : AppSpacing.xl),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildPrescriptionCard(context, ref, db, prescriptions[index]),
                );
              },
              childCount: prescriptions.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.medication_outlined,
                size: 64,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Prescriptions Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.displayLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prescriptions will appear here when created from patient details',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, WidgetRef ref, DoctorDatabase db, Prescription prescription) {
    // V5: Use compatibility method to get medications from either normalized table or legacy JSON
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.getMedicationsForPrescriptionCompat(prescription.id),
      builder: (context, medsSnapshot) {
        final medications = medsSnapshot.data ?? [];
        
        // Parse lab tests, follow-up, notes from itemsJson (still stored there for now)
        List<dynamic> labTests = [];
        Map<String, dynamic> followUp = {};
        String notes = '';
        
        try {
          final parsed = jsonDecode(prescription.itemsJson);
          if (parsed is Map<String, dynamic>) {
            labTests = (parsed['lab_tests'] as List<dynamic>?) ?? [];
            followUp = (parsed['follow_up'] as Map<String, dynamic>?) ?? {};
            notes = (parsed['notes'] as String?) ?? '';
          }
        } catch (_) {}
    
        return FutureBuilder<Patient?>(
          future: db.getPatientById(prescription.patientId),
          builder: (context, patientSnapshot) {
            final patient = patientSnapshot.data;
            final patientName = patient != null 
                ? '${patient.firstName} ${patient.lastName}'
                : 'Patient #${prescription.patientId}';
            
            final theme = Theme.of(context);
            final screenWidth = MediaQuery.of(context).size.width;
            final isCompact = screenWidth < 400;
            
            return AppCard(
              margin: EdgeInsets.only(bottom: isCompact ? 12 : 16),
              color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          borderColor: theme.dividerColor.withValues(alpha: 0.5),
          borderWidth: 1,
          boxShadow: [
            BoxShadow(
              color: AppColors.prescriptions.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          onTap: () => _showPrescriptionDetails(
            context, 
            ref, 
            prescription, 
            medications, 
            patient,
            labTests: labTests,
            followUp: followUp,
            notes: notes,
          ),
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
                                    color: theme.colorScheme.onSurface,
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
                                      color: theme.textTheme.bodySmall?.color,
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
                                color: theme.textTheme.bodySmall?.color,
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
                                    : theme.dividerColor.withValues(alpha: 0.5),
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
                                        : theme.textTheme.bodySmall?.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    prescription.isRefillable ? 'Refill' : 'Once',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: prescription.isRefillable
                                          ? AppColors.success
                                          : theme.textTheme.bodySmall?.color,
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
                        color: theme.scaffoldBackgroundColor,
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
                                color: theme.textTheme.bodySmall?.color,
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
      },
    );
  }

  void _showPrescriptionDetails(
    BuildContext context,
    WidgetRef ref,
    Prescription prescription,
    List<dynamic> medications,
    Patient? patient, {
    List<dynamic> labTests = const [],
    Map<String, dynamic> followUp = const {},
    String notes = '',
  }) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
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
                    color: theme.dividerColor,
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
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: theme.textTheme.bodyLarge?.color,
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
                          style: theme.textTheme.titleLarge,
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
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateFormat.format(prescription.createdAt),
                                  style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color,
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
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primary,
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
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          if (patient.phone.isNotEmpty)
                            Text(
                              patient.phone,
                              style: TextStyle(
                                color: theme.textTheme.bodySmall?.color,
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
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 40, color: theme.dividerColor),
                    Column(
                      children: [
                        Icon(
                          Icons.refresh,
                          color: prescription.isRefillable ? AppColors.success : theme.textTheme.bodySmall?.color,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.isRefillable ? 'Yes' : 'No',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: prescription.isRefillable ? AppColors.success : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        Text(
                          'Refillable',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
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
                                      color: theme.textTheme.bodyLarge?.color,
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
                                  _buildMedChip(context, Icons.medical_services_outlined, 'Dosage', med['dosage'].toString()),
                                if (med['frequency'] != null && med['frequency'].toString().isNotEmpty)
                                  _buildMedChip(context, Icons.schedule_outlined, 'Frequency', med['frequency'].toString()),
                                if (med['duration'] != null && med['duration'].toString().isNotEmpty)
                                  _buildMedChip(context, Icons.timer_outlined, 'Duration', med['duration'].toString()),
                                if (med['route'] != null && med['route'].toString().isNotEmpty)
                                  _buildMedChip(context, Icons.alt_route, 'Route', med['route'].toString()),
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
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
                                  color: theme.textTheme.bodyLarge?.color,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Chief Complaint / Symptoms
                    if (prescription.chiefComplaint.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.sick_outlined, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Chief Complaint',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          prescription.chiefComplaint,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    
                    // Diagnosis
                    if (prescription.diagnosis.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.medical_information_outlined, color: Colors.purple[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Diagnosis',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          prescription.diagnosis,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    
                    // Lab Tests / Investigations
                    if (labTests.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.science_outlined, color: Colors.teal[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Investigations (${labTests.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: labTests.map((test) {
                            final testName = test is Map ? (test['name'] as String? ?? test.toString()) : test.toString();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 14, color: Colors.teal[700]),
                                  const SizedBox(width: 6),
                                  Text(
                                    testName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.teal[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    
                    // Follow-up
                    if (followUp.isNotEmpty && followUp['date'] != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.event_outlined, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Follow-up',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateFormat.format(DateTime.parse(followUp['date'] as String)),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[800],
                                  ),
                                ),
                                if ((followUp['notes'] as String?)?.isNotEmpty == true)
                                  Text(
                                    followUp['notes'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Clinical Notes
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.note_alt_outlined, color: Colors.grey[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Clinical Notes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          notes,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    // Action buttons - Row 1
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.tertiary(
                            label: 'Edit',
                            icon: Icons.edit,
                            onPressed: () async {
                              Navigator.pop(context);
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPrescriptionScreen(
                                    prescription: prescription,
                                    patient: patient,
                                  ),
                                ),
                              );
                              if (result == true) {
                                ref.invalidate(doctorDbProvider);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Action buttons - Row 2
                    Row(
                      children: [
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
                    const SizedBox(height: 8),
                    // Delete button
                    AppButton.danger(
                      label: 'Delete Prescription',
                      icon: Icons.delete_outline,
                      fullWidth: true,
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(context, ref, prescription);
                      },
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

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Prescription prescription) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Delete Prescription'),
          ],
        ),
        content: const Text('Are you sure you want to delete this prescription? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final db = await ref.read(doctorDbProvider.future);
                await db.deletePrescription(prescription.id);
                ref.invalidate(doctorDbProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prescription deleted successfully'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete prescription: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedChip(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color,
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
