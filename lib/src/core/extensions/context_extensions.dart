/// BuildContext extensions for cleaner access to theme and media query
library;

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

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
  
  /// Check if screen is compact
  bool get isCompact => AppBreakpoint.isCompact(screenWidth);
  
  /// Check if screen is medium
  bool get isMedium => AppBreakpoint.isMedium(screenWidth);
  
  /// Check if screen is expanded
  bool get isExpanded => AppBreakpoint.isExpanded(screenWidth);
  
  /// Get responsive padding based on screen size
  double get responsivePadding => isCompact 
      ? AppSpacing.screenPaddingCompact 
      : AppSpacing.screenPadding;
  
  /// Get responsive card padding
  double get responsiveCardPadding => isCompact 
      ? AppSpacing.cardPaddingCompact 
      : AppSpacing.cardPadding;
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
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mediumRadius,
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
