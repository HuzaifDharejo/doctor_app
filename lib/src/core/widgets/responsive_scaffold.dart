import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
import '../theme/design_tokens.dart';

/// A responsive scaffold that adapts to different screen sizes.
/// 
/// Features:
/// - Constrains content width on large screens
/// - Adjusts padding based on screen size
/// - Handles safe areas properly
/// - Supports both scrollable and non-scrollable content
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.centerContent = true,
    this.maxContentWidth,
    this.horizontalPadding,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  
  /// Whether to center content on large screens
  final bool centerContent;
  
  /// Maximum width for content (defaults to 1200 on large screens)
  final double? maxContentWidth;
  
  /// Custom horizontal padding (defaults to responsive padding)
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        child: _ResponsiveContent(
          centerContent: centerContent,
          maxContentWidth: maxContentWidth,
          horizontalPadding: horizontalPadding,
          child: body,
        ),
      ),
    );
  }
}

/// Internal widget that handles responsive content layout
class _ResponsiveContent extends StatelessWidget {
  const _ResponsiveContent({
    required this.child,
    required this.centerContent,
    this.maxContentWidth,
    this.horizontalPadding,
  });

  final Widget child;
  final bool centerContent;
  final double? maxContentWidth;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxContentWidth ?? context.contentMaxWidth;
    
    // On large screens, center the content with max width
    if (centerContent && context.isLarge) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: child,
        ),
      );
    }
    
    // On expanded screens, add some horizontal padding
    if (context.isExpanded) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding ?? 24.0,
        ),
        child: child,
      );
    }
    
    return child;
  }
}

/// A responsive container that wraps content with proper constraints
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    required this.child,
    super.key,
    this.maxWidth,
    this.padding,
    this.centerOnLargeScreens = true,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centerOnLargeScreens;

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    
    // Apply padding if provided
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    
    // Apply max width constraint
    final effectiveMaxWidth = maxWidth ?? context.contentMaxWidth;
    if (effectiveMaxWidth != double.infinity) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: content,
      );
      
      // Center on large screens
      if (centerOnLargeScreens && context.isLarge) {
        content = Center(child: content);
      }
    }
    
    return content;
  }
}

/// Responsive grid that adapts columns based on screen width
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    super.key,
    this.compactColumns = 2,
    this.mediumColumns = 3,
    this.expandedColumns = 4,
    this.largeColumns = 5,
    this.spacing = 12.0,
    this.runSpacing = 12.0,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  final List<Widget> children;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;
  final int largeColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(
      compact: compactColumns,
      medium: mediumColumns,
      expanded: expandedColumns,
      large: largeColumns,
    );

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive row that wraps to column on compact screens
class ResponsiveRowOrColumn extends StatelessWidget {
  const ResponsiveRowOrColumn({
    required this.children,
    super.key,
    this.breakpoint = ScreenWidth.compact,
    this.rowMainAxisAlignment = MainAxisAlignment.start,
    this.rowCrossAxisAlignment = CrossAxisAlignment.center,
    this.columnMainAxisAlignment = MainAxisAlignment.start,
    this.columnCrossAxisAlignment = CrossAxisAlignment.stretch,
    this.spacing = 12.0,
  });

  final List<Widget> children;
  final ScreenWidth breakpoint;
  final MainAxisAlignment rowMainAxisAlignment;
  final CrossAxisAlignment rowCrossAxisAlignment;
  final MainAxisAlignment columnMainAxisAlignment;
  final CrossAxisAlignment columnCrossAxisAlignment;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final useColumn = _shouldUseColumn(context.widthCategory);
    
