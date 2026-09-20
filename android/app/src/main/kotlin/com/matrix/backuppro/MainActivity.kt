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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledVpnApps" -> result.success(getInstalledVpnApps())
                "launchPackage" -> result.success(launchPackage(call.argument<String>("package")))
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

    private fun launchPackage(pkg: String?): Boolean {
        if (pkg == null) return false
        val intent = packageManager.getLaunchIntentForPackage(pkg) ?: return false
        startActivity(intent)
        return true
    }
}
