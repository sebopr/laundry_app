import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    surface: const Color(0xFFF5F5F5),
    primary: const Color(0xFF5C6BC0),
    secondary: Colors.white,
    tertiary: Colors.white,
    inversePrimary: Colors.grey.shade900,
  ),
);
