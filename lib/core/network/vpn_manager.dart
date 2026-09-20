import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class VpnApp {
  final String package;
  final String label;
  VpnApp({required this.package, required this.label});
}

class VpnManager {
  static const _channel = MethodChannel('backup_pro/vpn');

  Future<List<VpnApp>> getInstalledVpnApps() async {
    final apps = await _channel.invokeMethod<List<dynamic>>('getInstalledVpnApps') ?? [];
    return apps
        .map((a) => VpnApp(package: a['package'] as String, label: a['label'] as String))
        .toList();
  }

  Future<bool> _isOnLan(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ensures the device can reach [host]:[port] (the NAS), launching the
  /// user's preferred VPN app if it currently can't. Returns true once
  /// reachable, false if still unreachable after retrying.
  Future<bool> ensureOnNetwork(String host, {int port = 445}) async {
    if (await _isOnLan(host, port)) return true;

    final prefs = await SharedPreferences.getInstance();
    final preferredPackage = prefs.getString('preferred_vpn_package');
    if (preferredPackage == null) return false;

    try {
      // Launching by MethodChannel would only work when a UI FlutterEngine is
      // attached (e.g. MainActivity's configureFlutterEngine). Scheduled syncs
      // run in Workmanager's headless background isolate, which has no such
      // engine, so a custom platform channel there throws MissingPluginException.
      // url_launcher is a real registered plugin and works in both engines.
      await launchUrl(
        Uri(scheme: 'android-app', host: preferredPackage),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Fall through to the reachability retries below; if the VPN never
      // came up we report unreachable rather than throwing out of a
      // background sync task.
    }

    // ponytail: fixed poll/backoff waiting for the VPN to connect, not an
    // event-based hook into the VPN app's own connection state (none of the
    // candidate apps expose one via intent). Upgrade if a specific VPN app's
    // connected-state broadcast is needed.
    for (final wait in [const Duration(seconds: 3), const Duration(seconds: 5), const Duration(seconds: 8)]) {
      await Future.delayed(wait);
      if (await _isOnLan(host, port)) return true;
    }

    return false;
  }
}
