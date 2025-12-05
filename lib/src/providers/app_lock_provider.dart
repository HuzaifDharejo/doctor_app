/// App Lock Provider
/// 
/// Provides app lock service through Riverpod for state management
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_lock_service.dart';

/// Provider for AppLockService
final appLockServiceProvider = ChangeNotifierProvider<AppLockService>((ref) {
  final service = AppLockService();
  service.initialize();
  return service;
});

/// Provider to check if app is currently locked
final isAppLockedProvider = Provider<bool>((ref) {
  final service = ref.watch(appLockServiceProvider);
  return service.isLocked;
});

/// Provider to check if app lock is enabled
final isAppLockEnabledProvider = Provider<bool>((ref) {
  final service = ref.watch(appLockServiceProvider);
  return service.settings.isEnabled;
});
