/// Result type for functional error handling
/// 
/// Use this instead of throwing exceptions for expected failures.
/// Example:
/// ```dart
/// Result<User, AppException> getUser(int id) {
///   try {
///     return Result.success(db.getUser(id));
///   } catch (e) {
///     return Result.failure(DatabaseException('Failed to get user'));
///   }
/// }
/// ```
library;

import 'package:flutter/foundation.dart';

/// A Result type that represents either a success value or a failure
/// 
/// - [T] is the success type
/// - [E] is the error type (should extend Exception or be a custom error type)
@immutable
sealed class Result<T, E> {
  const Result._();
  
  /// Creates a successful result with the given value
  const factory Result.success(T value) = Success<T, E>;
  
  /// Creates a failed result with the given error
  const factory Result.failure(E error) = Failure<T, E>;
  
  /// Returns true if this is a success result
  bool get isSuccess;
  
  /// Returns true if this is a failure result
  bool get isFailure;
  
  /// Returns the success value or null if this is a failure
  T? get valueOrNull;
  
  /// Returns the error or null if this is a success
  E? get errorOrNull;
  
  /// Returns the success value or throws if this is a failure
  T get valueOrThrow;
  
  /// Pattern matching on Result
  /// 
  /// Example:
  /// ```dart
  /// result.when(
  ///   success: (value) => print('Got: $value'),
  ///   failure: (error) => print('Error: $error'),
  /// );
  /// ```
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  });
  
  /// Maps the success value to a new value
  Result<R, E> map<R>(R Function(T value) mapper);
  
  /// Maps the error to a new error type
  Result<T, R> mapError<R>(R Function(E error) mapper);
  
  /// Flat maps the success value to a new Result
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) mapper);
  
  /// Returns the value or a default
  T getOrElse(T Function() defaultValue);
  
  /// Returns the value or the result of orElse function
  T getOrHandle(T Function(E error) orElse);
  
  /// Executes side effect on success
  Result<T, E> onSuccess(void Function(T value) action);
  
  /// Executes side effect on failure
  Result<T, E> onFailure(void Function(E error) action);
}

/// Represents a successful result
@immutable
final class Success<T, E> extends Result<T, E> {
  /// The success value
  final T value;
  
  const Success(this.value) : super._();
  
  @override
  bool get isSuccess => true;
  
  @override
  bool get isFailure => false;
  
  @override
  T? get valueOrNull => value;
  
  @override
  E? get errorOrNull => null;
  
  @override
  T get valueOrThrow => value;
  
  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) => success(value);
  
  @override
  Result<R, E> map<R>(R Function(T value) mapper) => Result.success(mapper(value));
  
  @override
  Result<T, R> mapError<R>(R Function(E error) mapper) => Result.success(value);
  
  @override
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) mapper) => mapper(value);
  
  @override
  T getOrElse(T Function() defaultValue) => value;
  
  @override
  T getOrHandle(T Function(E error) orElse) => value;
  
  @override
  Result<T, E> onSuccess(void Function(T value) action) {
    action(value);
    return this;
  }
  
  @override
  Result<T, E> onFailure(void Function(E error) action) => this;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> && runtimeType == other.runtimeType && value == other.value;
  
  @override
  int get hashCode => value.hashCode;
  
  @override
  String toString() => 'Success($value)';
}

/// Represents a failed result
@immutable
final class Failure<T, E> extends Result<T, E> {
  /// The error value
  final E error;
  
  const Failure(this.error) : super._();
  
  @override
  bool get isSuccess => false;
  
  @override
  bool get isFailure => true;
  
  @override
  T? get valueOrNull => null;
  
  @override
  E? get errorOrNull => error;
  
  @override
  T get valueOrThrow => throw error is Exception ? error as Exception : Exception(error.toString());
  
  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) => failure(error);
  
  @override
  Result<R, E> map<R>(R Function(T value) mapper) => Result.failure(error);
  
  @override
  Result<T, R> mapError<R>(R Function(E error) mapper) => Result.failure(mapper(error));
  
  @override
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) mapper) => Result.failure(error);
  
  @override
  T getOrElse(T Function() defaultValue) => defaultValue();
  
  @override
  T getOrHandle(T Function(E error) orElse) => orElse(error);
  
  @override
  Result<T, E> onSuccess(void Function(T value) action) => this;
  
  @override
  Result<T, E> onFailure(void Function(E error) action) {
    action(error);
    return this;
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, E> && runtimeType == other.runtimeType && error == other.error;
  
  @override
  int get hashCode => error.hashCode;
  
  @override
  String toString() => 'Failure($error)';
}

/// Extension to convert Future<T> to Future<Result<T, E>>
extension FutureResultExtension<T> on Future<T> {
  /// Wraps the future in a Result, catching exceptions
  Future<Result<T, Exception>> toResult() async {
    try {
      return Result.success(await this);
    } catch (e) {
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }
  
  /// Wraps the future in a Result with a custom error mapper
  Future<Result<T, E>> toResultWith<E>(E Function(Object error) errorMapper) async {
    try {
      return Result.success(await this);
    } catch (e) {
      return Result.failure(errorMapper(e));
    }
  }
}

/// Extension for Result of Future
extension ResultFutureExtension<T, E> on Result<Future<T>, E> {
  /// Awaits the inner future if success
  Future<Result<T, E>> unwrap() async {
    return when(
      success: (future) async => Result.success(await future),
      failure: (error) async => Result.failure(error),
    );
  }
}

/// Unit type for operations that don't return a value
class Unit {
  const Unit._();
  static const Unit value = Unit._();
  
  @override
  String toString() => '()';
}

/// Type alias for Result<Unit, E> - operations that can fail but don't return a value
typedef VoidResult<E> = Result<Unit, E>;
