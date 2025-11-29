/// Application-specific exceptions
/// 
/// Use these instead of generic exceptions for better error handling
/// and more meaningful error messages.
library;

import 'package:flutter/foundation.dart';

/// Base exception for all app-specific exceptions
@immutable
sealed class AppException implements Exception {

  const AppException({
    required this.message,
    this.technicalDetails,
    this.cause,
    this.stackTrace,
  });
  /// Human-readable error message for users
  final String message;
  
  /// Technical details for logging (not shown to users)
  final String? technicalDetails;
  
  /// Original error that caused this exception
  final Object? cause;
  
  /// Stack trace of the original error
  final StackTrace? stackTrace;
  
  /// User-friendly message to display
  String get userMessage => message;
  
  /// Get the full error details for logging
  String get logDetails {
    final buffer = StringBuffer()
      ..writeln('[$runtimeType] $message');
    if (technicalDetails != null) {
      buffer.writeln('Details: $technicalDetails');
    }
    if (cause != null) {
      buffer.writeln('Cause: $cause');
    }
    return buffer.toString();
  }

  @override
  String toString() => '[$runtimeType] $message';
}

/// Database-related exceptions
final class DatabaseException extends AppException {

  const DatabaseException(
    String message, {
    this.operation,
    this.table,
    super.technicalDetails,
    super.cause,
    super.stackTrace,
  }) : super(
          message: message,
        );

