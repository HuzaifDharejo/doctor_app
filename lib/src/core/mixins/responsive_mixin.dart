import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/design_tokens.dart';

/// Responsive mixin providing screen-size aware utilities
/// Use with StatefulWidget: `with ResponsiveStateMixin`
/// Use with StatelessWidget: Use ResponsiveBuilder widget instead
mixin ResponsiveStateMixin<T extends StatefulWidget> on State<T> {
  /// Current screen width
  double get screenWidth => MediaQuery.of(context).size.width;
  
  /// Current screen height
  double get screenHeight => MediaQuery.of(context).size.height;
  
  /// Is compact/phone layout (< 600px)
  bool get isCompact => screenWidth < 600;
  
  /// Is tablet layout (600-839px)
  bool get isTablet => screenWidth >= 600 && screenWidth < 840;
  
  /// Is expanded layout (840-1199px)
  bool get isExpanded => screenWidth >= 840 && screenWidth < 1200;
  
  /// Is desktop layout (>= 1200px)
  bool get isDesktop => screenWidth >= 1200;
  
  /// Is landscape orientation
  bool get isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;

  /// Is short screen height (<= 600px)
  bool get isShortScreen => screenHeight <= 600;

  /// Is tall screen height (>= 900px)
  bool get isTallScreen => screenHeight >= 900;

  /// Get width category
  ScreenWidth get widthCategory => AppBreakpoint.getWidthCategory(screenWidth);

  /// Get height category
  ScreenHeight get heightCategory => AppBreakpoint.getHeightCategory(screenHeight);
  
  /// Horizontal padding based on screen size
  double get horizontalPadding {
    if (isCompact) return isShortScreen ? 10.0 : 12.0;
    if (isTablet) return 20.0;
    if (isExpanded) return 28.0;
    return 32.0;
  }
  
  /// Vertical padding based on screen size
  double get verticalPadding {
    if (isCompact) return isShortScreen ? 6.0 : 8.0;
    if (isTablet) return 12.0;
    if (isExpanded) return 20.0;
    return 24.0;
  }
  
  /// Card padding based on screen size
  double get cardPadding {
    if (isCompact) return isShortScreen ? 10.0 : 12.0;
    return 16.0;
  }
  
  /// Grid columns for responsive grids
  int get gridColumns {
    if (isCompact) return 2;
    if (isTablet) return 3;
    if (isExpanded) return 4;
    return 5;
  }
  
  /// List item columns (for horizontal lists)
  int get listColumns {
    if (isCompact) return 1;
    if (isTablet) return 2;
    return 3;
  }
  
  /// Font scale factor
  double get fontScale {
    if (isCompact) return isShortScreen ? 0.9 : 1.0;
    if (isTablet) return 1.05;
    return 1.1;
  }
  
  /// Icon size based on screen
  double get iconSize {
    if (isCompact) return isShortScreen ? 18.0 : 20.0;
    if (isTablet) return 22.0;
    return 24.0;
  }
  
  /// Large icon size
  double get largeIconSize {
    if (isCompact) return isShortScreen ? 24.0 : 28.0;
    if (isTablet) return 32.0;
    return 36.0;
  }
  
  /// Avatar size
  double get avatarSize {
    if (isCompact) return isShortScreen ? 36.0 : 40.0;
    if (isTablet) return 48.0;
    return 56.0;
  }
  
  /// Large avatar size
  double get largeAvatarSize {
    if (isCompact) return isShortScreen ? 56.0 : 64.0;
    if (isTablet) return 72.0;
    return 80.0;
  }
  
  /// Bottom sheet height factor
  double get bottomSheetHeightFactor {
    if (isShortScreen) return 0.9;
    if (isCompact) return 0.85;
    if (isTablet) return 0.7;
    return 0.6;
  }
  
  /// Dialog max width
  double get dialogMaxWidth {
    if (isCompact) return screenWidth * 0.95;
    if (isTablet) return 500.0;
    return 600.0;
  }
  
  /// Content max width (for centering on large screens)
  double get contentMaxWidth {
    if (isDesktop) return 1200.0;
    if (isExpanded) return 900.0;
    return double.infinity;
  }
  
  /// Spacing between items
  double get itemSpacing {
    if (isCompact) return isShortScreen ? 6.0 : 8.0;
    if (isTablet) return 10.0;
    return 12.0;
  }
  
  /// Section spacing
  double get sectionSpacing {
    if (isCompact) return isShortScreen ? 12.0 : 16.0;
    if (isTablet) return 20.0;
    return 24.0;
  }
  
  /// Title font size
  double get titleFontSize {
    if (isCompact) return isShortScreen ? 16.0 : 18.0;
    if (isTablet) return 20.0;
    return 22.0;
  }
  
  /// Subtitle font size
  double get subtitleFontSize {
    if (isCompact) return isShortScreen ? 13.0 : 14.0;
    if (isTablet) return 15.0;
    return 16.0;
  }
  
  /// Body font size
  double get bodyFontSize {
    if (isCompact) return isShortScreen ? 12.0 : 13.0;
    return 14.0;
  }
  
  /// Caption font size
  double get captionFontSize {
    if (isCompact) return isShortScreen ? 10.0 : 11.0;
    return 12.0;
  }
  
  /// Button height
  double get buttonHeight {
    if (isCompact) return isShortScreen ? 40.0 : 44.0;
    return 48.0;
  }
  
  /// Input field height
  double get inputHeight {
    if (isCompact) return isShortScreen ? 44.0 : 48.0;
    return 56.0;
  }
  
  /// Card border radius
  double get cardRadius {
    if (isCompact) return isShortScreen ? 10.0 : 12.0;
    return 16.0;
  }
  
  /// Build responsive EdgeInsets
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );
  
  /// Responsive value helper - returns different values based on screen size
  R responsive<R>({
    required R compact,
    R? tablet,
    R? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if ((isTablet || isExpanded) && tablet != null) return tablet;
    return compact;
  }

  /// Height-based responsive value
  R heightResponsive<R>({
    required R normal,
    R? short,
    R? tall,
  }) {
    if (isShortScreen && short != null) return short;
    if (isTallScreen && tall != null) return tall;
    return normal;
  }
}

