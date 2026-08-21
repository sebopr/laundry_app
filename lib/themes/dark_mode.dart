import 'package:flutter/material.dart';

final _darkColorScheme = ColorScheme.dark(
  surface: const Color(0xFF171E27),
  primary: const Color(0xFF22C6C6),
  secondary: const Color(0xFF1D2530),
  tertiary: const Color(0xFF263140),
  inversePrimary: Colors.grey.shade100,
);

ThemeData darkMode = ThemeData(
  useMaterial3: true,
  colorScheme: _darkColorScheme,
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: _darkColorScheme.secondary,
    indicatorColor: _darkColorScheme.primary.withValues(alpha: 0.18),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: states.contains(WidgetState.selected)
            ? _darkColorScheme.primary
            : Colors.grey.shade500,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(WidgetState.selected)
            ? _darkColorScheme.primary
            : Colors.grey.shade500,
      ),
    ),
  ),
);
