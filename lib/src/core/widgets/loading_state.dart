/// Loading state widget with customizable appearance
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

class LoadingState extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool showMessage;

  const LoadingState({
    super.key,
    this.message,
    this.color,
    this.size = 36,
    this.showMessage = true,
  });

  /// Creates a compact loading indicator
  const LoadingState.compact({
    super.key,
    this.color,
  })  : message = null,
        size = 24,
        showMessage = false;

  /// Creates an inline loading indicator
  const LoadingState.inline({
    super.key,
    this.color,
  })  : message = null,
        size = 20,
        showMessage = false;

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? AppColors.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: indicatorColor,
              strokeWidth: size > 30 ? 3 : 2,
            ),
          ),
          if (showMessage && message != null) ...[
            SizedBox(height: AppSpacing.lg),
            Text(
              message ?? AppStrings.loading,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: AppFontSize.lg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading overlay that covers the entire screen
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? barrierColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.barrierColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: barrierColor ?? Colors.black.withValues(alpha: 0.3),
            child: LoadingState(message: message),
          ),
      ],
    );
  }
}

/// Shimmer loading placeholder
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  
  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
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
    if (!widget.isLoading) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
