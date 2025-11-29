/// Debouncer utility for rate-limiting operations
/// 
/// Use this for search fields, auto-save, or any operation that should
/// not fire too frequently.
/// 
/// Example:
/// ```dart
/// final _searchDebouncer = Debouncer(delay: Duration(milliseconds: 300));
/// 
/// void onSearchChanged(String query) {
///   _searchDebouncer.run(() {
///     performSearch(query);
///   });
/// }
/// ```
library;

import 'dart:async';

/// Debouncer for rate-limiting function calls
class Debouncer {

  /// Creates a debouncer with the specified delay
  /// Default delay is 300 milliseconds
  Debouncer({this.delay = const Duration(milliseconds: 300)});
  /// Delay before executing the action
  final Duration delay;
  
  Timer? _timer;

  /// Run the action after the delay
  /// If called again before the delay, the previous call is cancelled
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Run an async action after the delay
  void runAsync(Future<void> Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, () => action());
  }

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Check if there's a pending action
  bool get isPending => _timer?.isActive ?? false;

  /// Dispose the debouncer
  void dispose() {
    cancel();
  }
}

/// Throttler for limiting the rate of function calls
/// Unlike debouncer, throttler ensures the function is called at most once per interval
class Throttler {

  /// Creates a throttler with the specified interval
  Throttler({required this.interval});
  /// Minimum interval between calls
  final Duration interval;
  
  DateTime? _lastCall;
  Timer? _pendingTimer;
  void Function()? _pendingAction;

  /// Run the action immediately if interval has passed,
  /// otherwise schedule it for later
  void run(void Function() action) {
    final now = DateTime.now();
    
    if (_lastCall == null || now.difference(_lastCall!) >= interval) {
      _lastCall = now;
      action();
    } else {
      // Schedule for later if not already scheduled
      _pendingAction = action;
      _pendingTimer ??= Timer(
        interval - now.difference(_lastCall!),
        () {
          _lastCall = DateTime.now();
          _pendingAction?.call();
          _pendingAction = null;
          _pendingTimer = null;
        },
      );
    }
  }

  /// Cancel any pending action
  void cancel() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingAction = null;
  }

  /// Dispose the throttler
  void dispose() {
    cancel();
  }
}

/// Rate limiter that queues actions and executes them with a delay between each
class RateLimiter {

  /// Creates a rate limiter with the specified delay between actions
  RateLimiter({required this.delay});
  /// Delay between each action
  final Duration delay;
  
  final List<void Function()> _queue = [];
  Timer? _timer;
  bool _isProcessing = false;

  /// Add an action to the queue
  void add(void Function() action) {
    _queue.add(action);
    _processQueue();
  }

  void _processQueue() {
    if (_isProcessing || _queue.isEmpty) return;
    
    _isProcessing = true;
    final action = _queue.removeAt(0);
    action();
    
    _timer = Timer(delay, () {
      _isProcessing = false;
      _processQueue();
    });
  }

  /// Clear all pending actions
  void clear() {
    _queue.clear();
    _timer?.cancel();
    _timer = null;
    _isProcessing = false;
  }

  /// Get the number of pending actions
  int get pendingCount => _queue.length;

  /// Dispose the rate limiter
  void dispose() {
    clear();
  }
}

/// Extension for creating debouncers on functions
extension DebouncedFunction on void Function() {
  /// Creates a debounced version of this function
  void Function() debounced([Duration delay = const Duration(milliseconds: 300)]) {
    final debouncer = Debouncer(delay: delay);
    return () => debouncer.run(this);
  }

  /// Creates a throttled version of this function
  void Function() throttled([Duration interval = const Duration(milliseconds: 300)]) {
    final throttler = Throttler(interval: interval);
    return () => throttler.run(this);
  }
}
