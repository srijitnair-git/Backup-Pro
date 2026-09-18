import 'package:flutter/material.dart';

class PremiumTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1E3A8A), // Dark Blue
      scaffoldBackgroundColor: const Color(0xFF1E293B), // Slate Grey
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6),
        secondary: Color(0xFF64748B),
      ),
    );
  }
}
