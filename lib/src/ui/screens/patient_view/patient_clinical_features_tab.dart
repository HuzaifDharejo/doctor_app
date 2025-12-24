// Patient View - Clinical Features Tab
// Displays Problem List, Family History, Immunizations, Allergies, Referrals, and Clinical Reminders

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/components/app_button.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../db/doctor_db.dart';
import '../../../providers/db_provider.dart';
import '../../../services/family_history_service.dart';
import '../../../services/problem_list_service.dart';
import '../../../services/immunization_service.dart';
import '../../../services/referral_service.dart';
import '../../../services/lab_order_service.dart';
import '../../../theme/app_theme.dart';
import '../../../extensions/drift_extensions.dart';
import '../allergy_management_screen.dart';
import '../family_history_screen.dart';
import '../problem_list_screen.dart';
import '../immunizations_screen.dart';
import '../referrals_screen.dart';
import '../lab_orders_screen.dart';
import '../../../core/extensions/context_extensions.dart';

/// Clinical Features Tab - Problem List, Family History, Immunizations, Allergies, Referrals
class PatientClinicalFeaturesTab extends ConsumerStatefulWidget {
  const PatientClinicalFeaturesTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  ConsumerState<PatientClinicalFeaturesTab> createState() => _PatientClinicalFeaturesTabState();
}

class _PatientClinicalFeaturesTabState extends ConsumerState<PatientClinicalFeaturesTab> {
  bool _isLoading = true;
  String? _error;

  // Data
  List<ProblemListData> _activeProblems = [];
  List<ProblemListData> _allProblems = [];
  List<FamilyMedicalHistoryData> _familyHistory = [];
  List<Immunization> _immunizations = [];
  List<Referral> _referrals = [];
  List<LabOrder> _labOrders = [];
  int _referralCount = 0;
  int _labOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = await ref.read(doctorDbProvider.future);
      final familyHistoryService = FamilyHistoryService(db: db);
      final problemListService = ProblemListService(db: db);
      final immunizationService = ImmunizationService(db: db);
      final referralService = ReferralService(db: db);
      final labOrderService = LabOrderService(db: db);

      // Load all data in parallel
      final results = await Future.wait([
        familyHistoryService.getFamilyHistoryForPatient(widget.patient.id),
        problemListService.getProblemsForPatient(widget.patient.id),
        problemListService.getActiveProblems(widget.patient.id),
        immunizationService.getImmunizationsForPatient(widget.patient.id),
        referralService.getReferralsForPatient(widget.patient.id),
        labOrderService.getLabOrdersForPatient(widget.patient.id),
      ]);

