import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/doctor_db.dart';
import '../../theme/app_theme.dart';

/// Wait Time Statistics Calculator
/// 
/// Calculates average wait times, turnaround times, and queue metrics
/// for dashboard display and clinic efficiency monitoring.
class WaitTimeStats {
  WaitTimeStats({
    required this.averageWaitMinutes,
    required this.averageVisitMinutes,
    required this.totalPatientsToday,
    required this.currentQueueLength,
    required this.estimatedWaitMinutes,
    this.longestWaitMinutes,
    this.peakHour,
  });

  final double averageWaitMinutes;
  final double averageVisitMinutes;
  final int totalPatientsToday;
  final int currentQueueLength;
  final int estimatedWaitMinutes;
  final int? longestWaitMinutes;
  final int? peakHour; // Hour of day with most appointments

  /// Format wait time as readable string
  String get formattedAverageWait {
    if (averageWaitMinutes < 1) return '< 1 min';
    if (averageWaitMinutes < 60) return '${averageWaitMinutes.round()} min';
    final hours = (averageWaitMinutes / 60).floor();
    final mins = (averageWaitMinutes % 60).round();
    return '${hours}h ${mins}m';
  }

  String get formattedEstimatedWait {
    if (estimatedWaitMinutes < 1) return '< 1 min';
    if (estimatedWaitMinutes < 60) return '~$estimatedWaitMinutes min';
    final hours = (estimatedWaitMinutes / 60).floor();
    final mins = (estimatedWaitMinutes % 60);
    return '~${hours}h ${mins}m';
  }

  /// Get wait time rating (good, okay, long)
  WaitTimeRating get rating {
    if (averageWaitMinutes <= 15) return WaitTimeRating.excellent;
    if (averageWaitMinutes <= 30) return WaitTimeRating.good;
    if (averageWaitMinutes <= 45) return WaitTimeRating.okay;
    return WaitTimeRating.long;
  }
}

enum WaitTimeRating { excellent, good, okay, long }

/// Calculate wait time statistics from database
Future<WaitTimeStats> calculateWaitTimeStats(DoctorDatabase db) async {
  final today = DateTime.now();
  final todayAppts = await db.getAppointmentsForDay(today);
  final todayEncounters = await db.getTodaysEncounters();

  // Calculate average wait time from encounters with check-in times
  double totalWaitMinutes = 0;
  double totalVisitMinutes = 0;
  int waitSamples = 0;
  int visitSamples = 0;
  int? longestWait;
  
  // Track appointments per hour for peak detection
  final hourCounts = <int, int>{};

  for (final appt in todayAppts) {
    final hour = appt.appointmentDateTime.hour;
    hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
  }

  for (final enc in todayEncounters) {
    // Find corresponding appointment
    if (enc.appointmentId != null) {
      final appt = todayAppts.firstWhere(
        (a) => a.id == enc.appointmentId,
        orElse: () => todayAppts.first,
      );

      // Calculate wait time (appointment time to check-in time)
      if (enc.checkInTime != null) {
        final waitMins = enc.checkInTime!.difference(appt.appointmentDateTime).inMinutes.abs();
        // Only count reasonable wait times (< 2 hours)
        if (waitMins < 120) {
          totalWaitMinutes += waitMins;
          waitSamples++;
          if (longestWait == null || waitMins > longestWait) {
            longestWait = waitMins;
          }
        }
      }

      // Calculate visit duration (check-in to check-out)
      if (enc.checkInTime != null && enc.checkOutTime != null) {
        final visitMins = enc.checkOutTime!.difference(enc.checkInTime!).inMinutes;
        if (visitMins > 0 && visitMins < 180) {
          totalVisitMinutes += visitMins;
          visitSamples++;
        }
      }
    }
  }

  // Calculate averages
  final avgWait = waitSamples > 0 ? totalWaitMinutes / waitSamples : 0.0;
  final avgVisit = visitSamples > 0 ? totalVisitMinutes / visitSamples : 15.0; // Default 15 min

  // Calculate current queue length
  final pendingAppts = todayAppts.where((a) => 
    a.status == 'scheduled' || a.status == 'pending' || a.status == 'checked_in'
  ).length;

  // Estimate wait for new patient = pending * average visit time
  final estimatedWait = (pendingAppts * avgVisit).round();

  // Find peak hour
  int? peakHour;
  int maxCount = 0;
  hourCounts.forEach((hour, count) {
    if (count > maxCount) {
      maxCount = count;
      peakHour = hour;
    }
  });

  return WaitTimeStats(
    averageWaitMinutes: avgWait,
    averageVisitMinutes: avgVisit,
    totalPatientsToday: todayAppts.length,
    currentQueueLength: pendingAppts,
    estimatedWaitMinutes: estimatedWait,
    longestWaitMinutes: longestWait,
    peakHour: peakHour,
  );
}

/// Wait Time Card Widget for Dashboard
class WaitTimeCard extends StatelessWidget {
  const WaitTimeCard({
    super.key,
    required this.stats,
    required this.isCompact,
    required this.isDark,
  });

  final WaitTimeStats stats;
  final bool isCompact;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ratingColor = _getRatingColor(stats.rating);
    final ratingText = _getRatingText(stats.rating);

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ratingColor.withValues(alpha: 0.3)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: ratingColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ratingColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      color: ratingColor,
                      size: isCompact ? 18 : 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Wait Time',
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ratingColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ratingText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ratingColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 14 : 18),
          // Stats Row
          Row(
            children: [
              // Average Wait
              Expanded(
                child: _buildStatItem(
                  label: 'Avg Wait',
                  value: stats.formattedAverageWait,
                  icon: Icons.hourglass_empty_rounded,
                  color: ratingColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              // Queue Length
              Expanded(
                child: _buildStatItem(
                  label: 'In Queue',
                  value: '${stats.currentQueueLength}',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              // Est. Wait
              Expanded(
                child: _buildStatItem(
                  label: 'Est. Wait',
                  value: stats.formattedEstimatedWait,
                  icon: Icons.schedule_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          // Peak hour indicator
          if (stats.peakHour != null) ...[
            SizedBox(height: isCompact ? 10 : 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    size: 14,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Peak: ${_formatHour(stats.peakHour!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: isCompact ? 16 : 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 10 : 11,
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(WaitTimeRating rating) {
    switch (rating) {
      case WaitTimeRating.excellent:
        return AppColors.quickActionGreen;
      case WaitTimeRating.good:
        return AppColors.blue;
      case WaitTimeRating.okay:
        return AppColors.warning;
      case WaitTimeRating.long:
        return AppColors.error;
    }
  }

  String _getRatingText(WaitTimeRating rating) {
    switch (rating) {
      case WaitTimeRating.excellent:
        return 'Excellent';
      case WaitTimeRating.good:
        return 'Good';
      case WaitTimeRating.okay:
        return 'Moderate';
      case WaitTimeRating.long:
        return 'Long';
    }
  }

  String _formatHour(int hour) {
    final time = DateTime(2024, 1, 1, hour);
    return DateFormat('h a').format(time);
  }
}
