// Guards the dark-theme wiring: the dark ThemeData carries the dark NidPalette
// extension, `context.nid` resolves to it under a dark theme, and a
// representative screen builds in dark mode without throwing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/screens/tab_shells.dart';
import 'package:nguyenindoubt_app/theme/app_theme.dart';

void main() {
  test('dark theme is dark and carries the dark NidPalette', () {
    final dark = buildNidDarkTheme();
    expect(dark.brightness, Brightness.dark);
    final palette = dark.extension<NidPalette>();
    expect(palette, isNotNull);
    expect(palette!.ink, NidColorsDark.ink);
    expect(palette.surface, NidColorsDark.surface);
    // Sanity: light and dark ink differ (inverted for legibility).
    expect(NidColorsDark.ink, isNot(NidColors.ink));
  });

  testWidgets('context.nid resolves to the dark palette under a dark theme', (
    tester,
  ) async {
    late NidPalette seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNidTheme(),
        darkTheme: buildNidDarkTheme(),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            seen = context.nid;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen.ink, NidColorsDark.ink);
    expect(seen.fog, NidColorsDark.fog);
  });

  testWidgets('a section kicker renders in dark mode without error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNidTheme(),
        darkTheme: buildNidDarkTheme(),
        themeMode: ThemeMode.dark,
        home: const Scaffold(body: SectionKicker('Sleep')),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('SLEEP'), findsOneWidget);
  });
}
