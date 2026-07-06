import 'package:flutter_test/flutter_test.dart';
import 'package:nguyenindoubt_app/main.dart';
import 'package:nguyenindoubt_app/repositories/app_repository.dart';
import 'package:nguyenindoubt_app/services/health_data_provider.dart';
import 'package:nguyenindoubt_app/state/app_state.dart';

void main() {
  testWidgets('patient can sign up and import mock sleep data', (tester) async {
    final state = NguyenInDoubtState(
      repository: InMemoryAppRepository(),
      healthDataProvider: MockHealthDataProvider(),
    );

    await tester.pumpWidget(NguyenInDoubtApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patient sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Morning check-in'), findsOneWidget);
    expect(find.text('No sleep samples yet'), findsOneWidget);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(state.summaries, isNotEmpty);
    expect(find.text('No sleep samples yet'), findsNothing);
  });
}