    final spacedChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spacedChildren.add(
        useColumn ? children[i] : Expanded(child: children[i]),
      );
      if (i < children.length - 1) {
        spacedChildren.add(
          useColumn ? SizedBox(height: spacing) : SizedBox(width: spacing),
        );
      }
    }
    
    if (useColumn) {
      return Column(
        mainAxisAlignment: columnMainAxisAlignment,
        crossAxisAlignment: columnCrossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: spacedChildren,
      );
    }
    
    return Row(
      mainAxisAlignment: rowMainAxisAlignment,
      crossAxisAlignment: rowCrossAxisAlignment,
      children: spacedChildren,
    );
  }

  bool _shouldUseColumn(ScreenWidth current) {
    switch (breakpoint) {
      case ScreenWidth.compact:
        return current == ScreenWidth.compact;
      case ScreenWidth.medium:
        return current == ScreenWidth.compact || current == ScreenWidth.medium;
      case ScreenWidth.expanded:
        return current != ScreenWidth.large;
      case ScreenWidth.large:
        return true;
    }
  }
}

/// Responsive spacing widget
class ResponsiveSpacing extends StatelessWidget {
  const ResponsiveSpacing({
    super.key,
    this.compactHeight = 8.0,
    this.mediumHeight = 12.0,
    this.expandedHeight = 16.0,
    this.largeHeight = 20.0,
  });

  /// For sections
  const ResponsiveSpacing.section({super.key})
      : compactHeight = 16.0,
        mediumHeight = 20.0,
        expandedHeight = 24.0,
        largeHeight = 32.0;

  /// For items
  const ResponsiveSpacing.item({super.key})
      : compactHeight = 8.0,
        mediumHeight = 10.0,
        expandedHeight = 12.0,
        largeHeight = 14.0;

  /// For tight spacing
  const ResponsiveSpacing.tight({super.key})
      : compactHeight = 4.0,
        mediumHeight = 6.0,
        expandedHeight = 8.0,
        largeHeight = 10.0;

  final double compactHeight;
  final double mediumHeight;
  final double expandedHeight;
  final double largeHeight;

  @override
  Widget build(BuildContext context) {
    final height = context.responsive(
      compact: compactHeight,
      medium: mediumHeight,
      expanded: expandedHeight,
      large: largeHeight,
    );
    return SizedBox(height: height);
  }
}

/// Responsive text that scales based on screen size
class ResponsiveText extends StatelessWidget {
  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.compactFontSize,
    this.mediumFontSize,
    this.expandedFontSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final double? compactFontSize;
  final double? mediumFontSize;
  final double? expandedFontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();
    final fontSize = context.responsive(
      compact: compactFontSize ?? baseStyle.fontSize ?? 14.0,
      medium: mediumFontSize ?? (compactFontSize ?? baseStyle.fontSize ?? 14.0) * 1.05,
      expanded: expandedFontSize ?? (compactFontSize ?? baseStyle.fontSize ?? 14.0) * 1.1,
    );

    return Text(
      text,
      style: baseStyle.copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Extension for easy responsive values in widgets
extension ResponsiveWidgetExtension on BuildContext {
  /// Responsive EdgeInsets
  EdgeInsets responsiveEdgeInsets({
    double? compact,
    double? medium,
    double? expanded,
    double? large,
  }) {
    final value = responsive(
      compact: compact ?? responsivePadding,
      medium: medium,
      expanded: expanded,
      large: large,
    );
    return EdgeInsets.all(value);
  }

  /// Responsive symmetric EdgeInsets
  EdgeInsets responsiveSymmetricPadding({
    double? horizontalCompact,
    double? horizontalMedium,
    double? horizontalExpanded,
    double? verticalCompact,
    double? verticalMedium,
    double? verticalExpanded,
  }) {
    final horizontal = responsive(
      compact: horizontalCompact ?? 12.0,
      medium: horizontalMedium ?? 20.0,
      expanded: horizontalExpanded ?? 32.0,
    );
    final vertical = responsive(
      compact: verticalCompact ?? 8.0,
      medium: verticalMedium ?? 12.0,
      expanded: verticalExpanded ?? 16.0,
    );
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }
}
