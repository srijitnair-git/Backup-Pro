import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManualFolderSelection extends StatefulWidget {
  const ManualFolderSelection({super.key});

  @override
  State<ManualFolderSelection> createState() => _ManualFolderSelectionState();
}

class _ManualFolderSelectionState extends State<ManualFolderSelection> {
  final List<String> _selectedFolders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedFolders.addAll(prefs.getStringList('selected_backup_folders') ?? []);
    });
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_backup_folders', _selectedFolders);
  }

  Future<void> _pickFolder() async {
    String? selectedDirectory = await FilePicker.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        if (!_selectedFolders.contains(selectedDirectory)) {
          _selectedFolders.add(selectedDirectory);
        }
      });
    }
  }

  void _removeFolder(String folder) {
    setState(() {
      _selectedFolders.remove(folder);
    });
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
            child: _selectedFolders.isEmpty
                ? const Center(
                    child: Text(
                      'No folders selected for backup yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedFolders.length,
                    itemBuilder: (context, index) {
                      final folder = _selectedFolders[index];
                      final folderName = folder.split('/').last;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.folder_shared, color: Colors.blueAccent),
                          title: Text(folderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(folder, style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _removeFolder(folder),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedFolders.isNotEmpty ? FloatingActionButton.extended(
        onPressed: () async {
          await _saveFolders();
          if (mounted) {
            Navigator.pop(context, _selectedFolders);
          }
        },
        icon: const Icon(Icons.save),
        label: const Text('Save Configuration'),
      ) : null,
    );
  }
}
