import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

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
  }

  void startSync() {
    Workmanager().registerOneOffTask(
      "1",
      "simpleTask",
      initialDelay: const Duration(seconds: 10),
    );
  }

  Future<void> openVpnSettings() async {
    final Uri vpnUri = Uri.parse('intent:#Intent;action=android.settings.VPN_SETTINGS;end');
    if (await canLaunchUrl(vpnUri)) {
      await launchUrl(vpnUri);
    }
  }
}
