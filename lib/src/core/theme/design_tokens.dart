/// Design tokens for the Doctor App
/// Centralized source of truth for spacing, sizing, typography, and animation values

class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // Base spacing unit: 4px
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
  static const double xxxxxl = 48;

  // Semantic spacing
  static const double contentPadding = lg;
  static const double sectionSpacing = xxl;
  static const double cardPadding = lg;
  static const double buttonPadding = md;
  static const double itemSpacing = sm;
}

class AppRadius {
  AppRadius._();

  // Border radius values
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  // Semantic radius
  static const double card = lg;
  static const double button = sm;
  static const double input = md;
  static const double fab = full;
  static const double chip = full;
  static const double avatar = full;
}

class AppDuration {
  AppDuration._();

  // Animation durations in milliseconds
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);
  static const Duration slowest = Duration(milliseconds: 1000);

  // Semantic durations
  static const Duration itemAnimation = normal;
  static const Duration transitionAnimation = normal;
  static const Duration loadingAnimation = slow;
}

class AppFontSize {
  AppFontSize._();

  // Display sizes
  static const double displayLarge = 26;
  static const double displayMedium = 22;
  static const double displaySmall = 18;

  // Headline sizes
  static const double headlineLarge = 18;
  static const double headlineMedium = 16;
  static const double headlineSmall = 15;

  // Title sizes
  static const double titleLarge = 16;
  static const double titleMedium = 14;
  static const double titleSmall = 12;

  // Body sizes
  static const double bodyLarge = 14;
  static const double bodyMedium = 13;
  static const double bodySmall = 12;

  // Label sizes
  static const double labelLarge = 12;
  static const double labelMedium = 11;
  static const double labelSmall = 10;

  // Caption
  static const double caption = 11;
}

class AppShadow {
  AppShadow._();

  // Elevation levels
  static const double elevationLevel0 = 0;
  static const double elevationLevel1 = 1;
  static const double elevationLevel2 = 2;
  static const double elevationLevel3 = 4;
  static const double elevationLevel4 = 6;
  static const double elevationLevel5 = 8;

  // Shadow blur radius
  static const double shadowBlurSmall = 2;
  static const double shadowBlurMedium = 4;
  static const double shadowBlurLarge = 8;
  static const double shadowBlurXL = 12;

  // Shadow spread radius
  static const double spreadSmall = 0;
  static const double spreadMedium = 1;
}

class AppOpacity {
  AppOpacity._();

  // Opacity values
  static const double disabled = 0.38;
  static const double hover = 0.08;
  static const double focus = 0.12;
  static const double pressed = 0.16;
  static const double selected = 0.10;
  static const double divider = 0.12;
  static const double scrim = 0.32;
  static const double overlay = 0.50;
}

class AppIconSize {
  AppIconSize._();

  // Icon sizes
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 28;
  static const double xl = 32;
  static const double xxl = 48;

  // Semantic sizes
  static const double compact = 18;
  static const double medium = 22;
  static const double large = 26;
  static const double fab = 24;
  static const double button = 20;
}

class AppLineHeight {
  AppLineHeight._();

  // Line height multipliers
  static const double tight = 1.2;
  static const double normal = 1.5;
  static const double relaxed = 1.75;
  static const double loose = 2.0;
}

class AppLetterSpacing {
  AppLetterSpacing._();

  // Letter spacing in pixels
  static const double tight = -0.5;
  static const double normal = 0;
  static const double wide = 0.5;
}

class AppBreakpoint {
  AppBreakpoint._();

  // Responsive breakpoints
  static const double compact = 400;
  static const double medium = 600;
  static const double expanded = 840;
  static const double large = 1200;

  // Helper method to check if width is compact
  static bool isCompact(double width) => width < medium;

  // Helper method to check if width is medium
  static bool isMedium(double width) => width >= medium && width < expanded;

  // Helper method to check if width is expanded
  static bool isExpanded(double width) => width >= expanded;
}
