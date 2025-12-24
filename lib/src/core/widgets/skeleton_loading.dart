/// Skeleton loading widgets for smooth loading states
library;

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../extensions/context_extensions.dart';

/// A shimmer effect widget that animates a gradient across its child
class ShimmerEffect extends StatefulWidget {
  const ShimmerEffect({
    required this.child,
    super.key,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ??
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

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
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// A skeleton placeholder box with rounded corners
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A skeleton circle (for avatars)
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({
    super.key,
    this.size = 48,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Skeleton card placeholder for dashboard stat cards
class SkeletonStatCard extends StatelessWidget {
  const SkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonBox(width: 36, height: 36, borderRadius: 10),
              const SizedBox(width: 8),
              const Flexible(child: SkeletonBox(width: 40, height: 24)),
            ],
          ),
          const SizedBox(height: 10),
          const SkeletonBox(width: 50, height: 14),
        ],
      ),
    );
  }
}

/// Skeleton patient card placeholder
class SkeletonPatientCard extends StatelessWidget {
  const SkeletonPatientCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          const SkeletonCircle(size: 52),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 140, height: 16),
                const SizedBox(height: 8),
                const SkeletonBox(width: 100, height: 12),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Flexible(child: SkeletonBox(width: 60, height: 10)),
                    const SizedBox(width: 12),
                    const Flexible(child: SkeletonBox(width: 80, height: 10)),
                  ],
                ),
              ],
            ),
          ),
          // Risk badge
          const SkeletonBox(width: 24, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Skeleton appointment card placeholder
class SkeletonAppointmentCard extends StatelessWidget {
  const SkeletonAppointmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Time column
          Column(
            children: [
              const SkeletonBox(width: 50, height: 14),
              const SizedBox(height: 4),
              const SkeletonBox(width: 40, height: 10),
            ],
          ),
          const SizedBox(width: 16),
          // Divider
          Container(
            width: 3,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 120, height: 16),
                const SizedBox(height: 8),
                const SkeletonBox(width: 180, height: 12),
              ],
            ),
          ),
          // Status
          const SkeletonBox(width: 70, height: 28, borderRadius: 14),
        ],
      ),
    );
  }
}

/// Loading skeleton for dashboard
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.responsivePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                const SkeletonCircle(size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(width: 100, height: 14),
                      const SizedBox(height: 8),
                      const SkeletonBox(width: 160, height: 24),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Stats row
            Row(
              children: [
                const Expanded(child: SkeletonStatCard()),
                const SizedBox(width: 12),
                const Expanded(child: SkeletonStatCard()),
                const SizedBox(width: 12),
                const Expanded(child: SkeletonStatCard()),
                const SizedBox(width: 12),
                const Expanded(child: SkeletonStatCard()),
              ],
            ),
            const SizedBox(height: 24),
            // Section title
            const SkeletonBox(width: 120, height: 20),
            const SizedBox(height: 16),
            // Appointment cards
            const SkeletonAppointmentCard(),
            const SkeletonAppointmentCard(),
            const SkeletonAppointmentCard(),
          ],
        ),
      ),
    );
  }
}

/// Loading skeleton for patient list
class PatientListSkeleton extends StatelessWidget {
  const PatientListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(
            itemCount,
            (index) => const SkeletonPatientCard(),
          ),
        ),
      ),
    );
  }
}

/// Loading skeleton for appointment list
class AppointmentListSkeleton extends StatelessWidget {
  const AppointmentListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(
            itemCount,
            (index) => const SkeletonAppointmentCard(),
          ),
        ),
      ),
    );
  }
}

/// Skeleton prescription card placeholder
class SkeletonPrescriptionCard extends StatelessWidget {
  const SkeletonPrescriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonCircle(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 140, height: 16),
                    const SizedBox(height: 8),
                    const SkeletonBox(width: 100, height: 12),
                  ],
                ),
              ),
              const SkeletonBox(width: 60, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonBox(width: 200, height: 14),
          const SizedBox(height: 8),
          Row(
            children: [
              const Flexible(child: SkeletonBox(width: 80, height: 10)),
              const SizedBox(width: 12),
              const Flexible(child: SkeletonBox(width: 90, height: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Loading skeleton for prescription list
class PrescriptionListSkeleton extends StatelessWidget {
  const PrescriptionListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(
            itemCount,
            (index) => const SkeletonPrescriptionCard(),
          ),
        ),
      ),
    );
  }
}

/// Skeleton invoice card placeholder
class SkeletonInvoiceCard extends StatelessWidget {
  const SkeletonInvoiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: SkeletonBox(width: 120, height: 16),
                    ),
                    const SkeletonBox(width: 70, height: 24, borderRadius: 12),
                  ],
                ),
                const SizedBox(height: 8),
                const SkeletonBox(width: 180, height: 12),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SkeletonBox(width: 80, height: 14),
                    const Spacer(),
                    const SkeletonBox(width: 60, height: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading skeleton for invoice list
class InvoiceListSkeleton extends StatelessWidget {
  const InvoiceListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: List.generate(
            itemCount,
            (index) => const SkeletonInvoiceCard(),
          ),
        ),
      ),
    );
  }
}

/// Skeleton medical record card placeholder
class SkeletonMedicalRecordCard extends StatelessWidget {
  const SkeletonMedicalRecordCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          const SkeletonCircle(size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 150, height: 16),
                const SizedBox(height: 8),
                const SkeletonBox(width: 80, height: 20, borderRadius: 6),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SkeletonBox(width: 12, height: 12),
                    const SizedBox(width: 4),
                    const SkeletonBox(width: 100, height: 12),
                  ],
                ),
              ],
            ),
          ),
          const SkeletonBox(width: 24, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Loading skeleton for medical record list
class MedicalRecordListSkeleton extends StatelessWidget {
  const MedicalRecordListSkeleton({
    super.key,
    this.itemCount = 5,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(
            itemCount,
            (index) => const SkeletonMedicalRecordCard(),
          ),
        ),
      ),
    );
  }
}