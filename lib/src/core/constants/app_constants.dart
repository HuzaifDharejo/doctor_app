/// App-wide constants for consistent styling and behavior
library;

import 'package:flutter/material.dart';

/// Spacing and padding constants
abstract class AppSpacing {
  // Base unit
  static const double unit = 4.0;
  
  // Spacing values
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  
  // Screen padding
  static const double screenPadding = 20.0;
  static const double screenPaddingCompact = 12.0;
  
  // Card padding
  static const double cardPadding = 16.0;
  static const double cardPaddingCompact = 12.0;
  
  // List item spacing
  static const double listItemSpacing = 12.0;
  static const double listItemSpacingCompact = 8.0;
}

/// Border radius constants
abstract class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
  
  // Common border radius
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(xl));
}

/// Icon sizes
abstract class AppIconSize {
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 28.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Compact mode sizes
  static const double smCompact = 18.0;
  static const double mdCompact = 22.0;
  static const double lgCompact = 26.0;
}

/// Font sizes
abstract class AppFontSize {
  static const double xxs = 10.0;
  static const double xs = 11.0;
  static const double sm = 12.0;
  static const double md = 13.0;
  static const double lg = 14.0;
  static const double xl = 16.0;
  static const double xxl = 18.0;
  static const double xxxl = 22.0;
  static const double display = 26.0;
  
  // Compact mode sizes
  static const double smCompact = 10.0;
  static const double mdCompact = 11.0;
  static const double lgCompact = 13.0;
  static const double xlCompact = 15.0;
  static const double xxlCompact = 18.0;
}

/// Animation durations
abstract class AppDuration {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration short = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);
  
  // Specific animations
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration buttonPress = Duration(milliseconds: 150);
  static const Duration fadeIn = Duration(milliseconds: 200);
  static const Duration slideIn = Duration(milliseconds: 250);
}

/// Breakpoints for responsive design
abstract class AppBreakpoint {
  static const double compact = 400.0;
  static const double medium = 600.0;
  static const double expanded = 840.0;
  static const double large = 1200.0;
  
  /// Check if width is compact
  static bool isCompact(double width) => width < compact;
  
  /// Check if width is medium
  static bool isMedium(double width) => width >= compact && width < expanded;
  
  /// Check if width is expanded
  static bool isExpanded(double width) => width >= expanded;
}

/// Elevation values
abstract class AppElevation {
  static const double none = 0.0;
  static const double xs = 1.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 16.0;
}

/// Common box shadows
abstract class AppShadow {
  static List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> coloredShadow(Color color, {double opacity = 0.4}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
