import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/doctor_db.dart';
import '../services/data_migration_service.dart';

/// Provider for the data migration service
final dataMigrationServiceProvider = Provider<DataMigrationService>((ref) {
  return DataMigrationService(DoctorDatabase.instance);
});

/// Provider to check if migration is needed
final migrationNeededProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(dataMigrationServiceProvider);
  return service.needsMigration();
});

/// Provider for migration preview
final migrationPreviewProvider = FutureProvider<MigrationPreview>((ref) async {
  final service = ref.watch(dataMigrationServiceProvider);
  return service.getPreview();
});

/// State notifier for running migration
class MigrationNotifier extends StateNotifier<MigrationState> {
  MigrationNotifier(this._service) : super(const MigrationState.initial());

  final DataMigrationService _service;

  Future<void> runMigration() async {
    state = const MigrationState.running(message: 'Starting migration...', progress: 0);
    
    try {
      final stats = await _service.runFullMigration(
        onProgress: (message, progress) {
          state = MigrationState.running(message: message, progress: progress);
        },
      );
      
      state = MigrationState.completed(stats: stats);
    } catch (e) {
      state = MigrationState.error(error: e.toString());
    }
  }

  void reset() {
    state = const MigrationState.initial();
  }
}

/// State for migration process
sealed class MigrationState {
  const MigrationState();
  
  const factory MigrationState.initial() = MigrationInitial;
  const factory MigrationState.running({
    required String message,
    required double progress,
  }) = MigrationRunning;
  const factory MigrationState.completed({
    required MigrationStats stats,
  }) = MigrationCompleted;
  const factory MigrationState.error({
    required String error,
  }) = MigrationError;
}

class MigrationInitial extends MigrationState {
  const MigrationInitial();
}

class MigrationRunning extends MigrationState {
  final String message;
  final double progress;
  
  const MigrationRunning({required this.message, required this.progress});
}

class MigrationCompleted extends MigrationState {
  final MigrationStats stats;
  
  const MigrationCompleted({required this.stats});
}

class MigrationError extends MigrationState {
  final String error;
  
  const MigrationError({required this.error});
}

/// Provider for migration notifier
final migrationNotifierProvider = 
    StateNotifierProvider<MigrationNotifier, MigrationState>((ref) {
  final service = ref.watch(dataMigrationServiceProvider);
  return MigrationNotifier(service);
});
