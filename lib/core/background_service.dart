import 'dart:convert';
import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/folder_scanner.dart';
import 'network/smb_client.dart';
import 'network/retry.dart';
import 'network/vpn_manager.dart';

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
    final List<Map<String, dynamic>> folders =
        (jsonDecode(pairsRaw) as List).cast<Map<String, dynamic>>();
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
        final String folderPath = pair['local'] as String;
        final String remoteBase = pair['remote'] as String;

        print("Scanning $folderPath for modifications...");
        final List<File> filesToSync = await scanner.scanDirectory(folderPath);

        if (filesToSync.isEmpty) {
          print("No new files in $folderPath.");
          continue;
        }

        if (await FlutterForegroundTask.isRunningService) {
          FlutterForegroundTask.updateService(
            notificationTitle: 'Syncing ${filesToSync.length} files',
            notificationText: 'Uploading from $folderPath',
          );
        }

        await prefs.setString('sync_status', 'Syncing $folderPath');
        await prefs.setInt('sync_total_files', filesToSync.length);

        bool folderFullySucceeded = true;

        for (int i = 0; i < filesToSync.length; i++) {
          await prefs.setInt('sync_current_file', i + 1);
          final File file = filesToSync[i];
          final String relativePath = file.path.replaceFirst(folderPath, '');
          final String remotePath = "$remoteBase$relativePath";

          await prefs.setString('sync_current_filename', file.path.split('/').last);
          print("Uploading $remotePath...");

          try {
            // ponytail: retries the whole file on failure (file-level resume),
            // not a byte-range resume mid-upload. smb_connect has no clean
            // append/seek write API; upgrade if large-file resume matters.
            await withRetry(() => smbClient.uploadFile(file, remotePath));
          } catch (e) {
            print("Failed to upload $remotePath after retries: $e");
            folderFullySucceeded = false;
            anyFailure = true;
          }
        }

        // Only mark the folder synced if every file made it through, so
        // failures get re-scanned and retried on the next run.
        if (folderFullySucceeded) {
          await scanner.updateLastSyncTime(folderPath);
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
          notificationText: anyFailure ? 'Some files failed to upload.' : 'All folders are backed up.',
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
