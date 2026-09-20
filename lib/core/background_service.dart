import 'dart:convert';
import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/folder_scanner.dart';
import 'models/folder_pair.dart';
import 'network/smb_client.dart';
import 'network/retry.dart';
import 'network/vpn_manager.dart';

Future<int> _lastSyncEpoch(SharedPreferences prefs, String localPath) async {
  return prefs.getInt('last_sync_$localPath') ?? 0;
}

/// Uploads local files modified since the last sync to the NAS.
/// Returns true if every file made it through.
Future<bool> _syncToNas(SMBClient client, FolderScanner scanner, SharedPreferences prefs, FolderPair pair) async {
  final List<File> filesToSync = await scanner.scanDirectory(pair.local);
  if (filesToSync.isEmpty) return true;

  await prefs.setString('sync_status', 'Syncing ${pair.local}');
  await prefs.setInt('sync_total_files', filesToSync.length);

  bool allSucceeded = true;
  for (int i = 0; i < filesToSync.length; i++) {
    await prefs.setInt('sync_current_file', i + 1);
    final File file = filesToSync[i];
    final String relativePath = file.path.replaceFirst(pair.local, '');
    final String remotePath = "${pair.remote}$relativePath";
    await prefs.setString('sync_current_filename', file.path.split('/').last);
    print("Uploading $remotePath...");

    try {
      // ponytail: retries the whole file on failure (file-level resume), not
      // a byte-range resume mid-upload. smb_connect has no clean append/seek
      // write API; upgrade if large-file resume matters.
      await withRetry(() => client.uploadFile(file, remotePath));
    } catch (e) {
      print("Failed to upload $remotePath after retries: $e");
      allSucceeded = false;
    }
  }
  return allSucceeded;
}

/// Downloads NAS files modified since the last sync to the local folder.
/// Returns true if every file made it through.
Future<bool> _syncFromNas(SMBClient client, SharedPreferences prefs, FolderPair pair) async {
  final int lastSync = await _lastSyncEpoch(prefs, pair.local);
  final List<RemoteFileEntry> remoteEntries = await client.listFilesRecursive(pair.remote);
  final changed = remoteEntries.where((e) => e.lastModified > lastSync).toList();
  if (changed.isEmpty) return true;

  await prefs.setString('sync_status', 'Syncing ${pair.local}');
  await prefs.setInt('sync_total_files', changed.length);

  bool allSucceeded = true;
  for (int i = 0; i < changed.length; i++) {
    await prefs.setInt('sync_current_file', i + 1);
    final entry = changed[i];
    final String localFilePath = "${pair.local}/${entry.relativePath}";
    await prefs.setString('sync_current_filename', entry.relativePath.split('/').last);
    print("Downloading ${entry.relativePath}...");

    try {
      await withRetry(() => client.downloadFile('${pair.remote}/${entry.relativePath}', File(localFilePath)));
    } catch (e) {
      print("Failed to download ${entry.relativePath} after retries: $e");
      allSucceeded = false;
    }
  }
  return allSucceeded;
}

