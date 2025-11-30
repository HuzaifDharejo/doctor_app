import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_card.dart';
import '../../services/offline_sync_service.dart';
import '../widgets/offline_sync_widgets.dart';

/// Offline Sync Management Screen
/// Provides comprehensive sync management interface with queue, conflicts, history,
/// and manual sync controls.
class OfflineSyncScreen extends ConsumerStatefulWidget {
  const OfflineSyncScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OfflineSyncScreen> createState() => _OfflineSyncScreenState();
}

class _OfflineSyncScreenState extends ConsumerState<OfflineSyncScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late OfflineSyncService _syncService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _syncService = OfflineSyncService();
    _syncService.addListener(_onSyncStateChanged);
    _syncService.startPeriodicSync();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _syncService.removeListener(_onSyncStateChanged);
    _syncService.stopPeriodicSync();
    _syncService.dispose();
    super.dispose();
  }

  void _onSyncStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync Management'),
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Status', icon: Icon(Icons.cloud_done_outlined)),
            Tab(text: 'Queue', icon: Icon(Icons.pending_actions_outlined)),
            Tab(text: 'Conflicts', icon: Icon(Icons.warning_outlined)),
            Tab(text: 'History', icon: Icon(Icons.history_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatusTab(),
          _buildQueueTab(),
          _buildConflictsTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ============================================================================
  // Tab 1: Status
  // ============================================================================

  Widget _buildStatusTab() {
    final stats = _syncService.getCacheStatistics();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Online status
            _buildStatusCard(
              'Connection Status',
              _syncService.isOnline ? 'Online' : 'Offline',
              _syncService.isOnline ? Colors.green : Colors.orange,
              Icons.cloud_done_outlined,
            ),
            const SizedBox(height: 16),

            // Sync state
            _buildStatusCard(
              'Sync State',
              _getSyncStateLabel(),
              _getSyncStateColor(),
              _getSyncStateIcon(),
            ),
            const SizedBox(height: 16),

            // Last sync time
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Sync',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _syncService.lastSyncTime != null
                          ? _syncService.lastSyncTime.toString()
                          : 'Never',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statistics grid
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  'Cached Items',
                  stats.totalCachedItems.toString(),
                  Colors.blue,
                ),
                _buildStatCard(
                  'Queued Items',
                  stats.totalQueuedItems.toString(),
                  Colors.orange,
                ),
                _buildStatCard(
                  'Conflicts',
                  stats.totalConflicts.toString(),
                  Colors.red,
                ),
                _buildStatCard(
                  'History Entries',
                  stats.totalHistoryEntries.toString(),
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _syncService.isOnline && !_syncService.isSyncing
                    ? _handleManualSync
                    : null,
                icon: const Icon(Icons.sync_outlined),
                label: _syncService.isSyncing ? const Text('Syncing...') : const Text('Manual Sync'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleClearCache,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Cache'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleClearQueue,
                icon: const Icon(Icons.clear_all_outlined),
                label: const Text('Clear Queue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Tab 2: Queue
  // ============================================================================

  Widget _buildQueueTab() {
    final queue = _syncService.getSyncQueue();

    if (queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending items',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'All changes have been synced',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: queue.length,
      itemBuilder: (context, index) {
        final item = queue[index];
        return SyncQueueItemWidget(
          item: item,
          onRemove: () {
            _syncService.removeSyncQueueItem(item.id);
            setState(() {});
          },
        );
      },
    );
  }

  // ============================================================================
  // Tab 3: Conflicts
  // ============================================================================

  Widget _buildConflictsTab() {
    final conflicts = _syncService.getUnresolvedConflicts();

    if (conflicts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No conflicts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'All conflicts have been resolved',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conflicts.length,
      itemBuilder: (context, index) {
        final conflict = conflicts[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${conflict.entityType}:${conflict.entityId}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            conflict.conflictTime.toString(),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    _showConflictDialog(conflict);
                  },
                  child: const Text('Resolve'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // Tab 4: History
  // ============================================================================

  Widget _buildHistoryTab() {
    final history = _syncService.getSyncHistory();

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        final isSuccess = entry.status == 'success';
        final icon = isSuccess ? Icons.check_circle : Icons.error_outline;
        final color = isSuccess ? Colors.green : Colors.red;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.operation.toUpperCase()} ${entry.entityType}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${entry.entityId} • ${entry.timestamp}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      if (entry.error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          entry.error!,
                          style: const TextStyle(fontSize: 10, color: Colors.red),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // Helper Widgets
  // ============================================================================

  Widget _buildStatusCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
    );
  }

  // ============================================================================
  // Event Handlers
  // ============================================================================

  Future<void> _handleManualSync() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SyncProgressDialog(
        syncService: _syncService,
        onComplete: () {
          if (mounted) {
            Navigator.pop(context);
            setState(() {});
          }
        },
      ),
    );

    await _syncService.triggerSync();
  }

  void _handleClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will remove all cached data.'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _syncService.clearCache();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _handleClearQueue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Queue?'),
        content: const Text('Unsynced changes will be lost.'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _syncService.clearSyncQueue();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showConflictDialog(SyncConflict conflict) {
    showDialog(
      context: context,
      builder: (context) => ConflictResolutionDialog(
        conflict: conflict,
        onResolved: (resolution) {
          _syncService.resolveConflict(conflict.id, resolution);
          setState(() {});
        },
      ),
    );
  }

  // ============================================================================
  // Sync State Helpers
  // ============================================================================

  String _getSyncStateLabel() {
    switch (_syncService.syncState) {
      case OfflineSyncService.syncStateIdle:
        return 'Idle';
      case OfflineSyncService.syncStateSyncing:
        return 'Syncing...';
      case OfflineSyncService.syncStateError:
        return 'Error';
      case OfflineSyncService.syncStateConflict:
        return 'Conflict';
      default:
        return 'Unknown';
    }
  }

  Color _getSyncStateColor() {
    switch (_syncService.syncState) {
      case OfflineSyncService.syncStateIdle:
        return Colors.green;
      case OfflineSyncService.syncStateSyncing:
        return Colors.blue;
      case OfflineSyncService.syncStateError:
        return Colors.red;
      case OfflineSyncService.syncStateConflict:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getSyncStateIcon() {
    switch (_syncService.syncState) {
      case OfflineSyncService.syncStateIdle:
        return Icons.check_circle_outline;
      case OfflineSyncService.syncStateSyncing:
        return Icons.hourglass_bottom_outlined;
      case OfflineSyncService.syncStateError:
        return Icons.error_outline;
      case OfflineSyncService.syncStateConflict:
        return Icons.warning_outlined;
      default:
        return Icons.cloud_done_outlined;
    }
  }
}