      if (mounted) {
        setState(() {
          _familyHistory = results[0] as List<FamilyMedicalHistoryData>;
          _allProblems = results[1] as List<ProblemListData>;
          _activeProblems = results[2] as List<ProblemListData>;
          _immunizations = results[3] as List<Immunization>;
          _referrals = results[4] as List<Referral>;
          _labOrders = results[5] as List<LabOrder>;
          _referralCount = _referrals.length;
          _labOrderCount = _labOrders.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load clinical features: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: TextStyle(color: AppColors.error)),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: 'Retry',
              onPressed: _loadData,
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Problem List Section
        _buildSectionHeader(
          'Problem List',
          Icons.assignment_rounded,
          _activeProblems.length,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProblemListScreen(patientId: widget.patient.id),
            ),
          ),
        ),
        if (_activeProblems.isEmpty)
          _buildEmptyState(
            'No active problems',
            'Add problems from encounters or manually',
            Icons.assignment_outlined,
            onAdd: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProblemListScreen(patientId: widget.patient.id),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _activeProblems.length) return null;
                  final problem = _activeProblems[index];
                  return _buildProblemCard(problem, isDark, surfaceColor);
                },
                childCount: _activeProblems.length > 3 ? 3 : _activeProblems.length,
              ),
            ),
          ),
        if (_activeProblems.length > 3)
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProblemListScreen(patientId: widget.patient.id),
                    ),
                  ),
                  child: const Text('View All Problems'),
                ),
              ),
            ),
          ),

        // Family History Section
        _buildSectionHeader(
          'Family History',
          Icons.family_restroom_rounded,
          _familyHistory.length,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FamilyHistoryScreen(patientId: widget.patient.id),
            ),
          ),
        ),
        if (_familyHistory.isEmpty)
          _buildEmptyState(
            'No family history recorded',
            'Add family medical history',
            Icons.family_restroom_outlined,
            onAdd: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FamilyHistoryScreen(patientId: widget.patient.id),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _familyHistory.length) return null;
                  final history = _familyHistory[index];
                  return _buildFamilyHistoryCard(history, isDark, surfaceColor);
                },
                childCount: _familyHistory.length > 3 ? 3 : _familyHistory.length,
              ),
            ),
          ),
        if (_familyHistory.length > 3)
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FamilyHistoryScreen(patientId: widget.patient.id),
                    ),
                  ),
                  child: const Text('View All Family History'),
                ),
              ),
            ),
          ),

        // Immunizations Section
        _buildSectionHeader(
          'Immunizations',
          Icons.vaccines_rounded,
          _immunizations.length,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImmunizationsScreen(patientId: widget.patient.id),
            ),
          ),
        ),
        if (_immunizations.isEmpty)
          _buildEmptyState(
            'No immunizations recorded',
            'Add immunization records',
            Icons.vaccines_outlined,
            onAdd: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImmunizationsScreen(patientId: widget.patient.id),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _immunizations.length) return null;
                  final immunization = _immunizations[index];
                  return _buildImmunizationCard(immunization, isDark, surfaceColor);
                },
                childCount: _immunizations.length > 3 ? 3 : _immunizations.length,
              ),
            ),
          ),
        if (_immunizations.length > 3)
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImmunizationsScreen(patientId: widget.patient.id),
                    ),
                  ),
                  child: const Text('View All Immunizations'),
                ),
              ),
            ),
          ),

        // Allergies Section
        _buildSectionHeader(
          'Allergies',
          Icons.warning_rounded,
          widget.patient.allergies?.isNotEmpty == true ? 1 : 0,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AllergyManagementScreen(patientId: widget.patient.id),
            ),
          ),
        ),
        if (widget.patient.allergies?.isEmpty != false)
          _buildEmptyState(
            'No allergies recorded',
            'Add patient allergies',
            Icons.warning_outlined,
            onAdd: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllergyManagementScreen(patientId: widget.patient.id),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: _buildAllergyCard(widget.patient.allergies!, isDark, surfaceColor),
            ),
          ),

        // Referrals Section
        _buildSectionHeader(
          'Referrals',
          Icons.forward_to_inbox_rounded,
          _referralCount,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReferralsScreen(patientId: widget.patient.id),
            ),
          ),
        ),
        if (_referrals.isEmpty)
          _buildEmptyState(
            'No referrals',
            'Create referrals to specialists',
            Icons.forward_to_inbox_outlined,
            onAdd: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReferralsScreen(patientId: widget.patient.id),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _referrals.length) return null;
                  final referral = _referrals[index];
                  return _buildReferralCard(referral, isDark, surfaceColor);
                },
                childCount: _referrals.length > 3 ? 3 : _referrals.length,
              ),
            ),
          ),
        if (_referrals.length > 3)
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReferralsScreen(patientId: widget.patient.id),
                    ),
                  ),
                  child: const Text('View All Referrals'),
                ),
              ),
            ),
          ),

        // Lab Orders Section
        _buildSectionHeader(
          'Lab Orders',
          Icons.science_rounded,
          _labOrderCount,
          onViewAll: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LabOrdersScreen(patientId: widget.patient.id),
            ),
          ),
        ),
        if (_labOrders.isEmpty)
          _buildEmptyState(
            'No lab orders',
            'Create lab orders for tests',
            Icons.science_outlined,
            onAdd: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LabOrdersScreen(patientId: widget.patient.id),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= _labOrders.length) return null;
                  final labOrder = _labOrders[index];
                  return _buildLabOrderCard(labOrder, isDark, surfaceColor);
                },
                childCount: _labOrders.length > 3 ? 3 : _labOrders.length,
              ),
            ),
          ),
        if (_labOrders.length > 3)
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabOrdersScreen(patientId: widget.patient.id),
                    ),
                  ),
                  child: const Text('View All Lab Orders'),
                ),
              ),
            ),
          ),

        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count, {VoidCallback? onViewAll}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSize.lg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Spacer(),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, {VoidCallback? onAdd}) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Icon(icon, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppFontSize.md,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: AppFontSize.sm,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (onAdd != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton.secondary(
                  label: 'Add',
                  icon: Icons.add,
                  onPressed: onAdd,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProblemCard(ProblemListData problem, bool isDark, Color surfaceColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: surfaceColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: problem.status == 'active'
              ? AppColors.error.withValues(alpha: 0.15)
              : AppColors.success.withValues(alpha: 0.15),
          child: Icon(
            problem.status == 'active' ? Icons.warning_rounded : Icons.check_circle_rounded,
            color: problem.status == 'active' ? AppColors.error : AppColors.success,
            size: 20,
          ),
        ),
        title: Text(
          problem.problemName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (problem.icdCode.isNotEmpty)
              Text('ICD-10: ${problem.icdCode}'),
            if (problem.onsetDate != null)
              Text('Onset: ${DateFormat('MMM dd, yyyy').format(problem.onsetDate!)}'),
            Text(
              'Status: ${problem.status.toUpperCase()}',
              style: TextStyle(
                color: problem.status == 'active' ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProblemListScreen(patientId: widget.patient.id),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyHistoryCard(FamilyMedicalHistoryData history, bool isDark, Color surfaceColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: surfaceColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: const Icon(Icons.family_restroom_rounded, color: AppColors.primary, size: 20),
        ),
        title: Text(
          history.condition.isNotEmpty ? history.condition : 'Family History',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Relationship: ${history.relationship}'),
            if (history.ageAtOnset != null) Text('Age at Onset: ${history.ageAtOnset}'),
            if (history.notes.isNotEmpty)
              Text(
                history.notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FamilyHistoryScreen(patientId: widget.patient.id),
          ),
        ),
      ),
    );
  }

  Widget _buildImmunizationCard(Immunization immunization, bool isDark, Color surfaceColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: surfaceColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.success.withValues(alpha: 0.15),
          child: const Icon(Icons.vaccines_rounded, color: AppColors.success, size: 20),
        ),
        title: Text(
          immunization.vaccineName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${DateFormat('MMM dd, yyyy').format(immunization.dateAdministered)}'),
            if (immunization.doseNumber != null) Text('Dose: ${immunization.doseNumber}'),
            if (immunization.nextDueDate != null)
              Text('Next Due: ${DateFormat('MMM dd, yyyy').format(immunization.nextDueDate!)}'),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImmunizationsScreen(patientId: widget.patient.id),
          ),
        ),
      ),
    );
  }

  Widget _buildAllergyCard(String allergies, bool isDark, Color surfaceColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: surfaceColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
          child: const Icon(Icons.warning_rounded, color: AppColors.warning, size: 20),
        ),
        title: const Text(
          'Known Allergies',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(allergies),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AllergyManagementScreen(patientId: widget.patient.id),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCard(Referral referral, bool isDark, Color surfaceColor) {
    Color statusColor;
    IconData statusIcon;
    switch (referral.status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_rounded;
        break;
      case 'scheduled':
        statusColor = AppColors.info;
        statusIcon = Icons.calendar_today_rounded;
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.info_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: surfaceColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          referral.specialty,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${DateFormat('MMM dd, yyyy').format(referral.referralDate)}'),
            Text('Status: ${referral.status.toUpperCase()}'),
            if (referral.reasonForReferral.isNotEmpty)
              Text(
                referral.reasonForReferral,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReferralsScreen(patientId: widget.patient.id),
          ),
        ),
      ),
    );
  }

  String _getLabOrderTestNames(LabOrder labOrder) {
    if (labOrder.testNames.isEmpty || labOrder.testNames == '[]') {
      return 'Lab Order';
    }
    
    try {
      // Try to parse as JSON array
      if (labOrder.testNames.startsWith('[')) {
        final parsed = jsonDecode(labOrder.testNames) as List;
        if (parsed.isNotEmpty) {
          return parsed.map((e) => e.toString()).join(', ');
        }
      } else {
        // Try comma-separated string
        final names = labOrder.testNames.split(',').where((s) => s.trim().isNotEmpty).toList();
        if (names.isNotEmpty) {
          return names.join(', ');
        }
      }
    } catch (_) {
      // If parsing fails, return as-is if it looks like a simple string
      if (!labOrder.testNames.startsWith('[') && !labOrder.testNames.startsWith('{')) {
        return labOrder.testNames;
      }
    }
    
    return 'Lab Order';
  }

  Widget _buildLabOrderCard(LabOrder labOrder, bool isDark, Color surfaceColor) {
    Color statusColor;
    IconData statusIcon;
    switch (labOrder.status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_rounded;
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.info_rounded;
    }

    final testNames = _getLabOrderTestNames(labOrder);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: surfaceColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          testNames,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #: ${labOrder.orderNumber}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(labOrder.orderDate)}'),
            Text('Status: ${labOrder.status.toUpperCase()}'),
            if (labOrder.priority.isNotEmpty)
              Text('Priority: ${labOrder.priority.toUpperCase()}'),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LabOrdersScreen(patientId: widget.patient.id),
          ),
        ),
      ),
    );
  }
}