/// Responsive mixin for ConsumerStatefulWidget (Riverpod)
mixin ResponsiveConsumerStateMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  bool get isCompact => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 840;
  bool get isExpanded => screenWidth >= 840 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;
  bool get isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;
  bool get isShortScreen => screenHeight <= 600;
  bool get isTallScreen => screenHeight >= 900;

  ScreenWidth get widthCategory => AppBreakpoint.getWidthCategory(screenWidth);
  ScreenHeight get heightCategory => AppBreakpoint.getHeightCategory(screenHeight);
  
  double get horizontalPadding {
    if (isCompact) return isShortScreen ? 10.0 : 12.0;
    if (isTablet) return 20.0;
    if (isExpanded) return 28.0;
    return 32.0;
  }
  
  double get verticalPadding {
    if (isCompact) return isShortScreen ? 6.0 : 8.0;
    if (isTablet) return 12.0;
    if (isExpanded) return 20.0;
    return 24.0;
  }
  
  double get cardPadding {
    if (isCompact) return isShortScreen ? 10.0 : 12.0;
    return 16.0;
  }
  
  int get gridColumns {
    if (isCompact) return 2;
    if (isTablet) return 3;
    if (isExpanded) return 4;
    return 5;
  }
  
  int get listColumns {
    if (isCompact) return 1;
    if (isTablet) return 2;
    return 3;
  }
  
  double get fontScale {
    if (isCompact) return isShortScreen ? 0.9 : 1.0;
    if (isTablet) return 1.05;
    return 1.1;
  }
  
  double get iconSize {
    if (isCompact) return isShortScreen ? 18.0 : 20.0;
    if (isTablet) return 22.0;
    return 24.0;
  }
  
  double get largeIconSize {
    if (isCompact) return isShortScreen ? 24.0 : 28.0;
    if (isTablet) return 32.0;
    return 36.0;
  }
  
  double get avatarSize {
    if (isCompact) return isShortScreen ? 36.0 : 40.0;
    if (isTablet) return 48.0;
    return 56.0;
  }
  
  double get largeAvatarSize {
    if (isCompact) return isShortScreen ? 56.0 : 64.0;
    if (isTablet) return 72.0;
    return 80.0;
  }
  
  double get bottomSheetHeightFactor {
    if (isShortScreen) return 0.9;
    if (isCompact) return 0.85;
    if (isTablet) return 0.7;
    return 0.6;
  }
  
  double get dialogMaxWidth {
    if (isCompact) return screenWidth * 0.95;
    if (isTablet) return 500.0;
    return 600.0;
  }
  
  double get contentMaxWidth {
    if (isDesktop) return 1200.0;
    if (isExpanded) return 900.0;
    return double.infinity;
  }
  
  double get itemSpacing {
    if (isCompact) return isShortScreen ? 6.0 : 8.0;
    if (isTablet) return 10.0;
    return 12.0;
  }
  
  double get sectionSpacing {
    if (isCompact) return isShortScreen ? 12.0 : 16.0;
    if (isTablet) return 20.0;
    return 24.0;
  }
  
  double get titleFontSize {
    if (isCompact) return isShortScreen ? 16.0 : 18.0;
    if (isTablet) return 20.0;
    return 22.0;
  }
  
  double get subtitleFontSize {
    if (isCompact) return isShortScreen ? 13.0 : 14.0;
    if (isTablet) return 15.0;
    return 16.0;
  }
  
  double get bodyFontSize {
    if (isCompact) return isShortScreen ? 12.0 : 13.0;
    return 14.0;
  }
  
  double get captionFontSize {
    if (isCompact) return isShortScreen ? 10.0 : 11.0;
    return 12.0;
  }
  
  double get buttonHeight {
    if (isCompact) return isShortScreen ? 40.0 : 44.0;
    return 48.0;
  }
  
  double get inputHeight {
    if (isCompact) return isShortScreen ? 44.0 : 48.0;
    return 56.0;
  }
  
  double get cardRadius {
    if (isCompact) return isShortScreen ? 10.0 : 12.0;
    return 16.0;
  }
  
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );
  
  R responsive<R>({
    required R compact,
    R? tablet,
    R? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if ((isTablet || isExpanded) && tablet != null) return tablet;
    return compact;
  }

  R heightResponsive<R>({
    required R normal,
    R? short,
    R? tall,
  }) {
    if (isShortScreen && short != null) return short;
    if (isTallScreen && tall != null) return tall;
    return normal;
  }
}

