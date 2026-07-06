import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/screens/resources_screen.dart';
import 'package:nguyenindoubt_app/services/crisis_launcher.dart';

/// Records requested URIs and returns a configurable result WITHOUT launching
/// anything — so tests can assert the crisis wiring without hitting a real
/// platform channel or dialing a phone.
class _RecordingCrisisLauncher implements CrisisLauncher {
  _RecordingCrisisLauncher({this.result = true});

  final bool result;
  final List<Uri> requests = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    requests.add(uri);
    return result;
  }
}

Widget _wrap(CrisisLauncher launcher) {
  return MaterialApp(
    home: Scaffold(body: SafetyScreen(launcher: launcher)),
  );
}

Finder _selectableWithText(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is SelectableText && widget.data == value,
  );
}

void main() {
  testWidgets('crisis controls launch tel/sms URIs through the seam', (
    tester,
  ) async {
    final launcher = _RecordingCrisisLauncher();
    await tester.pumpWidget(_wrap(launcher));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Call 988'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text 988'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Call 911'));
    await tester.pumpAndSettle();

    expect(launcher.requests, <Uri>[
      Uri.parse('tel:988'),
      Uri.parse('sms:988'),
      Uri.parse('tel:911'),
    ]);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no handler degrades to a selectable number without crashing', (
    tester,
  ) async {
    final launcher = _RecordingCrisisLauncher(result: false);
    await tester.pumpWidget(_wrap(launcher));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Call 988'));
    await tester.pumpAndSettle();
    expect(_selectableWithText('988'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Call 911'));
    await tester.pumpAndSettle();
    expect(_selectableWithText('911'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The launch was attempted through the seam, but nothing auto-dialed.
    expect(
      launcher.requests,
      contains(Uri.parse('tel:988')),
    );
    expect(
      launcher.requests,
      contains(Uri.parse('tel:911')),
    );
  });

  testWidgets('educational and non-monitoring copy render without any tap', (
    tester,
  ) async {
    final launcher = _RecordingCrisisLauncher();
    await tester.pumpWidget(_wrap(launcher));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'NguyenInDoubt does not provide diagnosis, treatment, emergency monitoring, or patient-to-clinician messaging in this MVP.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('988 Suicide and Crisis Lifeline'),
      findsOneWidget,
    );
    expect(
      find.textContaining('nearest emergency department'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Got it'), findsNothing);
    expect(launcher.requests, isEmpty);
  });
}
