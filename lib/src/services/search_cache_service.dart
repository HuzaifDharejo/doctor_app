/// Search result caching service with TTL support
library;

import 'dart:async';
import '../services/logger_service.dart';

/// A cached search result with expiration
class _CachedResult<T> {
  final List<T> data;
  final DateTime expiresAt;

  _CachedResult(this.data, {required Duration ttl})
      : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Service for caching search results
class SearchCacheService {
  static final SearchCacheService _instance = SearchCacheService._internal();
  factory SearchCacheService() => _instance;
  SearchCacheService._internal();

  // Default TTL: 5 minutes
  static const Duration defaultTtl = Duration(minutes: 5);

  // Cache storage: Map<CacheKey, CachedResult>
  final Map<String, _CachedResult<dynamic>> _cache = {};
  Timer? _cleanupTimer;

  /// Initialize cleanup timer to periodically remove expired entries
  void _startCleanupTimer() {
    if (_cleanupTimer != null && _cleanupTimer!.isActive) return;

    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanupExpired();
    });
  }

  /// Remove expired cache entries
  void _cleanupExpired() {
    _cache.removeWhere((key, value) => value.isExpired);
  }

  /// Generate a cache key from search parameters
  String _generateKey(String cacheType, Map<String, dynamic> params) {
    final normalizedParams = Map<String, dynamic>.from(params)
      ..removeWhere((key, value) => value == null || value == '');
    
    // Sort keys for consistent key generation
    final sortedKeys = normalizedParams.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key:${normalizedParams[key]}')
        .join('|');
    
    return '$cacheType:$paramString';
  }

  /// Get cached results if available and not expired
  List<T>? getCached<T>({
    required String cacheType,
    required Map<String, dynamic> params,
  }) {
    final key = _generateKey(cacheType, params);
    final cached = _cache[key];

    if (cached == null) {
      return null;
    }

    if (cached.isExpired) {
      _cache.remove(key);
      return null;
    }

    // Cast cached data to List<T>
    try {
      return cached.data as List<T>;
    } catch (e) {
      log.w('SearchCache', 'Error casting cached result: $e');
      _cache.remove(key);
      return null;
    }
  }

  /// Store search results in cache
  void setCached<T>({
    required String cacheType,
    required Map<String, dynamic> params,
    required List<T> data,
    Duration? ttl,
  }) {
    final key = _generateKey(cacheType, params);
    _cache[key] = _CachedResult<T>(data, ttl: ttl ?? defaultTtl);
    _startCleanupTimer();
  }

  /// Invalidate cache for a specific type or all cache
  void invalidate({
    String? cacheType,
    Map<String, dynamic>? params,
  }) {
    if (cacheType == null) {
      // Clear all cache
      _cache.clear();
      log.d('SearchCache', 'Cleared all cache');
      return;
    }

    if (params != null) {
      // Invalidate specific cache entry
      final key = _generateKey(cacheType, params);
      _cache.remove(key);
      log.d('SearchCache', 'Invalidated cache entry: $key');
    } else {
      // Invalidate all entries of this type
      final keysToRemove = _cache.keys
          .where((key) => key.startsWith('$cacheType:'))
          .toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
      log.d('SearchCache', 'Invalidated all $cacheType cache (${keysToRemove.length} entries)');
    }
  }

  /// Clear all cache
  void clearAll() {
    _cache.clear();
    log.d('SearchCache', 'Cleared all cache');
  }

  /// Get cache statistics (for debugging)
  Map<String, dynamic> getStats() {
    final byType = <String, int>{};
    int expiredCount = 0;

    for (final entry in _cache.entries) {
      final type = entry.key.split(':').first;
      byType[type] = (byType[type] ?? 0) + 1;
      if (entry.value.isExpired) {
        expiredCount++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'expiredEntries': expiredCount,
      'byType': byType,
    };
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _cache.clear();
  }
}