/// Stateless responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.builder,
    super.key,
  });
  
  final Widget Function(BuildContext context, ResponsiveInfo info) builder;
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    
    return builder(context, ResponsiveInfo(
      screenWidth: width,
      screenHeight: height,
      isCompact: width < 600,
      isTablet: width >= 600 && width < 840,
      isExpanded: width >= 840 && width < 1200,
      isDesktop: width >= 1200,
      isLandscape: orientation == Orientation.landscape,
      isShortScreen: height <= 600,
      isTallScreen: height >= 900,
    ));
  }
}

/// Responsive information data class
class ResponsiveInfo {
  const ResponsiveInfo({
    required this.screenWidth,
    required this.screenHeight,
    required this.isCompact,
    required this.isTablet,
    required this.isExpanded,
    required this.isDesktop,
    required this.isLandscape,
    required this.isShortScreen,
    required this.isTallScreen,
  });
  
  final double screenWidth;
  final double screenHeight;
  final bool isCompact;
  final bool isTablet;
  final bool isExpanded;
  final bool isDesktop;
  final bool isLandscape;
  final bool isShortScreen;
  final bool isTallScreen;

  ScreenWidth get widthCategory => AppBreakpoint.getWidthCategory(screenWidth);
  ScreenHeight get heightCategory => AppBreakpoint.getHeightCategory(screenHeight);
  
  double get horizontalPadding {
    if (isCompact) return isShortScreen ? 10.0 : 12.0;
    if (isTablet) return 20.0;
    if (isExpanded) return 28.0;
    return 32.0;
  }
  
  double get verticalPadding {
    if (isCompact) return isShortScreen ? 6.0 : 8.0;
    if (isTablet) return 12.0;
    if (isExpanded) return 20.0;
    return 24.0;
  }
  
  double get cardPadding {
    if (isCompact) return isShortScreen ? 10.0 : 12.0;
    return 16.0;
  }
  
  int get gridColumns {
    if (isCompact) return 2;
    if (isTablet) return 3;
    if (isExpanded) return 4;
    return 5;
  }
  
  double get itemSpacing {
    if (isCompact) return isShortScreen ? 6.0 : 8.0;
    if (isTablet) return 10.0;
    return 12.0;
  }
  
  double get sectionSpacing {
    if (isCompact) return isShortScreen ? 12.0 : 16.0;
    if (isTablet) return 20.0;
    return 24.0;
  }
  
  double get titleFontSize {
    if (isCompact) return isShortScreen ? 16.0 : 18.0;
    if (isTablet) return 20.0;
    return 22.0;
  }
  
  double get subtitleFontSize {
    if (isCompact) return isShortScreen ? 13.0 : 14.0;
    if (isTablet) return 15.0;
    return 16.0;
  }
  
  double get bodyFontSize {
    if (isCompact) return isShortScreen ? 12.0 : 13.0;
    return 14.0;
  }
  
  double get cardRadius {
    if (isCompact) return isShortScreen ? 10.0 : 12.0;
    return 16.0;
  }
  
  double get iconSize {
    if (isCompact) return isShortScreen ? 18.0 : 20.0;
    if (isTablet) return 22.0;
    return 24.0;
  }
  
  double get avatarSize {
    if (isCompact) return isShortScreen ? 36.0 : 40.0;
    if (isTablet) return 48.0;
    return 56.0;
  }
  
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );
  
  R responsive<R>({
    required R compact,
    R? tablet,
    R? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if ((isTablet || isExpanded) && tablet != null) return tablet;
    return compact;
  }

  R heightResponsive<R>({
    required R normal,
    R? short,
    R? tall,
  }) {
    if (isShortScreen && short != null) return short;
    if (isTallScreen && tall != null) return tall;
    return normal;
  }
}
