import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/offline_sync_service.dart';

// ============================================================================
// Sync Status Banner Widget
// ============================================================================

class SyncStatusBanner extends ConsumerWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const SyncStatusBanner({
    Key? key,
    this.onRetry,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In real implementation, would use provider to watch sync service
    // For now, returning empty container
    return const SizedBox.shrink();
  }
}

// ============================================================================
// Sync Progress Dialog Widget
// ============================================================================

class SyncProgressDialog extends StatefulWidget {
  final OfflineSyncService syncService;
  final VoidCallback? onComplete;

  const SyncProgressDialog({
    Key? key,
    required this.syncService,
    this.onComplete,
  }) : super(key: key);

  @override
  State<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<SyncProgressDialog> {
  late final StreamSubscription _syncSubscription;

  @override
  void initState() {
    super.initState();
    _syncSubscription = Stream.periodic(const Duration(milliseconds: 500))
        .listen((_) {
          if (mounted) setState(() {});
          if (!widget.syncService.isSyncing) {
            widget.onComplete?.call();
          }
        });
  }

  @override
  void dispose() {
    _syncSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final stats = widget.syncService.getCacheStatistics();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Synchronizing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Progress info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Queued Items', '${stats.totalQueuedItems}'),
                  _buildInfoRow('Cached Items', '${stats.totalCachedItems}'),
                  _buildInfoRow('Conflicts', '${stats.totalConflicts}'),
                  if (widget.syncService.lastSyncTime != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last sync: ${widget.syncService.lastSyncTime}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Cancel button
            AppButton.tertiary(
              label: 'Close',
              onPressed: Navigator.of(context).pop,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ============================================================================
// Offline Indicator Widget
// ============================================================================

class OfflineIndicator extends ConsumerWidget {
  final OfflineSyncService syncService;

  const OfflineIndicator({
    Key? key,
    required this.syncService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (syncService.isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.orange.withValues(alpha: 0.9),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are offline. Changes will be synced when online.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Conflict Resolution Dialog Widget
// ============================================================================

class ConflictResolutionDialog extends StatefulWidget {
  final SyncConflict conflict;
  final Function(ConflictResolution) onResolved;

  const ConflictResolutionDialog({
    Key? key,
    required this.conflict,
    required this.onResolved,
  }) : super(key: key);

  @override
  State<ConflictResolutionDialog> createState() =>
      _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  ConflictResolution? _selectedResolution;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resolve Conflict',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.conflict.entityType}:${widget.conflict.entityId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            // Data comparison
            Row(
              children: [
                Expanded(
                  child: _buildDataColumn(
                    context,
                    'Local Data',
                    widget.conflict.localData,
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDataColumn(
                    context,
                    'Remote Data',
                    widget.conflict.remoteData,
                    isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Resolution options
            _buildResolutionOption(
              'Keep Local',
              'Use your local version',
              ConflictResolution.keepLocal,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildResolutionOption(
              'Use Remote',
              'Use the server version',
              ConflictResolution.useRemote,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildResolutionOption(
              'Merge',
              'Combine both versions',
              ConflictResolution.merge,
              Colors.purple,
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton.tertiary(
                  label: 'Cancel',
                  onPressed: Navigator.of(context).pop,
                ),
                const SizedBox(width: 12),
                AppButton.primary(
                  label: 'Resolve',
                  onPressed: _selectedResolution != null
                      ? () {
                          widget.onResolved(_selectedResolution!);
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataColumn(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatData(data),
            style: const TextStyle(fontSize: 11),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionOption(
    String title,
    String subtitle,
    ConflictResolution resolution,
    Color color,
  ) {
    return Material(
      child: InkWell(
        onTap: () => setState(() => _selectedResolution = resolution),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Radio<ConflictResolution>(
                value: resolution,
                groupValue: _selectedResolution,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedResolution = value);
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatData(Map<String, dynamic> data) {
    return data.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n')
        .substring(0, 100);
  }
}

// ============================================================================
// Sync Queue Item Widget
// ============================================================================

class SyncQueueItemWidget extends StatelessWidget {
  final SyncQueueItem item;
  final VoidCallback? onRemove;

  const SyncQueueItemWidget({
    Key? key,
    required this.item,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final icon = _getOperationIcon();
    final color = _getOperationColor();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.operation.toUpperCase()} ${item.entityType}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${item.entityId}${item.name != null ? ' • ${item.name}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  if (item.retryCount > 0)
                    Text(
                      'Retry ${item.retryCount}/${3}',
                      style: const TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemove,
              tooltip: 'Remove from queue',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getOperationIcon() {
    switch (item.operation) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.cloud_upload_outlined;
    }
  }

  Color _getOperationColor() {
    switch (item.operation) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
