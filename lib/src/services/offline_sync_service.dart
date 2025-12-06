import 'dart:async';

import 'package:flutter/foundation.dart';

/// Offline Sync Service
/// Manages offline capability with local caching, sync queue, conflict resolution,
/// and background synchronization when connectivity is restored.
class OfflineSyncService extends ChangeNotifier {
  // Sync states
  static const int syncStateIdle = 0;
  static const int syncStateSyncing = 1;
  static const int syncStateError = 2;
  static const int syncStateConflict = 3;

  // Cache storage
  final Map<String, CachedEntity> _cache = {};
  final List<SyncQueueItem> _syncQueue = [];
  final List<SyncConflict> _conflicts = [];
  final List<SyncHistoryEntry> _syncHistory = [];

  // State management
  int _syncState = syncStateIdle;
  String? _lastError;
  DateTime? _lastSyncTime;
  int _pendingSyncCount = 0;
  bool _isOnline = true;

  // Sync configuration
  final int maxRetries;
  final Duration retryDelay;
  final Duration syncCheckInterval;

  // Timer for periodic sync checks
  Timer? _syncTimer;

  OfflineSyncService({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
    this.syncCheckInterval = const Duration(minutes: 5),
  });

  // ============================================================================
  // Public Getters
  // ============================================================================

  int get syncState => _syncState;
  bool get isSyncing => _syncState == syncStateSyncing;
  bool get hasErrors => _syncState == syncStateError;
  bool get hasConflicts => _conflicts.isNotEmpty;
  bool get isOnline => _isOnline;
  String? get lastError => _lastError;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingSyncCount => _pendingSyncCount;
  List<SyncQueueItem> get syncQueue => List.unmodifiable(_syncQueue);
  List<SyncConflict> get conflicts => List.unmodifiable(_conflicts);
  List<SyncHistoryEntry> get syncHistory => List.unmodifiable(_syncHistory);

  // ============================================================================
  // Cache Operations
  // ============================================================================

  /// Cache an entity for offline access
  void cacheEntity(
    String entityType,
    String entityId,
    Map<String, dynamic> data, {
    String? entityName,
  }) {
    final key = '$entityType:$entityId';
    _cache[key] = CachedEntity(
      type: entityType,
      id: entityId,
      data: data,
      name: entityName,
      cachedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Get cached entity
  CachedEntity? getCachedEntity(String entityType, String entityId) {
    return _cache['$entityType:$entityId'];
  }

  /// Get all cached entities of a type
  List<CachedEntity> getCachedEntitiesByType(String entityType) {
    return _cache.values
        .where((entity) => entity.type == entityType)
        .toList();
  }

  /// Clear cache for specific entity or all
  void clearCache({String? entityType, String? entityId}) {
    if (entityType != null && entityId != null) {
      _cache.remove('$entityType:$entityId');
    } else if (entityType != null) {
      _cache.removeWhere((key, _) => key.startsWith('$entityType:'));
    } else {
      _cache.clear();
    }
    notifyListeners();
  }

  // ============================================================================
  // Sync Queue Operations
  // ============================================================================

  /// Add item to sync queue
  void addToSyncQueue(
    String operation,
    String entityType,
    String entityId,
    Map<String, dynamic> data, {
    String? entityName,
  }) {
    _syncQueue.add(SyncQueueItem(
      id: '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      operation: operation, // 'create', 'update', 'delete'
      entityType: entityType,
      entityId: entityId,
      data: data,
      name: entityName,
      timestamp: DateTime.now(),
      retryCount: 0,
    ));
    _pendingSyncCount = _syncQueue.length;
    notifyListeners();
  }

  /// Get sync queue
  List<SyncQueueItem> getSyncQueue() => List.unmodifiable(_syncQueue);

  /// Remove item from sync queue
  void removeSyncQueueItem(String queueItemId) {
    _syncQueue.removeWhere((item) => item.id == queueItemId);
    _pendingSyncCount = _syncQueue.length;
    notifyListeners();
  }

  /// Clear sync queue
  void clearSyncQueue() {
    _syncQueue.clear();
    _pendingSyncCount = 0;
    notifyListeners();
  }

  // ============================================================================
  // Conflict Management
  // ============================================================================

  /// Add conflict for resolution
  void addConflict(
    String entityType,
    String entityId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    DateTime conflictTime,
  ) {
    _conflicts.add(SyncConflict(
      id: '${entityType}_${entityId}_${conflictTime.millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      localData: localData,
      remoteData: remoteData,
      conflictTime: conflictTime,
      resolved: false,
    ));
    _syncState = syncStateConflict;
    notifyListeners();
  }

  /// Resolve conflict (choose local or remote)
  void resolveConflict(String conflictId, ConflictResolution resolution) {
    final index = _conflicts.indexWhere((c) => c.id == conflictId);
    if (index != -1) {
      final conflict = _conflicts[index];
      _conflicts[index] = SyncConflict(
        id: conflict.id,
        entityType: conflict.entityType,
        entityId: conflict.entityId,
        localData: conflict.localData,
        remoteData: conflict.remoteData,
        conflictTime: conflict.conflictTime,
        resolved: true,
        resolution: resolution,
      );

      // If any conflicts remain, keep conflict state
      if (_conflicts.every((c) => c.resolved)) {
        _syncState = syncStateIdle;
      }
      notifyListeners();
    }
  }

  /// Get unresolved conflicts
  List<SyncConflict> getUnresolvedConflicts() {
    return _conflicts.where((c) => !c.resolved).toList();
  }

  // ============================================================================
  // Sync Operations
  // ============================================================================

  /// Set online/offline status
  void setOnlineStatus(bool online) {
    _isOnline = online;
    if (online && _syncQueue.isNotEmpty) {
      // Trigger sync when coming back online
      _triggerSync();
    }
    notifyListeners();
  }

  /// Trigger manual sync
  Future<void> triggerSync() async {
    if (isSyncing) return;
    await _triggerSync();
  }

  Future<void> _triggerSync() async {
    _syncState = syncStateSyncing;
    _lastError = null;
    notifyListeners();

    try {
      // Simulate sync process
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Process sync queue
      final itemsToRemove = <SyncQueueItem>[];
      for (var item in _syncQueue) {
        try {
          await _syncItem(item);
          itemsToRemove.add(item);

          // Add to history
          _syncHistory.add(SyncHistoryEntry(
            id: item.id,
            operation: item.operation,
            entityType: item.entityType,
            entityId: item.entityId,
            status: 'success',
            timestamp: DateTime.now(),
          ));
        } catch (e) {
          // Retry logic
          if (item.retryCount < maxRetries) {
            item.retryCount++;
            await Future<void>.delayed(retryDelay * (1 << (item.retryCount - 1)));
          } else {
            // Max retries exceeded
            _lastError = 'Sync failed for ${item.entityType}:${item.entityId}';
            _syncState = syncStateError;

            _syncHistory.add(SyncHistoryEntry(
              id: item.id,
              operation: item.operation,
              entityType: item.entityType,
              entityId: item.entityId,
              status: 'failed',
              timestamp: DateTime.now(),
              error: e.toString(),
            ));
          }
        }
      }

      // Remove successfully synced items
      for (var item in itemsToRemove) {
        _syncQueue.remove(item);
      }

      _pendingSyncCount = _syncQueue.length;
      _lastSyncTime = DateTime.now();

      if (_syncQueue.isEmpty && _conflicts.isEmpty) {
        _syncState = syncStateIdle;
      }
    } catch (e) {
      _lastError = e.toString();
      _syncState = syncStateError;
    }

    notifyListeners();
  }

  Future<void> _syncItem(SyncQueueItem item) async {
    // Simulate server sync operation
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // In real implementation, this would make API calls
    // For now, it simulates successful sync
    if (item.operation == 'delete') {
      clearCache(entityType: item.entityType, entityId: item.entityId);
    }
  }

  /// Start periodic sync
  void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(syncCheckInterval, (_) {
      if (_isOnline && !isSyncing && _syncQueue.isNotEmpty) {
        _triggerSync();
      }
    });
  }

  /// Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
  }

