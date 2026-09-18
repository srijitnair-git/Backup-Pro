import 'package:flutter/material.dart';

class ManualFolderSelection extends StatefulWidget {
  const ManualFolderSelection({Key? key}) : super(key: key);

  @override
  State<ManualFolderSelection> createState() => _ManualFolderSelectionState();
}

class _ManualFolderSelectionState extends State<ManualFolderSelection> {
  final List<String> _selectedFolders = [];

  void _toggleFolder(String folder) {
    setState(() {
      if (_selectedFolders.contains(folder)) {
        _selectedFolders.remove(folder);
      } else {
        _selectedFolders.add(folder);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableFolders = ['Camera', 'Downloads', 'Documents', 'WhatsApp Images'];

    return Scaffold(
      appBar: AppBar(title: const Text('Select Folders')),
      body: ListView.builder(
        itemCount: availableFolders.length,
        itemBuilder: (context, index) {
          final folder = availableFolders[index];
          final isSelected = _selectedFolders.contains(folder);
          return CheckboxListTile(
            title: Text(folder),
            value: isSelected,
            onChanged: (bool? value) {
              _toggleFolder(folder);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Save and pop
          Navigator.pop(context, _selectedFolders);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
