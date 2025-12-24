/// BuildContext extensions for cleaner access to theme and media query

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Theme and color extensions
extension ThemeExtension on BuildContext {
  /// Get current theme data
  ThemeData get theme => Theme.of(this);
  
  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Check if dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Get primary color
  Color get primaryColor => colorScheme.primary;
  
  /// Get surface color
  Color get surfaceColor => colorScheme.surface;
  
  /// Get on surface color (text color)
  Color get onSurfaceColor => colorScheme.onSurface;
  
  /// Get error color
  Color get errorColor => colorScheme.error;
  
  /// Get background color
  Color get backgroundColor => theme.scaffoldBackgroundColor;
}

/// Media query extensions
extension MediaQueryExtension on BuildContext {
  /// Get media query data
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Get screen size
  Size get screenSize => mediaQuery.size;
  
  /// Get screen width
  double get screenWidth => screenSize.width;
  
  /// Get screen height
  double get screenHeight => screenSize.height;
  
  /// Get padding (safe area)
  EdgeInsets get padding => mediaQuery.padding;
  
  /// Get view insets (keyboard)
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  
  /// Check if keyboard is visible
  bool get isKeyboardVisible => viewInsets.bottom > 0;
  
  /// Check if screen is compact (< 600px width)
  bool get isCompact => AppBreakpoint.isCompact(screenWidth);
  
  /// Check if screen is medium (600-839px width)
  bool get isMedium => AppBreakpoint.isMedium(screenWidth);
  
  /// Check if screen is expanded (840-1199px width)
  bool get isExpanded => AppBreakpoint.isExpanded(screenWidth);

  /// Check if screen is large (>= 1200px width)
  bool get isLarge => AppBreakpoint.isLarge(screenWidth);

  /// Check if screen is short height (<= 600px)
  bool get isShortScreen => AppBreakpoint.isShortScreen(screenHeight);

  /// Check if screen is tall height (>= 900px)
  bool get isTallScreen => AppBreakpoint.isTallScreen(screenHeight);

  /// Get screen width category
  ScreenWidth get widthCategory => AppBreakpoint.getWidthCategory(screenWidth);

  /// Get screen height category
  ScreenHeight get heightCategory => AppBreakpoint.getHeightCategory(screenHeight);
  
  /// Get responsive padding based on screen size
  double get responsivePadding => isCompact 
      ? AppSpacing.screenPaddingCompact 
      : AppSpacing.screenPadding;
  
  /// Get responsive card padding
  double get responsiveCardPadding => isCompact 
      ? AppSpacing.cardPaddingCompact 
      : AppSpacing.cardPadding;

  /// Responsive font scale (smaller on compact, normal on medium, larger on desktop)
  double get fontScale {
    if (isCompact) return isShortScreen ? 0.9 : 1.0;
    if (isMedium) return 1.05;
    return 1.1;
  }

  /// Responsive icon size
  double get responsiveIconSize {
    if (isCompact) return isShortScreen ? 18.0 : 20.0;
    if (isMedium) return 22.0;
    return 24.0;
  }

  /// Responsive avatar size
  double get responsiveAvatarSize {
    if (isCompact) return isShortScreen ? 36.0 : 40.0;
    if (isMedium) return 48.0;
    return 56.0;
  }

  /// Responsive item spacing
  double get responsiveItemSpacing {
    if (isCompact) return isShortScreen ? 6.0 : 8.0;
    if (isMedium) return 10.0;
    return 12.0;
  }

  /// Responsive section spacing
  double get responsiveSectionSpacing {
    if (isCompact) return isShortScreen ? 12.0 : 16.0;
    if (isMedium) return 20.0;
    return 24.0;
  }

  /// Grid columns based on width
  int get responsiveGridColumns {
    switch (widthCategory) {
      case ScreenWidth.compact: return 2;
      case ScreenWidth.medium: return 3;
      case ScreenWidth.expanded: return 4;
      case ScreenWidth.large: return 5;
    }
  }

