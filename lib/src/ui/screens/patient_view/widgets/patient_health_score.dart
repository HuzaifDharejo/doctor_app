import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';

/// Circular health score widget with trend indicator
class PatientHealthScore extends StatelessWidget {
  const PatientHealthScore({
    super.key,
    required this.score,
    this.previousScore,
    this.label = 'Health Score',
    this.size = 120,
  });

  /// Current health score (0-100)
  final int score;
  
  /// Previous score for trend comparison
  final int? previousScore;
  
  /// Label below the score
  final String label;
  
  /// Widget size
  final double size;

  Color _getScoreColor() {
    if (score >= 80) return const Color(0xFF10B981); // Green
    if (score >= 60) return const Color(0xFF3B82F6); // Blue
    if (score >= 40) return const Color(0xFFF59E0B); // Yellow
    return const Color(0xFFEF4444); // Red
  }

  String _getScoreLabel() {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }

  IconData? _getTrendIcon() {
    if (previousScore == null) return null;
    if (score > previousScore!) return Icons.trending_up_rounded;
    if (score < previousScore!) return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }

  Color _getTrendColor() {
    if (previousScore == null) return Colors.grey;
    if (score > previousScore!) return const Color(0xFF10B981);
    if (score < previousScore!) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _getScoreColor();
    final trendIcon = _getTrendIcon();
    
    return Container(
      width: size + 40,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress with score
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                CustomPaint(
                  size: Size(size, size),
                  painter: _ScoreRingPainter(
                    score: score / 100,
                    color: color,
                    backgroundColor: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.15),
                    strokeWidth: 10,
                  ),
                ),
                // Score text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: size * 0.32,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getScoreLabel(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Label with trend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              if (trendIcon != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getTrendColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    trendIcon,
                    size: 14,
                    color: _getTrendColor(),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({
    required this.score,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  final double score;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final scorePaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          color.withValues(alpha: 0.6),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * score;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}

/// Compact inline health score widget
class PatientHealthScoreCompact extends StatelessWidget {
  const PatientHealthScoreCompact({
    super.key,
    required this.score,
    this.previousScore,
  });

  final int score;
  final int? previousScore;

  Color _getScoreColor() {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF3B82F6);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trendDiff = previousScore != null ? score - previousScore! : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini circular indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Health Score',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              if (trendDiff != null)
                Row(
                  children: [
                    Icon(
                      trendDiff > 0 
                          ? Icons.arrow_upward_rounded 
                          : trendDiff < 0 
                              ? Icons.arrow_downward_rounded 
                              : Icons.remove_rounded,
                      size: 12,
                      color: trendDiff > 0 
                          ? const Color(0xFF10B981) 
                          : trendDiff < 0 
                              ? const Color(0xFFEF4444)
                              : Colors.grey,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trendDiff > 0 ? '+' : ''}$trendDiff pts',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: trendDiff > 0 
                            ? const Color(0xFF10B981) 
                            : trendDiff < 0 
                                ? const Color(0xFFEF4444)
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
