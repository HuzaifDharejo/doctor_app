/// Gradient floating action button
library;

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../constants/app_constants.dart';

class GradientFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final String? heroTag;
  final Gradient? gradient;
  final Color? shadowColor;
  final double? size;

  const GradientFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.heroTag,
    this.gradient,
    this.shadowColor,
    this.size,
  });

  /// Creates a primary gradient FAB
  const GradientFAB.primary({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.heroTag,
  })  : gradient = AppColors.primaryGradient,
        shadowColor = AppColors.primary,
        size = null;

  /// Creates an accent gradient FAB
  const GradientFAB.accent({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
    this.heroTag,
  })  : gradient = AppColors.accentGradient,
        shadowColor = AppColors.accent,
        size = null;

  /// Creates a success gradient FAB
  const GradientFAB.success({
    super.key,
    required this.onPressed,
    this.icon = Icons.check,
    this.tooltip,
    this.heroTag,
  })  : gradient = AppColors.successGradient,
        shadowColor = AppColors.success,
        size = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: AppShadow.coloredShadow(shadowColor ?? AppColors.primary),
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: Colors.transparent,
        elevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        child: Icon(icon, size: AppIconSize.lg),
      ),
    );
  }
}

/// Extended gradient FAB with label
class GradientExtendedFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final String? heroTag;
  final Gradient? gradient;
  final Color? shadowColor;

  const GradientExtendedFAB({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
    this.heroTag,
    this.gradient,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: AppRadius.largeRadius,
        boxShadow: AppShadow.coloredShadow(shadowColor ?? AppColors.primary),
      ),
      child: FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
