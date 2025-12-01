import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class AppBreakpoint {
  // Phone: < 600
  static const double phoneMax = 599;
  
  // Tablet: 600-1200
  static const double tabletMin = 600;
  static const double tabletMax = 1199;
  
  // Desktop: >= 1200
  static const double desktopMin = 1200;

  static bool isPhone(double width) => width <= phoneMax;
  
  static bool isTablet(double width) => 
      width >= tabletMin && width <= tabletMax;
  
  static bool isDesktop(double width) => width >= desktopMin;

  static DeviceType getDeviceType(double width) {
    if (isPhone(width)) return DeviceType.phone;
    if (isTablet(width)) return DeviceType.tablet;
    return DeviceType.desktop;
  }
}

enum DeviceType { phone, tablet, desktop }

/// Responsive layout helper for exam room environment
/// Adapts to portrait/landscape and screen size
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.phonePortrait,
    required this.phoneLandscape,
    required this.tabletPortrait,
    required this.tabletLandscape,
    this.desktopLayout,
    super.key,
  });

  final Widget Function(BuildContext) phonePortrait;
  final Widget Function(BuildContext) phoneLandscape;
  final Widget Function(BuildContext) tabletPortrait;
  final Widget Function(BuildContext) tabletLandscape;
  final Widget Function(BuildContext)? desktopLayout;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final deviceType = AppBreakpoint.getDeviceType(width);
            final isLandscape = orientation == Orientation.landscape;

            switch (deviceType) {
              case DeviceType.phone:
                return isLandscape
                    ? phoneLandscape(context)
                    : phonePortrait(context);
              case DeviceType.tablet:
                return isLandscape
                    ? tabletLandscape(context)
                    : tabletPortrait(context);
              case DeviceType.desktop:
                return desktopLayout?.call(context) ?? tabletLandscape(context);
            }
          },
        );
      },
    );
  }
}

/// Adaptive grid layout that adjusts columns based on screen size/orientation
class AdaptiveGridLayout extends StatelessWidget {
  const AdaptiveGridLayout({
    required this.items,
    required this.itemBuilder,
    this.spacing = 16,
    super.key,
  });

  final List<dynamic> items;
  final Widget Function(BuildContext, int, dynamic) itemBuilder;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final orientation = MediaQuery.of(context).orientation;

        // Calculate grid columns based on device type
        late int crossAxisCount;
        
        if (AppBreakpoint.isPhone(width)) {
          crossAxisCount = orientation == Orientation.landscape ? 4 : 2;
        } else if (AppBreakpoint.isTablet(width)) {
          crossAxisCount = orientation == Orientation.landscape ? 6 : 3;
        } else {
          crossAxisCount = 8;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(context, index, items[index]),
        );
      },
    );
  }
}

/// Exam mode: Large button grid optimized for touch
class ExamModeLayout extends StatelessWidget {
  const ExamModeLayout({
    required this.buttons,
    this.padding = 12,
    this.spacing = 8,
    super.key,
  });

  final List<ExamModeButton> buttons;
  final double padding;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        final crossAxisCount = isLandscape ? 4 : 3;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1 / 1.15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: buttons
                .map((btn) => _ExamModeButtonTile(button: btn))
                .toList(),
          ),
        );
      },
    );
  }
}

/// Data class for exam mode buttons
class ExamModeButton {
  const ExamModeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

/// Individual exam mode button tile (minimum 48x48 touch target)
class _ExamModeButtonTile extends StatefulWidget {
  const _ExamModeButtonTile({required this.button});

  final ExamModeButton button;

  @override
  State<_ExamModeButtonTile> createState() => _ExamModeButtonTileState();
}

class _ExamModeButtonTileState extends State<_ExamModeButtonTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.button.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.button.color.withValues(alpha: 0.3),
            ),
            boxShadow: _isPressed
                ? null
                : [
                    BoxShadow(
                      color: widget.button.color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.button.color.withValues(alpha: 0.2),
                      widget.button.color.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.button.icon,
                  color: widget.button.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  widget.button.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