  /// List columns for side-by-side layouts
  int get responsiveListColumns {
    switch (widthCategory) {
      case ScreenWidth.compact: return 1;
      case ScreenWidth.medium: return 2;
      case ScreenWidth.expanded: return 2;
      case ScreenWidth.large: return 3;
    }
  }

  /// Content max width for centering on large screens
  double get contentMaxWidth {
    if (isLarge) return 1200.0;
    if (isExpanded) return 900.0;
    return double.infinity;
  }

  /// Responsive helper - return different values based on screen size
  T responsive<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? large,
  }) {
    switch (widthCategory) {
      case ScreenWidth.large:
        return large ?? expanded ?? medium ?? compact;
      case ScreenWidth.expanded:
        return expanded ?? medium ?? compact;
      case ScreenWidth.medium:
        return medium ?? compact;
      case ScreenWidth.compact:
        return compact;
    }
  }

  /// Responsive value for short screens - returns shortValue on short screens
  T heightResponsive<T>({
    required T normal,
    T? short,
    T? tall,
  }) {
    switch (heightCategory) {
      case ScreenHeight.short:
        return short ?? normal;
      case ScreenHeight.tall:
        return tall ?? normal;
      case ScreenHeight.medium:
        return normal;
    }
  }

  /// Combined responsive for both width and height
  T fullResponsive<T>({
    required T base,
    T? compactShort,
    T? compact,
    T? medium,
    T? expanded,
    T? large,
  }) {
    // First check for compact + short screen special case
    if (isCompact && isShortScreen && compactShort != null) {
      return compactShort;
    }
    // Then fall back to width-based
    return responsive(
      compact: compact ?? base,
      medium: medium,
      expanded: expanded,
      large: large,
    );
  }
}

/// Navigation extensions
extension NavigationExtension on BuildContext {
  /// Get navigator state
  NavigatorState get navigator => Navigator.of(this);
  
  /// Push a new route
  Future<T?> push<T>(Widget page) => navigator.push<T>(
    MaterialPageRoute<T>(builder: (_) => page),
  );
  
  /// Push and replace current route
  Future<T?> pushReplacement<T>(Widget page) => navigator.pushReplacement<T, void>(
    MaterialPageRoute<T>(builder: (_) => page),
  );
  
  /// Pop current route
  void pop<T>([T? result]) => navigator.pop<T>(result);
  
  /// Pop until condition is met
  void popUntil(bool Function(Route<dynamic>) predicate) => 
      navigator.popUntil(predicate);
  
  /// Pop to first route
  void popToFirst() => navigator.popUntil((route) => route.isFirst);
  
  /// Check if can pop
  bool get canPop => navigator.canPop();
}

/// Scaffold/Snackbar extensions
extension ScaffoldExtension on BuildContext {
  /// Show a snackbar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
        margin: EdgeInsets.all(responsivePadding),
      ),
    );
  }
  
  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: colorScheme.primary);
  }
  
  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: errorColor);
  }
  
  /// Hide current snackbar
  void hideSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }
}

/// Dialog extensions
extension DialogExtension on BuildContext {
  /// Show a dialog
  Future<T?> showAppDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (_) => child,
    );
  }
  
  /// Show confirmation dialog
  Future<bool> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop<bool>(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => context.pop<bool>(true),
            style: isDestructive 
                ? TextButton.styleFrom(foregroundColor: context.errorColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  /// Show loading dialog
  void showLoadingDialog({String? message}) {
    showDialog<void>(
      context: this,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message ?? 'Loading...'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Focus extensions
extension FocusExtension on BuildContext {
  /// Unfocus current field
  void unfocus() => FocusScope.of(this).unfocus();
  
  /// Request focus
  void requestFocus(FocusNode node) => FocusScope.of(this).requestFocus(node);
}
