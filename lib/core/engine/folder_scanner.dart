import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class FolderScanner {
  /// Scans the given directory path and returns a list of File objects
  /// that have been modified since the last sync time.
  Future<List<File>> scanDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final String lastSyncKey = 'last_sync_$path';
    
    // Load last sync time (default to epoch 0 if never synced)
    final int lastSyncEpoch = prefs.getInt(lastSyncKey) ?? 0;
    final DateTime lastSync = DateTime.fromMillisecondsSinceEpoch(lastSyncEpoch);

    final dir = Directory(path);
    if (!await dir.exists()) {
      return [];
    }

    List<File> filesToSync = [];
    try {
      // Use list() stream instead of listSync() to prevent blocking the main thread
      // on massive folders.
      await for (final FileSystemEntity entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final FileStat stat = await entity.stat();
          if (stat.type == FileSystemEntityType.file) {
            if (stat.modified.isAfter(lastSync)) {
              filesToSync.add(entity);
            }
          }
        }
      }
    } catch (e) {
      print('Failed to scan directory $path: $e');
    }
    
    return filesToSync;
  }

  /// Marks a directory as successfully synced up to the current time.
  Future<void> updateLastSyncTime(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final String lastSyncKey = 'last_sync_$path';
    await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }
}
