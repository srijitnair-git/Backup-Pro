import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FolderPair {
  String local;
  String remote;

  FolderPair({required this.local, required this.remote});

  Map<String, String> toJson() => {'local': local, 'remote': remote};

  factory FolderPair.fromJson(Map<String, dynamic> json) =>
      FolderPair(local: json['local'] as String, remote: json['remote'] as String);
}

class ManualFolderSelection extends StatefulWidget {
  const ManualFolderSelection({super.key});

  @override
  State<ManualFolderSelection> createState() => _ManualFolderSelectionState();
}

class _ManualFolderSelectionState extends State<ManualFolderSelection> {
  final List<FolderPair> _folders = [];
  final Map<String, int> _lastSyncEpochs = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('backup_folder_pairs');
    final loaded = <FolderPair>[];

    if (raw != null) {
      for (final entry in jsonDecode(raw) as List) {
        loaded.add(FolderPair.fromJson(entry as Map<String, dynamic>));
      }
    } else {
      // Migrate from the old flat local-path-only format.
      final legacy = prefs.getStringList('selected_backup_folders') ?? [];
      for (final path in legacy) {
        loaded.add(FolderPair(local: path, remote: path.split('/').last));
      }
    }

    final syncEpochs = <String, int>{};
    for (final pair in loaded) {
      syncEpochs[pair.local] = prefs.getInt('last_sync_${pair.local}') ?? 0;
    }

    setState(() {
      _folders.addAll(loaded);
      _lastSyncEpochs.addAll(syncEpochs);
    });
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backup_folder_pairs', jsonEncode(_folders.map((f) => f.toJson()).toList()));
    await prefs.remove('selected_backup_folders');
  }

  Future<void> _pickFolder() async {
    String? selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      if (_folders.any((f) => f.local == selectedDirectory)) return;
      setState(() {
        _folders.add(FolderPair(local: selectedDirectory, remote: selectedDirectory.split('/').last));
        _lastSyncEpochs[selectedDirectory] = 0;
      });
    }
  }

  void _removeFolder(FolderPair pair) {
    setState(() => _folders.remove(pair));
  }

  Future<void> _editDestination(FolderPair pair) async {
    final controller = TextEditingController(text: pair.remote);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Destination Path on NAS'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Relative path under the NAS share',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => pair.remote = result);
    }
  }

  String _syncStatusLabel(FolderPair pair) {
    final epoch = _lastSyncEpochs[pair.local] ?? 0;
    if (epoch == 0) return 'Never synced';
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch);
    return 'Last synced: ${dt.toLocal()}'.split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Select Backup Folders'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: _pickFolder,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.create_new_folder_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      'Add New Folder Pair',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _folders.isEmpty
                ? const Center(
                    child: Text(
                      'No folders selected for backup yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _folders.length,
                    itemBuilder: (context, index) {
                      final pair = _folders[index];
                      final folderName = pair.local.split('/').last;
                      final synced = (_lastSyncEpochs[pair.local] ?? 0) > 0;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(
                            synced ? Icons.cloud_done : Icons.cloud_off,
                            color: synced ? Colors.green : Colors.grey,
                          ),
                          title: Text(folderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From: ${pair.local}', style: const TextStyle(fontSize: 12)),
                              Text('To: ${pair.remote}', style: const TextStyle(fontSize: 12)),
                              Text(_syncStatusLabel(pair), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editDestination(pair),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _removeFolder(pair),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _folders.isNotEmpty ? FloatingActionButton.extended(
        onPressed: () async {
          await _saveFolders();
          if (mounted) {
            Navigator.pop(context, _folders);
          }
        },
        icon: const Icon(Icons.save),
        label: const Text('Save Configuration'),
      ) : null,
    );
  }
}
