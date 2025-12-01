import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/doctor_db.dart';
import '../../theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../screens/add_appointment_screen.dart';
import '../screens/add_patient_screen.dart';
import '../screens/add_prescription_screen.dart';
import '../screens/psychiatric_assessment_screen_modern.dart';
import '../screens/pulmonary_evaluation_screen_modern.dart';
import '../screens/records/select_record_type_screen.dart';

/// Exam Room Toolbar
/// Optimized for fast access in clinical environments
/// Features: Large 48x48 touch targets, landscape support, haptic feedback
class ExamRoomToolbar extends ConsumerWidget {
  const ExamRoomToolbar({
    this.preselectedPatient,
    super.key,
  });

  final Patient? preselectedPatient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    
    // Responsive grid: 3 columns on portrait, 6 on landscape
    final crossAxisCount = isLandscape ? 6 : 3;

    return Container(
      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Exam Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Grid of quick action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1 / 1.1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ExamActionButton(
                  icon: Icons.favorite_rounded,
                  label: 'Vitals',
                  color: const Color(0xFFEF4444),
                  onTap: () => _showVitalsEntry(context),
                ),
                _ExamActionButton(
                  icon: Icons.event_note_rounded,
                  label: 'Appointment',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _navigateTo(
                    context,
                    const AddAppointmentScreen(),
                  ),
                ),
                _ExamActionButton(
                  icon: Icons.psychology_rounded,
                  label: 'Psych',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PsychiatricAssessmentScreenModern(),
                    ),
                  ),
                ),
                _ExamActionButton(
                  icon: Icons.air_rounded,
                  label: 'Pulmonary',
                  color: const Color(0xFFEC4899),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PulmonaryEvaluationScreenModern(),
                    ),
                  ),
                ),
                _ExamActionButton(
                  icon: Icons.description_rounded,
                  label: 'Record',
                  color: const Color(0xFF14B8A6),
                  onTap: () => _navigateTo(
                    context,
                    const SelectRecordTypeScreen(),
                  ),
                ),
                _ExamActionButton(
                  icon: Icons.medication_rounded,
                  label: 'Prescription',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _navigateTo(
                    context,
                    const AddPrescriptionScreen(),
                  ),
                ),
                _ExamActionButton(
                  icon: Icons.person_add_rounded,
                  label: 'New Patient',
                  color: const Color(0xFF6366F1),
                  onTap: () => _navigateTo(
                    context,
                    const AddPatientScreen(),
                  ),
                ),
                _ExamActionButton(
                  icon: Icons.follow_the_signs_rounded,
                  label: 'Follow-up',
                  color: const Color(0xFF06B6D4),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Follow-up scheduling coming soon')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _showVitalsEntry(BuildContext context) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick vitals entry - feature in development')),
    );
  }
}

/// Individual exam action button with large touch target (48x48 minimum)
class _ExamActionButton extends StatelessWidget {
  const _ExamActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        // Ensures touch target is at least 48x48
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container with minimum 48x48 touch target
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              // Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

