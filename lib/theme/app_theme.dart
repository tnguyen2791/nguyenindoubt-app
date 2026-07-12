import 'package:flutter/material.dart';

import 'tokens.dart';

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

  /// Faintest caption tone — axis labels, day letters, quiet sub-text.
  static const faint = Color(0xFF7A887F);

  /// Contributor-bar name label — softer than ink so the name recedes
  /// behind the state word (== design contributor-name tone).
  static const contributorName = Color(0xFF33413A);
}

/// The dark-theme palette — the mocks' `[data-theme="dark"]` `:root` values
/// (e.g. `16-dashboard-dark.html`). Semantic names mirror [NidColors] so the
/// widget layer reads one brightness-aware [NidPalette] instead of either
/// fixed set.
class NidColorsDark {
  static const ink = Color(0xFFE8EEE2);
  static const canopy = Color(0xFF8FB56A);
  static const moss = Color(0xFF7FA45E);
  static const sage = Color(0xFFA9BA92);
  static const mint = Color(0xFF26332A);
  static const fog = Color(0xFF0F150F);
  static const ember = Color(0xFFE08A63);
  static const slate = Color(0xFF9DA99B);
  static const faint = Color(0xFF7C8A7E);
  static const contributorName = Color(0xFFC2CCBE);

  /// Card / raised surface (mock `--surface`) — replaces white in dark.
  static const surface = Color(0xFF18211A);

  /// Text/icon on a canopy-filled accent (mock `--onaccent`).
  static const onAccent = Color(0xFF0B120F);
}

/// The brightness-aware palette every widget reads via `context.nid`. Carries
/// the same semantic tones as [NidColors]/[NidColorsDark] plus [surface]
/// (card fill, white in light) and [onAccent] (text on a canopy fill), so the
/// widget layer never hardcodes `Colors.white` or a fixed hairline.
@immutable
class NidPalette extends ThemeExtension<NidPalette> {
  const NidPalette({
    required this.ink,
    required this.canopy,
    required this.moss,
    required this.sage,
    required this.mint,
    required this.fog,
    required this.ember,
    required this.slate,
    required this.faint,
    required this.contributorName,
    required this.surface,
    required this.onAccent,
    required this.line,
  });

  final Color ink;
  final Color canopy;
  final Color moss;
  final Color sage;
  final Color mint;
  final Color fog;
  final Color ember;
  final Color slate;
  final Color faint;
  final Color contributorName;
  final Color surface;
  final Color onAccent;

  /// The 1px hairline (mock `--line`): canopy@14% in light, ink@12% in dark.
  final Color line;

  static const light = NidPalette(
    ink: NidColors.ink,
    canopy: NidColors.canopy,
    moss: NidColors.moss,
    sage: NidColors.sage,
    mint: NidColors.mint,
    fog: NidColors.fog,
    ember: NidColors.ember,
    slate: NidColors.slate,
    faint: NidColors.faint,
    contributorName: NidColors.contributorName,
    surface: Colors.white,
    onAccent: Colors.white,
    line: Color(0x241E4A34), // canopy @ 14%
  );

  static const dark = NidPalette(
    ink: NidColorsDark.ink,
    canopy: NidColorsDark.canopy,
    moss: NidColorsDark.moss,
    sage: NidColorsDark.sage,
    mint: NidColorsDark.mint,
    fog: NidColorsDark.fog,
    ember: NidColorsDark.ember,
    slate: NidColorsDark.slate,
    faint: NidColorsDark.faint,
    contributorName: NidColorsDark.contributorName,
    surface: NidColorsDark.surface,
    onAccent: NidColorsDark.onAccent,
    line: Color(0x1FE8EEE2), // ink @ 12%
  );

  @override
  NidPalette copyWith({
    Color? ink,
    Color? canopy,
    Color? moss,
    Color? sage,
    Color? mint,
    Color? fog,
    Color? ember,
    Color? slate,
    Color? faint,
    Color? contributorName,
    Color? surface,
    Color? onAccent,
    Color? line,
  }) {
    return NidPalette(
      ink: ink ?? this.ink,
      canopy: canopy ?? this.canopy,
      moss: moss ?? this.moss,
      sage: sage ?? this.sage,
      mint: mint ?? this.mint,
      fog: fog ?? this.fog,
      ember: ember ?? this.ember,
      slate: slate ?? this.slate,
      faint: faint ?? this.faint,
      contributorName: contributorName ?? this.contributorName,
      surface: surface ?? this.surface,
      onAccent: onAccent ?? this.onAccent,
      line: line ?? this.line,
    );
  }

