import 'package:flutter/material.dart';

/// Self-contained NetWatch theme — independent of the host app's color seed,
/// so the inspector renders consistently regardless of how the user themed
/// their MaterialApp.
ThemeData nwTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final scheme = isDark
      ? const ColorScheme.dark(
          primary: Color(0xFF82AAFF),
          onPrimary: Color(0xFF002B5C),
          surface: Color(0xFF1A1A1A),
          onSurface: Color(0xFFE6E6E6),
          surfaceContainerLow: Color(0xFF222222),
          surfaceContainerHigh: Color(0xFF2A2A2A),
          surfaceContainerHighest: Color(0xFF333333),
          outline: Color(0xFF505050),
          outlineVariant: Color(0xFF3A3A3A),
          error: Color(0xFFF28B82),
        )
      : const ColorScheme.light(
          primary: Color(0xFF1F6FEB),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF1A1A1A),
          surfaceContainerLow: Color(0xFFF7F7F7),
          surfaceContainerHigh: Color(0xFFEDEDED),
          surfaceContainerHighest: Color(0xFFE3E3E3),
          outline: Color(0xFFAAAAAA),
          outlineVariant: Color(0xFFD0D0D0),
          error: Color(0xFFD93025),
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: scheme.onSurface),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.6),
      indicatorColor: scheme.primary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      selectedColor: scheme.primary.withValues(alpha: 0.18),
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
      secondaryLabelStyle: TextStyle(color: scheme.primary, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.onPrimary;
        return scheme.onSurface.withValues(alpha: 0.6);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return scheme.primary;
        return scheme.surfaceContainerHighest;
      }),
    ),
  );
}
