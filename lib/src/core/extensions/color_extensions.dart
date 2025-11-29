/// Color extensions for cleaner opacity handling
library;

import 'package:flutter/material.dart';

/// Extension to replace deprecated withOpacity
extension ColorOpacity on Color {
  /// Returns a new color with the specified opacity (0.0 to 1.0)
  /// Uses withValues() instead of deprecated withOpacity()
  Color withOpacityValue(double opacity) {
    return withValues(alpha: opacity);
  }
  
  /// Common opacity presets
  Color get opacity5 => withValues(alpha: 0.05);
  Color get opacity8 => withValues(alpha: 0.08);
  Color get opacity10 => withValues(alpha: 0.1);
  Color get opacity12 => withValues(alpha: 0.12);
  Color get opacity15 => withValues(alpha: 0.15);
  Color get opacity20 => withValues(alpha: 0.2);
  Color get opacity25 => withValues(alpha: 0.25);
  Color get opacity30 => withValues(alpha: 0.3);
  Color get opacity40 => withValues(alpha: 0.4);
  Color get opacity50 => withValues(alpha: 0.5);
  Color get opacity60 => withValues(alpha: 0.6);
  Color get opacity70 => withValues(alpha: 0.7);
  Color get opacity80 => withValues(alpha: 0.8);
  Color get opacity85 => withValues(alpha: 0.85);
  Color get opacity90 => withValues(alpha: 0.9);
  Color get opacity95 => withValues(alpha: 0.95);
}
