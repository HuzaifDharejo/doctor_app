import 'dart:async';

import 'package:doctor_app/src/core/utils/connectivity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RetryConfig', () {
    test('default values are correct', () {
      const config = RetryConfig.network;
      
      expect(config.maxAttempts, 3);
      expect(config.initialDelay, const Duration(seconds: 1));
      expect(config.maxDelay, const Duration(seconds: 30));
      expect(config.backoffMultiplier, 2.0);
    });
    
    test('delayForAttempt returns zero for first attempt', () {
      const config = RetryConfig.network;
      
      expect(config.delayForAttempt(0), Duration.zero);
    });
    
    test('delayForAttempt increases with each attempt', () {
      const config = RetryConfig.network;
      
      final delay1 = config.delayForAttempt(1);
      final delay2 = config.delayForAttempt(2);
      final delay3 = config.delayForAttempt(3);
      
      expect(delay1.inSeconds, 1);
      expect(delay2.inSeconds, greaterThan(delay1.inSeconds));
      expect(delay3.inSeconds, greaterThan(delay2.inSeconds));
    });
    
    test('delayForAttempt respects maxDelay', () {
      const config = RetryConfig(
        initialDelay: Duration(seconds: 10),
        maxDelay: Duration(seconds: 5),
        backoffMultiplier: 10,
      );
      
      final delay = config.delayForAttempt(5);
      
      expect(delay.inSeconds, lessThanOrEqualTo(5));
    });
    
    test('network preset has default values', () {
      expect(RetryConfig.network.maxAttempts, 3);
    });
    
    test('critical preset has more attempts', () {
      expect(RetryConfig.critical.maxAttempts, 5);
    });
  });
  
  group('RetryResult', () {
    test('success result has correct properties', () {
      const result = RetryResult<int>.success(
        42,
        attempts: 1,
        totalDuration: Duration(milliseconds: 100),
      );
      
      expect(result.isSuccess, isTrue);
      expect(result.value, 42);
      expect(result.error, isNull);
      expect(result.attempts, 1);
    });
    
    test('failure result has correct properties', () {
      final result = RetryResult<int>.failure(
        Exception('test error'),
        attempts: 3,
        totalDuration: const Duration(seconds: 5),
      );
      
      expect(result.isSuccess, isFalse);
      expect(result.value, isNull);
      expect(result.error, isNotNull);
      expect(result.attempts, 3);
    });
    
    test('getOrThrow returns value on success', () {
      const result = RetryResult<int>.success(
        42,
        attempts: 1,
        totalDuration: Duration.zero,
      );
      
      expect(result.getOrThrow(), 42);
    });
    
    test('getOrThrow throws on failure', () {
      final result = RetryResult<int>.failure(
        Exception('test'),
        attempts: 1,
        totalDuration: Duration.zero,
      );
      
      expect(result.getOrThrow, throwsException);
    });
    
    test('getOrDefault returns value on success', () {
      const result = RetryResult<int>.success(
        42,
        attempts: 1,
        totalDuration: Duration.zero,
      );
      
      expect(result.getOrDefault(0), 42);
    });
    
    test('getOrDefault returns default on failure', () {
      final result = RetryResult<int>.failure(
        Exception('test'),
        attempts: 1,
        totalDuration: Duration.zero,
      );
      
      expect(result.getOrDefault(99), 99);
    });
  });
  
  group('withRetry', () {
    test('returns success on first try', () async {
      var callCount = 0;
      
      final result = await withRetry<int>(
        () async {
          callCount++;
          return 42;
        },
      );
      
      expect(result.isSuccess, isTrue);
      expect(result.value, 42);
      expect(result.attempts, 1);
      expect(callCount, 1);
    });
    
    test('retries on failure and succeeds', () async {
      var callCount = 0;
      
      final result = await withRetry<int>(
        () async {
          callCount++;
          if (callCount < 3) {
            throw TimeoutException('test');
          }
          return 42;
        },
        config: const RetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 10),
        ),
      );
      
      expect(result.isSuccess, isTrue);
      expect(result.value, 42);
      expect(result.attempts, 3);
      expect(callCount, 3);
    });
    
    test('fails after max attempts', () async {
      var callCount = 0;
      
      final result = await withRetry<int>(
        () async {
          callCount++;
          throw TimeoutException('always fail');
        },
        config: const RetryConfig(
          initialDelay: Duration(milliseconds: 10),
        ),
      );
      
      expect(result.isSuccess, isFalse);
      expect(result.attempts, 3);
      expect(callCount, 3);
    });
    
    test('does not retry non-retryable errors', () async {
      var callCount = 0;
      
      final result = await withRetry<int>(
        () async {
          callCount++;
          throw ArgumentError('not retryable');
        },
        config: const RetryConfig(
          retryableErrors: [TimeoutException],
        ),
      );
      
      expect(result.isSuccess, isFalse);
      expect(result.attempts, 1);
      expect(callCount, 1);
    });
    
    test('calls onRetry callback', () async {
      final retryAttempts = <int>[];
      
      await withRetry<int>(
        () async {
          if (retryAttempts.length < 2) {
            throw TimeoutException('retry me');
          }
          return 42;
        },
        config: const RetryConfig(
          maxAttempts: 5,
          initialDelay: Duration(milliseconds: 10),
        ),
        onRetry: (attempt, error, delay) {
          retryAttempts.add(attempt);
        },
      );
      
      expect(retryAttempts, [1, 2]);
    });
    
    test('respects custom shouldRetry function', () async {
      var callCount = 0;
      
      final result = await withRetry<int>(
        () async {
          callCount++;
          throw Exception('should retry');
        },
        config: const RetryConfig(
          initialDelay: Duration(milliseconds: 10),
        ),
        shouldRetry: (error) => true,
      );
      
      expect(result.isSuccess, isFalse);
      expect(callCount, 3);
    });
  });
  
  group('OfflineQueue', () {
    test('starts empty', () {
      final queue = OfflineQueue<int>();
      
      expect(queue.isEmpty, isTrue);
      expect(queue.length, 0);
    });
    
    test('enqueue adds operation', () {
      final queue = OfflineQueue<int>();
      
      final added = queue.enqueue(
        operation: () async => 42,
        id: 'op1',
      );
      
      expect(added, isTrue);
      expect(queue.length, 1);
      expect(queue.isEmpty, isFalse);
    });
    
    test('enqueue rejects duplicates', () {
      final queue = OfflineQueue<int>();
      
      queue.enqueue(operation: () async => 1, id: 'op1');
      final added = queue.enqueue(operation: () async => 2, id: 'op1');
      
      expect(added, isFalse);
      expect(queue.length, 1);
    });
    
    test('enqueue rejects when full', () {
      final queue = OfflineQueue<int>(maxQueueSize: 2);
      
      queue.enqueue(operation: () async => 1, id: 'op1');
      queue.enqueue(operation: () async => 2, id: 'op2');
      final added = queue.enqueue(operation: () async => 3, id: 'op3');
      
      expect(added, isFalse);
      expect(queue.length, 2);
      expect(queue.isFull, isTrue);
    });
    
    test('remove deletes operation', () {
      final queue = OfflineQueue<int>();
      
      queue.enqueue(operation: () async => 1, id: 'op1');
      queue.enqueue(operation: () async => 2, id: 'op2');
      
      final removed = queue.remove('op1');
      
      expect(removed, isTrue);
      expect(queue.length, 1);
    });
    
    test('remove returns false for non-existent id', () {
      final queue = OfflineQueue<int>();
      
      queue.enqueue(operation: () async => 1, id: 'op1');
      
      final removed = queue.remove('op999');
      
      expect(removed, isFalse);
    });
    
    test('processAll executes operations', () async {
      final queue = OfflineQueue<int>();
      var sum = 0;
      
      queue.enqueue(
        operation: () async {
          sum += 1;
          return 1;
        },
        id: 'op1',
      );
      queue.enqueue(
        operation: () async {
          sum += 2;
          return 2;
        },
        id: 'op2',
      );
      
      final results = await queue.processAll();
      
      expect(results.length, 2);
      expect(sum, 3);
      expect(queue.isEmpty, isTrue); // Successful ops are removed
    });
    
    test('processAll keeps failed operations in queue', () async {
      final queue = OfflineQueue<int>();
      
      queue.enqueue(
        operation: () async => 1,
        id: 'success',
      );
      queue.enqueue(
        operation: () async => throw Exception('fail'),
        id: 'fail',
      );
      
      final results = await queue.processAll(
        retryConfig: const RetryConfig(
          maxAttempts: 1,
          initialDelay: Duration.zero,
        ),
      );
      
      expect(results.length, 2);
      expect(queue.length, 1); // Failed operation remains
    });
    
    test('clear removes all operations', () {
      final queue = OfflineQueue<int>();
      
      queue.enqueue(operation: () async => 1, id: 'op1');
      queue.enqueue(operation: () async => 2, id: 'op2');
      
      queue.clear();
      
      expect(queue.isEmpty, isTrue);
    });
  });
  
  group('ConnectivityStatus', () {
    test('has expected values', () {
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.connected));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.offline));
      expect(ConnectivityStatus.values, contains(ConnectivityStatus.unknown));
    });
  });
}
