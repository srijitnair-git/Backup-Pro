import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/folder_scanner.dart';
import 'network/smb_client.dart';

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
    
    // The selected folders from our UI
    final List<String> folders = prefs.getStringList('selected_backup_folders') ?? [];
    if (folders.isEmpty) {
      print("No folders configured to backup.");
      return Future.value(true);
    }

    final scanner = FolderScanner();
    final smbClient = SMBClient(
      ip: nasIp,
      shareName: nasShare,
      username: nasUser,
      password: nasPass,
    );

    try {
      await smbClient.connect();

      for (String folderPath in folders) {
        print("Scanning $folderPath for modifications...");
        final List<File> filesToSync = await scanner.scanDirectory(folderPath);
        
        if (filesToSync.isEmpty) {
          print("No new files in $folderPath.");
          continue;
        }

        // Send a notification update via foreground service if it's running
        if (await FlutterForegroundTask.isRunningService) {
          FlutterForegroundTask.updateService(
            notificationTitle: 'Syncing ${filesToSync.length} files',
            notificationText: 'Uploading from $folderPath',
          );
        }

        for (int i = 0; i < filesToSync.length; i++) {
          final File file = filesToSync[i];
          final String relativePath = file.path.replaceFirst(folderPath, '');
          // Remote path structure: /DeviceName/FolderName/relative/path.jpg
          final String remotePath = "MyDevice/${folderPath.split('/').last}$relativePath";
          
          print("Uploading $remotePath...");
          await smbClient.uploadFile(file, remotePath);
        }

        // Successfully synced this folder
        await scanner.updateLastSyncTime(folderPath);
      }
      
      print("Sync complete.");
    } catch (e) {
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
          notificationTitle: 'Sync Complete',
          notificationText: 'All folders are backed up.',
        );
      }
    }

    return Future.value(true);
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

  Future<void> openVpnSettings() async {
    final Uri vpnUri = Uri.parse('intent:#Intent;action=android.settings.VPN_SETTINGS;end');
    if (await canLaunchUrl(vpnUri)) {
      await launchUrl(vpnUri);
    }
  }
}