  @override
  NidPalette lerp(ThemeExtension<NidPalette>? other, double t) {
    if (other is! NidPalette) return this;
    return NidPalette(
      ink: Color.lerp(ink, other.ink, t)!,
      canopy: Color.lerp(canopy, other.canopy, t)!,
      moss: Color.lerp(moss, other.moss, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      fog: Color.lerp(fog, other.fog, t)!,
      ember: Color.lerp(ember, other.ember, t)!,
      slate: Color.lerp(slate, other.slate, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      contributorName: Color.lerp(contributorName, other.contributorName, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

/// Reads the active [NidPalette] from the theme. Widgets call `context.nid.ink`
/// etc. so every color resolves for the current brightness. Falls back to the
/// light palette if the extension is somehow absent.
extension NidPaletteContext on BuildContext {
  NidPalette get nid =>
      Theme.of(this).extension<NidPalette>() ?? NidPalette.light;
}

/// State colors for metric readouts — the design's `--state-*` ramp.
///
/// Every state color a data-display widget shows resolves here, never as a
/// hex literal in widget code. States describe the metric, never the person.
class NidStateColors {
  const NidStateColors._();

  static const optimal = Color(0xFF4F7A3C);
  static const good = Color(0xFF6E8544);
  static const fair = Color(0xFFA08B48);
  static const attention = Color(0xFFC4633E);

  /// The consistency-heatmap ramp (design `.l1`-`.l4`): more filled = closer to
  /// target. l1 is a pale mint-green, climbing to canopy at l4. `heatFlag`
  /// marks a short/attention day and matches the attention tone.
  static const heatEmpty = Color(0x00000000); // transparent gap cell
  static const heatL1 = Color(0xFFD7E4C9);
  static const heatL2 = NidColors.sage; // #A9BA92
  static const heatL3 = NidColors.moss; // #5D7F43
  static const heatL4 = NidColors.canopy; // #1E4A34
  static const heatFlag = Color(0xFFC4633E);

  /// Gradient stops for the continuous short-to-optimal sleep-hours ramp.
  static const rampStops = <double>[0.0, 0.22, 0.42, 0.60, 0.80, 1.0];

  /// Colors paired 1:1 with [rampStops].
  static const rampColors = <Color>[
    Color(0xFFC25A3A),
    Color(0xFFC0784A),
    Color(0xFFB58F47),
    Color(0xFF94904A),
    Color(0xFF6E8544),
    Color(0xFF4F7A3C),
  ];

  /// Continuous hours-to-color ramp: 5h and below reads short (ember-red),
  /// 8h and above reads optimal (deep green), piecewise-linear between.
  static Color forSleepHours(double hours) {
    final t = ((hours - 5) / 3).clamp(0.0, 1.0);
    for (var i = 0; i < rampStops.length - 1; i++) {
      if (t <= rampStops[i + 1]) {
        final span = rampStops[i + 1] - rampStops[i];
        final segment = span == 0 ? 0.0 : (t - rampStops[i]) / span;
        return Color.lerp(rampColors[i], rampColors[i + 1], segment)!;
      }
    }
    return rampColors.last;
  }
}

/// The light theme (unchanged tokens). See [_buildNidTheme].
ThemeData buildNidTheme() => _buildNidTheme(Brightness.light, NidPalette.light);

/// The dark theme — same structure, the mocks' dark palette. Driven by
/// `ThemeMode.system` from the app entry so the OS appearance selects it.
ThemeData buildNidDarkTheme() =>
    _buildNidTheme(Brightness.dark, NidPalette.dark);

/// One theme builder parameterized over a [NidPalette] so light and dark stay
/// structurally identical and only the palette changes. The palette is also
/// attached as a [ThemeExtension] so widgets read `context.nid.*`.
ThemeData _buildNidTheme(Brightness brightness, NidPalette p) {
  // Neutralize the fromSeed leak: keep canopy as the seed but pin every tone
  // that bleeds into components (outline/surface/secondary/tertiary) to
  // blessed palette values so nothing on screen is a generated tint (DS-04).
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.canopy,
        brightness: brightness,
        primary: p.canopy,
        secondary: p.moss,
        surface: p.fog,
        error: p.ember,
      ).copyWith(
        onPrimary: p.onAccent,
        onSurface: p.ink,
        outline: p.sage,
        outlineVariant: p.mint,
        secondaryContainer: p.mint,
        onSecondaryContainer: p.canopy,
        tertiary: p.moss,
        onSurfaceVariant: p.slate,
        surfaceContainerLowest: p.surface,
        surfaceContainerLow: p.fog,
        surfaceContainer: p.fog,
        surfaceContainerHigh: p.mint,
        surfaceContainerHighest: p.mint,
      );

  // The single type ladder. Every token the app reads is defined here so no
  // screen falls back to stock Material (DS-01). Inter ships only 400/500/600/
  // 700, so headings top out at w700 — never heavier.
  final textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: p.ink,
    ),
    displaySmall: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: p.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: p.ink,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: p.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: p.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: p.ink,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: p.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: p.ink,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: p.slate,
    ),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.fog,
    fontFamily: 'Inter',
    textTheme: textTheme,
    extensions: [p],
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? p.canopy : p.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? p.onAccent : p.ink;
        }),
        side: WidgetStateProperty.all(
          BorderSide(color: p.canopy.withValues(alpha: 0.16)),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NidRadius.card),
        side: BorderSide(color: p.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.canopy,
        foregroundColor: p.onAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NidRadius.control),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        // Min height 50 without forcing width: intrinsic when inline (e.g.
        // the trend-card "Import" button in a Row), full-width only when the
        // caller wraps it in SizedBox(width: double.infinity). Size.fromHeight
        // would set width == infinity and blow up unbounded-Row layouts.
        minimumSize: const Size(0, 50),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.slate,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NidRadius.control),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NidRadius.control),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NidRadius.control),
        borderSide: BorderSide(color: p.canopy, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.fog,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.mint,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
