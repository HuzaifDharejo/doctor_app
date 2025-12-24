import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../theme/app_theme.dart';

/// Quick action button data
class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

/// Horizontal scrollable quick action strip
class QuickActionStrip extends StatelessWidget {
  const QuickActionStrip({
    super.key,
    required this.actions,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final List<QuickAction> actions;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _QuickActionButton(action: action),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  const _QuickActionButton({required this.action});

  final QuickAction action;

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.action.onTap();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final action = widget.action;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.color.withValues(alpha: _isPressed ? 0.25 : 0.15),
                action.color.withValues(alpha: _isPressed ? 0.15 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: action.color.withValues(alpha: _isPressed ? 0.5 : 0.3),
              width: 1,
            ),
            boxShadow: _isPressed
                ? null
                : [
                    BoxShadow(
                      color: action.color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [action.color, action.color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: action.color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  action.icon,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact icon-only quick action for tight spaces
class QuickActionIcon extends StatelessWidget {
  const QuickActionIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 44,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.45,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    return button;
  }
}

/// Grid of quick actions for modal sheets
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    super.key,
    required this.actions,
    this.crossAxisCount = 4,
  });

  final List<QuickAction> actions;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.responsive(
          compact: crossAxisCount.clamp(2, 4),
          medium: (crossAxisCount + 1).clamp(3, 5),
          expanded: (crossAxisCount + 2).clamp(4, 6),
        ),
        mainAxisSpacing: context.responsiveItemSpacing,
        crossAxisSpacing: context.responsiveItemSpacing,
        childAspectRatio: context.responsive(
          compact: 0.83,
          medium: 0.85,
          expanded: 0.9,
        ),
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildGridItem(action, isDark);
      },
    );
  }

  Widget _buildGridItem(QuickAction action, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: action.color.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [action.color, action.color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: action.color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  action.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
