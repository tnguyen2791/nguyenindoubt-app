import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';

/// SAFE-02 affordance truth: the clinician invite rows must tell the truth
/// about tappability. Only accepted rows (which open a sleep summary) present
/// as tappable — enabled InkWell + chevron. Pending/revoked/expired rows are
/// muted (reduced opacity), carry no ink ripple or chevron, and never absorb a
/// tap. Lifecycle-label coverage lives in test/widget_test.dart; this test is
/// focused purely on the actionable/inert affordance split.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('only the accepted invite row exposes a tappable affordance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state, showSplash: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clinician demo override'));
    await tester.pumpAndSettle();

    // Seeded links: NID-8274 accepted, NID-1138 pending, NID-4455 expired.
    // Exactly one row is actionable, so exactly one chevron is present.
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    // The inert pending row is wrapped in a reduced-opacity layer.
    final inertOpacities = tester.widgetList<Opacity>(
      find.ancestor(
        of: find.text('NID-1138 - pending'),
        matching: find.byType(Opacity),
      ),
    );
    expect(
      inertOpacities.any((opacity) => opacity.opacity < 1.0),
      isTrue,
      reason: 'Inert (pending) rows must be muted with Opacity < 1.0.',
    );

    // The inert row has NO enabled InkWell tap target.
    expect(
      find.ancestor(
        of: find.text('NID-1138 - pending'),
        matching: find.byType(InkWell),
      ),
      findsNothing,
      reason: 'Inert rows must not present an ink ripple / tap target.',
    );

    // The accepted row IS reachable through an enabled InkWell.
    final acceptedInkWell = tester.widget<InkWell>(
      find.ancestor(
        of: find.text('NID-8274 - accepted'),
        matching: find.byType(InkWell),
      ),
    );
    expect(
      acceptedInkWell.onTap,
      isNotNull,
      reason: 'Accepted rows must expose a real onTap.',
    );

    // Clinician mode auto-selects the first linked patient on entry.
    final bundleBeforeInertTap = state.selectedPatientBundle;
    expect(bundleBeforeInertTap, isNotNull);

    // Tapping an inert row absorbs nothing — the selected bundle is untouched
    // (identity unchanged, no selectPatient call, no privacy path hit).
    await tester.tap(find.text('NID-1138 - pending'));
    await tester.pumpAndSettle();
    expect(state.selectedPatientBundle, same(bundleBeforeInertTap));

    // Tapping the accepted row DOES select the patient — a fresh bundle is
    // fetched, proving the affordance responds.
    await tester.tap(find.text('NID-8274 - accepted'));
    await tester.pumpAndSettle();
    expect(state.selectedPatientBundle, isNotNull);
    expect(state.selectedPatientBundle, isNot(same(bundleBeforeInertTap)));
  });
}
