import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../db/doctor_db.dart';
import 'cloud_backup_service.dart';
import 'encryption_service.dart';
import 'logger_service.dart';

/// Result of a Google Drive backup operation
class DriveBackupResult {
  final bool success;
  final String? fileId;
  final String? fileName;
  final String? error;
  final DateTime? timestamp;

  DriveBackupResult({
    required this.success,
    this.fileId,
    this.fileName,
    this.error,
    this.timestamp,
  });

  factory DriveBackupResult.success({
    required String fileId,
    required String fileName,
  }) =>
      DriveBackupResult(
        success: true,
        fileId: fileId,
        fileName: fileName,
        timestamp: DateTime.now(),
      );

  factory DriveBackupResult.failure(String error) => DriveBackupResult(
        success: false,
        error: error,
      );
}

/// Information about a backup stored in Google Drive
class DriveBackupInfo {
  final String fileId;
  final String fileName;
  final DateTime createdTime;
  final DateTime? modifiedTime;
  final int? size;

  DriveBackupInfo({
    required this.fileId,
    required this.fileName,
    required this.createdTime,
    this.modifiedTime,
    this.size,
  });

  String get formattedSize {
    if (size == null) return 'Unknown';
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// HTTP client that adds Google auth headers
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
  }
}

/// Service for backing up database to Google Drive
class GoogleDriveBackupService {
  static const String _folderName = 'Doctor App Backups';
  static const String _backupMimeType = 'application/octet-stream';
  static const String _connectedKey = 'google_drive_connected';
  static const String _folderIdKey = 'google_drive_folder_id';
  static const String _lastBackupKey = 'google_drive_last_backup';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  final EncryptionService _encryptionService = EncryptionService();

