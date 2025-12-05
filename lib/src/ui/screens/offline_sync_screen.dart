import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/app_button.dart';
import '../../core/theme/design_tokens.dart';
import '../../theme/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : const Color(0xFF6366F1),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                        : [Colors.white, const Color(0xFFF8F9FA)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.cloud_sync_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sync Management',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage offline data sync',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF6366F1),
              indicatorWeight: 3,
              labelColor: isDark ? Colors.white : const Color(0xFF6366F1),
              unselectedLabelColor: isDark 
                  ? Colors.white.withValues(alpha: 0.5)
                  : const Color(0xFF6B7280),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Status'),
                Tab(text: 'Queue'),
                Tab(text: 'Conflicts'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildStatusTab(),
            _buildQueueTab(),
            _buildConflictsTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // Tab 1: Status
  // ============================================================================

  Widget _buildStatusTab() {
    final stats = _syncService.getCacheStatistics();

    return SingleChildScrollView(
      primary: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text(
              'Sync Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Online status
            _buildStatusCard(
              'Connection Status',
              _syncService.isOnline ? 'Online' : 'Offline',
              _syncService.isOnline ? Colors.green : Colors.orange,
              _syncService.isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            ),
            const SizedBox(height: 12),

            // Sync state
            _buildStatusCard(
              'Sync State',
              _getSyncStateLabel(),
              _getSyncStateColor(),
              _getSyncStateIcon(),
            ),
            const SizedBox(height: 12),

            // Last sync time
            _buildStatusCard(
              'Last Sync',
              _syncService.lastSyncTime != null
                  ? _formatDateTime(_syncService.lastSyncTime!)
                  : 'Never synced',
              _syncService.lastSyncTime != null ? Colors.blue : Colors.grey,
              Icons.access_time_rounded,
            ),
            const SizedBox(height: 24),
            
            // Statistics section title
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Statistics grid
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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
            
            // Actions section title
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            _buildActionButton(
              icon: Icons.sync_rounded,
              label: _syncService.isSyncing ? 'Syncing...' : 'Sync Now',
              color: AppColors.primary,
              isLoading: _syncService.isSyncing,
              isDisabled: !_syncService.isOnline || _syncService.isSyncing,
              onPressed: _handleManualSync,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              icon: Icons.cached_rounded,
              label: 'Clear Cache',
              color: Colors.orange,
              onPressed: _handleClearCache,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              icon: Icons.clear_all_rounded,
              label: 'Clear Queue',
              color: Colors.red,
              onPressed: _handleClearQueue,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDisabled 
                ? (isDark ? Colors.grey[800] : Colors.grey[200])
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled ? Colors.transparent : color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Icon(icon, color: isDisabled ? Colors.grey : color, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDisabled ? Colors.grey[400] : color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // Tab 2: Queue
  // ============================================================================

  Widget _buildQueueTab() {
    final queue = _syncService.getSyncQueue();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (queue.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: Colors.green[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'All Synced!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No pending changes to sync.\nAll your data is up to date.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (conflicts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_rounded,
                  size: 64,
                  color: Colors.green[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Conflicts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'All data conflicts have been resolved.\nYour data is consistent.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: conflicts.length,
      itemBuilder: (context, index) {
        final conflict = conflicts[index];
        return _buildConflictCard(conflict, isDark);
      },
    );
  }
  
  Widget _buildConflictCard(SyncConflict conflict, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conflict.entityType,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      'ID: ${conflict.entityId}',
                      style: TextStyle(
                        fontSize: 12, 
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDateTime(conflict.conflictTime),
                style: TextStyle(
                  fontSize: 11, 
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showConflictDialog(conflict),
              icon: const Icon(Icons.compare_arrows_rounded, size: 18),
              label: const Text('Resolve Conflict'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Tab 4: History
  // ============================================================================

  Widget _buildHistoryTab() {
    final history = _syncService.getSyncHistory();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No History Yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sync history will appear here\nafter your first synchronization.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return _buildHistoryCard(entry, isDark);
      },
    );
  }
  
  Widget _buildHistoryCard(SyncHistoryEntry entry, bool isDark) {
    final isSuccess = entry.status == 'success';
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;
    final color = isSuccess ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getOperationColor(entry.operation).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.operation.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: _getOperationColor(entry.operation),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.entityType,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${entry.entityId} • ${_formatDateTime(entry.timestamp)}',
                  style: TextStyle(
                    fontSize: 11, 
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                if (entry.error != null) ...[  
                  const SizedBox(height: 4),
                  Text(
                    entry.error!,
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getOperationColor(String operation) {
    switch (operation) {
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

  // ============================================================================
  // Helper Widgets
  // ============================================================================

  Widget _buildStatusCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
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
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: Navigator.of(context).pop,
          ),
          AppButton.primary(
            label: 'Clear',
            onPressed: () {
              _syncService.clearCache();
              Navigator.pop(context);
              setState(() {});
            },
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
          AppButton.tertiary(
            label: 'Cancel',
            onPressed: Navigator.of(context).pop,
          ),
          AppButton.primary(
            label: 'Clear',
            onPressed: () {
              _syncService.clearSyncQueue();
              Navigator.pop(context);
              setState(() {});
            },
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

