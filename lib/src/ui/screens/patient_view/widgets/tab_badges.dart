import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Tab with notification badge
class BadgedTab extends StatelessWidget {
  const BadgedTab({
    super.key,
    required this.text,
    this.count,
    this.showBadge = true,
    this.badgeColor,
  });

  final String text;
  final int? count;
  final bool showBadge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final hasCount = count != null && count! > 0 && showBadge;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasCount) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count! > 99 ? '99+' : '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom TabBar with badge support
class BadgedTabBar extends StatelessWidget implements PreferredSizeWidget {
  const BadgedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.counts,
    this.badgeColors,
  });

  final TabController controller;
  final List<String> tabs;
  final List<int?>? counts;
  final List<Color?>? badgeColors;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TabBar(
      controller: controller,
      isScrollable: tabs.length > 4,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tabs: List.generate(tabs.length, (index) {
        return BadgedTab(
          text: tabs[index],
          count: counts != null && index < counts!.length ? counts![index] : null,
          badgeColor: badgeColors != null && index < badgeColors!.length 
              ? badgeColors![index] 
              : null,
        );
      }),
      labelColor: AppColors.primary,
      unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      dividerColor: Colors.transparent,
    );
  }
}

/// Notification dot badge (no count)
class NotificationDot extends StatelessWidget {
  const NotificationDot({
    super.key,
    this.color,
    this.size = 8,
    this.animated = false,
  });

  final Color? color;
  final double size;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    if (animated) {
      return _AnimatedDot(color: color ?? AppColors.error, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? AppColors.error,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (color ?? AppColors.error).withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  const _AnimatedDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.6),
                  blurRadius: widget.size,
                  spreadRadius: widget.size * 0.3 * _animation.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Badge wrapper for any widget
class WithBadge extends StatelessWidget {
  const WithBadge({
    super.key,
    required this.child,
    this.count,
    this.showDot = false,
    this.badgeColor,
    this.offset = Offset.zero,
  });

  final Widget child;
  final int? count;
  final bool showDot;
  final Color? badgeColor;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final hasContent = (count != null && count! > 0) || showDot;
    if (!hasContent) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4 + offset.dx,
          top: -4 + offset.dy,
          child: showDot
              ? NotificationDot(color: badgeColor)
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: (badgeColor ?? AppColors.error).withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    count! > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