  /// Check if Google Drive backup is connected
  Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_connectedKey) ?? false;
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastBackupKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Get connected user email
  Future<String?> getConnectedEmail() async {
    if (_currentUser != null) return _currentUser!.email;
    final connected = await isConnected();
    if (!connected) return null;
    
    // Try silent sign in to get user info
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser?.email;
    } catch (e) {
      return null;
    }
  }

  /// Sign in to Google Drive
  Future<bool> signIn() async {
    if (kIsWeb) {
      log.w('DRIVE', 'Google Drive backup not fully supported on web');
      return false;
    }

    try {
      // Try silent sign in first
      _currentUser = await _googleSignIn.signInSilently();
      _currentUser ??= await _googleSignIn.signIn();

      if (_currentUser == null) {
        log.w('DRIVE', 'User cancelled sign in');
        return false;
      }

      // Initialize Drive API
      final authHeaders = await _currentUser!.authHeaders;
      final authenticatedClient = _GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticatedClient);

      // Ensure backup folder exists
      await _getOrCreateBackupFolder();

      // Save connected state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_connectedKey, true);

      log.i('DRIVE', 'Connected to Google Drive: ${_currentUser!.email}');
      return true;
    } catch (e) {
      log.e('DRIVE', 'Sign in failed', error: e);
      return false;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _driveApi = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_connectedKey, false);
      await prefs.remove(_folderIdKey);

      log.i('DRIVE', 'Disconnected from Google Drive');
    } catch (e) {
      log.e('DRIVE', 'Sign out failed', error: e);
    }
  }

  /// Ensure we're connected, reconnecting if necessary
  Future<bool> _ensureConnected() async {
    if (_driveApi != null) return true;

    final connected = await isConnected();
    if (!connected) return false;

    return await signIn();
  }

  /// Get or create the backup folder in Google Drive
  Future<String?> _getOrCreateBackupFolder() async {
    if (_driveApi == null) return null;

    // Check if we have cached folder ID
    final prefs = await SharedPreferences.getInstance();
    final cachedFolderId = prefs.getString(_folderIdKey);

    if (cachedFolderId != null) {
      // Verify folder still exists
      try {
        await _driveApi!.files.get(cachedFolderId);
        return cachedFolderId;
      } catch (_) {
        // Folder doesn't exist, create new one
      }
    }

    // Search for existing folder
    try {
      final query = "name = '$_folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final fileList = await _driveApi!.files.list(q: query, spaces: 'drive');

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final folderId = fileList.files!.first.id!;
        await prefs.setString(_folderIdKey, folderId);
        return folderId;
      }
    } catch (e) {
      log.e('DRIVE', 'Error searching for folder', error: e);
    }

    // Create new folder
    try {
      final folder = drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi!.files.create(folder);
      final folderId = createdFolder.id!;
      await prefs.setString(_folderIdKey, folderId);
      
      log.i('DRIVE', 'Created backup folder: $folderId');
      return folderId;
    } catch (e) {
      log.e('DRIVE', 'Error creating folder', error: e);
      return null;
    }
  }

  /// Create a backup and upload to Google Drive
  Future<DriveBackupResult> createBackup(DoctorDatabase db) async {
    if (kIsWeb) {
      return DriveBackupResult.failure('Google Drive backup not supported on web');
    }

    if (!await _ensureConnected()) {
      return DriveBackupResult.failure('Not connected to Google Drive');
    }

    try {
      log.i('DRIVE', 'Starting Google Drive backup...');

      // Get backup folder
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) {
        return DriveBackupResult.failure('Could not create backup folder');
      }

      // Generate backup data using CloudBackupService
      final backupService = CloudBackupService();
      final backupData = await backupService.generateBackupData(db);

      // Encrypt the backup
      await _encryptionService.initialize();
      final encryptedData = _encryptionService.encrypt(jsonEncode(backupData));
      final bytes = Uint8List.fromList(utf8.encode(encryptedData));

      // Create file metadata
      final timestamp = DateTime.now();
      final fileName = 'doctor_app_backup_${timestamp.toIso8601String().replaceAll(':', '-')}.dab';

      final file = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..mimeType = _backupMimeType
        ..description = 'Doctor App encrypted backup - ${timestamp.toLocal()}';

      // Upload file
      final media = drive.Media(
        Stream.fromIterable([bytes]),
        bytes.length,
      );

      final uploadedFile = await _driveApi!.files.create(
        file,
        uploadMedia: media,
      );

      // Save last backup time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupKey, timestamp.millisecondsSinceEpoch);

      log.i('DRIVE', 'Backup uploaded successfully: ${uploadedFile.id}');

      return DriveBackupResult.success(
        fileId: uploadedFile.id!,
        fileName: fileName,
      );
    } catch (e) {
      log.e('DRIVE', 'Backup failed', error: e);
      return DriveBackupResult.failure(e.toString());
    }
  }

  /// List all backups in Google Drive
  Future<List<DriveBackupInfo>> listBackups() async {
    if (!await _ensureConnected()) {
      return [];
    }

    try {
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) return [];

      final query = "'$folderId' in parents and trashed = false";
      final fileList = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime, modifiedTime, size)',
      );

      if (fileList.files == null) return [];

      return fileList.files!
          .where((f) => f.name?.endsWith('.dab') ?? false)
          .map((f) => DriveBackupInfo(
                fileId: f.id!,
                fileName: f.name!,
                createdTime: f.createdTime ?? DateTime.now(),
                modifiedTime: f.modifiedTime,
                size: int.tryParse(f.size ?? ''),
              ))
          .toList();
    } catch (e) {
      log.e('DRIVE', 'Error listing backups', error: e);
      return [];
    }
  }

  /// Restore from a Google Drive backup
  Future<RestoreResult> restoreBackup({
    required String fileId,
    required DoctorDatabase db,
  }) async {
    if (!await _ensureConnected()) {
      return RestoreResult.failure('Not connected to Google Drive');
    }

    try {
      log.i('DRIVE', 'Downloading backup: $fileId');

      // Download file
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final encryptedContent = utf8.decode(bytes);

      // Decrypt
      await _encryptionService.initialize();
      final decryptedJson = _encryptionService.decrypt(encryptedContent);
      final backupData = jsonDecode(decryptedJson) as Map<String, dynamic>;

      // Restore using CloudBackupService
      final backupService = CloudBackupService();
      final result = await backupService.restoreFromData(
        backupData: backupData,
        db: db,
      );

      log.i('DRIVE', 'Restore completed: ${result.success}');
      return result;
    } catch (e) {
      log.e('DRIVE', 'Restore failed', error: e);
      return RestoreResult.failure(e.toString());
    }
  }

  /// Delete a backup from Google Drive
  Future<bool> deleteBackup(String fileId) async {
    if (!await _ensureConnected()) {
      return false;
    }

    try {
      await _driveApi!.files.delete(fileId);
      log.i('DRIVE', 'Deleted backup: $fileId');
      return true;
    } catch (e) {
      log.e('DRIVE', 'Error deleting backup', error: e);
      return false;
    }
  }
}
