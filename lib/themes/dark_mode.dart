import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    surface: const Color(0xFF1C1B2E),
    primary: const Color(0xFF9FA8DA),
    secondary: const Color(0xFF252540),
    tertiary: const Color(0xFF2E2D4A),
    inversePrimary: Colors.grey.shade100,
  ),
);
