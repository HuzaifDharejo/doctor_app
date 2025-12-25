import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/components/app_button.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/pagination.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/skeleton_loading.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../services/pdf_service.dart';
import '../../services/whatsapp_service.dart';
import '../../theme/app_theme.dart';
import 'edit_prescription_screen.dart';

class PrescriptionsScreen extends ConsumerStatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  ConsumerState<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends ConsumerState<PrescriptionsScreen> {
  late PaginationController<Prescription> _paginationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initPaginationController();
  }

  void _initPaginationController() {
    _paginationController = PaginationController<Prescription>(
      fetchPage: _fetchPage,
    );
    _paginationController.addListener(_onPaginationUpdate);
    _paginationController.loadInitial();
  }

  void _onPaginationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<(List<Prescription>, int)> _fetchPage(int pageIndex, int pageSize) async {
    final db = await ref.read(doctorDbProvider.future);
    return db.getPrescriptionsPaginated(
      offset: pageIndex * pageSize,
      limit: pageSize,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _paginationController.removeListener(_onPaginationUpdate);
    _paginationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    _paginationController.onScroll(
      scrollPosition: _scrollController.position.pixels,
      maxScrollExtent: _scrollController.position.maxScrollExtent,
      threshold: 200,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          _buildModernSliverAppBar(context),
          _buildPrescriptionsSliverList(context, ref),
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
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Container(
          decoration: BoxDecoration(
            color: theme.dividerColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: AppIconSize.sm,
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
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxxxl, AppSpacing.xl, AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.responsivePadding),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
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
                      size: AppIconSize.xl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescriptions',
                          style: TextStyle(
                            fontSize: AppFontSize.display,
                            fontWeight: FontWeight.w800,
                            color: theme.textTheme.displayLarge?.color,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Manage medications & prescriptions',
                          style: TextStyle(
                            fontSize: AppFontSize.lg,
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

  Widget _buildPrescriptionsSliverList(BuildContext context, WidgetRef ref) {
    final isCompact = AppBreakpoint.isCompact(MediaQuery.of(context).size.width);
    final dbAsync = ref.watch(doctorDbProvider);
    
    if (!_paginationController.hasInitialized) {
      return const SliverToBoxAdapter(
        child: PrescriptionListSkeleton(itemCount: 5),
      );
    }
    
    if (_paginationController.error != null) {
      return SliverFillRemaining(
        child: ErrorState.generic(
          message: _paginationController.error!,
          onRetry: () => _paginationController.loadInitial(),
        ),
      );
    }
    
    final prescriptions = _paginationController.items;
    
    if (prescriptions.isEmpty && !_paginationController.isLoading) {
      return SliverFillRemaining(
        child: _buildModernEmptyState(context),
      );
    }
    
    return dbAsync.when(
      data: (db) => SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: isCompact ? AppSpacing.md : AppSpacing.xl),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= prescriptions.length) {
                // Loading indicator at the end
                if (_paginationController.hasMore && _paginationController.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return const SizedBox.shrink();
              }
              
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
            childCount: prescriptions.length + (_paginationController.hasMore ? 1 : 0),
          ),
        ),
      ),
      loading: () => const SliverToBoxAdapter(
        child: PrescriptionListSkeleton(itemCount: 5),
      ),
      error: (err, stack) => SliverFillRemaining(
        child: ErrorState.generic(
          message: err.toString(),
          onRetry: () => ref.invalidate(doctorDbProvider),
        ),
      ),
    );
  }

  Widget _buildModernEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsivePadding),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xxl),
              ),
              child: Icon(
                Icons.medication_outlined,
                size: AppIconSize.xxl,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'No Prescriptions Yet',
              style: TextStyle(
                fontSize: AppFontSize.xxxl,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.displayLarge?.color,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Prescriptions will appear here when created from patient details',
              style: TextStyle(
                fontSize: AppFontSize.lg,
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
    // V5: Use compatibility methods to get all prescription data
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: db.getMedicationsForPrescriptionCompat(prescription.id),
      builder: (context, medsSnapshot) {
        final medications = medsSnapshot.data ?? [];
        
        // Get lab tests, follow-up, and notes using helper methods (with backwards compatibility)
        return FutureBuilder<Map<String, dynamic>>(
          future: Future.wait([
            db.getLabTestsForPrescriptionCompat(prescription.id),
            db.getFollowUpForPrescriptionCompat(prescription.id),
            db.getClinicalNotesForPrescriptionCompat(prescription.id),
          ]).then((results) => {
            'labTests': results[0] as List<Map<String, dynamic>>,
            'followUp': results[1] as Map<String, dynamic>?,
            'notes': results[2] as String,
          }),
          builder: (context, dataSnapshot) {
            final data = dataSnapshot.data ?? {'labTests': <Map<String, dynamic>>[], 'followUp': null, 'notes': ''};
            final labTestsData = data['labTests'] as List<Map<String, dynamic>>;
            final followUpData = data['followUp'] as Map<String, dynamic>?;
            final notesData = data['notes'] as String;
            
            // Convert to expected format
            final List<dynamic> labTests = labTestsData.map((test) => {
              'name': test['name'] ?? '',
            }).toList();
            final Map<String, dynamic> followUp = followUpData ?? {};
            final String notes = notesData;
    
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
              margin: EdgeInsets.only(bottom: isCompact ? AppSpacing.md : AppSpacing.lg),
              color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
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
                    padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
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
                        topLeft: Radius.circular(AppRadius.xxl),
                        topRight: Radius.circular(AppRadius.xxl),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isCompact ? AppSpacing.sm : AppSpacing.md),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.prescriptions,
                                    AppColors.prescriptions.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.md),
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
                                size: isCompact ? AppIconSize.sm : AppIconSize.md,
                              ),
                            ),
                            SizedBox(width: isCompact ? AppSpacing.sm : AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rx #${prescription.id}',
                                  style: TextStyle(
                                    fontSize: isCompact ? AppFontSize.md : AppFontSize.titleLarge,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                SizedBox(
                                  width: isCompact ? 100 : 140,
                                  child: Text(
                                    patientName,
                                    style: TextStyle(
                                      fontSize: isCompact ? AppFontSize.xs : AppFontSize.xs,
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
                                fontSize: isCompact ? AppFontSize.xs : AppFontSize.sm,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
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
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    prescription.isRefillable 
                                        ? Icons.autorenew_rounded 
                                        : Icons.do_not_disturb_rounded,
                                    size: AppIconSize.xs,
                                    color: prescription.isRefillable
                                        ? AppColors.success
                                        : theme.textTheme.bodySmall?.color,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    prescription.isRefillable ? 'Refill' : 'Once',
                                    style: TextStyle(
                                      fontSize: AppFontSize.xs,
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
                      padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_pharmacy_rounded, size: AppIconSize.xs, color: AppColors.primary),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      '${medications.length} medications',
                                      style: const TextStyle(
                                        fontSize: AppFontSize.xs,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...medications.take(3).map((med) {
                            final medMap = med as Map<String, dynamic>;
                            final name = medMap['name'] as String? ?? 'Unknown';
                            final dosage = medMap['dosage'] as String? ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.prescriptions, AppColors.primary],
                                      ),
                                      borderRadius: BorderRadius.circular(AppRadius.xs),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      '$name${dosage.isNotEmpty ? " • $dosage" : ""}',
                                      style: TextStyle(
                                        fontSize: isCompact ? AppFontSize.xs : AppFontSize.sm,
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
                              padding: const EdgeInsets.only(top: AppSpacing.xs),
                              child: Row(
                                children: [
                                  const SizedBox(width: AppSpacing.lg),
                                  Text(
                                    '+${medications.length - 3} more',
                                    style: const TextStyle(
                                      fontSize: AppFontSize.xs,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  const Icon(Icons.arrow_forward_rounded, size: AppIconSize.xs, color: AppColors.primary),
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
                      padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppRadius.xxl),
                          bottomRight: Radius.circular(AppRadius.xxl),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              size: AppIconSize.xs,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              prescription.instructions,
                              style: TextStyle(
                                fontSize: isCompact ? AppFontSize.xs : AppFontSize.sm,
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
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Header with back button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: AppIconSize.sm,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: AppColors.warning,
                      size: AppIconSize.lg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescription #${prescription.id}',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: AppIconSize.xs,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  dateFormat.format(prescription.createdAt),
                                  style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color,
                                    fontSize: AppFontSize.md,
                                  ),
                                ),
                              ],
                            ),
                            if (prescription.isRefillable)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, size: AppIconSize.xs, color: AppColors.success),
                                    SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Refillable',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: AppFontSize.xs,
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
              const SizedBox(height: AppSpacing.xxl),
              // Patient info
              if (patient != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
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
                    const SizedBox(width: AppSpacing.md),
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
                                  fontSize: AppFontSize.md,
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              // Summary card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warning.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.medication, color: AppColors.warning, size: AppIconSize.md),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${medications.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppFontSize.xxl,
                            color: AppColors.warning,
                          ),
                        ),
                        Text(
                          'Medications',
                          style: TextStyle(
                            fontSize: AppFontSize.sm,
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
                          size: AppIconSize.md,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          prescription.isRefillable ? 'Yes' : 'No',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppFontSize.xxl,
                            color: prescription.isRefillable ? AppColors.success : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        Text(
                          'Refillable',
                          style: TextStyle(
                            fontSize: AppFontSize.sm,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Medications title
              Row(
                children: [
                  const Icon(Icons.medication_outlined, color: AppColors.warning, size: AppIconSize.sm),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Medications (${medications.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
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
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    med['name'] as String? ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: AppFontSize.xl,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Divider(),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: AppSpacing.lg,
                              runSpacing: AppSpacing.md,
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
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.assignment_outlined, color: AppColors.info, size: AppIconSize.sm),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            "Doctor's Instructions",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info),
                            const SizedBox(width: AppSpacing.md),
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
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Icon(Icons.sick_outlined, color: Colors.orange[700], size: AppIconSize.sm),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Chief Complaint',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Icon(Icons.medical_information_outlined, color: Colors.purple[700], size: AppIconSize.sm),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Diagnosis',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Icon(Icons.science_outlined, color: Colors.teal[700], size: AppIconSize.sm),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Investigations (${labTests.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                        ),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: labTests.map((test) {
                            final testName = test is Map ? (test['name'] as String? ?? test.toString()) : test.toString();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline, size: AppIconSize.xs, color: Colors.teal[700]),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    testName,
                                    style: TextStyle(
                                      fontSize: AppFontSize.sm,
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
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Icon(Icons.event_outlined, color: Colors.green[700], size: AppIconSize.sm),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Follow-up',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: AppIconSize.sm, color: Colors.green[700]),
                            const SizedBox(width: AppSpacing.md),
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
                                      fontSize: AppFontSize.md,
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
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Icon(Icons.note_alt_outlined, color: Colors.grey[700], size: AppIconSize.sm),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Clinical Notes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
                    
                    const SizedBox(height: AppSpacing.lg),
                    // Action buttons - Row 1
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.primary(
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
                              if (result == true && mounted) {
                                // Refresh pagination controller
                                _paginationController.refresh();
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.sm),
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
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton.primary(
                            label: 'PDF',
                            icon: Icons.picture_as_pdf,
                            onPressed: () async {
                              Navigator.pop(context);
                              if (patient != null) {
                                try {
                                  final db = await ref.read(doctorDbProvider.future);
                                  final medications = await db.getMedicationsForPrescriptionCompat(prescription.id);
                                  
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
                                    medicationsList: medications,
                                    templateConfig: profile.pdfTemplateConfig,
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error generating PDF: $e'),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.xxl),
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
            SizedBox(width: AppSpacing.md),
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
                // Refresh pagination controller
                _paginationController.refresh();
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.xs, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSize.xs,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppFontSize.md,
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
            SizedBox(width: AppSpacing.md),
            Text('Refill Prescription'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create a new prescription with the same medications for ${patient.firstName} ${patient.lastName}?'),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: AppIconSize.sm),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'A new prescription will be created with today\'s date.',
                      style: TextStyle(fontSize: AppFontSize.md, color: AppColors.info),
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
        itemsJson: Value(prescription.itemsJson),
        instructions: Value(prescription.instructions),
        isRefillable: Value(prescription.isRefillable),
      );

      await db.insertPrescription(newPrescription);
      
      // Refresh pagination controller
      _paginationController.refresh();

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
