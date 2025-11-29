import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A row widget for displaying labeled information.
///
/// This widget provides a consistent way to display key-value pairs:
/// - Label and value
/// - Optional icon
/// - Optional copy button
/// - Optional action button
///
/// Example:
/// ```dart
/// InfoRow(
///   label: 'Email',
///   value: 'patient@email.com',
///   icon: Icons.email,
///   copyable: true,
/// )
/// ```
class InfoRow extends StatelessWidget {
  /// Creates an info row.
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.copyable = false,
    this.onTap,
    this.actionIcon,
    this.onAction,
    this.valueStyle,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// The label text.
  final String label;

  /// The value text.
  final String value;

  /// Optional leading icon.
  final IconData? icon;

  /// Icon color.
  final Color? iconColor;

  /// Whether the value can be copied.
  final bool copyable;

  /// Callback when the row is tapped.
  final VoidCallback? onTap;

  /// Action button icon.
  final IconData? actionIcon;

  /// Callback for the action button.
  final VoidCallback? onAction;

  /// Custom value text style.
  final TextStyle? valueStyle;

  /// Cross axis alignment.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: iconColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: valueStyle ?? theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (copyable) ...[
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              tooltip: 'Copy',
            ),
          ],
          if (actionIcon != null && onAction != null) ...[
            IconButton(
              icon: Icon(actionIcon, size: 20),
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

/// A compact info row for inline display.
class InfoRowCompact extends StatelessWidget {
  /// Creates a compact info row.
  const InfoRowCompact({
    super.key,
    required this.label,
    required this.value,
    this.separator = ':',
  });

  /// The label text.
  final String label;

  /// The value text.
  final String value;

  /// Separator between label and value.
  final String separator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label$separator ',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

/// A vertical info display for prominent values.
class InfoColumn extends StatelessWidget {
  /// Creates an info column.
  const InfoColumn({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.alignment = CrossAxisAlignment.start,
    this.valueStyle,
    this.onTap,
  });

  /// The label text.
  final String label;

  /// The value text.
  final String value;

  /// Optional icon above the label.
  final IconData? icon;

  /// Alignment of the column.
  final CrossAxisAlignment alignment;

  /// Custom value text style.
  final TextStyle? valueStyle;

  /// Callback when tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Column(
      crossAxisAlignment: alignment,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          value,
          style: valueStyle ??
              theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// A list of info rows with optional dividers.
class InfoList extends StatelessWidget {
  /// Creates an info list.
  const InfoList({
    super.key,
    required this.items,
    this.showDividers = true,
  });

  /// The info rows to display.
  final List<InfoRow> items;

  /// Whether to show dividers between rows.
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    if (!showDividers) {
      return Column(children: items);
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          items[i],
          if (i < items.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

/// A key-value grid for displaying multiple info items.
class InfoGrid extends StatelessWidget {
  /// Creates an info grid.
  const InfoGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  /// Map of label to value.
  final Map<String, String> items;

  /// Number of columns.
  final int crossAxisCount;

  /// Horizontal spacing.
  final double spacing;

  /// Vertical spacing.
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = items.entries.toList();

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: entries.map((entry) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 
                  (crossAxisCount + 1) * spacing) / 
                 crossAxisCount,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// A badge/chip info display.
class InfoBadge extends StatelessWidget {
  /// Creates an info badge.
  const InfoBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.onTap,
  });

  /// The badge text.
  final String label;

  /// Background color.
  final Color? color;

  /// Optional leading icon.
  final IconData? icon;

  /// Callback when tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primaryContainer;
    final textColor = color != null
        ? (color!.computeLuminance() > 0.5 ? Colors.black : Colors.white)
        : theme.colorScheme.onPrimaryContainer;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }

    return content;
  }
}
