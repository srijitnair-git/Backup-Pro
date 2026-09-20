import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/smb_client.dart';
import '../../core/network/vpn_manager.dart';

enum _ConnectionTestState { none, testing, success, failure }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipController = TextEditingController();
  final _shareController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = true;
  _ConnectionTestState _testState = _ConnectionTestState.none;
  String? _testError;
  List<VpnApp> _vpnApps = [];
  String? _preferredVpnPackage;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final vpnApps = await VpnManager().getInstalledVpnApps();
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _ipController.text = prefs.getString('nas_ip') ?? '';
      _shareController.text = prefs.getString('nas_share') ?? '';
      _userController.text = prefs.getString('nas_user') ?? '';
      _passController.text = prefs.getString('nas_pass') ?? '';
      _vpnApps = vpnApps;
      _preferredVpnPackage = prefs.getString('preferred_vpn_package');
      _appVersion = 'v${packageInfo.version} (build ${packageInfo.buildNumber})';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nas_ip', _ipController.text.trim());
    await prefs.setString('nas_share', _shareController.text.trim());
    await prefs.setString('nas_user', _userController.text.trim());
    await prefs.setString('nas_pass', _passController.text.trim());
    if (_preferredVpnPackage != null) {
      await prefs.setString('preferred_vpn_package', _preferredVpnPackage!);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NAS Settings saved successfully')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testState = _ConnectionTestState.testing;
      _testError = null;
    });

    final client = SMBClient(
      ip: _ipController.text.trim(),
      shareName: _shareController.text.trim(),
      username: _userController.text.trim(),
      password: _passController.text.trim(),
    );

    try {
      await client.connect();
      await client.disconnect();
      if (mounted) setState(() => _testState = _ConnectionTestState.success);
    } catch (e) {
      if (mounted) {
        setState(() {
          _testState = _ConnectionTestState.failure;
          _testError = e.toString();
        });
      }
    }
  }

  Widget _buildTestResult() {
    switch (_testState) {
      case _ConnectionTestState.testing:
        return const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Testing connection...'),
          ],
        );
      case _ConnectionTestState.success:
        return const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Connected successfully', style: TextStyle(color: Colors.green)),
          ],
        );
      case _ConnectionTestState.failure:
        return Row(
          children: [
            const Icon(Icons.error, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(child: Text('Failed: $_testError', style: const TextStyle(color: Colors.redAccent))),
          ],
        );
      case _ConnectionTestState.none:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('NAS Configuration'), elevation: 0, backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SettingsSection(
              title: 'NAS Credentials',
              children: [
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'NAS IP Address (e.g. 192.168.1.100)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _shareController,
                  decoration: const InputDecoration(
                    labelText: 'Share Name (e.g. Backup)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _testState == _ConnectionTestState.testing ? null : _testConnection,
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Test Connection'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTestResult(),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsSection(
              title: 'VPN Automation',
              children: [
                if (_vpnApps.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _vpnApps.any((a) => a.package == _preferredVpnPackage) ? _preferredVpnPackage : null,
                    decoration: const InputDecoration(
                      labelText: 'Preferred VPN app (auto-launched when off-network)',
                      border: OutlineInputBorder(),
                    ),
                    items: _vpnApps
                        .map((a) => DropdownMenuItem(value: a.package, child: Text(a.label)))
                        .toList(),
                    onChanged: (value) => setState(() => _preferredVpnPackage = value),
                  )
                else
                  const Text(
                    'No supported VPN apps detected on this device.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('Save Settings', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Backup Pro $_appVersion',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
