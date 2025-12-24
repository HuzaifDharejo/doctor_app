import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../db/doctor_db.dart';
import '../../providers/db_provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Quick Stats Dashboard Widget
/// Shows unified stats with click-to-view-details functionality
class QuickStatsDashboard extends ConsumerWidget {
  const QuickStatsDashboard({
    super.key,
    this.onStatTap,
  });

  final void Function(String statType)? onStatTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(doctorDbProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return dbAsync.when(
      data: (db) => FutureBuilder<_StatsData>(
        future: _loadStats(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(isDark);
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error.toString(), isDark);
          }

          final stats = snapshot.data ?? _StatsData.empty();
          return _buildStatsGrid(context, stats, isDark);
        },
      ),
      loading: () => _buildLoadingState(isDark),
      error: (err, _) => _buildErrorState(context, err.toString(), isDark),
    );
  }

  Future<_StatsData> _loadStats(DoctorDatabase db) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    // Load stats in parallel
    final results = await Future.wait([
      // Patients seen today (from appointments with status completed or in_progress)
      db.getAppointmentsForDay(today).then((appts) => appts
          .where((a) => a.status == 'completed' || a.status == 'in_progress')
          .length),
      // Total appointments today
      db.getAppointmentsForDay(today).then((appts) => appts.length),
      // Pending prescriptions (active prescriptions)
      db.getAllPrescriptions().then((rx) => rx
          .where((p) => p.createdAt.isAfter(startOfDay))
          .length),
      // Lab results pending (count from database - filter in Dart for simplicity)
      db.select(db.labOrders).get().then((orders) {
        return orders.where((o) => 
          o.status == 'pending' || 
          o.status == 'ordered' || 
          o.status == 'in_progress').length;
      }).catchError((_) => 0),
      // Unpaid invoices total
      db.getAllInvoices().then((invoices) {
        final unpaid = invoices.where((inv) => inv.paymentStatus != 'paid');
        return unpaid.fold<double>(0.0, (sum, inv) => sum + inv.grandTotal);
      }),
    ]);

    return _StatsData(
      patientsSeenToday: results[0] as int,
      totalAppointmentsToday: results[1] as int,
      pendingPrescriptions: results[2] as int,
      labResultsPending: results[3] as int,
      unpaidInvoicesTotal: results[4] as double,
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.0, // Reduced to give more height and prevent overflow
        children: List.generate(4, (index) => _buildStatCardSkeleton(isDark)),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load stats',
              style: TextStyle(
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, _StatsData stats, bool isDark) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.0, // Reduced to give more height and prevent overflow
        children: [
          _buildStatCard(
            context,
            title: 'Patients Seen',
            value: '${stats.patientsSeenToday}/${stats.totalAppointmentsToday}',
            icon: Icons.people_rounded,
            color: AppColors.patients,
            progress: stats.totalAppointmentsToday > 0
                ? stats.patientsSeenToday / stats.totalAppointmentsToday
                : 0.0,
            onTap: () => onStatTap?.call('patients'),
            isDark: isDark,
          ),
          _buildStatCard(
            context,
            title: 'Pending Rx',
            value: '${stats.pendingPrescriptions}',
            icon: Icons.pending_actions_rounded,
            color: AppColors.warning,
            onTap: () => onStatTap?.call('prescriptions'),
            isDark: isDark,
          ),
          _buildStatCard(
            context,
            title: 'Lab Results',
            value: '${stats.labResultsPending}',
            icon: Icons.science_rounded,
            color: AppColors.info,
            onTap: () => onStatTap?.call('labs'),
            isDark: isDark,
          ),
          _buildStatCard(
            context,
            title: 'Unpaid',
            value: currencyFormat.format(stats.unpaidInvoicesTotal),
            icon: Icons.receipt_long_rounded,
            color: AppColors.error,
            onTap: () => onStatTap?.call('invoices'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double? progress,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs), // Minimal padding to maximize space
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: AppFontSize.lg,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppFontSize.sm,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (progress != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark
                        ? AppColors.darkDivider
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCardSkeleton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs), // Minimal padding to maximize space
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 80,
                height: 10,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsData {
  final int patientsSeenToday;
  final int totalAppointmentsToday;
  final int pendingPrescriptions;
  final int labResultsPending;
  final double unpaidInvoicesTotal;

  _StatsData({
    required this.patientsSeenToday,
    required this.totalAppointmentsToday,
    required this.pendingPrescriptions,
    required this.labResultsPending,
    required this.unpaidInvoicesTotal,
  });

  factory _StatsData.empty() {
    return _StatsData(
      patientsSeenToday: 0,
      totalAppointmentsToday: 0,
      pendingPrescriptions: 0,
      labResultsPending: 0,
      unpaidInvoicesTotal: 0.0,
    );
  }
}