/// Syncs both directions. A file changed on only one side syncs that way; a
/// file changed on both sides since the last sync is skipped as a conflict
/// (matches FolderSync Pro's own default conflict behavior).
Future<bool> _syncTwoWay(SMBClient client, FolderScanner scanner, SharedPreferences prefs, FolderPair pair) async {
  final int lastSync = await _lastSyncEpoch(prefs, pair.local);

  final List<File> localFiles = await scanner.scanDirectory(pair.local);
  final Map<String, File> localChanged = {
    for (final f in localFiles) f.path.replaceFirst('${pair.local}/', ''): f,
  };

  final List<RemoteFileEntry> remoteEntries = await client.listFilesRecursive(pair.remote);
  final Map<String, RemoteFileEntry> remoteChanged = {
    for (final e in remoteEntries.where((e) => e.lastModified > lastSync)) e.relativePath: e,
  };

  final conflicts = localChanged.keys.toSet().intersection(remoteChanged.keys.toSet());
  for (final path in conflicts) {
    print("Conflict on $path (changed on both sides) - skipping.");
  }

  final toUpload = Map.of(localChanged)..removeWhere((k, _) => conflicts.contains(k));
  final toDownload = Map.of(remoteChanged)..removeWhere((k, _) => conflicts.contains(k));

  if (toUpload.isEmpty && toDownload.isEmpty) return true;

  await prefs.setString('sync_status', 'Syncing ${pair.local}');
  await prefs.setInt('sync_total_files', toUpload.length + toDownload.length);

  bool allSucceeded = true;
  int i = 0;

  for (final entry in toUpload.entries) {
    i++;
    await prefs.setInt('sync_current_file', i);
    await prefs.setString('sync_current_filename', entry.key.split('/').last);
    print("Uploading ${pair.remote}/${entry.key}...");
    try {
      await withRetry(() => client.uploadFile(entry.value, '${pair.remote}/${entry.key}'));
    } catch (e) {
      print("Failed to upload ${entry.key} after retries: $e");
      allSucceeded = false;
    }
  }

  for (final entry in toDownload.entries) {
    i++;
    await prefs.setInt('sync_current_file', i);
    await prefs.setString('sync_current_filename', entry.key.split('/').last);
    print("Downloading ${entry.key}...");
    try {
      await withRetry(() => client.downloadFile('${pair.remote}/${entry.key}', File('${pair.local}/${entry.key}')));
    } catch (e) {
      print("Failed to download ${entry.key} after retries: $e");
      allSucceeded = false;
    }
  }

  return allSucceeded;
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Native called background task: $task");
    final prefs = await SharedPreferences.getInstance();

    // In a real app, these would be loaded securely from flutter_secure_storage
    // or SharedPreferences after the user configures their NAS profile.
    final String nasIp = prefs.getString('nas_ip') ?? '192.168.1.100';
    final String nasShare = prefs.getString('nas_share') ?? 'Backup';
    final String nasUser = prefs.getString('nas_user') ?? 'admin';
    final String nasPass = prefs.getString('nas_pass') ?? 'password';

    // The source/destination folder pairs configured in the UI.
    final String? pairsRaw = prefs.getString('backup_folder_pairs');
    if (pairsRaw == null) {
      print("No folders configured to backup.");
      return Future.value(true);
    }
    final List<FolderPair> folders =
        (jsonDecode(pairsRaw) as List).map((e) => FolderPair.fromJson(e as Map<String, dynamic>)).toList();
    if (folders.isEmpty) {
      print("No folders configured to backup.");
      return Future.value(true);
    }

    if (!await VpnManager().ensureOnNetwork(nasIp)) {
      await prefs.setString('sync_status', 'Failed: Could not reach NAS (VPN required)');
      print("NAS unreachable and VPN could not establish connectivity.");
      return Future.value(false);
    }

    final scanner = FolderScanner();
    final smbClient = SMBClient(
      ip: nasIp,
      shareName: nasShare,
      username: nasUser,
      password: nasPass,
    );

    bool anyFailure = false;

    try {
      await withRetry(() => smbClient.connect());

      for (final pair in folders) {
        print("Scanning ${pair.local} (${pair.direction.name}) for modifications...");

        if (await FlutterForegroundTask.isRunningService) {
          FlutterForegroundTask.updateService(
            notificationTitle: 'Syncing ${pair.local}',
            notificationText: 'Direction: ${pair.direction.label}',
          );
        }

        final bool succeeded = switch (pair.direction) {
          SyncDirection.toNas => await _syncToNas(smbClient, scanner, prefs, pair),
          SyncDirection.fromNas => await _syncFromNas(smbClient, prefs, pair),
          SyncDirection.twoWay => await _syncTwoWay(smbClient, scanner, prefs, pair),
        };

        if (succeeded) {
          await scanner.updateLastSyncTime(pair.local);
        } else {
          anyFailure = true;
        }
      }

      await prefs.setString('sync_status', anyFailure ? 'Completed with errors' : 'Complete');
      print("Sync complete.");
    } catch (e) {
      await prefs.setString('sync_status', 'Failed: $e');
      print("Sync failed: $e");
      if (await FlutterForegroundTask.isRunningService) {
        FlutterForegroundTask.updateService(
          notificationTitle: 'Sync Failed',
          notificationText: 'Error connecting to NAS',
        );
      }
      return Future.value(false);
    } finally {
      await smbClient.disconnect();
      if (await FlutterForegroundTask.isRunningService) {
        FlutterForegroundTask.updateService(
          notificationTitle: anyFailure ? 'Sync Completed with Errors' : 'Sync Complete',
          notificationText: anyFailure ? 'Some files failed to sync.' : 'All folders are synced.',
        );
      }
    }

    return Future.value(!anyFailure);
  });
}

class BackgroundService {
  void initialize() {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'backup_pro_channel',
        channelName: 'Backup Pro Sync',
        channelDescription: 'Shows sync progress',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
  }

  void startSync() {
    Workmanager().registerOneOffTask(
      "backup_pro_sync_task",
      "syncTask",
      initialDelay: const Duration(seconds: 0),
    );
  }

  Future<void> startForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'Syncing files...',
      notificationText: 'Preparing to sync',
    );
  }

  Future<void> stopForegroundService() async {
    await FlutterForegroundTask.stopService();
  }
}
