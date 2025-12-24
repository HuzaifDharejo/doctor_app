/// Expandable Floating Action Button with radial menu
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../extensions/context_extensions.dart';

/// A floating action button that expands into a radial menu
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    required this.actions,
    super.key,
    this.icon = Icons.add_rounded,
    this.closeIcon = Icons.close_rounded,
    this.distance = 100,
    this.duration = const Duration(milliseconds: 250),
    this.primaryColor,
    this.secondaryColor,
    this.onOpen,
    this.onClose,
  });

  final List<FabAction> actions;
  final IconData icon;
  final IconData closeIcon;
  final double distance;
  final Duration duration;
  final Color? primaryColor;
  final Color? secondaryColor;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
        widget.onOpen?.call();
      } else {
        _controller.reverse();
        widget.onClose?.call();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() => _isOpen = false);
      _controller.reverse();
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF6366F1);
    final secondaryColor = widget.secondaryColor ?? const Color(0xFF8B5CF6);

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        // Background overlay
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withValues(alpha: _expandAnimation.value * 0.5),
                  );
                },
              ),
            ),
          ),
        // Action buttons in a fan pattern
        ..._buildExpandingActions(primaryColor),
        // Main FAB
        _buildMainFab(primaryColor, secondaryColor),
      ],
    );
  }

  List<Widget> _buildExpandingActions(Color primaryColor) {
    final actionCount = widget.actions.length;
    final angleStep = 90 / (actionCount - 1).clamp(1, actionCount);

    return List.generate(actionCount, (index) {
      final angle = (90 + index * angleStep) * (math.pi / 180);
      final action = widget.actions[index];

      return AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          final offset = Offset(
            -widget.distance * math.cos(angle) * _expandAnimation.value,
            -widget.distance * math.sin(angle) * _expandAnimation.value,
          );

          return Positioned(
            right: 8 - offset.dx,
            bottom: 8 - offset.dy,
            child: Transform.scale(
              scale: _expandAnimation.value,
              child: Opacity(
                opacity: _expandAnimation.value,
                child: _ActionButton(
                  action: action,
                  onPressed: () {
                    _close();
                    action.onPressed?.call();
                  },
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildMainFab(Color primaryColor, Color secondaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(context.responsivePadding),
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _expandAnimation.value * (math.pi / 4),
                  child: Icon(
                    _isOpen ? widget.closeIcon : widget.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// An action item for the expandable FAB
class FabAction {
  const FabAction({
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.onPressed,
  });

  final FabAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = action.backgroundColor ??
        (isDark ? const Color(0xFF2A2A2A) : Colors.white);
    final iconColor = action.color ?? const Color(0xFF6366F1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            action.label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Icon button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              action.icon,
              color: iconColor,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

/// A simple expandable FAB for vertical list expansion
class ExpandableFabVertical extends StatefulWidget {
  const ExpandableFabVertical({
    required this.actions,
    super.key,
    this.icon = Icons.add_rounded,
    this.closeIcon = Icons.close_rounded,
    this.spacing = 16,
    this.duration = const Duration(milliseconds: 200),
    this.primaryColor,
    this.secondaryColor,
  });

  final List<FabAction> actions;
  final IconData icon;
  final IconData closeIcon;
  final double spacing;
  final Duration duration;
  final Color? primaryColor;
  final Color? secondaryColor;

  @override
  State<ExpandableFabVertical> createState() => _ExpandableFabVerticalState();
}

class _ExpandableFabVerticalState extends State<ExpandableFabVertical>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF6366F1);
    final secondaryColor = widget.secondaryColor ?? const Color(0xFF8B5CF6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action buttons
        ..._buildActionButtons(),
        // Main FAB
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(context.responsivePadding),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animation.value * (math.pi / 4),
                      child: Icon(
                        _isOpen ? widget.closeIcon : widget.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons() {
    return List.generate(widget.actions.length, (index) {
      final reversedIndex = widget.actions.length - 1 - index;
      final action = widget.actions[reversedIndex];

      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Stagger the animation for each button
          final staggeredValue = (_animation.value - (index * 0.1)).clamp(0.0, 1.0);

          return Transform.translate(
            offset: Offset(0, (1 - staggeredValue) * 20),
            child: Opacity(
              opacity: staggeredValue,
              child: Padding(
                padding: EdgeInsets.only(bottom: widget.spacing),
                child: _ActionButton(
                  action: action,
                  onPressed: () {
                    _toggle();
                    action.onPressed?.call();
                  },
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
