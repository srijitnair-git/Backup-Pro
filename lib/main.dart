import 'package:flutter/material.dart';

void main() {
  runApp(const BackupProApp());
}

class BackupProApp extends StatelessWidget {
  const BackupProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backup Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Backup Pro - Core Initialized'),
        ),
      ),
    );
  }
}
