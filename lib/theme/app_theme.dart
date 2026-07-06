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

  /// Muted caption / legend tone — was a one-off literal outside the palette.
  static const slate = Color(0xFF54635A);
}

ThemeData buildNidTheme() {
  // Neutralize the fromSeed leak: keep canopy as the seed but pin every tone
  // that bleeds into components (outline/surface/secondary/tertiary) to
  // blessed NidColors values so nothing on screen is a generated tint (DS-04).
  final scheme =
      ColorScheme.fromSeed(
        seedColor: NidColors.canopy,
        brightness: Brightness.light,
        primary: NidColors.canopy,
        secondary: NidColors.moss,
        surface: NidColors.fog,
        error: NidColors.ember,
      ).copyWith(
        outline: NidColors.sage,
        outlineVariant: NidColors.mint,
        secondaryContainer: NidColors.mint,
        onSecondaryContainer: NidColors.canopy,
        tertiary: NidColors.moss,
        onSurfaceVariant: NidColors.slate,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: NidColors.fog,
        surfaceContainer: NidColors.fog,
        surfaceContainerHigh: NidColors.mint,
        surfaceContainerHighest: NidColors.mint,
      );

  // The single type ladder. Every token the app reads is defined here so no
  // screen falls back to stock Material (DS-01). Inter ships only 400/500/600/
  // 700, so headings top out at w700 — never heavier.
  const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: NidColors.ink,
    ),
    displaySmall: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: NidColors.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
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
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: NidColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: NidColors.ink,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: NidColors.slate,
    ),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: NidColors.fog,
    fontFamily: 'Inter',
    textTheme: textTheme,
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? NidColors.canopy
              : Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.white
              : NidColors.ink;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: NidColors.canopy.withValues(alpha: 0.16)),
        ),
      ),
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
      backgroundColor: NidColors.fog,
      surfaceTintColor: Colors.transparent,
      indicatorColor: NidColors.mint,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
