import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/folder_pair.dart';
import 'nas_folder_browser.dart';

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
    if (selectedDirectory == null) return;
    if (_folders.any((f) => f.local == selectedDirectory)) return;

    final defaultRemote = selectedDirectory.split('/').last;
    final pair = FolderPair(local: selectedDirectory, remote: defaultRemote);
    setState(() {
      _folders.add(pair);
      _lastSyncEpochs[selectedDirectory] = 0;
    });

    // A folder pair needs both a source and a destination - immediately
    // prompt for the NAS destination instead of silently defaulting it.
    await _editDestination(pair, initialPath: defaultRemote);
  }

  void _removeFolder(FolderPair pair) {
    setState(() => _folders.remove(pair));
  }

  void _setDirection(FolderPair pair, SyncDirection direction) {
    setState(() => pair.direction = direction);
  }

  Future<void> _editDestination(FolderPair pair, {String? initialPath}) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => NasFolderBrowser(initialPath: initialPath ?? pair.remote)),
    );

    if (result != null && mounted) {
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
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  synced ? Icons.cloud_done : Icons.cloud_off,
                                  color: synced ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    folderName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit destination',
                                  onPressed: () => _editDestination(pair),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Remove folder',
                                  onPressed: () => _removeFolder(pair),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _FolderPathRow(label: 'Source', value: pair.local),
                            const SizedBox(height: 6),
                            _FolderPathRow(label: 'Destination', value: pair.remote),
                            const SizedBox(height: 12),
                            SegmentedButton<SyncDirection>(
                              segments: const [
                                ButtonSegment(value: SyncDirection.toNas, label: Text('To'), icon: Icon(Icons.upload, size: 16)),
                                ButtonSegment(value: SyncDirection.fromNas, label: Text('From'), icon: Icon(Icons.download, size: 16)),
                                ButtonSegment(value: SyncDirection.twoWay, label: Text('Two-Way'), icon: Icon(Icons.sync, size: 16)),
                              ],
                              selected: {pair.direction},
                              onSelectionChanged: (selection) => _setDirection(pair, selection.first),
                              style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _syncStatusLabel(pair),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
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

class _FolderPathRow extends StatelessWidget {
  final String label;
  final String value;

  const _FolderPathRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
