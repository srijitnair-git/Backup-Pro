import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Native called background task: $task");
    // Simulate sync
    await Future.delayed(const Duration(seconds: 2));
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
      "1",
      "simpleTask",
      initialDelay: const Duration(seconds: 10),
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
