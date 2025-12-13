import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// Mini sparkline chart for vital signs trends
class VitalsSparkline extends StatelessWidget {
  const VitalsSparkline({
    super.key,
    required this.values,
    required this.label,
    required this.unit,
    required this.color,
    this.normalRange,
    this.height = 40,
    this.width = 80,
  });

  /// List of values to plot (newest last)
  final List<double> values;
  
  /// Label for the vital (e.g., "BP", "HR")
  final String label;
  
  /// Unit (e.g., "bpm", "mmHg")
  final String unit;
  
  /// Line color
  final Color color;
  
  /// Normal range [min, max] - values outside will show red dots
  final (double, double)? normalRange;
  
  /// Chart height
  final double height;
  
  /// Chart width
  final double width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (values.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final latestValue = values.last;
    final isAbnormal = normalRange != null && 
        (latestValue < normalRange!.$1 || latestValue > normalRange!.$2);

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAbnormal 
                ? AppColors.error.withValues(alpha: 0.4)
                : color.withValues(alpha: 0.2),
            width: isAbnormal ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isAbnormal ? AppColors.error : color).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with label and current value
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      latestValue.toStringAsFixed(latestValue.truncateToDouble() == latestValue ? 0 : 1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isAbnormal 
                            ? AppColors.error 
                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isAbnormal) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.warning_rounded,
                        size: 12,
                        color: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Sparkline chart
            SizedBox(
              height: height,
              width: width,
              child: CustomPaint(
                size: Size(width, height),
                painter: _SparklinePainter(
                  values: values,
                  color: color,
                  normalRange: normalRange,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Trend indicator
            _buildTrendIndicator(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: height,
            width: width,
            child: Center(
              child: Text(
                'No data',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(bool isDark) {
    if (values.length < 2) return const SizedBox.shrink();

    final diff = values.last - values.first;
    final percentChange = (diff / values.first * 100).abs();
    
    final isUp = diff > 0;
    final isSignificant = percentChange > 5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 10,
          color: isSignificant
              ? (isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444))
              : Colors.grey,
        ),
        const SizedBox(width: 2),
        Text(
          '${isUp ? '+' : ''}${diff.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isSignificant
                ? (isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                : Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    this.normalRange,
  });

  final List<double> values;
  final Color color;
  final (double, double)? normalRange;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue == 0 ? 1 : maxValue - minValue;
    
    final points = <Offset>[];
    final abnormalPoints = <Offset>[];
    
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1).clamp(1, double.infinity)) * size.width;
      final y = size.height - ((values[i] - minValue) / range) * size.height;
      final point = Offset(x, y.clamp(0, size.height));
      points.add(point);
      
      // Check if value is abnormal
      if (normalRange != null && 
          (values[i] < normalRange!.$1 || values[i] > normalRange!.$2)) {
        abnormalPoints.add(point);
      }
    }

    // Draw gradient area under the line
    final gradientPath = Path();
    gradientPath.moveTo(0, size.height);
    for (final point in points) {
      gradientPath.lineTo(point.dx, point.dy);
    }
    gradientPath.lineTo(size.width, size.height);
    gradientPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(gradientPath, gradientPaint);

    // Draw the line
    if (points.length > 1) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        // Smooth curve using cubic bezier
        final prev = points[i - 1];
        final curr = points[i];
        final controlX1 = prev.dx + (curr.dx - prev.dx) / 3;
        final controlX2 = prev.dx + 2 * (curr.dx - prev.dx) / 3;
        linePath.cubicTo(controlX1, prev.dy, controlX2, curr.dy, curr.dx, curr.dy);
      }

      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Draw normal points
    final normalPointPaint = Paint()..color = color;
    for (final point in points) {
      if (!abnormalPoints.contains(point)) {
        canvas.drawCircle(point, 3, normalPointPaint);
      }
    }

    // Draw abnormal points (red)
    final abnormalPointPaint = Paint()..color = AppColors.error;
    final abnormalOutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final point in abnormalPoints) {
      canvas.drawCircle(point, 4, abnormalPointPaint);
      canvas.drawCircle(point, 4, abnormalOutlinePaint);
    }

    // Draw latest point with emphasis
    if (points.isNotEmpty) {
      final lastPoint = points.last;
      final isLastAbnormal = abnormalPoints.contains(lastPoint);
      
      // Outer glow
      canvas.drawCircle(
        lastPoint,
        6,
        Paint()..color = (isLastAbnormal ? AppColors.error : color).withValues(alpha: 0.3),
      );
      // Inner point
      canvas.drawCircle(
        lastPoint,
        4,
        Paint()..color = isLastAbnormal ? AppColors.error : color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

/// Row of vital sparklines
class VitalsTrendRow extends StatelessWidget {
  const VitalsTrendRow({
    super.key,
    required this.bpSystolic,
    required this.bpDiastolic,
    required this.heartRate,
    required this.spO2,
    this.temperature,
  });

  final List<double> bpSystolic;
  final List<double> bpDiastolic;
  final List<double> heartRate;
  final List<double> spO2;
  final List<double>? temperature;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          VitalsSparkline(
            values: bpSystolic,
            label: 'Systolic',
            unit: 'mmHg',
            color: const Color(0xFFEF4444),
            normalRange: (90, 140),
          ),
          const SizedBox(width: 10),
          VitalsSparkline(
            values: heartRate,
            label: 'Heart Rate',
            unit: 'bpm',
            color: const Color(0xFFEC4899),
            normalRange: (60, 100),
          ),
          const SizedBox(width: 10),
          VitalsSparkline(
            values: spO2,
            label: 'SpO₂',
            unit: '%',
            color: const Color(0xFF3B82F6),
            normalRange: (95, 100),
          ),
          if (temperature != null && temperature!.isNotEmpty) ...[
            const SizedBox(width: 10),
            VitalsSparkline(
              values: temperature!,
              label: 'Temp',
              unit: '°C',
              color: const Color(0xFFF59E0B),
              normalRange: (36.1, 37.5),
            ),
          ],
        ],
      ),
    );
  }
}
