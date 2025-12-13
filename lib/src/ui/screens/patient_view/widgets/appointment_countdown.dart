import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Countdown widget for upcoming appointments
class AppointmentCountdown extends StatelessWidget {
  const AppointmentCountdown({
    super.key,
    required this.appointmentDateTime,
    this.appointmentType,
    this.onReschedule,
    this.onCancel,
  });

  final DateTime appointmentDateTime;
  final String? appointmentType;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  String _getCountdownText() {
    final now = DateTime.now();
    final difference = appointmentDateTime.difference(now);
    
    if (difference.isNegative) {
      return 'Past appointment';
    }
    
    if (difference.inMinutes < 60) {
      return 'In ${difference.inMinutes} minutes';
    }
    
    if (difference.inHours < 24) {
      if (appointmentDateTime.day == now.day) {
        return 'Today at ${_formatTime(appointmentDateTime)}';
      }
      return 'In ${difference.inHours} hours';
    }
    
    if (difference.inDays == 0 || (difference.inDays == 1 && appointmentDateTime.day == now.day + 1)) {
      return 'Tomorrow at ${_formatTime(appointmentDateTime)}';
    }
    
    if (difference.inDays < 7) {
      return 'In ${difference.inDays} days';
    }
    
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'In $weeks ${weeks == 1 ? 'week' : 'weeks'}';
    }
    
    return 'In ${(difference.inDays / 30).floor()} months';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  Color _getUrgencyColor() {
    final now = DateTime.now();
    final difference = appointmentDateTime.difference(now);
    
    if (difference.isNegative) {
      return AppColors.error;
    }
    
    if (difference.inHours < 2) {
      return const Color(0xFFEF4444); // Urgent red
    }
    
    if (difference.inHours < 24) {
      return const Color(0xFFF59E0B); // Today yellow
    }
    
    if (difference.inDays <= 1) {
      return const Color(0xFF3B82F6); // Tomorrow blue
    }
    
    return const Color(0xFF10B981); // Future green
  }

  bool _shouldPulse() {
    final now = DateTime.now();
    final difference = appointmentDateTime.difference(now);
    return difference.inHours < 24 && !difference.isNegative;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getUrgencyColor();
    final shouldPulse = _shouldPulse();
    final countdownText = _getCountdownText();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.25 : 0.12),
            color.withValues(alpha: isDark ? 0.15 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Pulsing calendar icon
              _PulsingIcon(
                icon: Icons.event_available_rounded,
                color: color,
                shouldPulse: shouldPulse,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Appointment',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countdownText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Type badge
              if (appointmentType != null)
                Flexible(
                  flex: 0,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      appointmentType!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Date and time row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _formatDate(appointmentDateTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time_rounded, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  _formatTime(appointmentDateTime),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          if (onReschedule != null || onCancel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onReschedule != null)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.schedule_rounded,
                      label: 'Reschedule',
                      color: const Color(0xFF3B82F6),
                      onTap: onReschedule!,
                      isDark: isDark,
                    ),
                  ),
                if (onReschedule != null && onCancel != null)
                  const SizedBox(width: 10),
                if (onCancel != null)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel',
                      color: const Color(0xFFEF4444),
                      onTap: onCancel!,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({
    required this.icon,
    required this.color,
    required this.shouldPulse,
  });

  final IconData icon;
  final Color color;
  final bool shouldPulse;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.shouldPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulsingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.shouldPulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            if (widget.shouldPulse)
              Transform.scale(
                scale: _animation.value,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.2 * (1.3 - _animation.value)),
                  ),
                ),
              ),
            // Icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.color, widget.color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 20),
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
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
        ),
      ),
    );
  }
}

/// Compact appointment countdown badge
class AppointmentCountdownBadge extends StatelessWidget {
  const AppointmentCountdownBadge({
    super.key,
    required this.appointmentDateTime,
    this.onTap,
  });

  final DateTime appointmentDateTime;
  final VoidCallback? onTap;

  String _getCompactText() {
    final now = DateTime.now();
    final diff = appointmentDateTime.difference(now);
    
    if (diff.isNegative) return 'Past';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  Color _getColor() {
    final diff = appointmentDateTime.difference(DateTime.now());
    if (diff.isNegative) return AppColors.error;
    if (diff.inHours < 24) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              _getCompactText(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
