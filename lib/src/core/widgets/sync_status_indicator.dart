import 'package:flutter/material.dart';
import '../utils/connectivity.dart';
import '../extensions/context_extensions.dart';

/// A widget that displays the current sync/connectivity status.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    required this.status,
    super.key,
    this.size = 24,
    this.showLabel = true,
    this.onTap,
  });

  /// The current connectivity status.
  final ConnectivityStatus status;

  /// Size of the indicator icon.
  final double size;

  /// Whether to show the status label.
  final bool showLabel;

  /// Callback when the indicator is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _getStatusConfig();

    final indicator = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size * 0.75, color: color),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: indicator,
      );
    }

    return indicator;
  }

  (IconData, Color, String) _getStatusConfig() {
    switch (status) {
      case ConnectivityStatus.connected:
        return (Icons.cloud_done_rounded, Colors.green, 'Synced');
      case ConnectivityStatus.offline:
        return (Icons.cloud_off_rounded, Colors.orange, 'Offline');
      case ConnectivityStatus.unknown:
        return (Icons.cloud_outlined, Colors.grey, 'Checking...');
    }
  }
}

/// A widget that shows sync progress with a message.
class SyncProgressIndicator extends StatelessWidget {
  const SyncProgressIndicator({
    required this.message,
    super.key,
    this.progress,
    this.isIndeterminate = true,
  });

  /// The sync status message to display.
  final String message;

  /// Optional progress value between 0.0 and 1.0.
  final double? progress;

  /// Whether to show indeterminate progress.
  final bool isIndeterminate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(context.responsivePadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: isIndeterminate
                ? CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  )
                : CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A banner that appears when the device is offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.message = 'You are currently offline',
    this.actionLabel,
    this.onAction,
  });

  /// The message to display.
  final String message;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback when action button is pressed.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade800,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A wrapper that shows an offline banner when disconnected.
class ConnectivityAwareScaffold extends StatelessWidget {
  const ConnectivityAwareScaffold({
    required this.status,
    required this.body,
    super.key,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.offlineMessage = 'You are currently offline. Changes will sync when connected.',
    this.showOfflineBanner = true,
  });

  /// Current connectivity status.
  final ConnectivityStatus status;

  /// The main body of the scaffold.
  final Widget body;

  /// Optional app bar.
  final PreferredSizeWidget? appBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Optional bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// Message to show when offline.
  final String offlineMessage;

  /// Whether to show the offline banner.
  final bool showOfflineBanner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Column(
        children: [
          if (showOfflineBanner && status == ConnectivityStatus.offline)
            OfflineBanner(message: offlineMessage),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// A widget that shows pending sync items count.
class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({
    required this.count,
    super.key,
    this.child,
  });

  /// Number of pending items.
  final int count;

  /// Optional child widget to wrap with badge.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return child ?? const SizedBox.shrink();
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (child == null) {
      return badge;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        Positioned(
          right: -8,
          top: -4,
          child: badge,
        ),
      ],
    );
  }
}
