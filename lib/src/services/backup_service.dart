import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupService {
  Future<String> exportDatabase(File dbFile) async {
    final docs = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docs.path, 'backups'));
    // ignore: avoid_slow_async_io
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    final out = File(p.join(backupDir.path, 'backup-${DateTime.now().toIso8601String()}.sqlite'));
    await dbFile.copy(out.path);
    return out.path;
  }

  Future<void> importDatabase(File incoming) async {
    final docs = await getApplicationDocumentsDirectory();
    final dest = File(p.join(docs.path, 'doctor_app.sqlite'));
    // ignore: avoid_slow_async_io
    if (await dest.exists()) await dest.delete();
    await incoming.copy(dest.path);
  }
}
