import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smb_connect/smb_connect.dart';

import '../../core/network/smb_client.dart';

/// Lets the user browse the configured NAS share and pick a destination
/// folder, instead of typing a path by hand. Returns the chosen relative
/// path (e.g. "Photos/2026") via Navigator.pop, or null if cancelled.
class NasFolderBrowser extends StatefulWidget {
  final String initialPath;

  const NasFolderBrowser({super.key, this.initialPath = ''});

  @override
  State<NasFolderBrowser> createState() => _NasFolderBrowserState();
}

class _NasFolderBrowserState extends State<NasFolderBrowser> {
  SMBClient? _client;
  String _currentPath = '';
  List<SmbFile> _folders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
    _connectAndLoad();
  }

  Future<void> _connectAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('nas_ip') ?? '';
    final share = prefs.getString('nas_share') ?? '';
    final user = prefs.getString('nas_user') ?? '';
    final pass = prefs.getString('nas_pass') ?? '';

    if (ip.isEmpty || share.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Set up your NAS IP and share name in NAS Configuration first.';
      });
      return;
    }

    _client = SMBClient(ip: ip, shareName: share, username: user, password: pass);
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final folders = await _client!.listFolders(_currentPath);
      folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _folders = folders;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not list folders: $e';
        _loading = false;
      });
    }
  }

  void _enterFolder(String name) {
    setState(() => _currentPath = _currentPath.isEmpty ? name : '$_currentPath/$name');
    _load();
  }

  void _goUp() {
    final segments = _currentPath.split('/')..removeLast();
    setState(() => _currentPath = segments.join('/'));
    _load();
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Folder name', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;
    final newPath = _currentPath.isEmpty ? name : '$_currentPath/$name';
    try {
      await _client!.createFolder(newPath);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create folder: $e')));
      }
    }
  }

  @override
  void dispose() {
    _client?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_currentPath.isEmpty ? 'Select NAS Folder' : '/$_currentPath'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New folder',
            onPressed: _client == null ? null : _createFolder,
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _currentPath),
            child: const Text('SELECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }

    return ListView(
      children: [
        if (_currentPath.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.arrow_upward),
            title: const Text('.. (up one level)'),
            onTap: _goUp,
          ),
        if (_folders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No subfolders here.', style: TextStyle(color: Colors.grey))),
          ),
        ..._folders.map((f) => ListTile(
              leading: const Icon(Icons.folder, color: Colors.blueAccent),
              title: Text(f.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _enterFolder(f.name),
            )),
      ],
    );
  }
}
