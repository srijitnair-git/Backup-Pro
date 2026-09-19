import 'package:flutter/material.dart';
import 'ui/premium_theme.dart';
import 'ui/dashboard/home_screen.dart';

void main() {
  runApp(const BackupProApp());
}

class BackupProApp extends StatelessWidget {
  const BackupProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backup Pro',
      theme: PremiumTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
