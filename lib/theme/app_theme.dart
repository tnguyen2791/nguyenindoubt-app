import 'package:flutter/material.dart';

class NidColors {
  static const ink = Color(0xFF17211B);
  static const canopy = Color(0xFF1E4A34);
  static const moss = Color(0xFF5D7F43);
  static const sage = Color(0xFFA9BA92);
  static const mint = Color(0xFFE4EDDD);
  static const fog = Color(0xFFF6F7F1);
  static const bark = Color(0xFF6A4E35);
  static const ember = Color(0xFFC56844);
}

ThemeData buildNidTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: NidColors.canopy,
    brightness: Brightness.light,
    primary: NidColors.canopy,
    secondary: NidColors.moss,
    surface: NidColors.fog,
    error: NidColors.ember,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: NidColors.fog,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: NidColors.ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: NidColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: NidColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: NidColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: NidColors.ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: NidColors.ink),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: NidColors.canopy.withValues(alpha: 0.16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: NidColors.canopy, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: NidColors.mint,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
