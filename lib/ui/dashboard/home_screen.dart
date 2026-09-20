import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'live_transfer_dashboard.dart';
import 'manual_folder_selection.dart';
import 'settings_screen.dart';
import '../../core/background_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  double _progress = 0.0;
  String _currentFile = 'Idle';
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _pollStatus();
    });
    _pollStatus();
  }

  Future<void> _pollStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('sync_status') ?? 'Idle';
    final current = prefs.getInt('sync_current_file') ?? 0;
    final total = prefs.getInt('sync_total_files') ?? 1;
    final filename = prefs.getString('sync_current_filename') ?? 'Waiting...';

    double progress = total == 0 ? 0 : current / total;

    if (mounted) {
      setState(() {
        _status = status;
        _progress = progress;
        _currentFile = status == 'Complete' ? 'All files synced' : filename;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSync() {
    BackgroundService().startSync();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync triggered in background')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload_outlined, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Backup Pro', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LiveTransferDashboard(
              progress: _progress,
              currentFile: _currentFile,
            ),
            const SizedBox(height: 28),
            _ActionTile(
              icon: Icons.folder_copy_outlined,
              title: 'Backup Sources',
              subtitle: 'Select folders to sync to NAS',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManualFolderSelection()),
                );
              },
            ),
            const SizedBox(height: 14),
            _ActionTile(
              icon: Icons.settings_ethernet,
              title: 'NAS Configuration',
              subtitle: 'Set IP, Share, and Credentials',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 14),
            _ActionTile(
              icon: Icons.history,
              title: 'System Status',
              subtitle: _status,
              onTap: () {},
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _startSync,
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blueAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
