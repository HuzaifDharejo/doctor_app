/// Backup & Restore Settings Screen
/// 
/// Provides UI for:
/// - Creating local encrypted backups
/// - Viewing and managing existing backups
/// - Restoring from backup files
/// - Sharing backup files
/// - Google Drive cloud backup
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/db_provider.dart';
import '../../services/cloud_backup_service.dart';
import '../../services/google_drive_backup_service.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/components/app_button.dart';

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  final CloudBackupService _backupService = CloudBackupService();
  final GoogleDriveBackupService _driveService = GoogleDriveBackupService();
  List<BackupInfo> _backups = [];
  List<DriveBackupInfo> _driveBackups = [];
  bool _isLoading = false;
  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  bool _isDriveConnected = false;
  bool _isDriveLoading = false;
  bool _isDriveBackingUp = false;
  String? _driveEmail;
  DateTime? _lastDriveBackup;

  @override
  void initState() {
    super.initState();
    _loadBackups();
    _loadDriveStatus();
  }

  Future<void> _loadDriveStatus() async {
    if (kIsWeb) return;
    
    setState(() => _isDriveLoading = true);
    try {
      _isDriveConnected = await _driveService.isConnected();
      if (_isDriveConnected) {
        _driveEmail = await _driveService.getConnectedEmail();
        _lastDriveBackup = await _driveService.getLastBackupTime();
        _driveBackups = await _driveService.listBackups();
      }
    } finally {
      if (mounted) setState(() => _isDriveLoading = false);
    }
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      _backups = await _backupService.listLocalBackups();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);
    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.valueOrNull;
      if (db == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database not ready'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final result = await _backupService.createBackup(db: db, encrypt: true);
      
      if (!mounted) return;
      
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created successfully!\n${result.metadata?.patientCount ?? 0} patients backed up'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _loadBackups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _shareBackup(String filePath) async {
    final success = await _backupService.shareBackup(filePath);
    if (!mounted) return;
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share backup'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreBackup(String filePath) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will add data from the backup to your existing data. '
          'Duplicate entries may be created.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.valueOrNull;
      if (db == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database not ready'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final result = await _backupService.restoreFromFile(filePath: filePath, db: db);
      
      if (!mounted) return;
      
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restore successful!\n'
              '${result.patientsRestored} patients, '
              '${result.appointmentsRestored} appointments, '
              '${result.prescriptionsRestored} prescriptions restored',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access the selected file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _restoreBackup(file.path!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Are you sure you want to delete ${backup.fileName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _backupService.deleteBackup(backup.filePath);
    if (success) {
      _loadBackups();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: kIsWeb ? _buildWebNotSupported(theme, colors) : SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: colors.primaryContainer.withAlpha(50),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.primary),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Backups are encrypted and stored locally. '
                        'Share them to save to cloud storage.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Create Backup Section
            Text(
              'Create Backup',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create an encrypted backup of all your data including patients, '
                      'appointments, prescriptions, and medical records.',
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: _isCreatingBackup ? 'Creating Backup...' : 'Create Backup',
                        icon: Icons.backup,
                        onPressed: _isCreatingBackup ? null : _createBackup,
                        isLoading: _isCreatingBackup,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Import Backup Section
            Text(
              'Import Backup',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import a backup file from your device or cloud storage.',
                      style: theme.textTheme.bodySmall,
                    ),
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: _isRestoring ? 'Restoring...' : 'Import Backup File',
                        icon: Icons.file_upload,
                        variant: AppButtonVariant.secondary,
                        onPressed: _isRestoring ? null : _importBackup,
                        isLoading: _isRestoring,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Local Backups Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local Backups',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_backups.isNotEmpty)
                  Text(
                    '${_backups.length} backup(s)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.outline,
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_backups.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: colors.outline,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'No local backups found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.outline,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Create a backup to get started',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _backups.length,
                itemBuilder: (context, index) {
                  final backup = _backups[index];
                  return _BackupTile(
                    backup: backup,
                    backupService: _backupService,
                    onShare: () => _shareBackup(backup.filePath),
                    onRestore: () => _restoreBackup(backup.filePath),
                    onDelete: () => _deleteBackup(backup),
                    isRestoring: _isRestoring,
                  );
                },
              ),
            
            SizedBox(height: AppSpacing.xl),
            
            // Google Drive Section
            _buildGoogleDriveSection(theme, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleDriveSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_to_drive, color: colors.primary),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Google Drive Backup',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        
        Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isDriveLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (!_isDriveConnected)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect your Google account to backup your data to Google Drive for secure cloud storage.',
                        style: theme.textTheme.bodySmall,
                      ),
                      SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Connect Google Drive',
                          icon: Icons.login,
                          onPressed: _connectGoogleDrive,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colors.primaryContainer,
                            child: Icon(Icons.check, color: colors.primary),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connected',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                if (_driveEmail != null)
                                  Text(
                                    _driveEmail!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.outline,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _disconnectGoogleDrive,
                            child: const Text('Disconnect'),
                          ),
                        ],
                      ),
                      if (_lastDriveBackup != null) ...[
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Last backup: ${_formatDate(_lastDriveBackup!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.outline,
                          ),
                        ),
                      ],
                      SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: _isDriveBackingUp ? 'Backing up...' : 'Backup Now',
                              icon: Icons.cloud_upload,
                              onPressed: _isDriveBackingUp ? null : _backupToGoogleDrive,
                              isLoading: _isDriveBackingUp,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadDriveStatus,
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        
        // Google Drive Backups List
        if (_isDriveConnected && _driveBackups.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Text(
            'Cloud Backups (${_driveBackups.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _driveBackups.length,
            itemBuilder: (context, index) {
              final backup = _driveBackups[index];
              return _DriveBackupTile(
                backup: backup,
                onRestore: () => _restoreFromDrive(backup),
                onDelete: () => _deleteFromDrive(backup),
                isRestoring: _isRestoring,
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _connectGoogleDrive() async {
    final success = await _driveService.signIn();
    if (success) {
      await _loadDriveStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to Google Drive'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to Google Drive'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnectGoogleDrive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Google Drive'),
        content: const Text(
          'This will disconnect your Google account. '
          'Your cloud backups will remain in Google Drive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _driveService.signOut();
    setState(() {
      _isDriveConnected = false;
      _driveEmail = null;
      _driveBackups = [];
    });
  }

  Future<void> _backupToGoogleDrive() async {
    setState(() => _isDriveBackingUp = true);
    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.valueOrNull;
      if (db == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database not ready'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await _driveService.createBackup(db);

      if (!mounted) return;

      if (result.success) {
        await _loadDriveStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup uploaded: ${result.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDriveBackingUp = false);
    }
  }

  Future<void> _restoreFromDrive(DriveBackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Cloud'),
        content: Text(
          'This will restore data from "${backup.fileName}".\n\n'
          'This will add data from the backup to your existing data. '
          'Duplicate entries may be created.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);
    try {
      final dbAsync = ref.read(doctorDbProvider);
      final db = dbAsync.valueOrNull;
      if (db == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database not ready'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await _driveService.restoreBackup(
        fileId: backup.fileId,
        db: db,
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restore successful!\n'
              '${result.patientsRestored} patients, '
              '${result.appointmentsRestored} appointments restored',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _deleteFromDrive(DriveBackupInfo backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cloud Backup'),
        content: Text('Are you sure you want to delete "${backup.fileName}" from Google Drive?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _driveService.deleteBackup(backup.fileId);
    if (success) {
      await _loadDriveStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup deleted from Google Drive'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildWebNotSupported(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: colors.outline,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Backup Not Available on Web',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'File system backup and restore functionality is not supported in the web browser.\n\n'
              'Please use the native app on Android, iOS, Windows, or macOS to create and restore backups.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.outline,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            Icon(
              Icons.phone_android,
              size: 32,
              color: colors.primary,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Use the mobile or desktop app for full backup support',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupTile extends StatelessWidget {
  final BackupInfo backup;
  final CloudBackupService backupService;
  final VoidCallback onShare;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final bool isRestoring;

  const _BackupTile({
    required this.backup,
    required this.backupService,
    required this.onShare,
    required this.onRestore,
    required this.onDelete,
    required this.isRestoring,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            Icons.backup,
            color: colors.primary,
          ),
        ),
        title: Text(
          backup.fileName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatDate(backup.createdAt)} • ${backupService.formatFileSize(backup.size)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.outline,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'share':
                onShare();
                break;
              case 'restore':
                onRestore();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'restore',
              enabled: !isRestoring,
              child: const Row(
                children: [
                  Icon(Icons.restore),
                  SizedBox(width: 12),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _DriveBackupTile extends StatelessWidget {
  final DriveBackupInfo backup;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final bool isRestoring;

  const _DriveBackupTile({
    required this.backup,
    required this.onRestore,
    required this.onDelete,
    required this.isRestoring,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.blue.withAlpha(30),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(
            Icons.cloud_done,
            color: Colors.blue,
          ),
        ),
        title: Text(
          backup.fileName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatDate(backup.createdTime)} • ${backup.formattedSize}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.outline,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'restore':
                onRestore();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              enabled: !isRestoring,
              child: const Row(
                children: [
                  Icon(Icons.restore),
                  SizedBox(width: 12),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
