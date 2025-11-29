/// Empty state widget for lists and content areas
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../constants/app_constants.dart';

class EmptyState extends StatefulWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Color? iconColor;
  final bool animate;

  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_rounded,
    this.action,
    this.onAction,
    this.actionLabel,
    this.iconColor,
    this.animate = true,
  });

  /// Creates an empty state for patients list
  const EmptyState.patients({
    super.key,
    this.onAction,
    this.animate = true,
  })  : title = 'No patients yet',
        message = 'Add your first patient to get started',
        icon = Icons.people_outline_rounded,
        action = null,
        actionLabel = 'Add Patient',
        iconColor = AppColors.patients;

  /// Creates an empty state for appointments list
  const EmptyState.appointments({
    super.key,
    this.onAction,
    this.animate = true,
  })  : title = 'No appointments',
        message = 'Schedule an appointment to get started',
        icon = Icons.calendar_today_rounded,
        action = null,
        actionLabel = 'Add Appointment',
        iconColor = AppColors.appointments;

  /// Creates an empty state for prescriptions list
  const EmptyState.prescriptions({
    super.key,
    this.onAction,
    this.animate = true,
  })  : title = 'No prescriptions',
        message = 'Create a prescription to get started',
        icon = Icons.medication_outlined,
        action = null,
        actionLabel = 'Add Prescription',
        iconColor = AppColors.prescriptions;

  /// Creates an empty state for invoices list
  const EmptyState.invoices({
    super.key,
    this.onAction,
    this.animate = true,
  })  : title = 'No invoices',
        message = 'Create an invoice to get started',
        icon = Icons.receipt_long_outlined,
        action = null,
        actionLabel = 'Create Invoice',
        iconColor = AppColors.billing;

  /// Creates an empty state for search results
  const EmptyState.searchResults({
    super.key,
    String? query,
  })  : title = 'No results found',
        message = query != null ? 'Try searching for something else' : null,
        icon = Icons.search_off_rounded,
        action = null,
        onAction = null,
        actionLabel = null,
        iconColor = null,
        animate = true;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _contentController;
  late Animation<double> _iconScale;
  late Animation<double> _iconBounce;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    
    // Icon breathing animation
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _iconScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
    
    _iconBounce = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
    
    // Content fade and slide animation
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    if (widget.animate) {
      _iconController.repeat(reverse: true);
      _contentController.forward();
    } else {
      _contentController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = widget.iconColor ?? colorScheme.primary;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Icon
                AnimatedBuilder(
                  animation: _iconController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -_iconBounce.value),
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          effectiveIconColor.withValues(alpha: 0.15),
                          effectiveIconColor.withValues(alpha: 0.05),
                        ],
                        radius: 0.8,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: effectiveIconColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: AppIconSize.xxl,
                      color: effectiveIconColor,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                
                // Title
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: AppFontSize.xxl,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Message
                if (widget.message != null) ...[
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.message!,
                    style: TextStyle(
                      fontSize: AppFontSize.lg,
                      color: isDark 
                          ? AppColors.darkTextSecondary 
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                SizedBox(height: AppSpacing.xl),
                
                // Animated Action button or custom action
                if (widget.action != null)
                  widget.action!
                else if (widget.onAction != null && widget.actionLabel != null)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.9, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: ElevatedButton.icon(
                      onPressed: widget.onAction,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(widget.actionLabel!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: effectiveIconColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        elevation: 4,
                        shadowColor: effectiveIconColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact empty state for inline use with subtle animation
class EmptyStateCompact extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool animate;

  const EmptyStateCompact({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: AppIconSize.md,
          color: isDark 
              ? AppColors.darkTextSecondary 
              : AppColors.textSecondary,
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          message,
          style: TextStyle(
            color: isDark 
                ? AppColors.darkTextSecondary 
                : AppColors.textSecondary,
            fontSize: AppFontSize.lg,
          ),
        ),
      ],
    );

    if (animate) {
      content = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: child,
            ),
          );
        },
        child: content,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: content,
    );
  }
}
