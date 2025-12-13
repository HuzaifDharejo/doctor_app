/// Interactive UI components with micro-interactions
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A pressable card with scale animation and haptic feedback
class PressableCard extends StatefulWidget {
  const PressableCard({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.borderRadius = 16,
    this.backgroundColor,
    this.pressedScale = 0.97,
    this.enableHaptic = true,
    this.padding,
    this.margin,
    this.elevation = 0,
    this.border,
    this.gradient,
    this.boxShadow,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final Color? backgroundColor;
  final double pressedScale;
  final bool enableHaptic;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final BoxBorder? border;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isPressed) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTap() {
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _onLongPress() {
    if (widget.enableHaptic) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF1A1A1A) : Colors.white);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: widget.onTap != null ? _onTapDown : null,
        onTapUp: widget.onTap != null ? _onTapUp : null,
        onTapCancel: widget.onTap != null ? _onTapCancel : null,
        onTap: widget.onTap != null ? _onTap : null,
        onLongPress: widget.onLongPress != null ? _onLongPress : null,
        child: Container(
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.gradient == null ? bgColor : null,
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.border,
            boxShadow: widget.boxShadow ??
                (widget.elevation > 0
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: widget.elevation * 2,
                          offset: Offset(0, widget.elevation),
                        ),
                      ]
                    : null),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A swipeable list item with action buttons
class SwipeableListItem extends StatefulWidget {
  const SwipeableListItem({
    required this.child,
    super.key,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftActionColor = const Color(0xFF10B981),
    this.rightActionColor = const Color(0xFFEF4444),
    this.leftActionIcon = Icons.check_rounded,
    this.rightActionIcon = Icons.delete_rounded,
    this.leftActionLabel,
    this.rightActionLabel,
    this.confirmDismissLeft,
    this.confirmDismissRight,
    this.threshold = 0.3,
    this.enableHaptic = true,
  });

  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Color leftActionColor;
  final Color rightActionColor;
  final IconData leftActionIcon;
  final IconData rightActionIcon;
  final String? leftActionLabel;
  final String? rightActionLabel;
  final Future<bool> Function()? confirmDismissLeft;
  final Future<bool> Function()? confirmDismissRight;
  final double threshold;
  final bool enableHaptic;

  @override
  State<SwipeableListItem> createState() => _SwipeableListItemState();
}

class _SwipeableListItemState extends State<SwipeableListItem> {
  bool _hasTriggeredHaptic = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: _getDirection(),
      dismissThresholds: {
        DismissDirection.startToEnd: widget.threshold,
        DismissDirection.endToStart: widget.threshold,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (widget.confirmDismissLeft != null) {
            return widget.confirmDismissLeft!();
          }
          return widget.onSwipeRight != null;
        } else {
          if (widget.confirmDismissRight != null) {
            return widget.confirmDismissRight!();
          }
          return widget.onSwipeLeft != null;
        }
      },
      onUpdate: (details) {
        if (details.progress > widget.threshold && !_hasTriggeredHaptic) {
          _hasTriggeredHaptic = true;
          if (widget.enableHaptic) {
            HapticFeedback.mediumImpact();
          }
        } else if (details.progress < widget.threshold) {
          _hasTriggeredHaptic = false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          widget.onSwipeRight?.call();
        } else {
          widget.onSwipeLeft?.call();
        }
      },
      background: _buildBackground(
        color: widget.leftActionColor,
        icon: widget.leftActionIcon,
        label: widget.rightActionLabel,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildBackground(
        color: widget.rightActionColor,
        icon: widget.rightActionIcon,
        label: widget.leftActionLabel,
        alignment: Alignment.centerRight,
      ),
      child: widget.child,
    );
  }

  DismissDirection _getDirection() {
    if (widget.onSwipeLeft != null && widget.onSwipeRight != null) {
      return DismissDirection.horizontal;
    } else if (widget.onSwipeRight != null) {
      return DismissDirection.startToEnd;
    } else if (widget.onSwipeLeft != null) {
      return DismissDirection.endToStart;
    }
    return DismissDirection.none;
  }

  Widget _buildBackground({
    required Color color,
    required IconData icon,
    required String? label,
    required Alignment alignment,
  }) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft && label != null) ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: Colors.white, size: 24),
          if (isLeft && label != null) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// An animated icon button with ripple effect
class AnimatedIconButton extends StatefulWidget {
  const AnimatedIconButton({
    required this.icon,
    super.key,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.padding = 12,
    this.borderRadius = 12,
    this.enableHaptic = true,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double padding;
  final double borderRadius;
  final bool enableHaptic;
  final String? tooltip;

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTap() {
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = widget.color ??
        (isDark ? Colors.white70 : Colors.grey[700]);
    final bgColor = widget.backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.1));

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: widget.onPressed != null ? _onTapDown : null,
        onTapUp: widget.onPressed != null ? _onTapUp : null,
        onTapCancel: widget.onPressed != null ? _onTapCancel : null,
        onTap: widget.onPressed != null ? _onTap : null,
        child: Container(
          padding: EdgeInsets.all(widget.padding),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: Icon(
            widget.icon,
            color: iconColor,
            size: widget.size,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// A bouncing animation wrapper
class BounceAnimation extends StatefulWidget {
  const BounceAnimation({
    required this.child,
    super.key,
    this.onTap,
    this.bounceScale = 0.95,
    this.duration = const Duration(milliseconds: 150),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double bounceScale;
  final Duration duration;

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 1.0, end: widget.bounceScale).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Animated counter for smooth number transitions
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    required this.value,
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix$animatedValue$suffix',
          style: style,
        );
      },
    );
  }
}

/// Staggered animation for list items
class StaggeredListAnimation extends StatelessWidget {
  const StaggeredListAnimation({
    required this.children,
    super.key,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 400),
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(children.length, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: animationDuration,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: children[index],
        );
      }),
    );
  }
}
