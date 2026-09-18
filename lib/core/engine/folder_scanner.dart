import 'dart:io';

class FolderScanner {
  /// Scans the given directory path and returns a list of File objects.
  Future<List<File>> scanDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return [];
    }

    List<File> files = [];
    try {
      final entities = dir.listSync(recursive: true);
      for (var entity in entities) {
        if (entity is File) {
          files.add(entity);
        }
      }
    } catch (e) {
      print('Failed to scan directory $path: $e');
    }
    return files;
  }
}
