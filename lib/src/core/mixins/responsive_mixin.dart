import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  
  /// Is tablet layout (600-1199px)
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  
  /// Is desktop layout (>= 1200px)
  bool get isDesktop => screenWidth >= 1200;
  
  /// Is landscape orientation
  bool get isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;
  
  /// Horizontal padding based on screen size
  double get horizontalPadding => isCompact ? 12.0 : (isTablet ? 20.0 : 32.0);
  
  /// Vertical padding based on screen size
  double get verticalPadding => isCompact ? 8.0 : (isTablet ? 16.0 : 24.0);
  
  /// Card padding based on screen size
  double get cardPadding => isCompact ? 12.0 : 16.0;
  
  /// Grid columns for responsive grids
  int get gridColumns => isCompact ? 2 : (isTablet ? 3 : 4);
  
  /// List item columns (for horizontal lists)
  int get listColumns => isCompact ? 1 : (isTablet ? 2 : 3);
  
  /// Font scale factor
  double get fontScale => isCompact ? 1.0 : (isTablet ? 1.1 : 1.15);
  
  /// Icon size based on screen
  double get iconSize => isCompact ? 20.0 : 24.0;
  
  /// Large icon size
  double get largeIconSize => isCompact ? 28.0 : 36.0;
  
  /// Avatar size
  double get avatarSize => isCompact ? 40.0 : 56.0;
  
  /// Large avatar size
  double get largeAvatarSize => isCompact ? 64.0 : 80.0;
  
  /// Bottom sheet height factor
  double get bottomSheetHeightFactor => isCompact ? 0.85 : 0.6;
  
  /// Dialog max width
  double get dialogMaxWidth => isCompact ? screenWidth * 0.95 : 500.0;
  
  /// Content max width (for centering on large screens)
  double get contentMaxWidth => isDesktop ? 1200.0 : double.infinity;
  
  /// Spacing between items
  double get itemSpacing => isCompact ? 8.0 : 12.0;
  
  /// Section spacing
  double get sectionSpacing => isCompact ? 16.0 : 24.0;
  
  /// Title font size
  double get titleFontSize => isCompact ? 18.0 : 22.0;
  
  /// Subtitle font size
  double get subtitleFontSize => isCompact ? 14.0 : 16.0;
  
  /// Body font size
  double get bodyFontSize => isCompact ? 13.0 : 14.0;
  
  /// Caption font size
  double get captionFontSize => isCompact ? 11.0 : 12.0;
  
  /// Button height
  double get buttonHeight => isCompact ? 44.0 : 48.0;
  
  /// Input field height
  double get inputHeight => isCompact ? 48.0 : 56.0;
  
  /// Card border radius
  double get cardRadius => isCompact ? 12.0 : 16.0;
  
  /// Build responsive EdgeInsets
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );
  
  /// Responsive value helper - returns different values based on screen size
  T responsive<T>({
    required T compact,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return compact;
  }
}

/// Responsive mixin for ConsumerStatefulWidget (Riverpod)
mixin ResponsiveConsumerStateMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  bool get isCompact => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;
  bool get isLandscape => MediaQuery.of(context).orientation == Orientation.landscape;
  
  double get horizontalPadding => isCompact ? 12.0 : (isTablet ? 20.0 : 32.0);
  double get verticalPadding => isCompact ? 8.0 : (isTablet ? 16.0 : 24.0);
  double get cardPadding => isCompact ? 12.0 : 16.0;
  int get gridColumns => isCompact ? 2 : (isTablet ? 3 : 4);
  int get listColumns => isCompact ? 1 : (isTablet ? 2 : 3);
  double get fontScale => isCompact ? 1.0 : (isTablet ? 1.1 : 1.15);
  double get iconSize => isCompact ? 20.0 : 24.0;
  double get largeIconSize => isCompact ? 28.0 : 36.0;
  double get avatarSize => isCompact ? 40.0 : 56.0;
  double get largeAvatarSize => isCompact ? 64.0 : 80.0;
  double get bottomSheetHeightFactor => isCompact ? 0.85 : 0.6;
  double get dialogMaxWidth => isCompact ? screenWidth * 0.95 : 500.0;
  double get contentMaxWidth => isDesktop ? 1200.0 : double.infinity;
  double get itemSpacing => isCompact ? 8.0 : 12.0;
  double get sectionSpacing => isCompact ? 16.0 : 24.0;
  double get titleFontSize => isCompact ? 18.0 : 22.0;
  double get subtitleFontSize => isCompact ? 14.0 : 16.0;
  double get bodyFontSize => isCompact ? 13.0 : 14.0;
  double get captionFontSize => isCompact ? 11.0 : 12.0;
  double get buttonHeight => isCompact ? 44.0 : 48.0;
  double get inputHeight => isCompact ? 48.0 : 56.0;
  double get cardRadius => isCompact ? 12.0 : 16.0;
  
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );
  
  T responsive<T>({
    required T compact,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return compact;
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
      isTablet: width >= 600 && width < 1200,
      isDesktop: width >= 1200,
      isLandscape: orientation == Orientation.landscape,
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
    required this.isDesktop,
    required this.isLandscape,
  });
  
  final double screenWidth;
  final double screenHeight;
  final bool isCompact;
  final bool isTablet;
  final bool isDesktop;
  final bool isLandscape;
  
  double get horizontalPadding => isCompact ? 12.0 : (isTablet ? 20.0 : 32.0);
  double get verticalPadding => isCompact ? 8.0 : (isTablet ? 16.0 : 24.0);
  double get cardPadding => isCompact ? 12.0 : 16.0;
  int get gridColumns => isCompact ? 2 : (isTablet ? 3 : 4);
  double get itemSpacing => isCompact ? 8.0 : 12.0;
  double get sectionSpacing => isCompact ? 16.0 : 24.0;
  double get titleFontSize => isCompact ? 18.0 : 22.0;
  double get subtitleFontSize => isCompact ? 14.0 : 16.0;
  double get bodyFontSize => isCompact ? 13.0 : 14.0;
  double get cardRadius => isCompact ? 12.0 : 16.0;
  double get iconSize => isCompact ? 20.0 : 24.0;
  double get avatarSize => isCompact ? 40.0 : 56.0;
  
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );
  
  T responsive<T>({
    required T compact,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return compact;
  }
}
