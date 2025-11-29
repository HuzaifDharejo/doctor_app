import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logger_service.dart';

/// Backup metadata for tracking and verification
class BackupMetadata {
  BackupMetadata({
    required this.createdAt,
    required this.appVersion,
    required this.dbVersion,
    required this.sizeBytes,
    this.description,
    this.isAutoBackup = false,
  });

  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      createdAt: DateTime.parse(json['createdAt'] as String),
      appVersion: json['appVersion'] as String,
      dbVersion: json['dbVersion'] as int,
      sizeBytes: json['sizeBytes'] as int,
      description: json['description'] as String?,
      isAutoBackup: json['isAutoBackup'] as bool? ?? false,
    );
  }

  final DateTime createdAt;
  final String appVersion;
  final int dbVersion;
  final int sizeBytes;
  final String? description;
  final bool isAutoBackup;

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'appVersion': appVersion,
    'dbVersion': dbVersion,
    'sizeBytes': sizeBytes,
    'description': description,
    'isAutoBackup': isAutoBackup,
  };
}

/// Backup info with file and metadata
class BackupInfo {
  BackupInfo({
    required this.file,
    required this.metadata,
  });

  final File file;
  final BackupMetadata metadata;

  String get fileName => p.basename(file.path);
  String get formattedDate {
    final d = metadata.createdAt;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
           '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  String get formattedSize {
    if (metadata.sizeBytes < 1024) return '${metadata.sizeBytes} B';
    if (metadata.sizeBytes < 1024 * 1024) return '${(metadata.sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(metadata.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Result of a backup verification
class BackupVerificationResult {
  const BackupVerificationResult.valid() : isValid = true, errorMessage = null;
  const BackupVerificationResult.invalid(this.errorMessage) : isValid = false;

  final bool isValid;
  final String? errorMessage;
}

/// Enhanced backup service with auto-scheduling and integrity verification
class BackupService {
  static const String _tag = 'Backup';
  static const String _prefsKeyLastBackup = 'last_backup_date';
  static const String _prefsKeyAutoBackup = 'auto_backup_enabled';
  static const String _prefsKeyBackupFrequency = 'backup_frequency_days';
  static const String _backupExtension = '.sqlite';
  static const String _metadataExtension = '.meta.json';
  static const int _maxBackupsToKeep = 10;
  static const String _appVersion = '0.1.0';
  static const int _dbVersion = 1;

  /// Get the backup directory
  Future<Directory> getBackupDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docs.path, 'backups'));
    // ignore: avoid_slow_async_io
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Export database with metadata
  Future<BackupInfo> exportDatabase(
    File dbFile, {
    String? description,
    bool isAutoBackup = false,
  }) async {
    log.i(_tag, 'Starting database export');
    
    final backupDir = await getBackupDirectory();
    final timestamp = DateTime.now();
    final fileName = 'backup-${_formatTimestamp(timestamp)}$_backupExtension';
    final backupFile = File(p.join(backupDir.path, fileName));
    
    // Copy database file
    await dbFile.copy(backupFile.path);
    
    // Create metadata
    final metadata = BackupMetadata(
      createdAt: timestamp,
      appVersion: _appVersion,
      dbVersion: _dbVersion,
      sizeBytes: await backupFile.length(),
      description: description,
      isAutoBackup: isAutoBackup,
    );
    
    // Save metadata
    final metadataFile = File('${backupFile.path}$_metadataExtension');
    await metadataFile.writeAsString(jsonEncode(metadata.toJson()));
    
    // Update last backup date
    await _updateLastBackupDate(timestamp);
    
    // Clean up old backups
    await _cleanupOldBackups();
    
    log.i(_tag, 'Database exported: ${backupFile.path}');
    
    return BackupInfo(file: backupFile, metadata: metadata);
  }

  /// Import database with verification
  Future<void> importDatabase(File incoming) async {
    log.i(_tag, 'Starting database import');
    
    // Verify backup integrity
    final verification = await verifyBackup(incoming);
    if (!verification.isValid) {
      throw Exception('Invalid backup: ${verification.errorMessage}');
    }
    
    final docs = await getApplicationDocumentsDirectory();
    final dest = File(p.join(docs.path, 'doctor_app.sqlite'));
    
    // Create backup of current database before replacing
    // ignore: avoid_slow_async_io
    if (await dest.exists()) {
      await exportDatabase(dest, description: 'Pre-import backup', isAutoBackup: true);
      await dest.delete();
    }
    
    await incoming.copy(dest.path);
    
    log.i(_tag, 'Database imported successfully');
  }

