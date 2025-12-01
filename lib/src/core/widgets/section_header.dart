import 'package:flutter/material.dart';

/// A consistent section header widget for lists and forms.
///
/// This widget provides a standardized section header with:
/// - Title text
/// - Optional action button
/// - Optional subtitle/count
/// - Consistent styling
///
/// Example:
/// ```dart
/// SectionHeader(
///   title: 'Recent Patients',
///   actionLabel: 'View All',
///   onAction: () => navigateToPatients(),
///   count: 12,
/// )
/// ```
class SectionHeader extends StatelessWidget {
  /// Creates a section header.
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.count,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.padding,
    this.titleStyle,
  });

  /// The section title.
  final String title;

  /// Optional subtitle below the title.
  final String? subtitle;

  /// Optional count to display.
  final int? count;

  /// Label for the action button.
  final String? actionLabel;

  /// Callback for the action button.
  final VoidCallback? onAction;

  /// Icon for the action button.
  final IconData? actionIcon;

  /// Custom padding.
  final EdgeInsets? padding;

  /// Custom title style.
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    return Padding(
      padding: effectivePadding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: titleStyle ??
                          theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton.icon(
              onPressed: onAction,
              icon: actionIcon != null
                  ? Icon(actionIcon, size: 18)
                  : const SizedBox.shrink(),
              label: Text(actionLabel!),
            )
          else if (onAction != null)
            IconButton(
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.chevron_right),
              tooltip: actionLabel,
            ),
        ],
      ),
    );
  }
}

/// A divider with an optional label in the center.
class LabeledDivider extends StatelessWidget {
  /// Creates a labeled divider.
  const LabeledDivider({
    super.key,
    required this.label,
    this.padding,
    this.thickness = 1,
  });

  /// The label to display.
  final String label;

  /// Custom padding.
  final EdgeInsets? padding;

  /// Divider thickness.
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

    return Padding(
      padding: effectivePadding,
      child: Row(
        children: [
          Expanded(
            child: Divider(
              thickness: thickness,
              height: thickness,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              thickness: thickness,
              height: thickness,
            ),
          ),
        ],
      ),
    );
  }
}

/// A grouped section container with header.
class GroupedSection extends StatelessWidget {
  /// Creates a grouped section.
  const GroupedSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding,
    this.spacing = 0,
  });

  /// The section title.
  final String title;

  /// Section content.
  final List<Widget> children;

  /// Optional subtitle.
  final String? subtitle;

  /// Action button label.
  final String? actionLabel;

  /// Action callback.
  final VoidCallback? onAction;

  /// Custom padding.
  final EdgeInsets? padding;

  /// Spacing between children.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          actionLabel: actionLabel,
          onAction: onAction,
          padding: padding,
        ),
        ...children.map(
          (child) => Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// A card-based section with header inside.
class HeaderCard extends StatelessWidget {
  /// Creates a header card.
  const HeaderCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.margin,
    this.padding,
  });

  /// The section title.
  final String title;

  /// Section content.
  final Widget child;

  /// Optional subtitle.
  final String? subtitle;

  /// Action button label.
  final String? actionLabel;

  /// Action callback.
  final VoidCallback? onAction;

  /// Card margin.
  final EdgeInsets? margin;

  /// Content padding.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveMargin = margin ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    final effectivePadding = padding ?? const EdgeInsets.all(16);

    return Card(
      margin: effectiveMargin,
      child: Padding(
        padding: effectivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              subtitle: subtitle,
              actionLabel: actionLabel,
              onAction: onAction,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// A collapsible section with header.
class CollapsibleSection extends StatefulWidget {
  /// Creates a collapsible section.
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = true,
    this.onExpansionChanged,
    this.padding,
  });

  /// The section title.
  final String title;

  /// Section content.
  final Widget child;

  /// Optional subtitle.
  final String? subtitle;

  /// Whether initially expanded.
  final bool initiallyExpanded;

  /// Callback when expansion changes.
  final ValueChanged<bool>? onExpansionChanged;

  /// Custom padding.
  final EdgeInsets? padding;

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggleExpansion,
          child: Padding(
            padding: effectivePadding,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: widget.child,
          secondChild: const SizedBox.shrink(),
          crossFadeState:
              _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
