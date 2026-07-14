// Regression tests for the two behavioural changes the fidelity sweep added:
// the InfoTip dot-size parameter (Explore markers use 16/10, everything else
// stays 15/9) and the Goals screen's inline unit letters (the "h"/"m" render
// small beside the big number, per the mock's `.goal .num` + `.u` grammar).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/screens/data_displays.dart';
import 'package:nguyenindoubt_app/screens/settings_screens.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';
import 'package:nguyenindoubt_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: buildNidTheme(),
  home: Scaffold(body: child),
);

/// Collects every explicit fontSize in an inline span tree (root + children).
List<double> _fontSizes(InlineSpan span) {
  final sizes = <double>[];
  void walk(InlineSpan s) {
    final size = s.style?.fontSize;
    if (size != null) sizes.add(size);
    if (s is TextSpan) {
      for (final child in s.children ?? const <InlineSpan>[]) {
        walk(child);
      }
    }
  }

  walk(span);
  return sizes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('InfoTip defaults to a 15px dot', (tester) async {
    await tester.pumpWidget(_wrap(const InfoTip(term: 'HRV', body: 'x')));
    final dot = find.descendant(
      of: find.byType(InfoTip),
      matching: find.byType(Container),
    );
    expect(tester.getSize(dot.first), const Size(15, 15));
  });

  testWidgets('InfoTip honours a custom dotSize (Explore markers = 16)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const InfoTip(term: 'HRV', body: 'x', dotSize: 16, iconSize: 10)),
    );
    final dot = find.descendant(
      of: find.byType(InfoTip),
      matching: find.byType(Container),
    );
    expect(tester.getSize(dot.first), const Size(16, 16));
  });

  testWidgets('Goals value renders unit letters small beside the big number', (
    tester,
  ) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(_wrap(GoalsSettingsScreen(state: state)));
    await tester.pumpAndSettle();

    // The sleep goal reads like "8h 00m": find the RichText whose text carries
    // a unit letter, then assert the big number is 34 and the unit is 15.
    final richTexts = tester.widgetList<RichText>(find.byType(RichText));
    final goalValue = richTexts.firstWhere(
      (rt) => RegExp(r'\dh').hasMatch(rt.text.toPlainText()),
      orElse: () => throw StateError('no goal value RichText found'),
    );
    final sizes = _fontSizes(goalValue.text);
    expect(goalValue.text.style?.fontSize, 34, reason: 'number stays 34px');
    expect(sizes, contains(15), reason: 'unit letters render at 15px');
  });
}
