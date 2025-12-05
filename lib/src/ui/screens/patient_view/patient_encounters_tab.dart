import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../db/doctor_db.dart';
import '../../../providers/encounter_provider.dart';
import '../../../services/encounter_service.dart';
import '../../../theme/app_theme.dart';
import '../encounter_screen.dart';

/// Tab showing patient's encounter history
class PatientEncountersTab extends ConsumerWidget {
  const PatientEncountersTab({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final encountersAsync = ref.watch(patientEncountersProvider(patient.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return encountersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error loading encounters: $error'),
          ],
        ),
      ),
      data: (encounters) {
        if (encounters.isEmpty) {
          return _buildEmptyState(context, isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: encounters.length,
          itemBuilder: (context, index) {
            final encounter = encounters[index];
            return _EncounterCard(
              encounter: encounter,
              patient: patient,
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primary : AppColors.primary)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Encounters Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Encounters will appear here when the patient\nhas clinical visits recorded',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EncounterCard extends StatelessWidget {
  const _EncounterCard({
    required this.encounter,
    required this.patient,
    required this.isDark,
  });

  final Encounter encounter;
  final Patient patient;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final encounterDate = encounter.encounterDate;
    final checkInTime = encounter.checkInTime;
    final checkOutTime = encounter.checkOutTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEncounter(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  _buildStatusBadge(),
                  const Spacer(),
                  Text(
                    dateFormat.format(encounterDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Encounter type and ID
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getTypeColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      color: _getTypeColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatEncounterType(encounter.encounterType),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Encounter #${encounter.id}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ],
              ),

              // Chief complaint
              if (encounter.chiefComplaint.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          encounter.chiefComplaint,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Time details
              const SizedBox(height: 12),
              Row(
                children: [
                  if (checkInTime != null) ...[
                    _buildTimeChip(
                      icon: Icons.login_rounded,
                      label: 'In: ${timeFormat.format(checkInTime)}',
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (checkOutTime != null) ...[
                    _buildTimeChip(
                      icon: Icons.logout_rounded,
                      label: 'Out: ${timeFormat.format(checkOutTime)}',
                    ),
                  ],
                  if (checkInTime != null && checkOutTime != null) ...[
                    const Spacer(),
                    Text(
                      _formatDuration(checkInTime, checkOutTime),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),

              // Provider
              if (encounter.providerName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      encounter.providerName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = encounter.status;
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'in_progress':
        color = AppColors.warning;
        icon = Icons.hourglass_top_rounded;
        label = 'In Progress';
      case 'completed':
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        label = 'Completed';
      case 'cancelled':
        color = AppColors.error;
        icon = Icons.cancel_rounded;
        label = 'Cancelled';
      case 'no_show':
        color = Colors.grey;
        icon = Icons.person_off_rounded;
        label = 'No Show';
      default:
        color = Colors.grey;
        icon = Icons.pending_rounded;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isDark ? Colors.white70 : Colors.black54),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (encounter.encounterType) {
      case 'initial':
        return AppColors.primary;
      case 'follow_up':
        return Colors.blue;
      case 'urgent':
        return AppColors.error;
      case 'consultation':
        return Colors.purple;
      case 'emergency':
        return AppColors.error;
      default:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon() {
    switch (encounter.encounterType) {
      case 'initial':
        return Icons.person_add_rounded;
      case 'follow_up':
        return Icons.event_repeat_rounded;
      case 'urgent':
        return Icons.priority_high_rounded;
      case 'consultation':
        return Icons.psychology_rounded;
      case 'emergency':
        return Icons.emergency_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  String _formatEncounterType(String type) {
    switch (type) {
      case 'initial':
        return 'Initial Visit';
      case 'follow_up':
        return 'Follow-up Visit';
      case 'urgent':
        return 'Urgent Visit';
      case 'consultation':
        return 'Consultation';
      case 'emergency':
        return 'Emergency';
      default:
        return type
            .split('_')
            .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    }
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  void _openEncounter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EncounterScreen(
          encounterId: encounter.id,
          patient: patient,
        ),
      ),
    );
  }
}
