import 'dart:io';
import 'package:smb_connect/smb_connect.dart';

class RemoteFileEntry {
  final String relativePath;
  final int lastModified;

  RemoteFileEntry({required this.relativePath, required this.lastModified});
}

class SMBClient {
  final String ip;
  final String shareName;
  final String username;
  final String password;
  final String domain;
  SmbConnect? _connection;

  SMBClient({
    required this.ip,
    required this.shareName,
    required this.username,
    required this.password,
    this.domain = '',
  });

  Future<void> connect() async {
    if (_connection != null) return;
    _connection = await SmbConnect.connectAuth(
      host: ip,
      username: username,
      password: password,
      domain: domain,
    );
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  Future<void> _ensureFolderExists(String remoteFolder) async {
    if (_connection == null) await connect();
    
    // Split the remote folder path and create each directory if needed
    List<String> segments = remoteFolder.split('/').where((s) => s.isNotEmpty).toList();
    String currentPath = "/$shareName";
    
    for (String segment in segments) {
      currentPath = "$currentPath/$segment";
      try {
        await _connection!.createFolder(currentPath);
      } catch (e) {
        // Ignored. The folder probably already exists.
        // SmbConnect throws if folder exists.
      }
    }
  }

  /// Lists the subfolders directly under [remoteRelativePath] (relative to
  /// the share root; pass '' for the share root itself).
  Future<List<SmbFile>> listFolders(String remoteRelativePath) async {
    if (_connection == null) await connect();

    final String fullRemotePath = remoteRelativePath.isEmpty ? "/$shareName" : "/$shareName/$remoteRelativePath";
    final SmbFile folder = await _connection!.file(fullRemotePath);
    final List<SmbFile> entries = await _connection!.listFiles(folder);

    return entries.where((f) => f.isDirectory() && f.name != '.' && f.name != '..').toList();
  }

  Future<void> createFolder(String remoteRelativePath) async {
    await _ensureFolderExists(remoteRelativePath);
  }

  /// Recursively walks [remoteBasePath] (relative to the share root) and
  /// returns every file found, with its path relative to that base and its
  /// last-modified time.
  Future<List<RemoteFileEntry>> listFilesRecursive(String remoteBasePath) async {
    if (_connection == null) await connect();

    final List<RemoteFileEntry> results = [];

    Future<void> walk(String relativeDir) async {
      final String fullPath = relativeDir.isEmpty
          ? "/$shareName/$remoteBasePath"
          : "/$shareName/$remoteBasePath/$relativeDir";
      final SmbFile folder = await _connection!.file(fullPath);
      final List<SmbFile> entries = await _connection!.listFiles(folder);

      for (final entry in entries) {
        if (entry.name == '.' || entry.name == '..') continue;
        final String childRelative = relativeDir.isEmpty ? entry.name : '$relativeDir/${entry.name}';
        if (entry.isDirectory()) {
          await walk(childRelative);
        } else {
          results.add(RemoteFileEntry(relativePath: childRelative, lastModified: entry.lastModified));
        }
      }
    }

    await walk('');
    return results;
  }

  Future<void> downloadFile(String remoteRelativePath, File localDestination) async {
    if (_connection == null) await connect();

    final String fullRemotePath = "/$shareName/$remoteRelativePath";
    final SmbFile smbFile = await _connection!.file(fullRemotePath);

    await localDestination.parent.create(recursive: true);
    final Stream<List<int>> sourceStream = await _connection!.openRead(smbFile);
    final IOSink sink = localDestination.openWrite();
    await sink.addStream(sourceStream);
    await sink.flush();
    await sink.close();
  }

  Future<void> uploadFile(File localFile, String remoteRelativePath) async {
    if (_connection == null) await connect();

    // The remote path requires the share name prefix for SmbConnect
    // e.g. /shareName/my/folder/file.jpg
    final String fullRemotePath = "/$shareName/$remoteRelativePath";

    // Ensure the parent directory exists
    final String parentDir = remoteRelativePath.substring(0, remoteRelativePath.lastIndexOf('/'));
    if (parentDir.isNotEmpty) {
      await _ensureFolderExists(parentDir);
    }

    // Create the file
    SmbFile smbFile;
    try {
      smbFile = await _connection!.createFile(fullRemotePath);
    } catch (e) {
      // If it exists, we just grab a reference to it
      smbFile = await _connection!.file(fullRemotePath);
    }

    // Stream the data
    final IOSink sink = await _connection!.openWrite(smbFile);
    final Stream<List<int>> sourceStream = localFile.openRead();
    
    await sink.addStream(sourceStream);
    await sink.flush();
    await sink.close();
  }
}
