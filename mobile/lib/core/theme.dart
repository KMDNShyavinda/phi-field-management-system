import 'package:flutter/material.dart';

class PhiTheme {
  static const seed = Color(0xFF0B6E4F);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4F7F5),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        centerTitle: false,
      ),
    );
  }

  static Color riskColor(String risk) {
    switch (risk) {
      case 'high':
        return const Color(0xFFC62828);
      case 'medium':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF2E7D32);
    }
  }
}