  // ============================================================================
  // Sync History
  // ============================================================================

  /// Get sync history
  List<SyncHistoryEntry> getSyncHistory({
    int limit = 50,
    String? entityType,
  }) {
    var history = _syncHistory;
    if (entityType != null) {
      history = history.where((h) => h.entityType == entityType).toList();
    }
    return history.take(limit).toList();
  }

  /// Clear sync history
  void clearSyncHistory() {
    _syncHistory.clear();
    notifyListeners();
  }

  /// Get cache statistics
  CacheStatistics getCacheStatistics() {
    final types = <String, int>{};
    for (var entity in _cache.values) {
      types[entity.type] = (types[entity.type] ?? 0) + 1;
    }

    return CacheStatistics(
      totalCachedItems: _cache.length,
      cacheByType: types,
      totalQueuedItems: _syncQueue.length,
      totalConflicts: _conflicts.length,
      totalHistoryEntries: _syncHistory.length,
    );
  }

  @override
  void dispose() {
    stopPeriodicSync();
    super.dispose();
  }
}

// ============================================================================
// Data Models
// ============================================================================

/// Represents a cached entity
class CachedEntity {
  final String type;
  final String id;
  final Map<String, dynamic> data;
  final String? name;
  final DateTime cachedAt;

  CachedEntity({
    required this.type,
    required this.id,
    required this.data,
    this.name,
    required this.cachedAt,
  });
}

/// Represents an item in the sync queue
class SyncQueueItem {
  final String id;
  final String operation; // 'create', 'update', 'delete'
  final String entityType;
  final String entityId;
  final Map<String, dynamic> data;
  final String? name;
  final DateTime timestamp;
  int retryCount;

  SyncQueueItem({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.data,
    this.name,
    required this.timestamp,
    this.retryCount = 0,
  });
}

/// Represents a sync conflict
class SyncConflict {
  final String id;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime conflictTime;
  final bool resolved;
  final ConflictResolution? resolution;

  SyncConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.localData,
    required this.remoteData,
    required this.conflictTime,
    this.resolved = false,
    this.resolution,
  });
}

/// Conflict resolution choice
enum ConflictResolution { keepLocal, useRemote, merge }

/// Represents a sync history entry
class SyncHistoryEntry {
  final String id;
  final String operation;
  final String entityType;
  final String entityId;
  final String status; // 'success', 'failed', 'pending'
  final DateTime timestamp;
  final String? error;

  SyncHistoryEntry({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.status,
    required this.timestamp,
    this.error,
  });
}

/// Cache statistics
class CacheStatistics {
  final int totalCachedItems;
  final Map<String, int> cacheByType;
  final int totalQueuedItems;
  final int totalConflicts;
  final int totalHistoryEntries;

  CacheStatistics({
    required this.totalCachedItems,
    required this.cacheByType,
    required this.totalQueuedItems,
    required this.totalConflicts,
    required this.totalHistoryEntries,
  });
}
