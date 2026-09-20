package com.matrix.backuppro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "backup_pro/vpn"

    // Known VPN app packages we know how to detect and launch.
    private val candidatePackages = mapOf(
        "com.wireguard.android" to "WireGuard",
        "com.tailscale.ipn" to "Tailscale",
        "net.openvpn.openvpn" to "OpenVPN Connect",
        "com.nordvpn.android" to "NordVPN",
        "com.protonvpn.android" to "ProtonVPN",
        "com.expressvpn.vpn" to "ExpressVPN",
        "com.surfshark.vpnclient.android" to "Surfshark",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Only "getInstalledVpnApps" is served here (Settings screen, always
        // run in the foreground UI engine). Launching the VPN app itself is
        // done via url_launcher from Dart instead, because that also needs to
        // work from Workmanager's headless background engine, which never
        // calls configureFlutterEngine and so never sees this channel.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledVpnApps" -> result.success(getInstalledVpnApps())
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledVpnApps(): List<Map<String, String>> {
        val pm = packageManager
        return candidatePackages.mapNotNull { (pkg, label) ->
            try {
                pm.getPackageInfo(pkg, 0)
                mapOf("package" to pkg, "label" to label)
            } catch (e: Exception) {
                null
            }
        }
    }
}
