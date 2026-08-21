import 'package:flutter/material.dart';

final _lightColorScheme = ColorScheme.light(
  surface: const Color(0xFFF3F7F7),
  primary: const Color(0xFF12A3A8),
  secondary: Colors.white,
  tertiary: Colors.white,
  inversePrimary: Colors.grey.shade900,
);

ThemeData lightMode = ThemeData(
  useMaterial3: true,
  colorScheme: _lightColorScheme,
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: _lightColorScheme.primary.withValues(alpha: 0.14),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: states.contains(WidgetState.selected)
            ? _lightColorScheme.primary
            : Colors.grey.shade500,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? _lightColorScheme.primary
            : Colors.grey.shade500,
      ),
    ),
  ),
);