  /// Verify backup integrity
  Future<BackupVerificationResult> verifyBackup(File backupFile) async {
    log.d(_tag, 'Verifying backup: ${backupFile.path}');
    
    // ignore: avoid_slow_async_io
    if (!await backupFile.exists()) {
      return const BackupVerificationResult.invalid('Backup file does not exist');
    }
    
    // Check file size
    final size = await backupFile.length();
    if (size == 0) {
      return const BackupVerificationResult.invalid('Backup file is empty');
    }
    
    // Verify SQLite header
    try {
      final bytes = await backupFile.openRead(0, 16).expand((b) => b).toList();
      final header = String.fromCharCodes(bytes.take(6));
      if (header != 'SQLite') {
        return const BackupVerificationResult.invalid('Not a valid SQLite database');
      }
    } catch (e) {
      return BackupVerificationResult.invalid('Could not read backup file: $e');
    }
    
    return const BackupVerificationResult.valid();
  }

  /// List all available backups
  Future<List<BackupInfo>> listBackups() async {
    final backupDir = await getBackupDirectory();
    final backups = <BackupInfo>[];
    
    // ignore: avoid_slow_async_io
    if (!await backupDir.exists()) {
      return backups;
    }
    
    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith(_backupExtension))
        .toList();
    
    for (final file in files) {
      final metadataFile = File('${file.path}$_metadataExtension');
      BackupMetadata metadata;
      
      // ignore: avoid_slow_async_io
      if (await metadataFile.exists()) {
        try {
          final json = jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>;
          metadata = BackupMetadata.fromJson(json);
        } catch (e) {
          // Create metadata from file info
          metadata = BackupMetadata(
            createdAt: file.lastModifiedSync(),
            appVersion: 'unknown',
            dbVersion: 0,
            sizeBytes: file.lengthSync(),
          );
        }
      } else {
        metadata = BackupMetadata(
          createdAt: file.lastModifiedSync(),
          appVersion: 'unknown',
          dbVersion: 0,
          sizeBytes: file.lengthSync(),
        );
      }
      
      backups.add(BackupInfo(file: file, metadata: metadata));
    }
    
    // Sort by date, newest first
    backups.sort((a, b) => b.metadata.createdAt.compareTo(a.metadata.createdAt));
    
    return backups;
  }

  /// Delete a specific backup
  Future<void> deleteBackup(BackupInfo backup) async {
    log.i(_tag, 'Deleting backup: ${backup.fileName}');
    
    await backup.file.delete();
    
    final metadataFile = File('${backup.file.path}$_metadataExtension');
    // ignore: avoid_slow_async_io
    if (await metadataFile.exists()) {
      await metadataFile.delete();
    }
  }

  /// Check if auto backup should run
  Future<bool> shouldRunAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    
    final autoEnabled = prefs.getBool(_prefsKeyAutoBackup) ?? true;
    if (!autoEnabled) return false;
    
    final lastBackupStr = prefs.getString(_prefsKeyLastBackup);
    if (lastBackupStr == null) return true;
    
    final lastBackup = DateTime.parse(lastBackupStr);
    final frequencyDays = prefs.getInt(_prefsKeyBackupFrequency) ?? 7;
    final nextBackupDue = lastBackup.add(Duration(days: frequencyDays));
    
    return DateTime.now().isAfter(nextBackupDue);
  }

  /// Run auto backup if needed
  Future<BackupInfo?> runAutoBackupIfNeeded(File dbFile) async {
    if (!await shouldRunAutoBackup()) {
      return null;
    }
    
    log.i(_tag, 'Running scheduled auto backup');
    return exportDatabase(dbFile, description: 'Scheduled backup', isAutoBackup: true);
  }

  /// Get last backup date
  Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_prefsKeyLastBackup);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  /// Set auto backup enabled
  // ignore: avoid_positional_boolean_parameters
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyAutoBackup, enabled);
    log.i(_tag, 'Auto backup ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Get auto backup enabled
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyAutoBackup) ?? true;
  }

  /// Set backup frequency in days
  Future<void> setBackupFrequency(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyBackupFrequency, days);
    log.i(_tag, 'Backup frequency set to $days days');
  }

  /// Get backup frequency in days
  Future<int> getBackupFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKeyBackupFrequency) ?? 7;
  }

  /// Get backup directory size
  Future<int> getBackupDirectorySize() async {
    final backupDir = await getBackupDirectory();
    var totalSize = 0;
    
    await for (final entity in backupDir.list()) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    
    return totalSize;
  }

  // Private helpers
  
  String _formatTimestamp(DateTime dt) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}'
           '-${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}'
           '${dt.second.toString().padLeft(2, '0')}';
  }
  
  Future<void> _updateLastBackupDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyLastBackup, date.toIso8601String());
  }
  
  Future<void> _cleanupOldBackups() async {
    final backups = await listBackups();
    
    // Keep only auto-backups for cleanup consideration
    final autoBackups = backups.where((b) => b.metadata.isAutoBackup).toList();
    
    if (autoBackups.length > _maxBackupsToKeep) {
      log.i(_tag, 'Cleaning up old auto backups');
      
      for (var i = _maxBackupsToKeep; i < autoBackups.length; i++) {
        await deleteBackup(autoBackups[i]);
      }
    }
  }
}
