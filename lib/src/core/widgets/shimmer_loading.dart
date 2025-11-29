import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Shimmer effect widget for loading states
class ShimmerLoading extends StatefulWidget {
  
  const ShimmerLoading({
    required this.child, super.key,
    this.isLoading = true,
  });
  final Widget child;
  final bool isLoading;

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
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
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
    final baseColor = isDark 
        ? AppColors.darkSurface 
        : Colors.grey.shade200;
    final highlightColor = isDark 
        ? AppColors.darkDivider 
        : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                0.5 + (_animation.value * 0.25),
                1.0,
              ],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Shimmer placeholder box
class ShimmerBox extends StatelessWidget {

  const ShimmerBox({
    required this.width, required this.height, super.key,
    this.borderRadius = 8,
  });
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer for stat cards on dashboard
class StatCardShimmer extends StatelessWidget {
  
  const StatCardShimmer({super.key, this.isCompact = false});
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ShimmerLoading(
      child: Container(
        width: isCompact ? 155 : 175,
        padding: EdgeInsets.all(isCompact ? 14 : 18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 40, height: 40, borderRadius: 12),
                ShimmerBox(width: 50, height: 24, borderRadius: 12),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 60, height: isCompact ? 26 : 32, borderRadius: 6),
                const SizedBox(height: 8),
                const ShimmerBox(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for patient cards
class PatientCardShimmer extends StatelessWidget {
  
  const PatientCardShimmer({super.key, this.isCompact = false});
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ShimmerLoading(
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            ShimmerBox(
              width: isCompact ? 48 : 54,
              height: isCompact ? 48 : 54,
              borderRadius: 27,
            ),
            SizedBox(width: isCompact ? 12 : 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: ShimmerBox(width: double.infinity, height: 16, borderRadius: 4)),
                      SizedBox(width: 8),
                      ShimmerBox(width: 60, height: 24, borderRadius: 12),
                    ],
                  ),
                  SizedBox(height: 10),
                  ShimmerBox(width: 120, height: 12, borderRadius: 4),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      ShimmerBox(width: 60, height: 24),
                      SizedBox(width: 6),
                      ShimmerBox(width: 80, height: 24),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const ShimmerBox(width: 32, height: 32, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for schedule items
class ScheduleItemShimmer extends StatelessWidget {
  const ScheduleItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isDark ? AppColors.darkDivider : AppColors.divider).withValues(alpha: 0.5),
          ),
        ),
        child: const Row(
          children: [
            ShimmerBox(width: 70, height: 36, borderRadius: 12),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 120, height: 14, borderRadius: 4),
                  SizedBox(height: 8),
                  ShimmerBox(width: 80, height: 12, borderRadius: 4),
                ],
              ),
            ),
            ShimmerBox(width: 70, height: 24, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}
