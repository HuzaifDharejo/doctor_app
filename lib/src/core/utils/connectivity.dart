/// Network connectivity and retry utilities.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Network connectivity status.
enum ConnectivityStatus {
  /// Device is connected to the internet.
  connected,
  
  /// Device is offline.
  offline,
  
  /// Connection status is unknown.
  unknown,
}

/// A service to monitor network connectivity.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService() {
    // Initial check
    checkConnectivity();
  }
  
  ConnectivityStatus _status = ConnectivityStatus.unknown;
  ConnectivityStatus get status => _status;
  
  bool get isConnected => _status == ConnectivityStatus.connected;
  bool get isOffline => _status == ConnectivityStatus.offline;
  
  Timer? _checkTimer;
  
  /// Check current connectivity status.
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      // Try to lookup a reliable host
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _updateStatus(ConnectivityStatus.connected);
      } else {
        _updateStatus(ConnectivityStatus.offline);
      }
    } on SocketException catch (_) {
      _updateStatus(ConnectivityStatus.offline);
    } on TimeoutException catch (_) {
      _updateStatus(ConnectivityStatus.offline);
    } catch (_) {
      _updateStatus(ConnectivityStatus.unknown);
    }
    
    return _status;
  }
  
  void _updateStatus(ConnectivityStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }
  
  /// Start periodic connectivity checks.
  void startPeriodicCheck({Duration interval = const Duration(seconds: 30)}) {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(interval, (_) => checkConnectivity());
  }
  
  /// Stop periodic connectivity checks.
  void stopPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }
  
  @override
  void dispose() {
    stopPeriodicCheck();
    super.dispose();
  }
}

/// Configuration for retry behavior.
@immutable
class RetryConfig {
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryableErrors = const [
      SocketException,
      TimeoutException,
      HttpException,
    ],
  });
  
  /// Maximum number of retry attempts.
  final int maxAttempts;
  
  /// Initial delay before first retry.
  final Duration initialDelay;
  
  /// Maximum delay between retries.
  final Duration maxDelay;
  
  /// Multiplier for exponential backoff.
  final double backoffMultiplier;
  
  /// Types of errors that should trigger a retry.
  final List<Type> retryableErrors;
  
  /// Default configuration for network operations.
  static const network = RetryConfig();
  
  /// Configuration for critical operations that should retry more.
  static const critical = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
  );
  
  /// Calculate delay for a given attempt number.
  Duration delayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;
    
    final delay = initialDelay.inMilliseconds * 
        (backoffMultiplier * (attempt - 1)).toInt().clamp(1, 100);
    return Duration(
      milliseconds: delay.clamp(0, maxDelay.inMilliseconds),
    );
  }
}

/// Result of a retry operation.
@immutable
class RetryResult<T> {
  /// Create a successful result.
  const RetryResult.success(
    T this.value, {
    required this.attempts,
    required this.totalDuration,
  })  : isSuccess = true,
        error = null;
  
  /// Create a failure result.
  const RetryResult.failure(
    Object this.error, {
    required this.attempts,
    required this.totalDuration,
  })  : isSuccess = false,
        value = null;
  
  /// Whether the operation succeeded.
  final bool isSuccess;
  
  /// The result value if successful.
  final T? value;
  
  /// The last error if failed.
  final Object? error;
  
  /// Number of attempts made.
  final int attempts;
  
  /// Total time spent including delays.
  final Duration totalDuration;
  
  /// Get value or throw error.
  T getOrThrow() {
    if (isSuccess && value != null) {
      return value as T;
    }
    throw error ?? Exception('Operation failed without error');
  }
  
  /// Get value or return default.
  T getOrDefault(T defaultValue) {
    return isSuccess && value != null ? value as T : defaultValue;
  }
}

/// Execute an operation with automatic retry on failure.
Future<RetryResult<T>> withRetry<T>(
  Future<T> Function() operation, {
  RetryConfig config = RetryConfig.network,
  bool Function(Object error)? shouldRetry,
  void Function(int attempt, Object error, Duration nextDelay)? onRetry,
}) async {
  final stopwatch = Stopwatch()..start();
  var attempts = 0;
  Object? lastError;
  
  while (attempts < config.maxAttempts) {
    attempts++;
    
    try {
      final result = await operation();
      stopwatch.stop();
      return RetryResult.success(
        result,
        attempts: attempts,
        totalDuration: stopwatch.elapsed,
      );
    } catch (e) {
      lastError = e;
      
      // Check if we should retry this error
      final canRetry = shouldRetry?.call(e) ?? 
          config.retryableErrors.any((type) => e.runtimeType == type);
      
      if (!canRetry || attempts >= config.maxAttempts) {
        break;
      }
      
      // Calculate delay and wait
      final delay = config.delayForAttempt(attempts);
      onRetry?.call(attempts, e, delay);
      
      await Future<void>.delayed(delay);
    }
  }
  
  stopwatch.stop();
  return RetryResult.failure(
    lastError ?? Exception('Unknown error'),
    attempts: attempts,
    totalDuration: stopwatch.elapsed,
  );
}

/// A queue for operations that should be retried when connectivity returns.
class OfflineQueue<T> {
  OfflineQueue({
    this.maxQueueSize = 100,
    this.persistKey,
  });
  
  /// Maximum number of operations to queue.
  final int maxQueueSize;
  
  /// Optional key for persisting queue to storage.
  final String? persistKey;
  
  final List<_QueuedOperation<T>> _queue = [];
  
  /// Number of queued operations.
  int get length => _queue.length;
  
  /// Whether the queue is empty.
  bool get isEmpty => _queue.isEmpty;
  
  /// Whether the queue is full.
  bool get isFull => _queue.length >= maxQueueSize;
  
  /// Add an operation to the queue.
  bool enqueue({
    required Future<T> Function() operation,
    required String id,
    Map<String, dynamic>? metadata,
  }) {
    if (isFull) return false;
    
    // Don't add duplicates
    if (_queue.any((op) => op.id == id)) return false;
    
    _queue.add(_QueuedOperation(
      id: id,
      operation: operation,
      queuedAt: DateTime.now(),
      metadata: metadata,
    ),);
    
    return true;
  }
  
  /// Remove an operation from the queue.
  bool remove(String id) {
    final index = _queue.indexWhere((op) => op.id == id);
    if (index >= 0) {
      _queue.removeAt(index);
      return true;
    }
    return false;
  }
  
  /// Process all queued operations.
  Future<List<(String id, RetryResult<T> result)>> processAll({
    RetryConfig retryConfig = RetryConfig.network,
  }) async {
    final results = <(String, RetryResult<T>)>[];
    final processed = <String>[];
    
    for (final op in _queue) {
      final result = await withRetry(op.operation, config: retryConfig);
      results.add((op.id, result));
      
      if (result.isSuccess) {
        processed.add(op.id);
      }
    }
    
    // Remove successfully processed operations
    _queue.removeWhere((op) => processed.contains(op.id));
    
    return results;
  }
  
  /// Clear all queued operations.
  void clear() {
    _queue.clear();
  }
}

class _QueuedOperation<T> {
  _QueuedOperation({
    required this.id,
    required this.operation,
    required this.queuedAt,
    this.metadata,
  });
  
  final String id;
  final Future<T> Function() operation;
  final DateTime queuedAt;
  final Map<String, dynamic>? metadata;
}
