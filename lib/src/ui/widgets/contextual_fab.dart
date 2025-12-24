import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Context type determines which quick actions to show
enum FABContext {
  patientView,
  appointments,
  dashboard,
}

/// Contextual Floating Action Button that adapts based on screen context
class ContextualFAB extends StatelessWidget {
  const ContextualFAB({
    super.key,
    required this.context,
    this.onNewVisit,
    this.onPrescription,
    this.onLabOrder,
    this.onInvoice,
    this.onCheckInSelected,
    this.onStartConsultation,
    this.onQuickPatientAdd,
    this.onTodaysQueue,
    this.emergencyButton,
  });

  final FABContext context;
  
  // Patient View actions
  final VoidCallback? onNewVisit;
  final VoidCallback? onPrescription;
  final VoidCallback? onLabOrder;
  final VoidCallback? onInvoice;
  
  // Appointments actions
  final VoidCallback? onCheckInSelected;
  final VoidCallback? onStartConsultation;
  
  // Dashboard actions
  final VoidCallback? onQuickPatientAdd;
  final VoidCallback? onTodaysQueue;
  
  // Optional emergency info button (for patient view)
  final Widget? emergencyButton;

  @override
  Widget build(BuildContext context) {
    switch (this.context) {
      case FABContext.patientView:
        return _buildPatientViewFAB(context);
      case FABContext.appointments:
        return _buildAppointmentsFAB(context);
      case FABContext.dashboard:
        return _buildDashboardFAB(context);
    }
  }

  Widget _buildPatientViewFAB(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (emergencyButton != null) ...[
          emergencyButton!,
          const SizedBox(height: 12),
        ],
        FloatingActionButton.extended(
          heroTag: 'patient_actions',
          onPressed: () => _showPatientViewActions(context),
          tooltip: 'Quick Actions',
          backgroundColor: Colors.transparent,
          elevation: 0,
          extendedPadding: EdgeInsets.zero,
          label: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'New Action',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsFAB(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'appointments_actions',
      onPressed: () => _showAppointmentsActions(context),
      tooltip: 'Quick Actions',
      backgroundColor: Colors.transparent,
      elevation: 0,
      extendedPadding: EdgeInsets.zero,
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.successGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardFAB(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'dashboard_actions',
      onPressed: () => _showDashboardActions(context),
      tooltip: 'Quick Actions',
      backgroundColor: Colors.transparent,
      elevation: 0,
      extendedPadding: EdgeInsets.zero,
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPatientViewActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Actions Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    if (onNewVisit != null)
                      _buildActionTile(
                        context: context,
                        icon: Icons.play_circle_filled_rounded,
                        label: 'New Visit',
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          onNewVisit!();
                        },
                      ),
                    if (onPrescription != null)
                      _buildActionTile(
                        context: context,
                        icon: Icons.medication_rounded,
                        label: 'Prescription',
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          onPrescription!();
                        },
                      ),
                    if (onLabOrder != null)
                      _buildActionTile(
                        context: context,
                        icon: Icons.science_rounded,
                        label: 'Lab Order',
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          onLabOrder!();
                        },
                      ),
                    if (onInvoice != null)
                      _buildActionTile(
                        context: context,
                        icon: Icons.receipt_long_rounded,
                        label: 'Invoice',
                        color: const Color(0xFF6366F1),
                        isDark: isDark,
                        onTap: () {
                          Navigator.pop(context);
                          onInvoice!();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppointmentsActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.successGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (onCheckInSelected != null)
                  _buildActionButton(
                    context: context,
                    icon: Icons.login_rounded,
                    label: 'Check-In Selected',
                    color: AppColors.success,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onCheckInSelected!();
                    },
                  ),
                if (onCheckInSelected != null && onStartConsultation != null)
                  const SizedBox(height: 12),
                if (onStartConsultation != null)
                  _buildActionButton(
                    context: context,
                    icon: Icons.play_arrow_rounded,
                    label: 'Start Consultation',
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onStartConsultation!();
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDashboardActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (onQuickPatientAdd != null)
                  _buildActionButton(
                    context: context,
                    icon: Icons.person_add_rounded,
                    label: 'Quick Patient Add',
                    color: AppColors.primary,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onQuickPatientAdd!();
                    },
                  ),
                if (onQuickPatientAdd != null && onTodaysQueue != null)
                  const SizedBox(height: 12),
                if (onTodaysQueue != null)
                  _buildActionButton(
                    context: context,
                    icon: Icons.queue_rounded,
                    label: "Today's Queue",
                    color: AppColors.success,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      onTodaysQueue!();
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(icon, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
