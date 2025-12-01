import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';

/// Extensions on BuildContext for convenient access to theme and design tokens
extension ThemeExtensions on BuildContext {
  /// Get current theme data
  ThemeData get theme => Theme.of(this);

  /// Get current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Check if dark mode is enabled
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get primary color
  Color get primaryColor => theme.primaryColor;

  /// Get surface color
  Color get surfaceColor => colorScheme.surface;

  /// Get background color
  Color get backgroundColor => theme.scaffoldBackgroundColor;

  /// Get on-surface color
  Color get onSurfaceColor => colorScheme.onSurface;
}

/// Extensions on TextStyle for easier creation of semantic styles
extension TextStyleExtensions on BuildContext {
  /// Display large text style
  TextStyle get displayLarge {
    return textTheme.displayLarge ?? const TextStyle();
  }

  /// Display medium text style
  TextStyle get displayMedium {
    return textTheme.displayMedium ?? const TextStyle();
  }

  /// Headline text style
  TextStyle get headlineStyle {
    return textTheme.headlineSmall ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  }

  /// Title text style
  TextStyle get titleStyle {
    return textTheme.titleMedium ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  }

  /// Subtitle text style
  TextStyle get subtitleStyle {
    return textTheme.titleSmall ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  }

  /// Body text style
  TextStyle get bodyStyle {
    return textTheme.bodyMedium ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.normal);
  }

  /// Caption text style
  TextStyle get captionStyle {
    return textTheme.labelMedium ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
  }

  /// Label text style
  TextStyle get labelStyle {
    return textTheme.labelMedium ??
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
  }
}

/// Extensions on BuildContext for responsive values
extension ResponsiveExtensions on BuildContext {
  /// Get current media query size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get current width
  double get screenWidth => screenSize.width;

  /// Get current height
  double get screenHeight => screenSize.height;

  /// Check if screen is compact (< 600px)
  bool get isCompact => screenWidth < AppBreakpoint.medium;

  /// Check if screen is medium (>= 600px && < 840px)
  bool get isMedium =>
      screenWidth >= AppBreakpoint.medium &&
      screenWidth < AppBreakpoint.expanded;

  /// Check if screen is expanded (>= 840px)
  bool get isExpanded => screenWidth >= AppBreakpoint.expanded;

  /// Get responsive padding based on screen size
  double get responsivePadding {
    if (isCompact) {
      return AppSpacing.md;
    } else if (isMedium) {
      return AppSpacing.lg;
    } else {
      return AppSpacing.xl;
    }
  }

  /// Get responsive card padding
  double get responsiveCardPadding {
    if (isCompact) {
      return AppSpacing.lg;
    } else if (isMedium) {
      return AppSpacing.xxl;
    } else {
      return AppSpacing.xxxl;
    }
  }

  /// Get responsive font size
  double responsiveFontSize(double compact, double medium, double expanded) {
    if (isCompact) {
      return compact;
    } else if (isMedium) {
      return medium;
    } else {
      return expanded;
    }
  }

  /// Get responsive padding value
  EdgeInsetsGeometry responsivePaddingGeometry({
    double? all,
    double? compact,
    double? medium,
    double? expanded,
  }) {
    final compactVal = compact ?? all ?? AppSpacing.md;
    final mediumVal = medium ?? all ?? AppSpacing.lg;
    final expandedVal = expanded ?? all ?? AppSpacing.xl;

    if (isCompact) {
      return EdgeInsets.all(compactVal);
    } else if (isMedium) {
      return EdgeInsets.all(mediumVal);
    } else {
      return EdgeInsets.all(expandedVal);
    }
  }
}

/// Extensions on BuildContext for convenient access to spacing
extension SpacingExtensions on BuildContext {
  /// Get spacing token
  double spacing(double value) => value;

  /// Get compact spacing (for small screens)
  double get spacingCompact => AppSpacing.sm;

  /// Get medium spacing
  double get spacingMedium => AppSpacing.md;

  /// Get large spacing
  double get spacingLarge => AppSpacing.lg;

  /// Get extra large spacing
  double get spacingXL => AppSpacing.xl;
}