  factory DatabaseException.insertFailed(String table, [Object? cause, StackTrace? stackTrace]) {
    return DatabaseException(
      'Failed to save data',
      operation: 'insert',
      table: table,
      technicalDetails: 'Insert into $table failed',
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory DatabaseException.updateFailed(String table, [Object? cause, StackTrace? stackTrace]) {
    return DatabaseException(
      'Failed to update data',
      operation: 'update',
      table: table,
      technicalDetails: 'Update on $table failed',
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory DatabaseException.deleteFailed(String table, [Object? cause, StackTrace? stackTrace]) {
    return DatabaseException(
      'Failed to delete data',
      operation: 'delete',
      table: table,
      technicalDetails: 'Delete from $table failed',
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory DatabaseException.notFound(String table, dynamic id) {
    return DatabaseException(
      'Record not found',
      operation: 'query',
      table: table,
      technicalDetails: 'Record with id $id not found in $table',
    );
  }

  factory DatabaseException.queryFailed(String table, [Object? cause, StackTrace? stackTrace]) {
    return DatabaseException(
      'Failed to load data',
      operation: 'query',
      table: table,
      technicalDetails: 'Query on $table failed',
      cause: cause,
      stackTrace: stackTrace,
    );
  }
  /// The operation that failed (e.g., 'insert', 'update', 'delete', 'query')
  final String? operation;
  
  /// The table involved, if any
  final String? table;
}

/// Validation-related exceptions
final class ValidationException extends AppException {

  const ValidationException(
    String message, {
    this.field,
    this.rule,
    super.technicalDetails,
  }) : super(
          message: message,
        );

  factory ValidationException.required(String field) {
    return ValidationException(
      '$field is required',
      field: field,
      rule: 'required',
    );
  }

  factory ValidationException.invalidFormat(String field, String expectedFormat) {
    return ValidationException(
      'Invalid $field format',
      field: field,
      rule: 'format',
      technicalDetails: 'Expected format: $expectedFormat',
    );
  }

  factory ValidationException.tooShort(String field, int minLength) {
    return ValidationException(
      '$field must be at least $minLength characters',
      field: field,
      rule: 'minLength',
    );
  }

  factory ValidationException.tooLong(String field, int maxLength) {
    return ValidationException(
      '$field must be at most $maxLength characters',
      field: field,
      rule: 'maxLength',
    );
  }

  factory ValidationException.outOfRange(String field, num min, num max) {
    return ValidationException(
      '$field must be between $min and $max',
      field: field,
      rule: 'range',
    );
  }

  factory ValidationException.invalidDate(String field) {
    return ValidationException(
      'Invalid date for $field',
      field: field,
      rule: 'date',
    );
  }
  /// The field that failed validation
  final String? field;
  
  /// The validation rule that failed
  final String? rule;
}

/// Network-related exceptions
final class NetworkException extends AppException {

  const NetworkException(
    String message, {
    this.statusCode,
    this.url,
    super.technicalDetails,
    super.cause,
    super.stackTrace,
  }) : super(
          message: message,
        );

  factory NetworkException.noConnection() {
    return const NetworkException(
      'No internet connection',
      technicalDetails: 'Network unavailable',
    );
  }

  factory NetworkException.timeout(String? url) {
    return NetworkException(
      'Connection timed out',
      url: url,
      technicalDetails: 'Request to $url timed out',
    );
  }

  factory NetworkException.serverError(int statusCode, String? url) {
    return NetworkException(
      'Server error occurred',
      statusCode: statusCode,
      url: url,
      technicalDetails: 'Server returned $statusCode for $url',
    );
  }

  factory NetworkException.unauthorized() {
    return const NetworkException(
      'Session expired. Please sign in again.',
      statusCode: 401,
    );
  }

  factory NetworkException.forbidden() {
    return const NetworkException(
      "You don't have permission to access this",
      statusCode: 403,
    );
  }
  /// HTTP status code if applicable
  final int? statusCode;
  
  /// The URL that was being accessed
  final String? url;
}

/// File-related exceptions
final class FileException extends AppException {

  const FileException(
    String message, {
    this.path,
    this.operation,
    super.technicalDetails,
    super.cause,
    super.stackTrace,
  }) : super(
          message: message,
        );

  factory FileException.notFound(String path) {
    return FileException(
      'File not found',
      path: path,
      operation: 'read',
      technicalDetails: 'File at $path does not exist',
    );
  }

  factory FileException.readFailed(String path, [Object? cause, StackTrace? stackTrace]) {
    return FileException(
      'Failed to read file',
      path: path,
      operation: 'read',
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory FileException.writeFailed(String path, [Object? cause, StackTrace? stackTrace]) {
    return FileException(
      'Failed to save file',
      path: path,
      operation: 'write',
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  factory FileException.permissionDenied(String path) {
    return FileException(
      'Permission denied',
      path: path,
      technicalDetails: 'No permission to access $path',
    );
  }
  /// The file path involved
  final String? path;
  
  /// The file operation that failed
  final String? operation;
}

/// Business logic related exceptions
final class BusinessException extends AppException {

  const BusinessException(
    String message, {
    this.code,
    super.technicalDetails,
    super.cause,
    super.stackTrace,
  }) : super(
          message: message,
        );

  factory BusinessException.appointmentConflict(DateTime dateTime) {
    return BusinessException(
      'There is already an appointment at this time',
      code: 'APPOINTMENT_CONFLICT',
      technicalDetails: 'Conflicting appointment at $dateTime',
    );
  }

  factory BusinessException.patientHasRecords() {
    return const BusinessException(
      'Cannot delete patient with existing records',
      code: 'PATIENT_HAS_RECORDS',
    );
  }

  factory BusinessException.invalidOperation(String reason) {
    return BusinessException(
      reason,
      code: 'INVALID_OPERATION',
    );
  }
  /// Error code for programmatic handling
  final String? code;
}

/// Authentication related exceptions
final class AuthException extends AppException {
  const AuthException(
    String message, {
    super.technicalDetails,
    super.cause,
    super.stackTrace,
  }) : super(
          message: message,
        );

  factory AuthException.notAuthenticated() {
    return const AuthException('Please sign in to continue');
  }

  factory AuthException.invalidCredentials() {
    return const AuthException('Invalid email or password');
  }

  factory AuthException.sessionExpired() {
    return const AuthException('Your session has expired. Please sign in again.');
  }

  factory AuthException.biometricFailed() {
    return const AuthException('Biometric authentication failed');
  }
}
