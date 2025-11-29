import 'package:flutter/material.dart';

/// A card widget for displaying statistics on a dashboard.
///
/// This widget provides a consistent way to display key metrics with:
/// - Title and value display
/// - Optional icon and trend indicator
/// - Customizable colors and styling
/// - Tap handling for drill-down
///
/// Example:
/// ```dart
/// StatCard(
///   title: 'Total Patients',
///   value: '1,234',
///   icon: Icons.people,
///   trend: StatTrend.up,
///   trendValue: '+12%',
///   onTap: () => navigateToPatients(),
/// )
/// ```
class StatCard extends StatelessWidget {
  /// Creates a stat card.
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.trend,
    this.trendValue,
    this.subtitle,
    this.onTap,
  });

  /// The stat title/label.
  final String title;

  /// The stat value to display prominently.
  final String value;

  /// Optional icon for the stat.
  final IconData? icon;

  /// Color for the icon.
  final Color? iconColor;

  /// Background color for the card.
  final Color? backgroundColor;

  /// Trend direction indicator.
  final StatTrend? trend;

  /// Trend value text (e.g., "+12%", "-5").
  final String? trendValue;

  /// Optional subtitle below the value.
  final String? subtitle;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ??
        theme.colorScheme.surface;

    return Card(
      color: effectiveBackgroundColor,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: effectiveIconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: effectiveIconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trend != null && trendValue != null) ...[
                    _TrendIndicator(
                      trend: trend!,
                      value: trendValue!,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A minimal stat card for compact displays.
class StatCardCompact extends StatelessWidget {
  /// Creates a compact stat card.
  const StatCardCompact({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.color,
    this.onTap,
  });

  /// The stat title.
  final String title;

  /// The stat value.
  final String value;

  /// Optional icon.
  final IconData? icon;

  /// Accent color.
  final Color? color;

  /// Callback when tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: effectiveColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A large stat card for hero displays.
class StatCardHero extends StatelessWidget {
  /// Creates a hero stat card.
  const StatCardHero({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.gradient,
    this.trend,
    this.trendValue,
    this.description,
    this.onTap,
  });

  /// The stat title.
  final String title;

  /// The stat value.
  final String value;

  /// Optional icon.
  final IconData? icon;

  /// Optional gradient for background.
  final LinearGradient? gradient;

  /// Trend direction.
  final StatTrend? trend;

  /// Trend value.
  final String? trendValue;

  /// Optional description text.
  final String? description;

  /// Callback when tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.primary,
        theme.colorScheme.primary.withOpacity(0.8),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient ?? defaultGradient,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trend != null && trendValue != null) ...[
                const SizedBox(height: 8),
                _TrendIndicator(
                  trend: trend!,
                  value: trendValue!,
                  lightMode: true,
                ),
              ],
              if (description != null) ...[
                const SizedBox(height: 12),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Trend direction for statistics.
enum StatTrend {
  /// Value is increasing (positive).
  up,
  
  /// Value is decreasing (negative).
  down,
  
  /// Value is unchanged (neutral).
  neutral,
}

/// Trend indicator widget.
class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({
    required this.trend,
    required this.value,
    this.lightMode = false,
  });

  final StatTrend trend;
  final String value;
  final bool lightMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color color;
    IconData icon;
    
    switch (trend) {
      case StatTrend.up:
        color = lightMode ? Colors.lightGreen : Colors.green;
        icon = Icons.trending_up;
      case StatTrend.down:
        color = lightMode ? Colors.redAccent : Colors.red;
        icon = Icons.trending_down;
      case StatTrend.neutral:
        color = lightMode
            ? Colors.white.withOpacity(0.7)
            : theme.colorScheme.onSurface.withOpacity(0.6);
        icon = Icons.trending_flat;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(lightMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of stat cards for dashboard grids.
class StatCardRow extends StatelessWidget {
  /// Creates a stat card row.
  const StatCardRow({
    super.key,
    required this.children,
    this.spacing = 8,
  });

  /// The stat cards to display.
  final List<Widget> children;

  /// Spacing between cards.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}
